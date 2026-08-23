function result = recon_TSE2D(filename, varargin)
%RECON_TSE2D Offline diagnostic reconstruction for Cartesian 2D TSE Twix.
%
% result = recon_TSE2D(filename, Name, Value, ...)
%
% Processing order
%   1. mapVBVD raw-data read
%   2. complex coil-noise prewhitening
%   3. per-slice/per-echo NAV phase correction
%   4. LIN-based Cartesian k-space packing
%   5. direct RSS (R=1) or 1D PE-GRAPPA followed by RSS (R>=2)
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
%   GRAPPA                  Reconstruct accelerated data (default true).
%   ComparePhaseCorrection  Also reconstruct without NAV correction (false).
%   Slices                  mapVBVD one-based SLC indices; [] means all.
%   OutputDir               If nonempty, save MAT/PNG/CSV diagnostics.
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
    p.addParameter('GRAPPA', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('GrappaKySourceCount', 4, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 2 && mod(x,1) == 0);
    p.addParameter('GrappaKxKernel', 0, ...
        @(x) isnumeric(x) && isvector(x) && all(mod(x,1) == 0));
    p.addParameter('GrappaRegularization', 1e-4, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('ComparePhaseCorrection', false, ...
        @(x) islogical(x) && isscalar(x));
    p.addParameter('Slices', [], @(x) isnumeric(x) && isvector(x));
    p.addParameter('KeepKspace', false, @(x) islogical(x) && isscalar(x));
    p.addParameter('OutputDir', '', @(x) ischar(x) || isstring(x));
    p.addParameter('OutputPrefix', '', @(x) ischar(x) || isstring(x));
    p.addParameter('SaveMat', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('SaveFigures', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('Verbose', true, @(x) islogical(x) && isscalar(x));
    p.parse(filename, varargin{:});
    opt = p.Results;

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
    clear noiseData;

    phaseCor = struct('applied',false,'coefficients',[], ...
        'metrics',table(),'warning',"");
    imageDataCorrected = imageData;
    refDataCorrected = refData;
    if opt.PhaseCorrection
        if isempty(phaseData)
            phaseCor.warning = "No phase-correction stream was available; no correction was applied.";
            warning('recon_TSE2D:NoPhaseCorrectionData','%s',phaseCor.warning);
        else
            phaseCor = estimate_TSE_phasecor(phaseData,phaseMdh, ...
                'ReferenceEcho',opt.PhaseReferenceEcho);
            imageDataCorrected = apply_TSE_phasecor(imageData,imageMdh,phaseCor);
            if ~isempty(refData)
                refDataCorrected = apply_TSE_phasecor(refData,refMdh,phaseCor);
            end
            phaseCor.applied = true;
            phaseCor.warning = "";
        end
    else
        phaseCor.warning = "Phase correction disabled by user.";
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
    if opt.KeepKspace
        finalKspace = cell(1,nSliceOut);
    else
        finalKspace = {};
    end

    R = meta.accelerationFactorPE;
    for iSlice = 1:nSliceOut
        slice = slices(iSlice);
        if opt.Verbose
            fprintf('recon_TSE2D: SLC=%d (%d/%d), R=%d\n', ...
                slice,iSlice,nSliceOut,R);
        end

        [kspace,imageMask,refMask] = pack_TSE2D_kspace( ...
            imageDataCorrected,imageMdh,refDataCorrected,refMdh,meta.nPE,slice);
        images.zeroFilled(:,:,iSlice) = recon_TSE2D_RSS(kspace);

        if R > 1 && opt.GRAPPA
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
        if opt.KeepKspace
            finalKspace{iSlice} = kspaceFinal;
        end

        if opt.ComparePhaseCorrection
            [kspaceNoPC,imageMaskNoPC,refMaskNoPC] = pack_TSE2D_kspace( ...
                imageData,imageMdh,refData,refMdh,meta.nPE,slice);
            if R > 1 && opt.GRAPPA
                kspaceNoPC = recon_TSE2D_GRAPPA(kspaceNoPC,imageMaskNoPC,refMaskNoPC,R, ...
                    'KySourceCount',opt.GrappaKySourceCount, ...
                    'KxKernel',opt.GrappaKxKernel, ...
                    'Regularization',opt.GrappaRegularization);
            end
            images.reconstructedNoPhaseCorrection(:,:,iSlice) = recon_TSE2D_RSS(kspaceNoPC);
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
    result.grappa = grappaInfo;
    result.images = images;
    result.kspace = finalKspace;
    result.rawStructure = raw;

    outputDir = char(string(opt.OutputDir));
    if ~isempty(outputDir)
        save_TSE2D_results(result,outputDir, ...
            'Prefix',opt.OutputPrefix, ...
            'SaveMat',opt.SaveMat, ...
            'SaveFigures',opt.SaveFigures);
    end

    if opt.Verbose
        fprintf('recon_TSE2D: complete. Matrix=%dx%d, slices=%d, R=%d, prewhiten=%d, phasecor=%d\n', ...
            meta.nRO,meta.nPE,nSliceOut,R,whiteningInfo.applied,phaseCor.applied);
    end
end
