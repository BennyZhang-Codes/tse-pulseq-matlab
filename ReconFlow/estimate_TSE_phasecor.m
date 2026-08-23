function phaseCor = estimate_TSE_phasecor(data, mdh, varargin)
%ESTIMATE_TSE_PHASECOR Estimate per-slice, per-echo TSE phase corrections.
%
% The unencoded phase-correction echo train is compared with ReferenceEcho.
% For each receive channel, a weighted linear model is fitted to the phase
% of currentEcho .* conj(referenceEcho) over readout k-space:
%
%   phase(kx) = linearSlope * normalizedKx + constantPhase.
%
% The model captures the constant phase used by cross-correlation and the
% readout-linear phase used by auto-correlation style TSE correction. It is
% a transparent diagnostic implementation, not a byte-for-byte ICE clone.
%
% Options
%   ReferenceEcho      Reference SEG/echo number (default 1).
%   MagnitudeThreshold Relative sample threshold for fitting (default 0.05).
%   MinimumSamples     Minimum fit samples per channel (default 12).

    p = inputParser;
    p.addParameter('ReferenceEcho', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    p.addParameter('MagnitudeThreshold', 0.05, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0 && x < 1);
    p.addParameter('MinimumSamples', 12, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 2 && mod(x,1) == 0);
    p.parse(varargin{:});
    opt = p.Results;

    required = {'Sli','Seg'};
    for i = 1:numel(required)
        if ~isfield(mdh, required{i})
            error('estimate_TSE_phasecor:MissingMdh', 'MDH field %s is required.', required{i});
        end
    end
    if isempty(data)
        error('estimate_TSE_phasecor:NoData', 'Phase-correction data are empty.');
    end

    nRO = size(data,1);
    nCha = size(data,2);
    slices = unique(mdh.Sli(:)).';
    echoes = unique(mdh.Seg(:)).';
    nSliceIndex = max(slices);
    nEchoIndex = max(echoes);
    if ~ismember(opt.ReferenceEcho, echoes)
        error('estimate_TSE_phasecor:MissingReferenceEcho', ...
            'Reference echo %d is absent from phase-correction data.', opt.ReferenceEcho);
    end

    normalizedKx = ((1:nRO).' - (nRO+1)/2) / nRO;
    coefficients = zeros(nSliceIndex, nEchoIndex, nCha, 2, 'single');
    amplitudeNorm = nan(nSliceIndex, nEchoIndex);
    constantMean = nan(nSliceIndex, nEchoIndex);
    slopeMean = nan(nSliceIndex, nEchoIndex);

    for slice = slices
        ref = meanNavigator(data, mdh, slice, opt.ReferenceEcho);
        refEnergy = sum(abs(double(ref)).^2, 1);
        for echo = echoes
            current = meanNavigator(data, mdh, slice, echo);
            amplitudeNorm(slice,echo) = sqrt(sum(abs(double(current(:))).^2) / ...
                max(sum(abs(double(ref(:))).^2), eps));

            if echo ~= opt.ReferenceEcho
                for coil = 1:nCha
                    z = double(current(:,coil)) .* conj(double(ref(:,coil)));
                    weight = abs(z);
                    if max(weight) <= 0
                        continue;
                    end
                    keep = weight > opt.MagnitudeThreshold*max(weight);
                    if nnz(keep) < opt.MinimumSamples
                        [~, order] = sort(weight, 'descend');
                        keep(order(1:min(opt.MinimumSamples,nRO))) = true;
                    end
                    index = find(keep);
                    phi = unwrap(angle(z(index)));
                    X = [normalizedKx(index), ones(numel(index),1)];
                    w = weight(index) / max(weight(index));
                    beta = (X'*(w.*X) + 1e-10*eye(2)) \ (X'*(w.*phi));
                    beta(2) = angle(exp(1i*beta(2)));
                    coefficients(slice,echo,coil,1) = single(beta(1));
                    coefficients(slice,echo,coil,2) = single(beta(2));
                end
            end

            coilWeight = refEnergy / max(sum(refEnergy), eps);
            slopes = double(squeeze(coefficients(slice,echo,:,1))).';
            constants = double(squeeze(coefficients(slice,echo,:,2))).';
            slopeMean(slice,echo) = sum(coilWeight .* slopes);
            constantMean(slice,echo) = angle(sum(coilWeight .* exp(1i*constants)));
        end
    end

    [sliceGrid, echoGrid] = ndgrid(slices, echoes);
    linearIndex = sub2ind([nSliceIndex nEchoIndex], sliceGrid(:), echoGrid(:));
    metrics = table(sliceGrid(:), echoGrid(:), amplitudeNorm(linearIndex), ...
        rad2deg(constantMean(linearIndex)), rad2deg(slopeMean(linearIndex)), ...
        'VariableNames', {'Slice','Echo','AmplitudeNorm', ...
        'ConstantPhaseDeg','LinearPhaseAcrossFOVDeg'});

    phaseCor = struct();
    phaseCor.applied = false;
    phaseCor.referenceEcho = opt.ReferenceEcho;
    phaseCor.coefficients = coefficients;
    phaseCor.amplitudeNorm = amplitudeNorm;
    phaseCor.constantPhase = constantMean;
    phaseCor.linearPhaseAcrossFOV = slopeMean;
    phaseCor.metrics = metrics;
    phaseCor.nRO = nRO;
    phaseCor.nCha = nCha;
end

function navigator = meanNavigator(data, mdh, slice, echo)
    index = find(mdh.Sli == slice & mdh.Seg == echo);
    if isempty(index)
        error('estimate_TSE_phasecor:MissingNavigator', ...
            'No phase-correction navigator for SLC=%d, SEG=%d.', slice, echo);
    end
    % Multiple repetitions/averages are combined. A warning is avoided here
    % because repeated navigators are legitimate; callers can inspect MDH.
    navigator = mean(data(:,:,index), 3);
end
