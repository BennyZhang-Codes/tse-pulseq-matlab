function [imageOut, info, sensitivities] = recon_TSE2D_CS( ...
        kspace, acquiredMask, calibrationMask, varargin)
%RECON_TSE2D_CS Multicoil Cartesian SENSE compressed-sensing reconstruction.
%
% Solves
%
%   min_x 0.5 || P F(Sx)-y ||_2^2
%         + TVWeight*||Dx||_2,1 + WaveletWeight*||W x||_1
%
% with a Chambolle-Pock primal-dual iteration. F is a unitary centered FFT,
% S contains ACS-derived complex coil sensitivities, P is the measured PE
% mask, D is the 2-D forward finite difference, and W is an orthonormal Haar
% transform whose coarsest approximation coefficients are not penalized.

    utilityDir = fullfile(fileparts(mfilename('fullpath')),'utils');
    if isfolder(utilityDir) && isempty(which('estimate_TSE2D_espirit'))
        addpath(utilityDir);
    end

    p = inputParser;
    p.addParameter('Iterations',120,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('TVWeight',0.002,@isNonnegativeScalar);
    p.addParameter('WaveletWeight',0.001,@isNonnegativeScalar);
    p.addParameter('WaveletLevels',2,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 0 && mod(x,1) == 0);
    p.addParameter('StepSize',0.30,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x > 0);
    p.addParameter('Tolerance',1e-4,@isNonnegativeScalar);
    p.addParameter('MinimumIterations',30,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('HistoryInterval',5,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('UseGPU','auto',@isValidUseGPU);
    p.addParameter('SensitivityReadoutWidth',30,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 2 && mod(x,1) == 0);
    p.addParameter('SensitivityMethod','espirit',@(x) ischar(x) || ...
        (isstring(x) && isscalar(x)));
    p.addParameter('ESPIRiTKernelSize',[6 6],@(x) isnumeric(x) && ...
        isvector(x) && numel(x) == 2 && all(isfinite(x)) && ...
        all(x >= 2) && all(mod(x,1) == 0));
    p.addParameter('ESPIRiTSubspaceThreshold',0.02,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x > 0 && x < 1);
    p.addParameter('ESPIRiTEigenvalueCrop',0.95,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 0 && x < 1.5);
    p.addParameter('CoilCompressionEnergy',0.99,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x > 0 && x <= 1);
    p.addParameter('MaximumVirtualCoils',12,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('MinimumVirtualCoils',4,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('SensitivityThreshold',0.02,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 0 && x < 1);
    p.addParameter('SensitivityMaps',[],@(x) isempty(x) || isnumeric(x));
    p.addParameter('KeepSensitivityMaps',false,@(x) islogical(x) && isscalar(x));
    p.addParameter('Verbose',true,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    model = prepare_TSE2D_sense_model( ...
        kspace,acquiredMask,calibrationMask, ...
        'SensitivityMethod',opt.SensitivityMethod, ...
        'SensitivityReadoutWidth',opt.SensitivityReadoutWidth, ...
        'ESPIRiTKernelSize',opt.ESPIRiTKernelSize, ...
        'ESPIRiTSubspaceThreshold',opt.ESPIRiTSubspaceThreshold, ...
        'ESPIRiTEigenvalueCrop',opt.ESPIRiTEigenvalueCrop, ...
        'CoilCompressionEnergy',opt.CoilCompressionEnergy, ...
        'MaximumVirtualCoils',opt.MaximumVirtualCoils, ...
        'MinimumVirtualCoils',opt.MinimumVirtualCoils, ...
        'SensitivityThreshold',opt.SensitivityThreshold, ...
        'SensitivityMaps',opt.SensitivityMaps, ...
        'UseGPU',opt.UseGPU, ...
        'Verbose',opt.Verbose);
    kspace = model.kspace;
    sensitivities = model.sensitivities;
    compressionInfo = model.compression;
    mapInfo = model.sensitivity;
    acquiredMask = model.acquiredMask;
    calibrationMask = model.calibrationMask;
    nRO = size(kspace,1);
    nPE = size(kspace,2);

    levels = resolveWaveletLevels([nRO nPE],double(opt.WaveletLevels));
    step = double(opt.StepSize);
    operatorNormSquaredBound = 1 + 8 + double(levels > 0);
    if step^2*operatorNormSquaredBound >= 1
        error('recon_TSE2D_CS:UnstableStepSize', ...
            ['StepSize %.6g is too large; require StepSize^2*%g < 1 ' ...
             'for the current operator.'],step,operatorNormSquaredBound);
    end

    useGPU = resolveUseGPU(opt.UseGPU);
    kspace = complex(single(kspace));
    sensitivities = complex(single(sensitivities));
    mask = model.mask;
    kspace = kspace.*mask;
    if useGPU
        kspace = gpuArray(kspace);
        sensitivities = gpuArray(sensitivities);
        mask = gpuArray(mask);
    end

    initial = sense_TSE2D_adjoint(kspace,sensitivities,mask);
    imageScale = robustScale(abs(initial),mapInfo.supportMask);
    kspace = kspace/cast(imageScale,'like',kspace);
    x = initial/cast(imageScale,'like',initial);
    xBar = x;

    dataDual = complex(zeros(size(kspace),'like',kspace));
    tvDualRO = complex(zeros(nRO,nPE,'like',x));
    tvDualPE = complex(zeros(nRO,nPE,'like',x));
    waveletDual = complex(zeros(nRO,nPE,'like',x));
    sigma = cast(step,'like',real(x));
    tau = sigma;
    tvWeight = cast(double(opt.TVWeight),'like',real(x));
    waveletWeight = cast(double(opt.WaveletWeight),'like',real(x));

    testX = complex(rand(nRO,nPE,'like',real(x)),rand(nRO,nPE,'like',real(x)));
    testForward = sense_TSE2D_forward(testX,sensitivities,mask);
    testAdjoint = sense_TSE2D_adjoint(kspace,sensitivities,mask);
    lhs = sum(conj(testForward(:)).*kspace(:));
    rhs = sum(conj(testX(:)).*testAdjoint(:));
    adjointRelativeError = scalarDouble(abs(lhs-rhs)/max(abs(lhs)+abs(rhs),eps));
    if adjointRelativeError > 5e-5
        error('recon_TSE2D_CS:AdjointCheckFailed', ...
            'SENSE forward/adjoint relative error is %.6g.',adjointRelativeError);
    end
    clear testX testForward testAdjoint lhs rhs

    nHistory = ceil(double(opt.Iterations)/double(opt.HistoryInterval))+1;
    historyIteration = zeros(nHistory,1);
    historyObjective = nan(nHistory,1);
    historyDataResidual = nan(nHistory,1);
    historyRelativeChange = nan(nHistory,1);
    historyIndex = 0;
    converged = false;
    timer = tic;

    for iteration = 1:double(opt.Iterations)
        forward = sense_TSE2D_forward(xBar,sensitivities,mask);
        dataDual = (dataDual+sigma*forward-sigma*kspace)/(1+sigma);

        if opt.TVWeight > 0
            [gradientRO,gradientPE] = forwardDifference(xBar);
            tvDualRO = tvDualRO+sigma*gradientRO;
            tvDualPE = tvDualPE+sigma*gradientPE;
            dualMagnitude = sqrt(abs(tvDualRO).^2+abs(tvDualPE).^2);
            dualScale = max(1,dualMagnitude/tvWeight);
            tvDualRO = tvDualRO./dualScale;
            tvDualPE = tvDualPE./dualScale;
        end

        if levels > 0 && opt.WaveletWeight > 0
            waveletDual = waveletDual+sigma*haarForward(xBar,levels);
            waveletDual = projectWaveletDual( ...
                waveletDual,waveletWeight,levels);
        end

        gradient = sense_TSE2D_adjoint(dataDual,sensitivities,mask);
        if opt.TVWeight > 0
            gradient = gradient+finiteDifferenceAdjoint(tvDualRO,tvDualPE);
        end
        if levels > 0 && opt.WaveletWeight > 0
            gradient = gradient+haarInverse(waveletDual,levels);
        end

        xPrevious = x;
        x = x-tau*gradient;
        xBar = 2*x-xPrevious;
        relativeChange = scalarDouble(norm(x(:)-xPrevious(:))/max(norm(xPrevious(:)),eps));

        record = mod(iteration,double(opt.HistoryInterval)) == 0 || ...
            iteration == 1 || iteration == double(opt.Iterations);
        if record
            [objective,relativeResidual] = evaluateObjective( ...
                x,kspace,sensitivities,mask,double(opt.TVWeight), ...
                double(opt.WaveletWeight),levels);
            historyIndex = historyIndex+1;
            historyIteration(historyIndex) = iteration;
            historyObjective(historyIndex) = objective;
            historyDataResidual(historyIndex) = relativeResidual;
            historyRelativeChange(historyIndex) = relativeChange;
            if opt.Verbose
                fprintf(['recon_TSE2D_CS: iter %3d, objective %.6g, ' ...
                    'data residual %.6g, relative change %.3g\n'], ...
                    iteration,objective,relativeResidual,relativeChange);
            end
        end

        if iteration >= double(opt.MinimumIterations) && ...
                opt.Tolerance > 0 && relativeChange < double(opt.Tolerance)
            converged = true;
            break
        end
    end

    elapsedSeconds = toc(timer);
    [finalObjective,finalResidual] = evaluateObjective( ...
        x,kspace,sensitivities,mask,double(opt.TVWeight), ...
        double(opt.WaveletWeight),levels);
    imageOut = gatherIfNeeded(x)*single(imageScale);
    imageOut = complex(single(imageOut));
    sensitivities = gatherIfNeeded(sensitivities);
    if ~opt.KeepSensitivityMaps
        sensitivities = [];
    end

    historyIndex = max(historyIndex,1);
    info = struct();
    info.method = 'multicoil SENSE + TV + orthonormal Haar L1';
    info.iterations = iteration;
    info.maximumIterations = double(opt.Iterations);
    info.converged = converged;
    info.tolerance = double(opt.Tolerance);
    info.elapsedSeconds = elapsedSeconds;
    info.useGPU = useGPU;
    info.acquiredLines = nnz(acquiredMask);
    info.calibrationLines = nnz(calibrationMask);
    info.effectiveAcceleration = nPE/nnz(acquiredMask);
    info.tvWeight = double(opt.TVWeight);
    info.waveletWeight = double(opt.WaveletWeight);
    info.waveletLevels = levels;
    info.stepSize = step;
    info.imageScale = imageScale;
    info.finalObjective = finalObjective;
    info.finalRelativeDataResidual = finalResidual;
    info.adjointRelativeError = adjointRelativeError;
    info.coilCompression = compressionInfo;
    info.sensitivity = rmfield(mapInfo,intersect( ...
        fieldnames(mapInfo),{'supportMask','lowResolutionRSS', ...
        'eigenvalueMap'}));
    info.history = table(historyIteration(1:historyIndex), ...
        historyObjective(1:historyIndex),historyDataResidual(1:historyIndex), ...
        historyRelativeChange(1:historyIndex), ...
        'VariableNames',{'Iteration','Objective','RelativeDataResidual', ...
        'RelativeChange'});
end

% Shared Cartesian SENSE operator helpers are located in utils.



% Regularization-specific helpers follow.

function [gradientRO,gradientPE] = forwardDifference(image)
    gradientRO = [diff(image,1,1); zeros(1,size(image,2),'like',image)];
    gradientPE = [diff(image,1,2), zeros(size(image,1),1,'like',image)];
end

function image = finiteDifferenceAdjoint(dualRO,dualPE)
    image = zeros(size(dualRO),'like',dualRO);
    image(1,:) = image(1,:)-dualRO(1,:);
    image(2:end-1,:) = image(2:end-1,:)+dualRO(1:end-2,:)-dualRO(2:end-1,:);
    image(end,:) = image(end,:)+dualRO(end-1,:);
    image(:,1) = image(:,1)-dualPE(:,1);
    image(:,2:end-1) = image(:,2:end-1)+dualPE(:,1:end-2)-dualPE(:,2:end-1);
    image(:,end) = image(:,end)+dualPE(:,end-1);
end

function coefficients = haarForward(image,levels)
    coefficients = image;
    rootTwo = cast(sqrt(2),'like',real(image));
    for level = 1:levels
        nRO = size(image,1)/2^(level-1);
        nPE = size(image,2)/2^(level-1);
        block = coefficients(1:nRO,1:nPE);
        lowRO = (block(1:2:end,:)+block(2:2:end,:))/rootTwo;
        highRO = (block(1:2:end,:)-block(2:2:end,:))/rootTwo;
        rowTransformed = [lowRO; highRO];
        lowPE = (rowTransformed(:,1:2:end)+rowTransformed(:,2:2:end))/rootTwo;
        highPE = (rowTransformed(:,1:2:end)-rowTransformed(:,2:2:end))/rootTwo;
        coefficients(1:nRO,1:nPE) = [lowPE highPE];
    end
end

function image = haarInverse(coefficients,levels)
    image = coefficients;
    rootTwo = cast(sqrt(2),'like',real(coefficients));
    for level = levels:-1:1
        nRO = size(coefficients,1)/2^(level-1);
        nPE = size(coefficients,2)/2^(level-1);
        block = image(1:nRO,1:nPE);
        lowPE = block(:,1:nPE/2);
        highPE = block(:,nPE/2+1:nPE);
        rowTransformed = zeros(nRO,nPE,'like',block);
        rowTransformed(:,1:2:end) = (lowPE+highPE)/rootTwo;
        rowTransformed(:,2:2:end) = (lowPE-highPE)/rootTwo;
        lowRO = rowTransformed(1:nRO/2,:);
        highRO = rowTransformed(nRO/2+1:nRO,:);
        reconstructed = zeros(nRO,nPE,'like',block);
        reconstructed(1:2:end,:) = (lowRO+highRO)/rootTwo;
        reconstructed(2:2:end,:) = (lowRO-highRO)/rootTwo;
        image(1:nRO,1:nPE) = reconstructed;
    end
end

function dual = projectWaveletDual(dual,weight,levels)
    approximationSize = size(dual)./2^levels;
    magnitude = abs(dual);
    scale = max(1,magnitude/weight);
    dual = dual./scale;
    dual(1:approximationSize(1),1:approximationSize(2)) = 0;
end

function [objective,relativeResidual] = evaluateObjective( ...
        image,data,sensitivities,mask,tvWeight,waveletWeight,levels)
    residual = sense_TSE2D_forward(image,sensitivities,mask)-data;
    dataEnergy = 0.5*sum(abs(residual(:)).^2);
    dataNorm = norm(data(:));
    relativeResidual = scalarDouble(norm(residual(:))/max(dataNorm,eps));
    regularization = 0;
    if tvWeight > 0
        [gradientRO,gradientPE] = forwardDifference(image);
        regularization = regularization+tvWeight*scalarDouble(sum( ...
            sqrt(abs(gradientRO(:)).^2+abs(gradientPE(:)).^2)));
    end
    if levels > 0 && waveletWeight > 0
        coefficients = haarForward(image,levels);
        approximationSize = size(image)./2^levels;
        coefficients(1:approximationSize(1),1:approximationSize(2)) = 0;
        regularization = regularization+waveletWeight*scalarDouble(sum(abs(coefficients(:))));
    end
    objective = scalarDouble(dataEnergy)+regularization;
end

function levels = resolveWaveletLevels(imageSize,requested)
    levels = 0;
    while levels < requested && all(mod(imageSize,2^(levels+1)) == 0)
        levels = levels+1;
    end
    if levels < requested
        warning('recon_TSE2D_CS:WaveletLevelsReduced', ...
            'WaveletLevels reduced from %d to %d for matrix %dx%d.', ...
            requested,levels,imageSize(1),imageSize(2));
    end
end

function scale = robustScale(values,support)
    values = gatherIfNeeded(values);
    if ~isempty(support) && isequal(size(support),size(values))
        values = values(logical(support));
    else
        values = values(:);
    end
    values = sort(double(values(isfinite(values) & values > 0)));
    if isempty(values)
        error('recon_TSE2D_CS:ZeroData','Cannot normalize zero-valued data.');
    end
    index = max(1,min(numel(values),round(0.995*numel(values))));
    scale = values(index);
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
            error('recon_TSE2D_CS:GPUUnavailable', ...
                'UseGPU was requested but no usable GPU is available: %s',ME.message);
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

function tf = isNonnegativeScalar(value)
    tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value >= 0;
end

function tf = isValidUseGPU(value)
    tf = islogical(value) && isscalar(value);
    if tf
        return
    end
    tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
        strcmpi(string(value),'auto');
end
