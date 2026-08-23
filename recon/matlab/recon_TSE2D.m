function result = recon_TSE2D(filename, varargin)
%RECON_TSE2D Offline diagnostic reconstruction for Cartesian 2D TSE Twix.
%
% result = recon_TSE2D(filename, Name, Value, ...)
%
% Processing order
%   1. mapVBVD raw-data read
%   2. complex coil-noise prewhitening
%   3. per-slice/per-echo NAV phase correction
%   4. optional per-slice/per-echo NAV magnitude equalization
%   5. LIN-based Cartesian k-space packing
%   6. RSS, GRAPPA, iterative ESPIRiT-SENSE, or regularized SENSE-CS
%   7. magnitude output and optional NIfTI/MAT/diagnostic saving
%
% This workflow intentionally targets conventional 2D TSE only. It does not
% implement gSlider encoding or proprietary Siemens ICE coil combination and
% image filters.
%
% Important options
%   MapVBVDPath             Folder containing mapVBVD.m.
%   Prewhiten               Enable noise prewhitening (default true).
%   NoiseShrinkage          Covariance shrinkage to its diagonal (0.02).
%   PhaseCorrection         Apply TSE NAV correction (default true).
%   EchoMagnitudeCorrection Enable NAV echo-magnitude correction (false).
%   EchoMagnitudeAlpha      Target envelope exponent in [0,1] (default 1).
%   EchoMagnitudeMethod     'power' (legacy) or 'wiener' (default power).
%   EchoMagnitudeLambda     Wiener scalar or 'auto' (default auto).
%   EchoMagnitudeMaxGain    Auto-Wiener smooth gain limit (default 2).
%   ReconstructionMethod    'auto', 'rss', 'grappa', 'sense', or 'cs'.
%   GRAPPA                  Enable GRAPPA when method is 'auto' (true).
%   IterativeUseGPU         Use GPU for SENSE/CS: true, false, or 'auto'.
%   SensitivityMethod       'espirit' (default) or low-resolution 'rss'.
%   SENSEIterations         Ordinary SENSE CG iterations (default 50).
%   SENSETikhonov           Ordinary SENSE L2 weight (default 1e-4).
%   CSIterations            Primal-dual iterations (default 120).
%   CSTVWeight              CS isotropic-TV weight (default 0.002).
%   ComparePhaseCorrection  Also reconstruct without NAV correction (false).
%   Slices                  mapVBVD one-based SLC indices; [] means all.
%   OutputDir               If nonempty, save requested outputs.
%   SaveNifti               Save reconstructed magnitude as .nii.gz (false).
%   KeepKspace              Retain per-slice final k-space in result (false).

    p = inputParser;
    p.addRequired('filename', @(x) ischar(x) || isstring(x));
    p.addParameter('MapVBVDPath', '', @(x) ischar(x) || isstring(x));
    p.addParameter('RemoveOversampling', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('Prewhiten', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('NoiseShrinkage', 0.02, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
    p.addParameter('NoiseEigenvalueFloor', 1e-6, ...
        @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('PhaseCorrection', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('PhaseReferenceEcho', 1, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('EchoMagnitudeCorrection', false, @(x) islogical(x) && isscalar(x));
    p.addParameter('EchoMagnitudeAlpha', 1, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0 && x <= 1);
    p.addParameter('EchoMagnitudeMethod', 'power', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('EchoMagnitudeLambda', 'auto', @isValidEchoMagnitudeLambda);
    p.addParameter('EchoMagnitudeMaxGain', 2, ...
        @(x) isnumeric(x) && isreal(x) && isscalar(x) && ~isnan(x) && x >= 1);
    p.addParameter('ReconstructionMethod','auto', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('GRAPPA', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('GrappaKySourceCount', 4, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 2 && mod(x,1) == 0);
    p.addParameter('GrappaKxKernel', 0, ...
        @(x) isnumeric(x) && isvector(x) && all(mod(x,1) == 0));
    p.addParameter('GrappaRegularization', 1e-4, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('SENSEIterations',50, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('SENSETolerance',1e-5, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('SENSETikhonov',1e-4, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('CSIterations',120, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('CSTVWeight',0.002, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('CSWaveletWeight',0.001, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('CSWaveletLevels',2, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0 && mod(x,1) == 0);
    p.addParameter('IterativeUseGPU','auto',@isValidUseGPU);
    p.addParameter('SensitivityMethod','espirit', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('SensitivityReadoutWidth',30, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('ESPIRiTKernelSize',[6 6], ...
        @(x) isnumeric(x) && isvector(x) && numel(x) == 2 && ...
        all(isfinite(x)) && all(x >= 2) && all(mod(x,1) == 0));
    p.addParameter('ESPIRiTSubspaceThreshold',0.02, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0 && x < 1);
    p.addParameter('ESPIRiTEigenvalueCrop',0.95, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0 && x < 1.5);
    p.addParameter('CoilCompressionEnergy',0.99, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0 && x <= 1);
    p.addParameter('MaximumVirtualCoils',12, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('KeepSensitivityMaps',false, ...
        @(x) islogical(x) && isscalar(x));
    p.addParameter('ComparePhaseCorrection', false, ...
        @(x) islogical(x) && isscalar(x));
    p.addParameter('Slices', [], @(x) isnumeric(x) && (isempty(x) || isvector(x)));
    p.addParameter('KeepKspace', false, @(x) islogical(x) && isscalar(x));
    p.addParameter('OutputDir', '', @(x) ischar(x) || isstring(x));
    p.addParameter('OutputPrefix', '', @(x) ischar(x) || isstring(x));
    p.addParameter('SaveMat', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('SaveFigures', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('SaveNifti', false, @(x) islogical(x) && isscalar(x));
    p.addParameter('NiftiVoxelSizeMm', [], @(x) isempty(x) || ...
        (isnumeric(x) && isvector(x) && numel(x) == 3 && all(isfinite(x)) && all(x > 0)));
    p.addParameter('OverwriteOutputs', false, @(x) islogical(x) && isscalar(x));
    p.addParameter('Verbose', true, @(x) islogical(x) && isscalar(x));
    p.parse(filename, varargin{:});
    opt = p.Results;

    reconstructionMethod = lower(string(opt.ReconstructionMethod));
    if ~ismember(reconstructionMethod,["auto","rss","grappa","sense","cs"])
        error('recon_TSE2D:InvalidReconstructionMethod', ...
            ['ReconstructionMethod must be ''auto'', ''rss'', ''grappa'', ' ...
             '''sense'', or ''cs''; received ''%s''.'],reconstructionMethod);
    end
    sensitivityMethod = lower(string(opt.SensitivityMethod));
    if ~ismember(sensitivityMethod,["espirit","rss"])
        error('recon_TSE2D:InvalidSensitivityMethod', ...
            'SensitivityMethod must be ''espirit'' or ''rss''; received ''%s''.', ...
            sensitivityMethod);
    end

    opt.EchoMagnitudeMethod = lower(string(opt.EchoMagnitudeMethod));
    if ~ismember(opt.EchoMagnitudeMethod,["power","wiener"])
        error('recon_TSE2D:InvalidEchoMagnitudeMethod', ...
            'EchoMagnitudeMethod must be ''power'' or ''wiener''; received ''%s''.', ...
            opt.EchoMagnitudeMethod);
    end

    if opt.Verbose
        fprintf('recon_TSE2D: reading %s\n', char(string(filename)));
    end
    raw = read_TSE2D_twix(filename, ...
        'MapVBVDPath',opt.MapVBVDPath, ...
        'RemoveOversampling',opt.RemoveOversampling, ...
        'LoadNoise',opt.Prewhiten);

    meta = raw.meta;
    imageData = raw.image.data;
    imageMdh = raw.image.mdh;
    phaseData = raw.phasecor.data;
    phaseMdh = raw.phasecor.mdh;
    refData = raw.refscan.data;
    refMdh = raw.refscan.mdh;
    noiseData = raw.noise.data;
    raw.image.data = [];
    raw.phasecor.data = [];
    raw.refscan.data = [];
    raw.refscanPC.data = [];
    raw.noise.data = [];

    if opt.Prewhiten
        [whiteningMatrix, whiteningInfo] = estimate_noise_whitener( ...
            noiseData, meta.nCha, ...
            'Shrinkage',opt.NoiseShrinkage, ...
            'EigenvalueFloor',opt.NoiseEigenvalueFloor);
        if strlength(whiteningInfo.warning) > 0
            warning('recon_TSE2D:PrewhiteningFallback','%s',whiteningInfo.warning);
        end
        imageData = apply_coil_matrix(imageData,whiteningMatrix);
        if ~isempty(phaseData)
            phaseData = apply_coil_matrix(phaseData,whiteningMatrix);
        end
        if ~isempty(refData)
            refData = apply_coil_matrix(refData,whiteningMatrix);
        end
    else
        whiteningMatrix = eye(meta.nCha,'single');
        whiteningInfo = struct('applied',false,'nSamples',0,'shrinkage',0, ...
            'conditionBefore',NaN,'conditionAfter',NaN,'covariance',[], ...
            'covarianceRegularized',[],'whitenedCovariance',[], ...
            'warning',"Prewhitening disabled by user.");
    end
    navigatorNoiseVariance = estimateWhitenedNoiseVariance(whiteningInfo);
    clear noiseData;

    phaseCor = struct('applied',false,'coefficients',[],'amplitudeNorm',[], ...
        'metrics',table(),'warning',"");
    echoMagCor = struct('applied',false,'method',opt.EchoMagnitudeMethod, ...
        'alpha',double(opt.EchoMagnitudeAlpha), ...
        'exponent',double(opt.EchoMagnitudeAlpha)-1, ...
        'referenceEcho',double(opt.PhaseReferenceEcho), ...
        'amplitudeNorm',[],'gain',[],'correctedAmplitude',[], ...
        'lambdaMode',string(opt.EchoMagnitudeLambda), ...
        'lambdaBySlice',[],'lambdaNoiseBySlice',[],'lambdaGainBySlice',[], ...
        'maximumGainTarget',double(opt.EchoMagnitudeMaxGain), ...
        'minimumGain',NaN,'maximumGain',NaN, ...
        'maximumNoiseStdGain',NaN,'maximumNoiseVarianceGain',NaN, ...
        'warning',"");
    imageDataCorrected = imageData;
    refDataCorrected = refData;
    imageDataNoPhaseCorrection = imageData;
    refDataNoPhaseCorrection = refData;

    needNavigatorModel = opt.PhaseCorrection || opt.EchoMagnitudeCorrection;
    if needNavigatorModel
        if isempty(phaseData)
            phaseCor.warning = "No phase-correction stream was available; no correction was applied.";
            if opt.EchoMagnitudeCorrection
                error('recon_TSE2D:NoEchoMagnitudeData', ...
                    'Echo-magnitude correction requires the phase-correction navigator stream.');
            end
            warning('recon_TSE2D:NoPhaseCorrectionData','%s',phaseCor.warning);
        else
            phaseCor = estimate_TSE_phasecor(phaseData,phaseMdh, ...
                'ReferenceEcho',opt.PhaseReferenceEcho, ...
                'NoiseVariance',navigatorNoiseVariance);
            if opt.PhaseCorrection
                imageDataCorrected = apply_TSE_phasecor(imageData,imageMdh,phaseCor);
                if ~isempty(refData)
                    refDataCorrected = apply_TSE_phasecor(refData,refMdh,phaseCor);
                end
                phaseCor.applied = true;
                phaseCor.warning = "";
            else
                phaseCor.warning = "Phase correction disabled by user.";
            end

            if opt.EchoMagnitudeCorrection
                echoMagnitudeArgs = {'Method',opt.EchoMagnitudeMethod, ...
                    'Lambda',opt.EchoMagnitudeLambda, ...
                    'MaximumGain',opt.EchoMagnitudeMaxGain};
                [imageDataCorrected,echoMagCor] = apply_TSE_echomagcor( ...
                    imageDataCorrected,imageMdh,phaseCor,opt.EchoMagnitudeAlpha, ...
                    echoMagnitudeArgs{:});
                if ~isempty(refDataCorrected)
                    refDataCorrected = apply_TSE_echomagcor( ...
                        refDataCorrected,refMdh,phaseCor,opt.EchoMagnitudeAlpha, ...
                        echoMagnitudeArgs{:});
                end
                if opt.ComparePhaseCorrection
                    imageDataNoPhaseCorrection = apply_TSE_echomagcor( ...
                        imageDataNoPhaseCorrection,imageMdh,phaseCor, ...
                        opt.EchoMagnitudeAlpha,echoMagnitudeArgs{:});
                    if ~isempty(refDataNoPhaseCorrection)
                        refDataNoPhaseCorrection = apply_TSE_echomagcor( ...
                            refDataNoPhaseCorrection,refMdh,phaseCor, ...
                            opt.EchoMagnitudeAlpha,echoMagnitudeArgs{:});
                    end
                end
                echoMagCor.warning = "";
            else
                echoMagCor.warning = "Echo-magnitude correction disabled by user.";
            end
        end
    else
        phaseCor.warning = "Phase correction disabled by user.";
        echoMagCor.warning = "Echo-magnitude correction disabled by user.";
    end
    clear phaseData;

    slices = opt.Slices;
    if isempty(slices)
        slices = meta.sliceIndices;
    end
    slices = reshape(unique(slices,'stable'),1,[]);
    if any(~ismember(slices,meta.sliceIndices))
        error('recon_TSE2D:InvalidSlice', ...
            'Requested slices must be contained in [%s].', sprintf('%d ',meta.sliceIndices));
    end

    nSliceOut = numel(slices);
    images = struct();
    images.zeroFilled = zeros(meta.nRO,meta.nPE,nSliceOut,'single');
    images.reconstructed = zeros(meta.nRO,meta.nPE,nSliceOut,'single');
    images.reconstructedNoPhaseCorrection = [];
    if opt.ComparePhaseCorrection
        images.reconstructedNoPhaseCorrection = zeros(meta.nRO,meta.nPE,nSliceOut,'single');
    end
    grappaInfo = cell(1,nSliceOut);
    senseInfo = cell(1,nSliceOut);
    csInfo = cell(1,nSliceOut);
    sensitivityMaps = cell(1,nSliceOut);
    samplingMasks = struct('image',{cell(1,nSliceOut)}, ...
        'reference',{cell(1,nSliceOut)},'acquired',{cell(1,nSliceOut)});
    if opt.KeepKspace
        finalKspace = cell(1,nSliceOut);
    else
        finalKspace = {};
    end

    R = meta.accelerationFactorPE;
    if reconstructionMethod == "auto"
        if R > 1 && opt.GRAPPA
            selectedMethod = "grappa";
        else
            selectedMethod = "rss";
        end
    else
        selectedMethod = reconstructionMethod;
    end
    if selectedMethod == "grappa" && R <= 1
        selectedMethod = "rss";
    end
    if opt.Verbose
        fprintf('recon_TSE2D: reconstruction method = %s\n',selectedMethod);
    end
    for iSlice = 1:nSliceOut
        slice = slices(iSlice);
        if opt.Verbose
            fprintf('recon_TSE2D: SLC=%d (%d/%d), R=%d\n', ...
                slice,iSlice,nSliceOut,R);
        end

        [kspace,imageMask,refMask] = pack_TSE2D_kspace( ...
            imageDataCorrected,imageMdh,refDataCorrected,refMdh,meta.nPE,slice);
        samplingMasks.image{iSlice} = logical(imageMask);
        samplingMasks.reference{iSlice} = logical(refMask);
        samplingMasks.acquired{iSlice} = logical(imageMask | refMask);
        images.zeroFilled(:,:,iSlice) = recon_TSE2D_RSS(kspace);

        if selectedMethod == "sense" || selectedMethod == "cs"
            [iterativeImage,iterativeInfo,sensitivityMaps{iSlice}] = ...
                reconstructIterativeTSE2D(kspace,imageMask,refMask, ...
                selectedMethod,opt);
            images.reconstructed(:,:,iSlice) = abs(iterativeImage);
            kspaceFinal = kspace;
            grappaInfo{iSlice} = struct('applied',false, ...
                'reason',sprintf('%s reconstruction selected',selectedMethod));
            if selectedMethod == "sense"
                senseInfo{iSlice} = iterativeInfo;
            else
                csInfo{iSlice} = iterativeInfo;
            end
        else
            if selectedMethod == "grappa"
                [kspaceFinal,grappaInfo{iSlice}] = recon_TSE2D_GRAPPA( ...
                    kspace,imageMask,refMask,R, ...
                    'KySourceCount',opt.GrappaKySourceCount, ...
                    'KxKernel',opt.GrappaKxKernel, ...
                    'Regularization',opt.GrappaRegularization);
            else
                kspaceFinal = kspace;
                grappaInfo{iSlice} = struct('accelerationFactor',R, ...
                    'calibrationNMSE',NaN,'missingLinesFilled',0);
            end
            images.reconstructed(:,:,iSlice) = recon_TSE2D_RSS(kspaceFinal);
        end
        if opt.KeepKspace
            finalKspace{iSlice} = kspaceFinal;
        end

        if opt.ComparePhaseCorrection
            [kspaceNoPC,imageMaskNoPC,refMaskNoPC] = pack_TSE2D_kspace( ...
                imageDataNoPhaseCorrection,imageMdh,refDataNoPhaseCorrection,refMdh,meta.nPE,slice);
            if selectedMethod == "sense" || selectedMethod == "cs"
                iterativeImageNoPC = reconstructIterativeTSE2D( ...
                    kspaceNoPC,imageMaskNoPC,refMaskNoPC,selectedMethod,opt);
                images.reconstructedNoPhaseCorrection(:,:,iSlice) = ...
                    abs(iterativeImageNoPC);
            else
                if selectedMethod == "grappa"
                    kspaceNoPC = recon_TSE2D_GRAPPA(kspaceNoPC,imageMaskNoPC,refMaskNoPC,R, ...
                        'KySourceCount',opt.GrappaKySourceCount, ...
                        'KxKernel',opt.GrappaKxKernel, ...
                        'Regularization',opt.GrappaRegularization);
                end
                images.reconstructedNoPhaseCorrection(:,:,iSlice) = recon_TSE2D_RSS(kspaceNoPC);
            end
        end
    end

    result = struct();
    result.sourceFile = string(filename);
    result.meta = meta;
    result.meta.reconstructedSlices = slices;
    result.options = opt;
    result.prewhitening = whiteningInfo;
    result.prewhitening.matrix = whiteningMatrix;
    result.phaseCorrection = phaseCor;
    result.echoMagnitudeCorrection = echoMagCor;
    result.grappa = grappaInfo;
    result.sense = senseInfo;
    result.cs = csInfo;
    result.sensitivityMaps = sensitivityMaps;
    result.samplingMasks = samplingMasks;
    result.reconstructionMethod = selectedMethod;
    result.images = images;
    result.kspace = finalKspace;
    result.rawStructure = raw;
    result.outputFiles = struct();

    outputDir = char(string(opt.OutputDir));
    if ~isempty(outputDir)
        result.outputFiles = save_TSE2D_results(result,outputDir, ...
            'Prefix',opt.OutputPrefix, ...
            'SaveMat',opt.SaveMat, ...
            'SaveFigures',opt.SaveFigures, ...
            'SaveNifti',opt.SaveNifti, ...
            'NiftiVoxelSizeMm',opt.NiftiVoxelSizeMm, ...
            'Overwrite',opt.OverwriteOutputs);
    end

    if opt.Verbose
        fprintf(['recon_TSE2D: complete. Matrix=%dx%d, slices=%d, R=%d, ' ...
            'prewhiten=%d, phasecor=%d, echomag=%d, method=%s, alpha=%.3g\n'], ...
            meta.nRO,meta.nPE,nSliceOut,R,whiteningInfo.applied,phaseCor.applied, ...
            echoMagCor.applied,echoMagCor.method,echoMagCor.alpha);
    end
end
function [image,info,maps] = reconstructIterativeTSE2D( ...
        kspace,imageMask,refMask,method,opt)
    commonArguments = {'UseGPU',opt.IterativeUseGPU, ...
        'SensitivityMethod',opt.SensitivityMethod, ...
        'SensitivityReadoutWidth',opt.SensitivityReadoutWidth, ...
        'ESPIRiTKernelSize',opt.ESPIRiTKernelSize, ...
        'ESPIRiTSubspaceThreshold',opt.ESPIRiTSubspaceThreshold, ...
        'ESPIRiTEigenvalueCrop',opt.ESPIRiTEigenvalueCrop, ...
        'CoilCompressionEnergy',opt.CoilCompressionEnergy, ...
        'MaximumVirtualCoils',opt.MaximumVirtualCoils, ...
        'KeepSensitivityMaps',opt.KeepSensitivityMaps, ...
        'Verbose',opt.Verbose};
    switch method
        case "sense"
            [image,info,maps] = recon_TSE2D_SENSE( ...
                kspace,imageMask | refMask,refMask,commonArguments{:}, ...
                'Iterations',opt.SENSEIterations, ...
                'Tolerance',opt.SENSETolerance, ...
                'Tikhonov',opt.SENSETikhonov);
        case "cs"
            [image,info,maps] = recon_TSE2D_CS( ...
                kspace,imageMask | refMask,refMask,commonArguments{:}, ...
                'Iterations',opt.CSIterations, ...
                'TVWeight',opt.CSTVWeight, ...
                'WaveletWeight',opt.CSWaveletWeight, ...
                'WaveletLevels',opt.CSWaveletLevels);
        otherwise
            error('recon_TSE2D:InvalidIterativeMethod', ...
                'Iterative method must be ''sense'' or ''cs''.');
    end
end


function variance = estimateWhitenedNoiseVariance(whiteningInfo)
    variance = NaN;
    if ~isstruct(whiteningInfo) || ~isfield(whiteningInfo,'applied') || ...
            ~whiteningInfo.applied || ~isfield(whiteningInfo,'whitenedCovariance') || ...
            isempty(whiteningInfo.whitenedCovariance)
        return
    end
    diagonal = real(diag(double(whiteningInfo.whitenedCovariance)));
    diagonal = diagonal(isfinite(diagonal) & diagonal >= 0);
    if ~isempty(diagonal)
        variance = median(diagonal);
    end
end

function tf = isValidEchoMagnitudeLambda(value)
    tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value >= 0;
    if tf
        return
    end
    tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
        strcmpi(string(value),'auto');
end

function tf = isValidUseGPU(value)
    tf = islogical(value) && isscalar(value);
    if tf
        return
    end
    tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
        strcmpi(string(value),'auto');
end
