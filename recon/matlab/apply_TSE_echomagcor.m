function [dataOut, correction] = apply_TSE_echomagcor(dataIn, mdh, phaseCor, alpha, varargin)
%APPLY_TSE_ECHOMAGCOR Apply noise-stable TSE echo-magnitude equalization.
%
% The navigator magnitude A_e is normalized to phaseCor.referenceEcho.
% Supported gain models are:
%
%   power:   g_e = A_e^(alpha - 1)
%   wiener:  g_e = (1 + lambda) * A_e^(alpha + 1) / (A_e^2 + lambda)
%
% alpha=1 preserves the measured echo envelope in the unregularized power
% model, alpha=0 targets full equalization, and intermediate values provide
% partial correction. The normalized Wiener model has unit gain at A_e=1
% and converges to the power model as lambda approaches zero.
%
% Options
%   Method       'power' (default) or 'wiener'.
%   Lambda       Non-negative scalar or 'auto' (default). Auto combines the
%                prewhitened reference-navigator noise-to-signal ratio with
%                the regularization needed to meet MaximumGain.
%   MaximumGain  Smooth Wiener gain limit used by auto lambda (default 2).

    p = inputParser;
    p.addParameter('Method','power',@(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('Lambda','auto',@isValidLambda);
    p.addParameter('MaximumGain',2,@isValidMaximumGain);
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(alpha,{'numeric'},{'real','finite','scalar','>=',0,'<=',1}, ...
        mfilename,'alpha');
    method = lower(string(opt.Method));
    if ~ismember(method,["power","wiener"])
        error('apply_TSE_echomagcor:InvalidMethod', ...
            'Method must be ''power'' or ''wiener''; received ''%s''.',method);
    end

    correction = buildCorrection(phaseCor,double(alpha),method, ...
        opt.Lambda,double(opt.MaximumGain));
    if isempty(dataIn)
        dataOut = dataIn;
        return
    end
    if ~isfield(mdh,'Sli') || ~isfield(mdh,'Seg')
        error('apply_TSE_echomagcor:MissingMdh', ...
            'MDH fields Sli and Seg are required.');
    end
    if size(dataIn,3) ~= numel(mdh.Sli) || size(dataIn,3) ~= numel(mdh.Seg)
        error('apply_TSE_echomagcor:MdhSizeMismatch', ...
            'The number of acquisitions must match MDH Sli and Seg.');
    end

    gain = correction.gain;
    dataOut = dataIn;
    for acquisition = 1:size(dataIn,3)
        slice = double(mdh.Sli(acquisition));
        echo = double(mdh.Seg(acquisition));
        if slice < 1 || echo < 1 || slice > size(gain,1) || echo > size(gain,2)
            error('apply_TSE_echomagcor:MissingGain', ...
                'No echo-magnitude gain for SLC=%d, SEG=%d.',slice,echo);
        end
        currentGain = gain(slice,echo);
        if ~isfinite(currentGain) || currentGain <= 0
            error('apply_TSE_echomagcor:InvalidGain', ...
                'Invalid echo-magnitude gain for SLC=%d, SEG=%d.',slice,echo);
        end
        dataOut(:,:,acquisition) = dataIn(:,:,acquisition) .* ...
            cast(currentGain,'like',dataIn);
    end
end

function correction = buildCorrection(phaseCor,alpha,method,lambdaSpec,maximumGain)
    if ~isstruct(phaseCor) || ~isfield(phaseCor,'amplitudeNorm') || ...
            isempty(phaseCor.amplitudeNorm)
        error('apply_TSE_echomagcor:MissingAmplitude', ...
            'phaseCor.amplitudeNorm is required.');
    end

    amplitude = double(phaseCor.amplitudeNorm);
    measured = isfinite(amplitude);
    if ~any(measured(:))
        error('apply_TSE_echomagcor:MissingAmplitude', ...
            'No finite normalized navigator amplitudes were measured.');
    end
    if any(amplitude(measured) <= 0)
        error('apply_TSE_echomagcor:InvalidAmplitude', ...
            'All measured normalized navigator amplitudes must be positive.');
    end

    gain = nan(size(amplitude));
    lambdaBySlice = nan(size(amplitude,1),1);
    lambdaNoiseBySlice = nan(size(amplitude,1),1);
    lambdaGainBySlice = nan(size(amplitude,1),1);
    lambdaMode = "not-used";

    switch method
        case "power"
            gain(measured) = amplitude(measured).^(alpha-1);
        case "wiener"
            [lambdaBySlice,lambdaNoiseBySlice,lambdaGainBySlice,lambdaMode] = ...
                resolveWienerLambda(amplitude,measured,phaseCor,lambdaSpec, ...
                maximumGain,alpha);
            for slice = 1:size(amplitude,1)
                rowMeasured = measured(slice,:);
                if ~any(rowMeasured)
                    continue
                end
                currentAmplitude = amplitude(slice,rowMeasured);
                currentLambda = lambdaBySlice(slice);
                gain(slice,rowMeasured) = (1+currentLambda) .* ...
                    currentAmplitude.^(alpha+1) ./ ...
                    (currentAmplitude.^2+currentLambda);
            end
    end

    finiteGain = gain(measured);
    correction = struct();
    correction.applied = any(abs(finiteGain-1) > 64*eps(max(1,max(abs(finiteGain)))));
    correction.method = method;
    correction.alpha = alpha;
    correction.exponent = alpha-1;
    correction.referenceEcho = phaseCor.referenceEcho;
    correction.amplitudeNorm = amplitude;
    correction.gain = gain;
    correction.correctedAmplitude = amplitude.*gain;
    correction.lambdaMode = lambdaMode;
    correction.lambdaBySlice = lambdaBySlice;
    correction.lambdaNoiseBySlice = lambdaNoiseBySlice;
    correction.lambdaGainBySlice = lambdaGainBySlice;
    correction.maximumGainTarget = maximumGain;
    correction.minimumGain = min(finiteGain);
    correction.maximumGain = max(finiteGain);
    correction.maximumNoiseStdGain = max(finiteGain);
    correction.maximumNoiseVarianceGain = max(finiteGain.^2);
end

function [lambdaBySlice,lambdaNoiseBySlice,lambdaGainBySlice,mode] = ...
        resolveWienerLambda(amplitude,measured,phaseCor,lambdaSpec,maximumGain,alpha)
    nSlice = size(amplitude,1);
    lambdaBySlice = nan(nSlice,1);
    lambdaNoiseBySlice = nan(nSlice,1);
    lambdaGainBySlice = nan(nSlice,1);

    if isnumeric(lambdaSpec)
        lambdaBySlice(any(measured,2)) = double(lambdaSpec);
        mode = "manual";
        return
    end

    mode = "auto";
    noiseRatio = nan(nSlice,1);
    if isfield(phaseCor,'referenceNoiseToSignalRatio') && ...
            ~isempty(phaseCor.referenceNoiseToSignalRatio)
        available = double(phaseCor.referenceNoiseToSignalRatio(:));
        count = min(nSlice,numel(available));
        noiseRatio(1:count) = available(1:count);
    end

    for slice = 1:nSlice
        currentAmplitude = amplitude(slice,measured(slice,:));
        if isempty(currentAmplitude)
            continue
        end

        if isfinite(noiseRatio(slice)) && noiseRatio(slice) >= 0
            lambdaNoiseBySlice(slice) = noiseRatio(slice);
        else
            lambdaNoiseBySlice(slice) = 0;
        end
        lambdaGainBySlice(slice) = lambdaForMaximumGain( ...
            currentAmplitude,alpha,maximumGain);
        lambdaBySlice(slice) = max(lambdaNoiseBySlice(slice),lambdaGainBySlice(slice));
    end
end

function lambda = lambdaForMaximumGain(amplitude,alpha,maximumGain)
    if isinf(maximumGain)
        lambda = 0;
        return
    end

    amplitude = amplitude(amplitude > 0 & amplitude < 1);
    if isempty(amplitude)
        lambda = 0;
        return
    end

    numeratorTerm = amplitude.^(alpha+1);
    denominator = maximumGain-numeratorTerm;
    candidate = zeros(size(amplitude));
    valid = denominator > 0;
    candidate(valid) = (numeratorTerm(valid)-maximumGain*amplitude(valid).^2) ./ ...
        denominator(valid);
    candidate = candidate(isfinite(candidate) & candidate > 0);
    if isempty(candidate)
        lambda = 0;
    else
        lambda = max(candidate);
    end
end

function tf = isValidLambda(value)
    tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value >= 0;
    if tf
        return
    end
    tf = (ischar(value) || (isstring(value) && isscalar(value))) && ...
        strcmpi(string(value),'auto');
end

function tf = isValidMaximumGain(value)
    tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
        ~isnan(value) && value >= 1;
end
