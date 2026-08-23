function [W, info] = estimate_noise_whitener(noiseData, nCha, varargin)
%ESTIMATE_NOISE_WHITENER Estimate a complex coil-noise whitening matrix.
%
% [W, info] = estimate_noise_whitener(noiseData, nCha, Name, Value)
%
% noiseData must be [readout, coil, acquisition]. The returned W is applied
% to row-wise coil vectors as data * W. The regularized covariance obeys
% W' * covarianceRegularized * W approximately equal to identity.
%
% Options
%   Shrinkage       Fraction shrunk toward diag(C), default 0.02.
%   EigenvalueFloor Relative floor against the median positive eigenvalue,
%                   default 1e-6.

    p = inputParser;
    p.addRequired('noiseData', @(x) isnumeric(x) || isempty(x));
    p.addRequired('nCha', @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('Shrinkage', 0.02, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
    p.addParameter('EigenvalueFloor', 1e-6, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.parse(noiseData, nCha, varargin{:});
    opt = p.Results;

    info = struct('applied', false, 'nSamples', 0, 'shrinkage', opt.Shrinkage, ...
        'conditionBefore', NaN, 'conditionAfter', NaN, ...
        'covariance', [], 'covarianceRegularized', [], ...
        'whitenedCovariance', [], 'warning', "");

    if isempty(noiseData)
        W = eye(nCha, 'single');
        info.warning = "No noise scan was available; identity whitening was used.";
        return;
    end
    if size(noiseData,2) ~= nCha
        error('estimate_noise_whitener:ChannelMismatch', ...
            'Noise has %d channels but image data have %d.', size(noiseData,2), nCha);
    end

    x = reshape(permute(noiseData, [1 3 2]), [], nCha);
    valid = all(isfinite(real(x)) & isfinite(imag(x)), 2) & any(abs(x) > 0, 2);
    x = double(x(valid,:));
    if size(x,1) <= nCha
        W = eye(nCha, 'single');
        info.nSamples = size(x,1);
        info.warning = sprintf( ...
            'Only %d valid noise samples were available for %d coils; identity whitening was used.', ...
            size(x,1), nCha);
        return;
    end

    x = x - mean(x,1);
    C = (x' * x) / (size(x,1)-1);
    C = (C + C') / 2;
    Creg = (1-opt.Shrinkage)*C + opt.Shrinkage*diag(diag(C));
    Creg = (Creg + Creg') / 2;

    [V, d] = eig(Creg, 'vector');
    d = real(d);
    positive = d(d > 0 & isfinite(d));
    if isempty(positive)
        W = eye(nCha, 'single');
        info.nSamples = size(x,1);
        info.warning = "Noise covariance was not positive; identity whitening was used.";
        return;
    end
    floorValue = opt.EigenvalueFloor * median(positive);
    floorValue = max(floorValue, eps(max(positive)));
    dFloor = max(d, floorValue);
    Wdouble = V * diag(1./sqrt(dFloor)) * V';
    Wdouble = (Wdouble + Wdouble') / 2;

    info.applied = true;
    info.nSamples = size(x,1);
    info.conditionBefore = max(positive) / min(positive);
    info.conditionAfter = max(dFloor) / min(dFloor);
    info.covariance = C;
    info.covarianceRegularized = Creg;
    info.whitenedCovariance = Wdouble' * Creg * Wdouble;
    W = single(Wdouble);
end
