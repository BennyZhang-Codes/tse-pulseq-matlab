function [kspace, imageMask, refMask, counts] = pack_TSE2D_kspace( ...
        imageData, imageMdh, refData, refMdh, nPE, slice)
%PACK_TSE2D_KSPACE Pack unsorted Twix acquisitions into Cartesian k-space.
%
% kspace is [readout, phase encode, coil]. Repeated image acquisitions at
% the same LIN are averaged. PAT reference data are averaged separately and
% then replace the corresponding central lines. This avoids double-weighting
% PATREFANDIMASCAN acquisitions that mapVBVD exposes in both streams.

    if isempty(imageData)
        error('pack_TSE2D_kspace:NoImageData', 'Image data are empty.');
    end
    if ~isfield(imageMdh,'Lin') || ~isfield(imageMdh,'Sli')
        error('pack_TSE2D_kspace:MissingMdh', 'Image MDH fields Lin and Sli are required.');
    end

    nRO = size(imageData,1);
    nCha = size(imageData,2);
    kImage = complex(zeros(nRO,nPE,nCha,'like',imageData));
    imageCount = zeros(1,nPE);

    acquisitions = find(imageMdh.Sli == slice);
    for i = 1:numel(acquisitions)
        a = acquisitions(i);
        line = imageMdh.Lin(a);
        validateLine(line, nPE, 'image');
        kImage(:,line,:) = kImage(:,line,:) + reshape(imageData(:,:,a),nRO,1,nCha);
        imageCount(line) = imageCount(line) + 1;
    end
    imageMask = imageCount > 0;
    for line = find(imageMask)
        kImage(:,line,:) = kImage(:,line,:) / imageCount(line);
    end

    kspace = kImage;
    refCount = zeros(1,nPE);
    if ~isempty(refData)
        if size(refData,1) ~= nRO || size(refData,2) ~= nCha
            error('pack_TSE2D_kspace:ReferenceSizeMismatch', ...
                'Reference and image data must have matching readout and coil dimensions.');
        end
        if ~isfield(refMdh,'Lin') || ~isfield(refMdh,'Sli')
            error('pack_TSE2D_kspace:MissingReferenceMdh', ...
                'Reference MDH fields Lin and Sli are required.');
        end
        kRef = complex(zeros(nRO,nPE,nCha,'like',refData));
        acquisitions = find(refMdh.Sli == slice);
        for i = 1:numel(acquisitions)
            a = acquisitions(i);
            line = refMdh.Lin(a);
            validateLine(line, nPE, 'reference');
            kRef(:,line,:) = kRef(:,line,:) + reshape(refData(:,:,a),nRO,1,nCha);
            refCount(line) = refCount(line) + 1;
        end
        for line = find(refCount > 0)
            kspace(:,line,:) = kRef(:,line,:) / refCount(line);
        end
    end
    refMask = refCount > 0;

    counts = struct('image',imageCount,'reference',refCount);
end

function validateLine(line, nPE, streamName)
    if line < 1 || line > nPE || mod(line,1) ~= 0
        error('pack_TSE2D_kspace:InvalidLine', ...
            '%s LIN=%g is outside the one-based matrix range [1,%d].', ...
            streamName, line, nPE);
    end
end
