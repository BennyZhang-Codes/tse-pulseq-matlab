function noise = estimate_TSE2D_image_noise(image,varargin)
%ESTIMATE_TSE2D_IMAGE_NOISE Estimate corner noise STD and stationary 2-D PSD.
%
% NOISE = ESTIMATE_TSE2D_IMAGE_NOISE(IMAGE) uses four corner patches. A
% plane is removed from every patch before estimating the variance and the
% Welch-like periodogram. NOISE.psd follows the normalization expected by
% BM3D 4.x: mean(NOISE.psd,'all') / numel(IMAGE) = NOISE.sigma^2.
%
% The PSD models stationary correlation only. Spatially varying GRAPPA
% g-factor noise cannot be represented by one PSD and is reported as a
% limitation rather than silently treated as stationary.

    p = inputParser;
    p.addParameter('CornerFraction',0.15, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0.08 && x <= 0.30);
    p.addParameter('PsdSmoothing',1.25, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(image,{'numeric'},{'2d','real','finite','nonempty'}, ...
        mfilename,'image',1);
    image = double(image);
    imageSize = size(image);
    nRow = imageSize(1);
    nCol = imageSize(2);
    patchRows = max(8,min(nRow,floor(opt.CornerFraction*nRow)));
    patchCols = max(8,min(nCol,floor(opt.CornerFraction*nCol)));

    rowRanges = {1:patchRows,1:patchRows, ...
        nRow-patchRows+1:nRow,nRow-patchRows+1:nRow};
    colRanges = {1:patchCols,nCol-patchCols+1:nCol, ...
        1:patchCols,nCol-patchCols+1:nCol};
    cornerMask = false(nRow,nCol);
    psdDensity = zeros(patchRows,patchCols);
    patchSigma = zeros(1,4);
    patchMean = zeros(1,4);

    window = periodicHann(patchRows)*periodicHann(patchCols).';
    windowEnergy = sum(window.^2,'all');
    for iPatch = 1:4
        rows = rowRanges{iPatch};
        cols = colRanges{iPatch};
        cornerMask(rows,cols) = true;
        patch = image(rows,cols);
        patchMean(iPatch) = mean(patch,'all');
        residual = removePlane(patch);
        patchSigma(iPatch) = std(residual,0,'all');
        spectrum = fft2(residual.*window);
        psdDensity = psdDensity + abs(spectrum).^2/windowEnergy;
    end
    psdDensity = psdDensity/4;

    validSigma = patchSigma(isfinite(patchSigma) & patchSigma > 0);
    if isempty(validSigma)
        sigma = eps;
    else
        % RMS pooling retains the average background noise power while
        % avoiding sensitivity to a single unusually quiet corner.
        sigma = sqrt(mean(validSigma.^2));
    end

    if opt.PsdSmoothing > 0
        psdDensity = imgaussfilt(psdDensity,opt.PsdSmoothing,'Padding','circular');
    end
    psdDensity = resizePeriodicSpectrum(psdDensity,[nRow nCol]);
    positivePsd = psdDensity(psdDensity > 0 & isfinite(psdDensity));
    if isempty(positivePsd)
        psdDensity(:) = sigma^2;
    else
        psdFloor = max(eps,median(positivePsd)*1e-4);
        psdDensity = max(psdDensity,psdFloor);
        psdDensity = psdDensity*(sigma^2/mean(psdDensity,'all'));
    end
    psd = psdDensity*numel(image);

    noise = struct();
    noise.sigma = sigma;
    noise.psd = psd;
    noise.psdDensity = psdDensity;
    noise.cornerMask = cornerMask;
    noise.patchSigma = patchSigma;
    noise.patchMean = patchMean;
    noise.cornerFraction = opt.CornerFraction;
    noise.psdNormalizationError = ...
        abs(mean(psd,'all')/numel(image)-sigma^2)/max(sigma^2,eps);
    noise.stationarityCV = std(patchSigma,0)/max(mean(patchSigma),eps);
end

function residual = removePlane(patch)
    [x,y] = ndgrid(linspace(-1,1,size(patch,1)), ...
        linspace(-1,1,size(patch,2)));
    design = [ones(numel(patch),1),x(:),y(:)];
    coefficients = design\patch(:);
    residual = patch-reshape(design*coefficients,size(patch));
end

function w = periodicHann(n)
    if n <= 1
        w = ones(n,1);
    else
        w = 0.5-0.5*cos(2*pi*(0:n-1)'/n);
    end
end

function resized = resizePeriodicSpectrum(spectrum,targetSize)
    shifted = fftshift(spectrum);
    sourceRow = linspace(-0.5,0.5,size(shifted,1));
    sourceCol = linspace(-0.5,0.5,size(shifted,2));
    targetRow = linspace(-0.5,0.5,targetSize(1));
    targetCol = linspace(-0.5,0.5,targetSize(2));
    [sourceColGrid,sourceRowGrid] = meshgrid(sourceCol,sourceRow);
    [targetColGrid,targetRowGrid] = meshgrid(targetCol,targetRow);
    resizedShifted = interp2(sourceColGrid,sourceRowGrid,shifted, ...
        targetColGrid,targetRowGrid,'linear');
    resizedShifted(~isfinite(resizedShifted)) = median(shifted,'all');
    resized = ifftshift(max(real(resizedShifted),0));
end
