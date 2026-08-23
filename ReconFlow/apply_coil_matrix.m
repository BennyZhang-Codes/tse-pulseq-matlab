function dataOut = apply_coil_matrix(dataIn, coilMatrix, varargin)
%APPLY_COIL_MATRIX Apply a matrix to row-wise coil vectors in raw data.
%
% dataOut = apply_coil_matrix(dataIn, coilMatrix)
% dataIn is [readout, coil, acquisition]. The operation for every readout
% sample and acquisition is dataOut(sample,:,acq) = dataIn(sample,:,acq) *
% coilMatrix. Chunking bounds temporary memory for large Twix files.

    p = inputParser;
    p.addParameter('ChunkAcquisitions', 64, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 1 && mod(x,1) == 0);
    p.parse(varargin{:});
    chunk = p.Results.ChunkAcquisitions;

    if isempty(dataIn)
        dataOut = dataIn;
        return;
    end
    nCha = size(dataIn,2);
    if ~isequal(size(coilMatrix), [nCha nCha])
        error('apply_coil_matrix:SizeMismatch', ...
            'coilMatrix must be %d-by-%d.', nCha, nCha);
    end

    coilMatrix = cast(coilMatrix, 'like', dataIn);
    dataOut = zeros(size(dataIn), 'like', dataIn);
    nAcq = size(dataIn,3);
    for first = 1:chunk:nAcq
        last = min(first+chunk-1, nAcq);
        block = permute(dataIn(:,:,first:last), [1 3 2]);
        blockSize = size(block);
        block = reshape(block, [], nCha) * coilMatrix;
        block = reshape(block, blockSize);
        dataOut(:,:,first:last) = permute(block, [1 3 2]);
    end
end
