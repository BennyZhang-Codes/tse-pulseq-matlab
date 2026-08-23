function [sensitivities, info] = estimate_TSE2D_espirit( ...
        kspace, calibrationMask, varargin)
%ESTIMATE_TSE2D_ESPIRIT Estimate one set of ESPIRiT sensitivity maps.
%
% This is a native MATLAB implementation of the single-map ESPIRiT
% calibration workflow: form a block-Hankel calibration matrix, retain its
% signal subspace, transform the kernels into an image-domain covariance
% operator, and use power iteration for its dominant eigenvector/eigenvalue.

    p = inputParser;
    p.addParameter('CalibrationReadoutWidth',30,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 8 && mod(x,1) == 0);
    p.addParameter('KernelSize',[6 6],@(x) isnumeric(x) && isvector(x) && ...
        numel(x) == 2 && all(isfinite(x)) && all(x >= 2) && all(mod(x,1) == 0));
    p.addParameter('SubspaceThreshold',0.02,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x > 0 && x < 1);
    p.addParameter('EigenvalueCrop',0.95,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 0 && x < 1.5);
    p.addParameter('PowerIterations',50,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('PowerTolerance',1e-5,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 0);
    p.addParameter('UseGPU','auto',@isValidUseGPU);
    p.addParameter('Verbose',true,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(kspace,{'numeric'},{'nonempty'},mfilename,'kspace');
    if ndims(kspace) ~= 3
        error('estimate_TSE2D_espirit:InvalidKspace', ...
            'KSPACE must have dimensions [readout, phase, coil].');
    end
    kspace = complex(single(kspace));
    nRO = size(kspace,1);
    nPE = size(kspace,2);
    nCoil = size(kspace,3);
    calibrationMask = logical(reshape(calibrationMask,1,[]));
    if numel(calibrationMask) ~= nPE
        error('estimate_TSE2D_espirit:MaskSize', ...
            'CALIBRATIONMASK must match the phase-encoding dimension.');
    end
    phaseLines = find(calibrationMask);
    if numel(phaseLines) < 8 || any(diff(phaseLines) ~= 1)
        error('estimate_TSE2D_espirit:InvalidCalibrationRegion', ...
            'ESPIRiT requires at least eight contiguous ACS lines.');
    end

    readoutWidth = min(nRO,double(opt.CalibrationReadoutWidth));
    readoutLines = centeredRange(nRO,readoutWidth);
    calibration = kspace(readoutLines,phaseLines,:);
    kernelSize = double(reshape(opt.KernelSize,1,2));
    calibrationSize = [size(calibration,1) size(calibration,2)];
    blockCount = calibrationSize-kernelSize+1;
    if any(blockCount < 1)
        error('estimate_TSE2D_espirit:KernelTooLarge', ...
            'Kernel [%d %d] does not fit calibration matrix [%d %d].', ...
            kernelSize,calibrationSize);
    end

    nBlock = prod(blockCount);
    nFeature = prod(kernelSize)*nCoil;
    calibrationMatrix = complex(zeros(nBlock,nFeature,'single'));
    column = 1;
    for coil = 1:nCoil
        for phaseOffset = 1:kernelSize(2)
            for readoutOffset = 1:kernelSize(1)
                block = calibration( ...
                    readoutOffset:readoutOffset+blockCount(1)-1, ...
                    phaseOffset:phaseOffset+blockCount(2)-1,coil);
                calibrationMatrix(:,column) = block(:);
                column = column+1;
            end
        end
    end

    gram = double(calibrationMatrix)'*double(calibrationMatrix);
    gram = (gram+gram')/2;
    [rightVectors,singularValuesSquared] = eig(gram,'vector');
    singularValues = sqrt(max(real(singularValuesSquared),0));
    [singularValues,order] = sort(singularValues,'descend');
    rightVectors = rightVectors(:,order);
    if isempty(singularValues) || singularValues(1) <= 0
        error('estimate_TSE2D_espirit:ZeroCalibration', ...
            'The calibration matrix contains no finite signal subspace.');
    end
    signalSubspace = singularValues > double(opt.SubspaceThreshold)*singularValues(1);
    nKernel = nnz(signalSubspace);
    if nKernel < 1
        error('estimate_TSE2D_espirit:EmptySignalSubspace', ...
            'No singular vector passed the ESPIRiT subspace threshold.');
    end
    signalVectors = rightVectors(:,signalSubspace);
    clear gram rightVectors calibrationMatrix

    covariance = complex(zeros(nRO,nPE,nCoil,nCoil,'single'));
    readoutKernelLines = centeredRange(nRO,kernelSize(1));
    phaseKernelLines = centeredRange(nPE,kernelSize(2));
    for index = 1:nKernel
        kernel = reshape(conj(single(signalVectors(:,index))), ...
            kernelSize(1),kernelSize(2),nCoil);
        paddedKernel = complex(zeros(nRO,nPE,nCoil,'single'));
        paddedKernel(readoutKernelLines,phaseKernelLines,:) = kernel;
        imageKernel = ifft2c(paddedKernel);
        for outputCoil = 1:nCoil
            for inputCoil = 1:nCoil
                covariance(:,:,outputCoil,inputCoil) = ...
                    covariance(:,:,outputCoil,inputCoil) + ...
                    imageKernel(:,:,outputCoil).*conj(imageKernel(:,:,inputCoil));
            end
        end
    end
    covariance = covariance*single((nRO*nPE)/prod(kernelSize));
    clear signalVectors

    useGPU = resolveUseGPU(opt.UseGPU);
    covariancePages = reshape(permute(covariance,[3 4 1 2]), ...
        nCoil,nCoil,nRO*nPE);
    maps = complex(ones(nCoil,1,nRO*nPE,'single'));
    if useGPU
        covariancePages = gpuArray(covariancePages);
        maps = gpuArray(maps);
    end
    maps = maps./sqrt(sum(abs(maps).^2,1));
    relativeChange = inf;
    for iteration = 1:double(opt.PowerIterations)
        updated = pagemtimes(covariancePages,maps);
        eigenvalues = sqrt(sum(abs(updated).^2,1));
        updated = updated./max(eigenvalues,cast(1e-8,'like',eigenvalues));
        relativeChange = scalarDouble(norm(updated(:)-maps(:))/max(norm(maps(:)),eps));
        maps = updated;
        if opt.PowerTolerance > 0 && relativeChange < double(opt.PowerTolerance)
            break
        end
    end
    updated = pagemtimes(covariancePages,maps);
    eigenvalues = real(sum(conj(maps).*updated,1));
    maps = gatherIfNeeded(maps);
    eigenvalues = gatherIfNeeded(eigenvalues);
    clear covariance covariancePages updated

    sensitivities = permute(reshape(maps,nCoil,nRO,nPE),[2 3 1]);
    eigenvalueMap = reshape(eigenvalues,nRO,nPE);
    reference = sensitivities(:,:,1);
    referencePhase = reference./max(abs(reference),single(1e-8));
    sensitivities = sensitivities.*conj(referencePhase);
    support = eigenvalueMap > double(opt.EigenvalueCrop);
    if ~any(support,'all')
        error('estimate_TSE2D_espirit:EmptyEigenvalueSupport', ...
            ['No pixel passed EigenvalueCrop %.6g; maximum ESPIRiT ' ...
             'eigenvalue is %.6g.'],opt.EigenvalueCrop,max(eigenvalueMap,[],'all'));
    end
    sensitivities = sensitivities.*support;
    normalization = sqrt(sum(abs(sensitivities).^2,3));
    sensitivities = sensitivities./max(normalization,single(1e-8));
    sensitivities = sensitivities.*support;
    normalization = sqrt(sum(abs(sensitivities).^2,3));

    info = struct();
    info.method = 'ESPIRiT single-map power iteration';
    info.calibrationReadoutLines = readoutLines;
    info.calibrationPhaseLines = phaseLines;
    info.calibrationMatrixSize = [nBlock nFeature];
    info.kernelSize = kernelSize;
    info.subspaceThreshold = double(opt.SubspaceThreshold);
    info.signalSubspaceKernels = nKernel;
    info.singularValues = singularValues;
    info.eigenvalueCrop = double(opt.EigenvalueCrop);
    info.eigenvalueMap = single(eigenvalueMap);
    info.supportMask = support;
    info.supportFraction = nnz(support)/numel(support);
    info.powerIterations = iteration;
    info.powerRelativeChange = relativeChange;
    info.useGPU = useGPU;
    info.maximumNormalizationError = max(abs(normalization(support)-1),[],'all');
    if opt.Verbose
        fprintf(['estimate_TSE2D_espirit: calibration %dx%d, kernel %dx%d, ' ...
            '%d/%d signal vectors, support %.1f%%, power iter %d\n'], ...
            calibrationSize,kernelSize,nKernel,numel(singularValues), ...
            100*info.supportFraction,iteration);
    end
end

function range = centeredRange(fullSize,width)
    width = min(fullSize,double(width));
    first = floor(fullSize/2)+1-floor(width/2);
    last = first+width-1;
    if first < 1
        first = 1;
        last = width;
    elseif last > fullSize
        last = fullSize;
        first = fullSize-width+1;
    end
    range = first:last;
end

function image = ifft2c(kspace)
    scale = sqrt(size(kspace,1)*size(kspace,2));
    image = fftshift(fftshift(ifft(ifft( ...
        ifftshift(ifftshift(kspace,1),2),[],1),[],2),1),2)*scale;
end

function useGPU = resolveUseGPU(specification)
    if islogical(specification)
        useGPU = specification;
    else
        useGPU = false;
        try
            useGPU = gpuDeviceCount('available') > 0;
        catch
            useGPU = false;
        end
    end
    if useGPU
        try
            gpuDevice();
        catch ME
            error('estimate_TSE2D_espirit:GPUUnavailable', ...
                'UseGPU was requested but unavailable: %s',ME.message);
        end
    end
end

function value = scalarDouble(value)
    value = gatherIfNeeded(value);
    value = double(value);
end

function value = gatherIfNeeded(value)
    if isa(value,'gpuArray')
        value = gather(value);
    end
end

function tf = isValidUseGPU(value)
    tf = islogical(value) && isscalar(value);
    if tf
        return
    end
    tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
        strcmpi(string(value),'auto');
end
