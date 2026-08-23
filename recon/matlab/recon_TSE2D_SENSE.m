function [imageOut,info,sensitivities] = recon_TSE2D_SENSE( ...
        kspace,acquiredMask,calibrationMask,varargin)
%RECON_TSE2D_SENSE Iterative Cartesian SENSE reconstruction for 2-D TSE.
%
% Solves the ordinary least-squares SENSE problem
%
%   min_x 0.5 || P F(Sx)-y ||_2^2 + 0.5*Tikhonov*||x||_2^2
%
% by conjugate gradients on the normal equations. The default Tikhonov
% value is zero. Coil compression, ESPIRiT maps, and the PFS encoding model
% are shared with recon_TSE2D_CS.

    utilityDir = fullfile(fileparts(mfilename('fullpath')),'utils');
    if isfolder(utilityDir) && isempty(which('prepare_TSE2D_sense_model'))
        addpath(utilityDir);
    end

    p = inputParser;
    p.addParameter('Iterations',50,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('Tolerance',1e-5,@isNonnegativeScalar);
    p.addParameter('Tikhonov',1e-4,@isNonnegativeScalar);
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

    useGPU = resolveUseGPU(opt.UseGPU);
    data = model.kspace.*model.mask;
    sensitivities = model.sensitivities;
    mask = model.mask;
    if useGPU
        data = gpuArray(data);
        sensitivities = gpuArray(sensitivities);
        mask = gpuArray(mask);
    end

    initial = sense_TSE2D_adjoint(data,sensitivities,mask);
    imageScale = robustScale(abs(initial),model.sensitivity.supportMask);
    data = data/cast(imageScale,'like',data);
    b = sense_TSE2D_adjoint(data,sensitivities,mask);
    lambda = cast(double(opt.Tikhonov),'like',real(b));

    testX = complex(rand(size(b),'like',real(b)),rand(size(b),'like',real(b)));
    testForward = sense_TSE2D_forward(testX,sensitivities,mask);
    testAdjoint = sense_TSE2D_adjoint(data,sensitivities,mask);
    lhs = sum(conj(testForward(:)).*data(:));
    rhsCheck = sum(conj(testX(:)).*testAdjoint(:));
    adjointRelativeError = scalarDouble( ...
        abs(lhs-rhsCheck)/max(abs(lhs)+abs(rhsCheck),eps));
    if adjointRelativeError > 5e-5
        error('recon_TSE2D_SENSE:AdjointCheckFailed', ...
            'SENSE forward/adjoint relative error is %.6g.',adjointRelativeError);
    end

    x = complex(zeros(size(b),'like',b));
    r = b-normalOperator(x,sensitivities,mask,lambda);
    direction = r;
    rr = real(sum(conj(r(:)).*r(:)));
    rrInitial = max(rr,cast(eps,'like',rr));
    dataNorm = max(norm(data(:)),cast(eps,'like',real(data)));
    nHistory = ceil(double(opt.Iterations)/double(opt.HistoryInterval))+1;
    historyIteration = zeros(nHistory,1);
    historyNormalResidual = nan(nHistory,1);
    historyDataResidual = nan(nHistory,1);
    historyIndex = 0;
    converged = false;
    timer = tic;

    for iteration = 1:double(opt.Iterations)
        normalDirection = normalOperator(direction,sensitivities,mask,lambda);
        denominator = real(sum(conj(direction(:)).*normalDirection(:)));
        if scalarDouble(denominator) <= eps
            break
        end
        alpha = rr/denominator;
        x = x+alpha*direction;
        r = r-alpha*normalDirection;
        rrNew = real(sum(conj(r(:)).*r(:)));
        relativeNormalResidual = scalarDouble(sqrt(rrNew/rrInitial));
        record = mod(iteration,double(opt.HistoryInterval)) == 0 || ...
            iteration == 1 || iteration == double(opt.Iterations);
        if record
            dataResidual = sense_TSE2D_forward(x,sensitivities,mask)-data;
            relativeDataResidual = scalarDouble(norm(dataResidual(:))/dataNorm);
            historyIndex = historyIndex+1;
            historyIteration(historyIndex) = iteration;
            historyNormalResidual(historyIndex) = relativeNormalResidual;
            historyDataResidual(historyIndex) = relativeDataResidual;
            if opt.Verbose
                fprintf(['recon_TSE2D_SENSE: iter %3d, normal residual %.3g, ' ...
                    'data residual %.6g\n'],iteration,relativeNormalResidual, ...
                    relativeDataResidual);
            end
        end
        if opt.Tolerance > 0 && relativeNormalResidual < double(opt.Tolerance)
            converged = true;
            rr = rrNew;
            break
        end
        beta = rrNew/max(rr,cast(eps,'like',rr));
        direction = r+beta*direction;
        rr = rrNew;
    end

    elapsedSeconds = toc(timer);
    dataResidual = sense_TSE2D_forward(x,sensitivities,mask)-data;
    finalRelativeDataResidual = scalarDouble(norm(dataResidual(:))/dataNorm);
    imageOut = complex(single(gatherIfNeeded(x)*single(imageScale)));
    sensitivities = gatherIfNeeded(sensitivities);
    if ~opt.KeepSensitivityMaps
        sensitivities = [];
    end

    historyIndex = max(historyIndex,1);
    info = struct();
    info.method = 'iterative least-squares SENSE (CG normal equations)';
    info.iterations = iteration;
    info.maximumIterations = double(opt.Iterations);
    info.converged = converged;
    info.tolerance = double(opt.Tolerance);
    info.tikhonov = double(opt.Tikhonov);
    info.elapsedSeconds = elapsedSeconds;
    info.useGPU = useGPU;
    info.acquiredLines = nnz(model.acquiredMask);
    info.calibrationLines = nnz(model.calibrationMask);
    info.effectiveAcceleration = size(kspace,2)/nnz(model.acquiredMask);
    info.imageScale = imageScale;
    info.finalRelativeDataResidual = finalRelativeDataResidual;
    info.adjointRelativeError = adjointRelativeError;
    info.coilCompression = model.compression;
    info.sensitivity = rmfield(model.sensitivity,intersect( ...
        fieldnames(model.sensitivity),{'supportMask','lowResolutionRSS', ...
        'eigenvalueMap'}));
    info.history = table(historyIteration(1:historyIndex), ...
        historyNormalResidual(1:historyIndex),historyDataResidual(1:historyIndex), ...
        'VariableNames',{'Iteration','RelativeNormalResidual', ...
        'RelativeDataResidual'});
end

function output = normalOperator(image,sensitivities,mask,lambda)
    output = sense_TSE2D_adjoint( ...
        sense_TSE2D_forward(image,sensitivities,mask),sensitivities,mask) ...
        +lambda*image;
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
        error('recon_TSE2D_SENSE:ZeroData','Cannot normalize zero-valued data.');
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
            error('recon_TSE2D_SENSE:GPUUnavailable', ...
                'UseGPU was requested but no usable GPU is available: %s',ME.message);
        end
    end
end

function value = scalarDouble(value)
    value = double(gatherIfNeeded(value));
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
