function [kspaceOut, info] = recon_TSE2D_GRAPPA( ...
        kspaceIn, imageMask, refMask, accelerationFactor, varargin)
%RECON_TSE2D_GRAPPA Regular Cartesian 1D GRAPPA along phase encoding.
%
% [kspaceOut, info] = recon_TSE2D_GRAPPA(kspaceIn, imageMask, refMask, R)
%
% The routine supports integer R >= 2. For each missing PE residue class it
% selects the nearest acquired lattice lines, calibrates from a contiguous
% ACS region, and fills only non-acquired lines. Acquired image and ACS
% samples are retained.
%
% Supported scope
%   - Cartesian acceleration along PE only.
%   - Regular integer acceleration lattice.
%   - Integrated contiguous ACS calibration.
%   - Optional readout-neighbor kernel offsets.
%
% Not implemented here
%   - Partial-Fourier GRAPPA.
%   - SMS / slice-GRAPPA.
%   - Non-Cartesian GRAPPA.
%   - Irregular variable-density / CS masks.
%   - Proprietary Siemens ICE kernel selection, scaling, or filtering.
%
% Options
%   KySourceCount  Acquired PE source lines per target (default 4).
%   KxKernel       Readout offsets used by the kernel (default 0).
%   Regularization Relative Tikhonov loading (default 1e-4).

    p = inputParser;
    p.addParameter('KySourceCount', 4, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 2 && mod(x,1) == 0);
    p.addParameter('KxKernel', 0, ...
        @(x) isnumeric(x) && isvector(x) && all(mod(x,1) == 0));
    p.addParameter('Regularization', 1e-4, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.parse(varargin{:});
    opt = p.Results;

    R = double(accelerationFactor);
    if R < 2 || mod(R,1) ~= 0
        error('recon_TSE2D_GRAPPA:InvalidAcceleration', 'R must be an integer >= 2.');
    end

    nPE = size(kspaceIn,2);
    imageMask = logical(reshape(imageMask,1,[]));
    refMask = logical(reshape(refMask,1,[]));
    if numel(imageMask) ~= nPE || numel(refMask) ~= nPE
        error('recon_TSE2D_GRAPPA:MaskSize', 'Masks must match the PE dimension.');
    end
    if nnz(refMask) < R+1
        error('recon_TSE2D_GRAPPA:InsufficientACS', ...
            'Only %d ACS lines are available for R=%d.', nnz(refMask), R);
    end

    acquiredMask = imageMask | refMask;
    missingLines = find(~acquiredMask);
    imageLines = find(imageMask);
    if numel(imageLines) < opt.KySourceCount
        error('recon_TSE2D_GRAPPA:InsufficientSources', ...
            'Only %d imaging-lattice lines are available.', numel(imageLines));
    end

    kspaceOut = kspaceIn;
    kernels = struct('key',{},'targetResidue',{},'offsets',{},'weights',{}, ...
        'calibrationTargets',{},'calibrationNMSE',{},'condition',{});

    for targetLine = missingLines
        offsets = nearestSourceOffsets(targetLine, imageLines, opt.KySourceCount);
        targetResidue = mod(targetLine-1, R);
        key = sprintf('r%d_%s', targetResidue, sprintf('%+d_',offsets));
        kernelIndex = find(strcmp({kernels.key}, key), 1);
        if isempty(kernelIndex)
            [weights, calibration] = calibrateKernel(kspaceIn, refMask, ...
                targetResidue, R, offsets, opt.KxKernel, opt.Regularization);
            kernelIndex = numel(kernels)+1;
            kernels(kernelIndex).key = key;
            kernels(kernelIndex).targetResidue = targetResidue;
            kernels(kernelIndex).offsets = offsets;
            kernels(kernelIndex).weights = weights;
            kernels(kernelIndex).calibrationTargets = calibration.targets;
            kernels(kernelIndex).calibrationNMSE = calibration.nmse;
            kernels(kernelIndex).condition = calibration.condition;
        end

        sourceLines = targetLine + kernels(kernelIndex).offsets;
        features = makeFeatures(kspaceIn, sourceLines, opt.KxKernel);
        predicted = features * kernels(kernelIndex).weights;
        kspaceOut(:,targetLine,:) = reshape(predicted, size(kspaceIn,1),1,size(kspaceIn,3));
    end

    nmse = [kernels.calibrationNMSE];
    info = struct();
    info.accelerationFactor = R;
    info.kySourceCount = opt.KySourceCount;
    info.kxKernel = opt.KxKernel;
    info.regularization = opt.Regularization;
    info.acquiredImageLines = nnz(imageMask);
    info.referenceLines = nnz(refMask);
    info.missingLinesFilled = numel(missingLines);
    info.calibrationNMSE = mean(nmse,'omitnan');
    info.kernels = kernels;
end

function offsets = nearestSourceOffsets(targetLine, imageLines, count)
    delta = imageLines(:) - targetLine;
    candidates = [abs(delta), delta, imageLines(:)];
    candidates = sortrows(candidates, [1 2]);
    sourceLines = sort(candidates(1:count,3));
    offsets = reshape(sourceLines-targetLine,1,[]);
end

function [weights, info] = calibrateKernel(kspace, refMask, targetResidue, R, ...
        offsets, kxKernel, regularization)
    nRO = size(kspace,1);
    nPE = size(kspace,2);
    nCha = size(kspace,3);
    allLines = 1:nPE;
    targetCandidates = allLines(refMask & mod(allLines-1,R) == targetResidue);
    valid = false(size(targetCandidates));
    for i = 1:numel(targetCandidates)
        sourceLines = targetCandidates(i)+offsets;
        valid(i) = all(sourceLines >= 1 & sourceLines <= nPE) && all(refMask(sourceLines));
    end
    targets = targetCandidates(valid);

    nFeatures = numel(offsets)*numel(kxKernel)*nCha;
    nRows = nRO*numel(targets);
    if isempty(targets) || nRows < nFeatures
        error('recon_TSE2D_GRAPPA:CalibrationUnderdetermined', ...
            ['GRAPPA kernel for residue %d and offsets [%s] has %d targets ', ...
             '(%d equations) for %d features. Increase ACS or reduce the kernel.'], ...
            targetResidue, sprintf('%d ',offsets), numel(targets), nRows, nFeatures);
    end

    A = complex(zeros(nRows,nFeatures,'like',kspace));
    B = complex(zeros(nRows,nCha,'like',kspace));
    for i = 1:numel(targets)
        rows = (i-1)*nRO + (1:nRO);
        A(rows,:) = makeFeatures(kspace, targets(i)+offsets, kxKernel);
        B(rows,:) = reshape(kspace(:,targets(i),:),nRO,nCha);
    end

    gram = A'*A;
    scale = real(trace(gram))/max(nFeatures,1);
    if ~isfinite(scale) || scale <= 0
        error('recon_TSE2D_GRAPPA:ZeroCalibration', 'ACS calibration energy is zero.');
    end
    lambda = regularization*scale;
    gramRegularized = gram + cast(lambda*eye(nFeatures),'like',gram);
    weights = gramRegularized \ (A'*B);
    residual = A*weights-B;

    info = struct();
    info.targets = targets;
    info.nmse = double(sum(abs(residual(:)).^2) / max(sum(abs(B(:)).^2),eps));
    info.condition = cond(double(gramRegularized));
end

function features = makeFeatures(kspace, sourceLines, kxKernel)
    nRO = size(kspace,1);
    nCha = size(kspace,3);
    nFeatures = numel(sourceLines)*numel(kxKernel)*nCha;
    features = complex(zeros(nRO,nFeatures,'like',kspace));
    column = 1;
    base = 0:nRO-1;
    for i = 1:numel(sourceLines)
        for j = 1:numel(kxKernel)
            readoutIndex = mod(base+kxKernel(j),nRO)+1;
            columns = column:(column+nCha-1);
            features(:,columns) = reshape(kspace(readoutIndex,sourceLines(i),:),nRO,nCha);
            column = column+nCha;
        end
    end
end
