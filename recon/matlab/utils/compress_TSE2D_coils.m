function [kspaceCompressed, compressionMatrix, info] = ...
        compress_TSE2D_coils(kspace, calibrationMask, varargin)
%COMPRESS_TSE2D_COILS Global PCA compression in the calibrated coil basis.

    p = inputParser;
    p.addParameter('EnergyFraction',0.99,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x > 0 && x <= 1);
    p.addParameter('MaximumCoils',12,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('MinimumCoils',4,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(kspace,{'numeric'},{'nonempty'},mfilename,'kspace');
    if ndims(kspace) ~= 3
        error('compress_TSE2D_coils:InvalidKspace', ...
            'KSPACE must have dimensions [readout, phase, coil].');
    end
    nCoil = size(kspace,3);
    calibrationMask = logical(reshape(calibrationMask,1,[]));
    if numel(calibrationMask) ~= size(kspace,2) || ~any(calibrationMask)
        error('compress_TSE2D_coils:InvalidCalibrationMask', ...
            'A nonempty PE calibration mask is required.');
    end

    calibration = kspace(:,calibrationMask,:);
    calibration = reshape(calibration,[],nCoil);
    covariance = double(calibration)'*double(calibration);
    covariance = (covariance+covariance')/2;
    [vectors,values] = eig(covariance,'vector');
    [values,order] = sort(max(real(values),0),'descend');
    vectors = vectors(:,order);
    totalEnergy = sum(values);
    if ~isfinite(totalEnergy) || totalEnergy <= 0
        error('compress_TSE2D_coils:ZeroCalibration', ...
            'The calibration region contains no coil energy.');
    end
    cumulativeEnergy = cumsum(values)/totalEnergy;
    requestedCoils = find(cumulativeEnergy >= double(opt.EnergyFraction),1);
    requestedCoils = max(double(opt.MinimumCoils),requestedCoils);
    nVirtualCoil = min([nCoil,double(opt.MaximumCoils),requestedCoils]);
    compressionMatrix = single(vectors(:,1:nVirtualCoil));

    samples = reshape(kspace,[],nCoil);
    compressed = samples*cast(compressionMatrix,'like',samples);
    kspaceCompressed = reshape(compressed,size(kspace,1),size(kspace,2),nVirtualCoil);

    info = struct();
    info.originalCoils = nCoil;
    info.virtualCoils = nVirtualCoil;
    info.energyFractionTarget = double(opt.EnergyFraction);
    info.retainedEnergyFraction = cumulativeEnergy(nVirtualCoil);
    info.eigenvalues = values;
    info.compressionMatrix = compressionMatrix;
end
