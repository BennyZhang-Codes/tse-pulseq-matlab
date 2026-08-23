function metrics = measure_TSE2D_denoising(original,denoised,noise)
%MEASURE_TSE2D_DENOISING No-reference safety metrics for one image slice.
%
% Metrics compare a denoised image with its noisy input. They quantify noise
% removal and structural change, not fidelity to an unavailable clean image.

    validateattributes(original,{'numeric'},{'2d','real','finite','nonempty'});
    validateattributes(denoised,{'numeric'},{'size',size(original),'real','finite'});
    original = double(original);
    denoised = double(denoised);
    cornerMask = noise.cornerMask;
    sigma = noise.sigma;
    backgroundBefore = original(cornerMask);
    backgroundAfter = denoised(cornerMask);
    residual = denoised-original;

    metrics = struct();
    metrics.backgroundStdBefore = std(backgroundBefore,0);
    metrics.backgroundStdAfter = std(backgroundAfter,0);
    metrics.noiseReductionPercent = 100*(1- ...
        metrics.backgroundStdAfter/max(metrics.backgroundStdBefore,eps));
    metrics.backgroundMeanRatio = mean(backgroundAfter)/max(mean(backgroundBefore),eps);

    threshold = mean(backgroundBefore)+5*sigma;
    foregroundMask = original > threshold;
    if nnz(foregroundMask) < 20
        foregroundMask = ~cornerMask;
    end
    metrics.foregroundSignalRatio = mean(denoised(foregroundMask))/ ...
        max(mean(original(foregroundMask)),eps);

    [gxBefore,gyBefore] = gradient(original);
    [gxAfter,gyAfter] = gradient(denoised);
    gradientBefore = hypot(gxBefore,gyBefore);
    gradientAfter = hypot(gxAfter,gyAfter);
    edgeThreshold = percentileSorted(sort(gradientBefore(foregroundMask)),0.90);
    edgeMask = foregroundMask & gradientBefore >= edgeThreshold;
    metrics.edgeGradientRatio = mean(gradientAfter(edgeMask))/ ...
        max(mean(gradientBefore(edgeMask)),eps);

    dynamicRange = max(original,[],'all')-min(original,[],'all');
    if exist('ssim','file') == 2
        metrics.ssimToOriginal = ssim(denoised,original, ...
            'DynamicRange',max(dynamicRange,eps));
    else
        metrics.ssimToOriginal = 1-sum(residual(:).^2)/max(sum(original(:).^2),eps);
    end
    edgeEnergyFraction = sum(residual(edgeMask).^2)/max(sum(residual(:).^2),eps);
    edgeAreaFraction = nnz(edgeMask)/numel(edgeMask);
    metrics.edgeResidualEnrichment = edgeEnergyFraction/max(edgeAreaFraction,eps);
    metrics.residualRmsOverNoiseSigma = rms(residual,'all')/max(sigma,eps);
    metrics.backgroundResidualLag1RO = maskedLagCorrelation(residual,cornerMask,1);
    metrics.backgroundResidualLag1PE = maskedLagCorrelation(residual,cornerMask,2);
    roEnergy = sum(diff(residual,1,1).^2,'all');
    peEnergy = sum(diff(residual,1,2).^2,'all');
    metrics.residualPEtoROGradientEnergy = peEnergy/max(roEnergy,eps);
    metrics.negativeVoxelFraction = nnz(denoised < 0)/numel(denoised);
end

function correlation = maskedLagCorrelation(image,mask,dimension)
    if dimension == 1
        first = image(1:end-1,:);
        second = image(2:end,:);
        pairMask = mask(1:end-1,:) & mask(2:end,:);
    else
        first = image(:,1:end-1);
        second = image(:,2:end);
        pairMask = mask(:,1:end-1) & mask(:,2:end);
    end
    first = first(pairMask);
    second = second(pairMask);
    if numel(first) < 3 || std(first,0) <= eps || std(second,0) <= eps
        correlation = NaN;
        return
    end
    first = first-mean(first);
    second = second-mean(second);
    correlation = sum(first.*second)/sqrt(sum(first.^2)*sum(second.^2));
end

function value = percentileSorted(sortedValues,fraction)
    if isempty(sortedValues)
        value = 0;
        return
    end
    index = max(1,min(numel(sortedValues),round(fraction*numel(sortedValues))));
    value = sortedValues(index);
end
