function [sensitivities, info] = estimate_TSE2D_sensitivities( ...
        kspace, calibrationMask, varargin)
%ESTIMATE_TSE2D_SENSITIVITIES Estimate complex SENSE maps from Cartesian ACS.
%
% KSPACE is [readout, phase, coil]. CALIBRATIONMASK is a logical PE mask.
% A centered low-resolution coil image is formed from the ACS, tapered in
% both encoded dimensions, and normalized by its root-sum-of-squares image.

    p = inputParser;
    p.addParameter('ReadoutWidth',64,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 2 && mod(x,1) == 0);
    p.addParameter('SupportThreshold',0.02,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 0 && x < 1);
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(kspace,{'numeric'},{'nonempty'},mfilename,'kspace');
    if ndims(kspace) ~= 3
        error('estimate_TSE2D_sensitivities:InvalidKspace', ...
            'KSPACE must have dimensions [readout, phase, coil].');
    end
    nRO = size(kspace,1);
    nPE = size(kspace,2);
    calibrationMask = logical(reshape(calibrationMask,1,[]));
    if numel(calibrationMask) ~= nPE
        error('estimate_TSE2D_sensitivities:MaskSize', ...
            'CALIBRATIONMASK must match the phase-encoding dimension.');
    end
    calibrationLines = find(calibrationMask);
    if numel(calibrationLines) < 4
        error('estimate_TSE2D_sensitivities:InsufficientCalibration', ...
            'At least four calibration lines are required; received %d.', ...
            numel(calibrationLines));
    end
    if any(diff(calibrationLines) ~= 1)
        error('estimate_TSE2D_sensitivities:NoncontiguousCalibration', ...
            'Sensitivity calibration requires a contiguous ACS region.');
    end

    readoutWidth = min(nRO,double(opt.ReadoutWidth));
    readoutWidth = max(2,2*floor(readoutWidth/2));
    readoutCenter = floor(nRO/2)+1;
    readoutFirst = readoutCenter-floor(readoutWidth/2);
    readoutLast = readoutFirst+readoutWidth-1;
    if readoutFirst < 1
        readoutFirst = 1;
        readoutLast = readoutWidth;
    elseif readoutLast > nRO
        readoutLast = nRO;
        readoutFirst = nRO-readoutWidth+1;
    end
    readoutLines = readoutFirst:readoutLast;

    readoutWindow = raisedCosine(numel(readoutLines));
    phaseWindow = raisedCosine(numel(calibrationLines));
    window = zeros(nRO,nPE,'like',real(kspace));
    window(readoutLines,calibrationLines) = cast( ...
        readoutWindow(:)*phaseWindow(:).','like',window);
    calibrationKspace = kspace.*window;
    coilImages = ifft2c(calibrationKspace);
    rss = sqrt(sum(abs(coilImages).^2,3));
    peak = max(rss,[],'all');
    if ~isfinite(peak) || peak <= 0
        error('estimate_TSE2D_sensitivities:ZeroCalibration', ...
            'The ACS region contains no finite signal.');
    end
    support = rss >= cast(opt.SupportThreshold,'like',rss)*peak;
    denominator = max(rss,cast(1e-6,'like',rss)*peak);
    sensitivities = coilImages./denominator;
    sensitivities = sensitivities.*support;

    normalization = sqrt(sum(abs(sensitivities).^2,3));
    sensitivities = sensitivities./max(normalization, ...
        cast(1e-6,'like',normalization));
    sensitivities = sensitivities.*support;
    normalization = sqrt(sum(abs(sensitivities).^2,3));
    valid = support;

    info = struct();
    info.method = 'ACS low-resolution RSS normalization';
    info.calibrationLines = calibrationLines;
    info.calibrationReadoutLines = readoutLines;
    info.calibrationMatrix = [numel(readoutLines) numel(calibrationLines)];
    info.supportThreshold = double(opt.SupportThreshold);
    info.supportFraction = nnz(support)/numel(support);
    info.maximumNormalizationError = max(abs( ...
        normalization(valid)-1),[],'all');
    info.supportMask = support;
    info.lowResolutionRSS = single(gatherIfNeeded(rss));
end

function values = raisedCosine(count)
    if count <= 2
        values = ones(1,count);
        return
    end
    index = 0:count-1;
    values = 0.5-0.5*cos(2*pi*(index+0.5)/count);
end

function image = ifft2c(kspace)
    scale = sqrt(size(kspace,1)*size(kspace,2));
    image = fftshift(fftshift(ifft(ifft( ...
        ifftshift(ifftshift(kspace,1),2),[],1),[],2),1),2)*scale;
end

function value = gatherIfNeeded(value)
    if isa(value,'gpuArray')
        value = gather(value);
    end
end
