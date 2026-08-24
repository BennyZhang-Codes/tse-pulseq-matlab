function comparison = evaluate_TSE2D_reconstruction(reconstructed,reference,varargin)
%EVALUATE_TSE2D_RECONSTRUCTION Register and compare magnitude volumes.
%
% A small in-plane translation is estimated independently for each slice,
% followed by one global least-squares intensity scale for the whole volume.
% NRMSE and SSIM are evaluated inside a reference-derived object mask.

    p = inputParser;
    p.addParameter('Register',true,@(x) islogical(x) && isscalar(x));
    p.addParameter('MaximumTranslationPixels',4,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('MaskThreshold',0.05,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x >= 0 && x < 1);
    p.addParameter('NormalizationPercentile',99.5,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x > 50 && x <= 100);
    p.parse(varargin{:});
    opt = p.Results;

    reconstructed = double(reconstructed);
    reference = double(reference);
    if ~isequal(size(reconstructed),size(reference))
        error('evaluate_TSE2D_reconstruction:SizeMismatch', ...
            'Reconstructed and reference arrays must have identical sizes.');
    end
    if ismatrix(reference)
        reference = reshape(reference,size(reference,1),size(reference,2),1);
        reconstructed = reshape(reconstructed,size(reconstructed,1), ...
            size(reconstructed,2),1);
    end

    positiveReference = reference(isfinite(reference) & reference > 0);
    referenceScale = percentile(positiveReference,opt.NormalizationPercentile);
    if ~isfinite(referenceScale) || referenceScale <= 0
        error('evaluate_TSE2D_reconstruction:ZeroReference', ...
            'Reference image has no positive finite signal.');
    end
    referenceNormalized = reference/referenceScale;
    movingScale = percentile(reconstructed(isfinite(reconstructed) & ...
        reconstructed > 0),opt.NormalizationPercentile);
    reconstructedNormalized = reconstructed/max(movingScale,eps);

    mask = referenceNormalized >= opt.MaskThreshold;
    aligned = zeros(size(reconstructedNormalized));
    shifts = zeros(size(reference,3),2);
    registrationScores = nan(size(reference,3),1);
    outputView = imref2d(size(reference(:,:,1)));
    for slice = 1:size(reference,3)
        moving = reconstructedNormalized(:,:,slice);
        fixed = referenceNormalized(:,:,slice);
        if opt.Register
            fixedRegistration = imgaussfilt(fixed,1);
            movingRegistration = imgaussfilt(moving,1);
            transform = imregcorr(movingRegistration,fixedRegistration, ...
                'translation');
            shift = extractTranslation(transform);
            if any(~isfinite(shift)) || any(abs(shift) > opt.MaximumTranslationPixels)
                transform = affine2d(eye(3));
                shift = [0 0];
            end
            moving = imwarp(moving,transform,'OutputView',outputView, ...
                'Interp','cubic','FillValues',0);
            shifts(slice,:) = shift;
        end
        aligned(:,:,slice) = moving;
        valid = mask(:,:,slice);
        if nnz(valid) > 10
            a = fixed(valid)-mean(fixed(valid));
            b = moving(valid)-mean(moving(valid));
            registrationScores(slice) = sum(a.*b)/max(norm(a)*norm(b),eps);
        end
    end

    valid = mask & isfinite(aligned) & isfinite(referenceNormalized);
    intensityScale = sum(referenceNormalized(valid).*aligned(valid))/ ...
        max(sum(aligned(valid).^2),eps);
    aligned = aligned*intensityScale;
    signedError = aligned-referenceNormalized;
    absoluteError = abs(signedError);

    nSlice = size(reference,3);
    sliceNRMSE = nan(nSlice,1);
    sliceSSIM = nan(nSlice,1);
    slicePSNR = nan(nSlice,1);
    for slice = 1:nSlice
        validSlice = valid(:,:,slice);
        referenceSlice = referenceNormalized(:,:,slice);
        alignedSlice = aligned(:,:,slice);
        errorSlice = signedError(:,:,slice);
        sliceNRMSE(slice) = norm(errorSlice(validSlice))/ ...
            max(norm(referenceSlice(validSlice)),eps);
        rmse = sqrt(mean(errorSlice(validSlice).^2));
        slicePSNR(slice) = 20*log10(1/max(rmse,eps));
        [~,ssimMap] = ssim(min(max(alignedSlice,0),1), ...
            min(max(referenceSlice,0),1),'DynamicRange',1);
        sliceSSIM(slice) = mean(ssimMap(validSlice),'omitnan');
    end

    volumeNRMSE = norm(signedError(valid))/ ...
        max(norm(referenceNormalized(valid)),eps);
    volumeRMSE = sqrt(mean(signedError(valid).^2));
    comparison = struct();
    comparison.referenceNormalized = single(referenceNormalized);
    comparison.reconstructedAligned = single(aligned);
    comparison.signedError = single(signedError);
    comparison.absoluteError = single(absoluteError);
    comparison.mask = mask;
    comparison.referenceScale = referenceScale;
    comparison.initialMovingScale = movingScale;
    comparison.intensityScale = intensityScale;
    comparison.translationPixelsXY = shifts;
    comparison.registrationCorrelation = registrationScores;
    comparison.nrmse = volumeNRMSE;
    comparison.ssim = mean(sliceSSIM,'omitnan');
    comparison.psnr = 20*log10(1/max(volumeRMSE,eps));
    comparison.sliceMetrics = table((1:nSlice)',sliceNRMSE,sliceSSIM, ...
        slicePSNR,shifts(:,1),shifts(:,2),registrationScores, ...
        'VariableNames',{'Slice','NRMSE','SSIM','PSNR', ...
        'TranslationX','TranslationY','RegistrationCorrelation'});
end

function shift = extractTranslation(transform)
    if isprop(transform,'T')
        shift = transform.T(3,1:2);
    elseif isprop(transform,'A')
        shift = transform.A(1:2,3)';
    else
        shift = [NaN NaN];
    end
end

function value = percentile(values,percent)
    values = sort(double(values(isfinite(values))));
    if isempty(values)
        value = NaN;
        return
    end
    index = 1+(numel(values)-1)*percent/100;
    lower = floor(index);
    upper = ceil(index);
    if lower == upper
        value = values(lower);
    else
        value = values(lower)+(index-lower)*(values(upper)-values(lower));
    end
end
