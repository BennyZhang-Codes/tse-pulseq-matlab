function report = tune_TSE2D_CS_parameters(inputDat,varargin)
%TUNE_TSE2D_CS_PARAMETERS Compare TV/Haar weights on identical TSE2D models.
%
% report = tune_TSE2D_CS_parameters(inputDat,Name,Value,...)
%
% The raw data are read and prewhitened once. For every selected slice, one
% coil-compressed ESPIRiT model is reused by all candidates, so differences
% arise from the CS regularization rather than from sensitivity estimation.

    p = inputParser;
    p.addRequired('inputDat',@(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('MapVBVDPath','',@(x) ischar(x) || isstring(x));
    p.addParameter('Slices',[],@(x) isnumeric(x) && (isempty(x) || isvector(x)));
    p.addParameter('Candidates',[0.00125 0.00025; 0.00125 0.00050; ...
        0.00150 0.00025; 0.00150 0.00050; 0.00150 0.00075; ...
        0.00175 0.00050; 0.00175 0.00075; 0.00200 0.00050; ...
        0.00200 0.00100],@(x) isnumeric(x) && size(x,2) == 2 && ...
        all(isfinite(x(:))) && all(x(:) >= 0));
    p.addParameter('Iterations',250,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('Tolerance',0,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 0);
    p.addParameter('WaveletLevels',2,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 0 && mod(x,1) == 0);
    p.addParameter('UseGPU','auto',@isValidUseGPU);
    p.addParameter('SensitivityReadoutWidth',30,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 2 && mod(x,1) == 0);
    p.addParameter('OutputDir','',@(x) ischar(x) || isstring(x));
    p.addParameter('OutputPrefix','',@(x) ischar(x) || isstring(x));
    p.addParameter('SaveImages',true,@(x) islogical(x) && isscalar(x));
    p.addParameter('Verbose',true,@(x) islogical(x) && isscalar(x));
    p.parse(inputDat,varargin{:});
    opt = p.Results;

    inputDat = char(string(inputDat));
    outputDir = char(string(opt.OutputDir));
    if isempty(outputDir)
        outputDir = fullfile(fileparts(inputDat),'tuning');
    end
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end
    prefix = char(string(opt.OutputPrefix));
    if isempty(prefix)
        [~,prefix] = fileparts(inputDat);
    end

    base = recon_TSE2D(inputDat, ...
        'MapVBVDPath',opt.MapVBVDPath, ...
        'ReconstructionMethod','rss', ...
        'Prewhiten',true, ...
        'PhaseCorrection',false, ...
        'EchoMagnitudeCorrection',false, ...
        'Slices',opt.Slices, ...
        'KeepKspace',true, ...
        'SaveMat',false,'SaveFigures',false,'SaveNifti',false, ...
        'Verbose',opt.Verbose);

    candidates = double(opt.Candidates);
    nCandidate = size(candidates,1);
    slices = base.meta.reconstructedSlices;
    nSlice = numel(slices);
    nRO = base.meta.nRO;
    nPE = base.meta.nPE;
    images = zeros(nRO,nPE,nSlice,nCandidate,'single');
    zeroFilled = base.images.zeroFilled;
    metricRows = cell(nSlice*nCandidate,1);
    modelInfo = cell(1,nSlice);
    row = 0;

    for iSlice = 1:nSlice
        kspace = base.kspace{iSlice};
        acquiredMask = base.samplingMasks.acquired{iSlice};
        calibrationMask = base.samplingMasks.calibration{iSlice};
        if opt.Verbose
            fprintf(['tune_TSE2D_CS_parameters: SLC=%d, acquired=%d, ' ...
                'ACS=%d\n'],slices(iSlice),nnz(acquiredMask), ...
                nnz(calibrationMask));
        end
        model = prepare_TSE2D_sense_model(kspace,acquiredMask, ...
            calibrationMask, ...
            'SensitivityMethod','espirit', ...
            'SensitivityReadoutWidth',opt.SensitivityReadoutWidth, ...
            'ESPIRiTKernelSize',[6 6], ...
            'ESPIRiTSubspaceThreshold',0.02, ...
            'ESPIRiTEigenvalueCrop',0.95, ...
            'CoilCompressionEnergy',0.99, ...
            'MaximumVirtualCoils',12, ...
            'UseGPU',opt.UseGPU, ...
            'Verbose',opt.Verbose);
        modelInfo{iSlice} = stripModel(model);

        for iCandidate = 1:nCandidate
            tvWeight = candidates(iCandidate,1);
            waveletWeight = candidates(iCandidate,2);
            if opt.Verbose
                fprintf('  candidate %d/%d: TV=%.5g, Haar=%.5g\n', ...
                    iCandidate,nCandidate,tvWeight,waveletWeight);
            end
            [image,info] = recon_TSE2D_CS(model.kspace, ...
                model.acquiredMask,model.calibrationMask, ...
                'SensitivityMaps',model.sensitivities, ...
                'Iterations',opt.Iterations, ...
                'Tolerance',opt.Tolerance, ...
                'TVWeight',tvWeight, ...
                'WaveletWeight',waveletWeight, ...
                'WaveletLevels',opt.WaveletLevels, ...
                'UseGPU',opt.UseGPU, ...
                'Verbose',false);
            magnitude = abs(image);
            images(:,:,iSlice,iCandidate) = magnitude;
            quality = measureImageQuality(magnitude, ...
                model.sensitivity.supportMask);
            row = row+1;
            finalChange = info.history.RelativeChange(end);
            metricRows{row} = table(string(prefix),slices(iSlice), ...
                tvWeight,waveletWeight,info.iterations,finalChange, ...
                info.finalRelativeDataResidual,info.finalObjective, ...
                info.elapsedSeconds,quality.roughness,quality.peRoughness, ...
                quality.roRoughness,quality.peToRoRatio,quality.edgeP95, ...
                'VariableNames',{'Dataset','Slice','TVWeight', ...
                'WaveletWeight','Iterations','RelativeChange', ...
                'RelativeDataResidual','Objective','ElapsedSeconds', ...
                'InteriorRoughness','PERoughness','RORoughness', ...
                'PEToRORatio','EdgeP95'});
        end

        if opt.SaveImages
            saveMontage(images(:,:,iSlice,:),candidates,slices(iSlice), ...
                fullfile(outputDir,sprintf('%s_SLC%d_full.png', ...
                prefix,slices(iSlice))),false);
            saveMontage(images(:,:,iSlice,:),candidates,slices(iSlice), ...
                fullfile(outputDir,sprintf('%s_SLC%d_zoom.png', ...
                prefix,slices(iSlice))),true);
        end
    end

    metrics = vertcat(metricRows{1:row});
    report = struct('sourceFile',string(inputDat),'options',opt, ...
        'slices',slices,'candidates',candidates,'images',images, ...
        'zeroFilled',zeroFilled,'metrics',metrics,'modelInfo',{modelInfo});
    matFile = fullfile(outputDir,[prefix '_CS_tuning.mat']);
    csvFile = fullfile(outputDir,[prefix '_CS_tuning.csv']);
    save(matFile,'report','-v7.3');
    writetable(metrics,csvFile);
    report.outputFiles = struct('mat',string(matFile),'csv',string(csvFile));
end

function quality = measureImageQuality(image,support)
    image = double(image);
    support = logical(support);
    if ~isequal(size(support),size(image)) || nnz(support) < 100
        support = image > 0.08*max(image(:));
    end
    scale = percentile(image(support),99.5);
    image = image/max(scale,eps);
    smooth = conv2(image,gaussianKernel(1.2),'same');
    [gradientRO,gradientPE] = gradient(smooth);
    gradientMagnitude = hypot(gradientRO,gradientPE);
    interior = conv2(double(support),ones(7),'same') == 49;
    candidate = interior & smooth > 0.15;
    threshold = percentile(gradientMagnitude(candidate),55);
    uniform = candidate & gradientMagnitude <= threshold;
    highPass = image-conv2(image,gaussianKernel(2),'same');
    quality.roughness = robustStd(highPass(uniform));

    differencePE = diff(image,1,2);
    pairPE = uniform(:,1:end-1) & uniform(:,2:end);
    differenceRO = diff(image,1,1);
    pairRO = uniform(1:end-1,:) & uniform(2:end,:);
    quality.peRoughness = robustStd(differencePE(pairPE));
    quality.roRoughness = robustStd(differenceRO(pairRO));
    quality.peToRoRatio = quality.peRoughness/max(quality.roRoughness,eps);
    quality.edgeP95 = percentile(gradientMagnitude(candidate),95);
end

function value = robustStd(values)
    values = double(values(isfinite(values)));
    if isempty(values)
        value = NaN;
        return
    end
    center = median(values);
    value = 1.4826*median(abs(values-center));
end

function value = percentile(values,percent)
    values = sort(double(values(isfinite(values))));
    if isempty(values)
        value = NaN;
        return
    end
    index = 1+(numel(values)-1)*percent/100;
    lower = floor(index);
    upper = ceil(index);
    if lower == upper
        value = values(lower);
    else
        value = values(lower)+(index-lower)*(values(upper)-values(lower));
    end
end

function kernel = gaussianKernel(sigma)
    radius = max(1,ceil(3*sigma));
    axis = -radius:radius;
    kernel = exp(-(axis.^2)/(2*sigma^2));
    kernel = kernel/sum(kernel);
    kernel = kernel'*kernel;
end

function output = stripModel(model)
    output = struct('compression',model.compression, ...
        'sensitivity',rmfield(model.sensitivity,intersect( ...
        fieldnames(model.sensitivity),{'supportMask','lowResolutionRSS', ...
        'eigenvalueMap'})), ...
        'acquiredLines',nnz(model.acquiredMask), ...
        'calibrationLines',nnz(model.calibrationMask));
end

function saveMontage(images,candidates,slice,filename,zoomed)
    images = squeeze(images);
    nCandidate = size(images,3);
    columns = min(3,nCandidate);
    rows = ceil(nCandidate/columns);
    figureHandle = figure('Visible','off','Color','k', ...
        'Position',[100 100 420*columns 420*rows]);
    layout = tiledlayout(figureHandle,rows,columns, ...
        'Padding','compact','TileSpacing','compact');
    for q = 1:nCandidate
        image = double(images(:,:,q));
        if zoomed
            nRO = size(image,1);
            nPE = size(image,2);
            image = image(round(0.18*nRO):round(0.82*nRO), ...
                round(0.22*nPE):round(0.68*nPE));
        end
        nexttile(layout);
        imagesc(image,[0 percentile(image(:),99.7)]);
        axis image off;
        colormap gray;
        title(sprintf('TV %.5g | W %.5g',candidates(q,1), ...
            candidates(q,2)),'Color','w','FontSize',11);
    end
    if zoomed
        montageLabel = ' resolution/detail zoom';
    else
        montageLabel = '';
    end
    title(layout,sprintf('SLC %d%s',slice,montageLabel),'Color','w');
    exportgraphics(figureHandle,filename,'Resolution',150);
    close(figureHandle);
end

function tf = isValidUseGPU(value)
    tf = islogical(value) && isscalar(value);
    if tf
        return
    end
    tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
        strcmpi(string(value),'auto');
end
