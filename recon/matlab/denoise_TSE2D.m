function [denoised,report] = denoise_TSE2D(volume,method,varargin)
%DENOISE_TSE2D Apply a mature image-domain denoiser to a 2-D TSE volume.
%
% Supported METHOD values are:
%   'nlm'   - MATLAB imnlmfilt, conservative slice-wise baseline
%   'bm3d'  - official BM3D 4.x with a corner-estimated colored-noise PSD
%   'sanlm' - CAT12 MRI SANLM, slice-wise by default for anisotropic TSE
%   'tgv2'  - second-order TGV-L2, slice-wise primal-dual implementation
%
% The function does not alter NIfTI geometry; it operates only on voxel
% values. BM3D and CAT12 are optional third-party dependencies whose code is
% intentionally not vendored in this repository.

    p = inputParser;
    p.addParameter('VoxelSpacing',[1 1 1], ...
        @(x) isnumeric(x) && isvector(x) && numel(x) >= 2 && all(isfinite(x)) && all(x > 0));
    p.addParameter('CornerFraction',0.15, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0.08 && x <= 0.30);
    p.addParameter('NLMStrength',0.6, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    p.addParameter('BM3DPath','',@(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('BM3DProfile','np',@(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('BM3DColoredNoise',true,@(x) islogical(x) && isscalar(x));
    p.addParameter('BM3DNoiseScale',0.6, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    p.addParameter('SANLMPath','',@(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('SANLMMode','slice2d',@(x) any(strcmpi(string(x),["slice2d","volume3d"])));
    p.addParameter('SANLMSearchRadius',3, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1 && x == floor(x));
    p.addParameter('SANLMPatchRadius',1, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1 && x == floor(x));
    % CAT12 itself defaults to Gaussian SANLM. Its legacy Rician branch is
    % optional and is not a correct noncentral-chi model for RSS data.
    p.addParameter('SANLMRician',false,@(x) islogical(x) && isscalar(x));
    p.addParameter('TGVStrength',0.2, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    p.addParameter('TGVAlphaRatio',2, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
    p.addParameter('TGVIterations',500, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1 && x == floor(x));
    p.addParameter('TGVTolerance',1e-5, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('Verbose',true,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(volume,{'numeric'},{'real','finite','nonempty'}, ...
        mfilename,'volume',1);
    method = validatestring(lower(char(string(method))),{'nlm','bm3d','sanlm','tgv2'});
    originalClass = class(volume);
    source = single(volume);
    imageSize = size3(source);
    source = reshape(source,imageSize);
    spacing = double(opt.VoxelSpacing(:).');
    spacing(end+1:3) = 1;
    spacing = spacing(1:3);

    noiseCell = cell(1,imageSize(3));
    for iSlice = 1:imageSize(3)
        noiseCell{iSlice} = estimate_TSE2D_image_noise(source(:,:,iSlice), ...
            'CornerFraction',opt.CornerFraction);
    end
    noise = [noiseCell{:}];

    dependency = '';
    if strcmp(method,'bm3d')
        dependency = configureBM3D(opt.BM3DPath);
    elseif strcmp(method,'sanlm')
        dependency = configureSANLM(opt.SANLMPath);
    end

    denoised = zeros(imageSize,'single');
    elapsed = zeros(1,imageSize(3));
    clippedFraction = zeros(1,imageSize(3));
    solverInfo = cell(1,imageSize(3));
    if strcmp(method,'sanlm') && strcmpi(opt.SANLMMode,'volume3d')
        if spacing(3)/min(spacing(1:2)) > 1.5
            warning('denoise_TSE2D:AnisotropicSANLM', ...
                ['Volume3D SANLM ignores physical voxel spacing; through-plane spacing ', ...
                 'is %.3g times the smallest in-plane spacing.'], ...
                spacing(3)/min(spacing(1:2)));
        end
        timer = tic;
        [denoised,clippedFraction(:)] = runSANLMVolume(source,opt);
        totalElapsed = toc(timer);
        elapsed(:) = totalElapsed/imageSize(3);
    else
        for iSlice = 1:imageSize(3)
            inputSlice = source(:,:,iSlice);
            timer = tic;
            switch method
                case 'nlm'
                    [comparisonWindow,searchWindow] = nlmWindows(spacing(1));
                    h = max(opt.NLMStrength*noise(iSlice).sigma,eps('single'));
                    outputSlice = imnlmfilt(inputSlice, ...
                        'DegreeOfSmoothing',h, ...
                        'ComparisonWindowSize',comparisonWindow, ...
                        'SearchWindowSize',searchWindow);
                    solverInfo{iSlice} = struct('degreeOfSmoothing',h, ...
                        'comparisonWindow',comparisonWindow,'searchWindow',searchWindow);
                case 'bm3d'
                    [outputSlice,clippedFraction(iSlice)] = ...
                        runBM3DSlice(inputSlice,noise(iSlice),opt);
                case 'sanlm'
                    [outputSlice,clippedFraction(iSlice)] = runSANLMSlice(inputSlice,opt);
                case 'tgv2'
                    scale = max(double(inputSlice),[],'all');
                    if scale <= 0
                        outputSlice = inputSlice;
                        solverInfo{iSlice} = struct('iterations',0,'relativeChange',0, ...
                            'converged',true,'alpha1',0,'alpha0',0);
                    else
                        normalizedSigma = noise(iSlice).sigma/scale;
                        alpha1 = opt.TGVStrength*normalizedSigma;
                        [normalizedOutput,solverInfo{iSlice}] = denoise_TGV2( ...
                            double(inputSlice)/scale,alpha1, ...
                            'Alpha0',opt.TGVAlphaRatio*alpha1, ...
                            'MaxIterations',opt.TGVIterations, ...
                            'Tolerance',opt.TGVTolerance,'Nonnegative',true);
                        outputSlice = single(normalizedOutput*scale);
                    end
            end
            elapsed(iSlice) = toc(timer);
            denoised(:,:,iSlice) = single(outputSlice);
            if opt.Verbose
                fprintf('  %s slice %d/%d: %.3f s\n',upper(method), ...
                    iSlice,imageSize(3),elapsed(iSlice));
            end
        end
    end

    if ~all(isfinite(denoised),'all')
        error('denoise_TSE2D:NonfiniteOutput','%s generated nonfinite values.',method);
    end
    if ~isa(volume,'single')
        denoised = cast(denoised,originalClass);
    end

    report = struct();
    report.method = method;
    report.imageSize = imageSize;
    report.voxelSpacing = spacing;
    report.noiseSigma = [noise.sigma];
    report.noiseStationarityCV = [noise.stationarityCV];
    report.noisePsdNormalizationError = [noise.psdNormalizationError];
    report.noise = noise;
    report.elapsedSecondsPerSlice = elapsed;
    report.elapsedSeconds = sum(elapsed);
    report.clippedNegativeFraction = clippedFraction;
    report.dependencyPath = dependency;
    report.solver = solverInfo;
    report.options = opt;
end

function [output,clippedFraction] = runBM3DSlice(input,noise,opt)
    scale = max(double(input),[],'all');
    if scale <= 0
        output = input;
        clippedFraction = 0;
        return
    end
    normalized = double(input)/scale;
    if opt.BM3DColoredNoise
        sigmaPsd = noise.psd/scale^2*opt.BM3DNoiseScale^2;
    else
        sigmaPsd = noise.sigma/scale*opt.BM3DNoiseScale;
    end
    filtered = BM3D(normalized,sigmaPsd,char(string(opt.BM3DProfile)));
    clippedFraction = nnz(filtered < 0)/numel(filtered);
    if all(input >= 0,'all')
        filtered = max(filtered,0);
    end
    output = single(filtered*scale);
end

function [output,clippedFraction] = runSANLMSlice(input,opt)
    scale = max(double(input),[],'all');
    if scale <= 0
        output = input;
        clippedFraction = 0;
        return
    end
    normalized = single(double(input)/scale);
    radius = opt.SANLMSearchRadius+opt.SANLMPatchRadius;
    depth = 2*radius+1;
    working = repmat(normalized,[1 1 depth]);
    cat_sanlm(working,opt.SANLMSearchRadius,opt.SANLMPatchRadius, ...
        double(opt.SANLMRician));
    filtered = working(:,:,radius+1);
    clippedFraction = nnz(filtered < 0)/numel(filtered);
    if all(input >= 0,'all')
        filtered = max(filtered,0);
    end
    output = single(filtered*scale);
end

function [output,clippedFraction] = runSANLMVolume(input,opt)
    scale = max(double(input),[],'all');
    if scale <= 0
        output = input;
        clippedFraction = 0;
        return
    end
    % Allocate and copy explicitly. cat_sanlm modifies its input in place
    % and does not honor MATLAB copy-on-write semantics.
    working = zeros(size(input),'single');
    working(:) = single(double(input(:))/scale);
    cat_sanlm(working,opt.SANLMSearchRadius,opt.SANLMPatchRadius, ...
        double(opt.SANLMRician));
    clippedFraction = nnz(working < 0)/numel(working);
    if all(input >= 0,'all')
        working = max(working,0);
    end
    output = single(working*scale);
end

function pathUsed = configureBM3D(requestedPath)
    pathUsed = char(string(requestedPath));
    if isempty(pathUsed)
        base = fileparts(mfilename('fullpath'));
        pathUsed = fullfile(base,'third_party_local','bm3d-4.0.3', ...
            'bm3d_matlab_package_4.0.3','bm3d');
    end
    if exist('BM3D','file') ~= 2
        if ~isfolder(pathUsed)
            error('denoise_TSE2D:BM3DMissing', ...
                'BM3D is not installed. See THIRD_PARTY_DENOISERS.md.');
        end
        addpath(pathUsed);
    end
    if exist('BM3D','file') ~= 2
        error('denoise_TSE2D:BM3DMissing','BM3D.m was not found in %s.',pathUsed);
    end
end

function pathUsed = configureSANLM(requestedPath)
    pathUsed = char(string(requestedPath));
    if isempty(pathUsed)
        base = fileparts(mfilename('fullpath'));
        pathUsed = fullfile(base,'third_party_local','cat12');
    end
    if exist('cat_sanlm','file') ~= 3
        if ~isfolder(pathUsed)
            error('denoise_TSE2D:SANLMMissing', ...
                'CAT12 SANLM is not installed. See THIRD_PARTY_DENOISERS.md.');
        end
        addpath(pathUsed);
    end
    % The CAT12 MEX stores its Rician flag in global C state and only ever
    % changes it from false to true. Unload/reload it before a volume so a
    % previous Rician call cannot contaminate a later Gaussian call.
    clear('cat_sanlm');
    if exist('cat_sanlm','file') ~= 3
        error('denoise_TSE2D:SANLMMissing', ...
            'A compatible cat_sanlm MEX binary was not found in %s.',pathUsed);
    end
end

function [comparisonWindow,searchWindow] = nlmWindows(inPlaneSpacingMm)
    if inPlaneSpacingMm <= 0.5
        comparisonWindow = 5;
        searchWindow = 21;
    else
        comparisonWindow = 3;
        searchWindow = 11;
    end
end

function dimensions = size3(volume)
    dimensions = size(volume);
    dimensions(end+1:3) = 1;
    dimensions = dimensions(1:3);
end
