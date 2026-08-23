function raw = read_TSE2D_twix(filename, varargin)
%READ_TSE2D_TWIX Read Cartesian 2D TSE data from a Siemens Twix file.
%
% raw = read_TSE2D_twix(filename, Name, Value, ...)
%
% Name-value options
%   MapVBVDPath          Folder containing mapVBVD.m. It is only added when
%                        mapVBVD is not already on the MATLAB path.
%   RemoveOversampling  Remove twofold readout oversampling for image,
%                        phase-correction, and reference data (default true).
%   LoadNoise           Load the noise scan without removing oversampling
%                        (default true).
%
% LIN, SLC, and SEG values returned in raw.*.mdh are MATLAB/mapVBVD
% one-based indices. SEG is used as the TSE echo number.

    p = inputParser;
    p.addRequired('filename', @(x) ischar(x) || isstring(x));
    p.addParameter('MapVBVDPath', '', @(x) ischar(x) || isstring(x));
    p.addParameter('RemoveOversampling', true, @(x) islogical(x) && isscalar(x));
    p.addParameter('LoadNoise', true, @(x) islogical(x) && isscalar(x));
    p.parse(filename, varargin{:});
    opt = p.Results;

    filename = char(string(filename));
    if ~isfile(filename)
        error('read_TSE2D_twix:FileNotFound', 'Twix file not found: %s', filename);
    end

    if isempty(which('mapVBVD'))
        mapPath = char(string(opt.MapVBVDPath));
        if ~isempty(mapPath)
            addpath(mapPath);
        end
    end
    if isempty(which('mapVBVD'))
        error('read_TSE2D_twix:MapVBVDMissing', ...
            'mapVBVD.m is not on the MATLAB path. Supply MapVBVDPath.');
    end

    twix = mapVBVD(filename);
    if iscell(twix)
        twix = twix{end};
    end
    if ~isfield(twix, 'image') || isempty(twix.image) || twix.image.NAcq < 1
        error('read_TSE2D_twix:NoImageData', 'No image acquisitions found in %s.', filename);
    end

    raw = struct();
    raw.filename = string(filename);
    raw.image = readStream(twix.image, opt.RemoveOversampling);
    raw.phasecor = readOptionalStream(twix, 'phasecor', opt.RemoveOversampling);
    raw.refscan = readOptionalStream(twix, 'refscan', opt.RemoveOversampling);
    raw.refscanPC = readOptionalStream(twix, 'refscanPC', opt.RemoveOversampling);

    if opt.LoadNoise
        % Do not remove readout oversampling from noise. Cropping in image
        % space correlates adjacent noise samples and biases covariance.
        raw.noise = readOptionalStream(twix, 'noise', false);
    else
        raw.noise = emptyStream();
    end

    raw.meta = extractMetadata(twix, raw);
end

function stream = readOptionalStream(twix, fieldName, removeOS)
    if ~isfield(twix, fieldName) || isempty(twix.(fieldName)) || twix.(fieldName).NAcq < 1
        stream = emptyStream();
        return;
    end
    stream = readStream(twix.(fieldName), removeOS);
end

function stream = readStream(obj, removeOS)
    obj.flagRemoveOS = removeOS;
    stream = struct();
    stream.exists = true;
    stream.data = single(obj.unsorted());
    stream.mdh = copyMdh(obj);
    stream.nAcq = double(obj.NAcq);
    stream.nCol = size(stream.data, 1);
    stream.nCha = size(stream.data, 2);
end

function stream = emptyStream()
    stream = struct('exists', false, 'data', [], 'mdh', struct(), ...
        'nAcq', 0, 'nCol', 0, 'nCha', 0);
end

function mdh = copyMdh(obj)
    names = {'Lin','Sli','Seg','Eco','Ave','Rep','Set','centerCol', ...
        'centerLin','centerPar','timestamp','scancounter','memPos', ...
        'IsReflected','IsRawDataCorrect','evalInfoMask','slicePos'};
    mdh = struct();
    for i = 1:numel(names)
        name = names{i};
        if isprop(obj, name)
            mdh.(name) = obj.(name);
        end
    end
end

function meta = extractMetadata(twix, raw)
    meta = struct();
    meta.nRO = raw.image.nCol;
    meta.nCha = raw.image.nCha;
    meta.nSlice = max(raw.image.mdh.Sli);
    meta.sliceIndices = unique(raw.image.mdh.Sli(:)).';
    meta.nEcho = max(raw.image.mdh.Seg);
    meta.imageAcquisitions = raw.image.nAcq;
    meta.phaseCorAcquisitions = raw.phasecor.nAcq;
    meta.refscanAcquisitions = raw.refscan.nAcq;
    meta.noiseAcquisitions = raw.noise.nAcq;

    meta.nPE = getNestedNumeric(twix.hdr, {'Config','PhaseEncodingLines'}, NaN);
    if ~isfinite(meta.nPE)
        meta.nPE = getNestedNumeric(twix.hdr, {'MeasYaps','sKSpace','lPhaseEncodingLines'}, NaN);
    end
    if ~isfinite(meta.nPE)
        centerLin = mode(raw.image.mdh.centerLin);
        meta.nPE = max(max(raw.image.mdh.Lin), 2*(centerLin-1));
    end
    meta.nPE = double(meta.nPE);

    meta.centerLine = mode(raw.image.mdh.centerLin); % mapVBVD one-based LIN
    meta.centerLineSiemens = meta.centerLine - 1;

    meta.accelerationFactorPE = getNestedNumeric(twix.hdr, ...
        {'MeasYaps','sPat','lAccelFactPE'}, NaN);
    if ~isfinite(meta.accelerationFactorPE) || meta.accelerationFactorPE < 1
        lin = sort(unique(raw.image.mdh.Lin));
        d = diff(lin);
        d = d(d > 0);
        if isempty(d)
            meta.accelerationFactorPE = 1;
        else
            meta.accelerationFactorPE = max(1, round(median(d)));
        end
    end
    meta.accelerationFactorPE = double(meta.accelerationFactorPE);

    meta.referenceLinesPE = getNestedNumeric(twix.hdr, ...
        {'MeasYaps','sPat','lRefLinesPE'}, raw.refscan.nAcq/max(meta.nSlice,1));
    meta.referenceScanMode = getNestedNumeric(twix.hdr, ...
        {'MeasYaps','sPat','ucRefScanMode'}, NaN);
    meta.imageLines = getNestedNumeric(twix.hdr, {'Config','ImageLines'}, meta.nPE);
    meta.fourierLines = getNestedNumeric(twix.hdr, {'Config','NoOfFourierLines'}, NaN);
    geometry = extractSliceGeometry(twix.hdr);
    meta.readoutFOVMm = geometry.readoutFOVMm;
    meta.phaseFOVMm = geometry.phaseFOVMm;
    meta.sliceThicknessMm = geometry.sliceThicknessMm;
    meta.sliceSpacingMm = geometry.sliceSpacingMm;
    meta.slicePositionsMm = geometry.slicePositionsMm;
    meta.sliceNormal = geometry.sliceNormal;
    meta.voxelSizeMm = [meta.readoutFOVMm/meta.nRO, ...
        meta.phaseFOVMm/meta.nPE, meta.sliceSpacingMm];

    mdhGeometry = extractMdhSliceGeometry(raw.image.mdh);
    meta.sliceCentersSCTMm = mdhGeometry.sliceCentersSCTMm;
    meta.sliceQuaternionsWXYZ = mdhGeometry.sliceQuaternionsWXYZ;
    meta.slicePositionVariationMm = mdhGeometry.positionVariationMm;
    meta.sliceQuaternionVariationDeg = mdhGeometry.quaternionVariationDeg;
    meta.geometrySource = mdhGeometry.source;
    meta.patientCoordinateSystem = ...
        'Siemens SCT/LPH: +Sag=left, +Cor=posterior, +Tra=head';


    meta.onlinePhaseCorrection = struct( ...
        'autoCorr', logical(getNestedNumeric(twix.hdr, {'Config','IsOnlinePCAutoCorr'}, false)), ...
        'crossCorr', logical(getNestedNumeric(twix.hdr, {'Config','IsOnlinePCCrossCorr'}, false)), ...
        'filtered', logical(getNestedNumeric(twix.hdr, {'Config','IsOnlinePCFiltered'}, false)));

    meta.phasecorAlsoRefscanPC = false;
    if raw.phasecor.exists && raw.refscanPC.exists && ...
            isfield(raw.phasecor.mdh, 'memPos') && isfield(raw.refscanPC.mdh, 'memPos')
        meta.phasecorAlsoRefscanPC = isequal(raw.phasecor.mdh.memPos, raw.refscanPC.mdh.memPos);
    end
end
function geometry = extractMdhSliceGeometry(mdh)
    geometry = struct('sliceCentersSCTMm',zeros(0,3), ...
        'sliceQuaternionsWXYZ',zeros(0,4), ...
        'positionVariationMm',zeros(0,1), ...
        'quaternionVariationDeg',zeros(0,1), ...
        'source','unavailable');
    if ~isfield(mdh,'Sli') || ~isfield(mdh,'slicePos') || ...
            isempty(mdh.Sli) || isempty(mdh.slicePos)
        return
    end

    sliceIds = double(mdh.Sli(:));
    slicePos = double(mdh.slicePos);
    if size(slicePos,1) == 7 && size(slicePos,2) == numel(sliceIds)
        % mapVBVD stores [Sag Cor Tra quaternion(w x y z)] by acquisition.
    elseif size(slicePos,2) == 7 && size(slicePos,1) == numel(sliceIds)
        slicePos = slicePos.';
    else
        return
    end

    nSlice = max(sliceIds);
    centers = NaN(nSlice,3);
    quaternions = NaN(nSlice,4);
    positionVariation = NaN(nSlice,1);
    quaternionVariation = NaN(nSlice,1);
    for slice = reshape(unique(sliceIds(isfinite(sliceIds) & sliceIds >= 1)),1,[])
        rows = sliceIds == slice;
        positions = slicePos(1:3,rows).';
        positions = positions(all(isfinite(positions),2),:);
        if ~isempty(positions)
            centers(slice,:) = median(positions,1);
            positionVariation(slice) = max(vecnorm( ...
                positions-centers(slice,:),2,2),[],1);
        end

        q = slicePos(4:7,rows).';
        q = q(all(isfinite(q),2),:);
        qNorm = vecnorm(q,2,2);
        q = q(qNorm > 0,:);
        qNorm = qNorm(qNorm > 0);
        if isempty(q)
            continue
        end
        q = q./qNorm;
        reference = q(1,:);
        flipRows = q*reference.' < 0;
        q(flipRows,:) = -q(flipRows,:);
        qMean = mean(q,1);
        qMean = qMean/norm(qMean);
        quaternions(slice,:) = qMean;
        cosineHalfAngle = min(1,abs(q*qMean.'));
        quaternionVariation(slice) = max(2*acosd(cosineHalfAngle));
    end

    geometry.sliceCentersSCTMm = centers;
    geometry.sliceQuaternionsWXYZ = quaternions;
    geometry.positionVariationMm = positionVariation;
    geometry.quaternionVariationDeg = quaternionVariation;
    geometry.source = 'Siemens MDH SliceData.slicePos';
end

function geometry = extractSliceGeometry(hdr)
    geometry = struct('readoutFOVMm',NaN,'phaseFOVMm',NaN, ...
        'sliceThicknessMm',NaN,'sliceSpacingMm',NaN, ...
        'slicePositionsMm',zeros(0,3),'sliceNormal',[NaN NaN NaN]);
    if ~isfield(hdr,'MeasYaps') || ~isfield(hdr.MeasYaps,'sSliceArray') || ...
            ~isfield(hdr.MeasYaps.sSliceArray,'asSlice')
        return
    end

    slices = hdr.MeasYaps.sSliceArray.asSlice;
    if ~iscell(slices)
        slices = num2cell(slices);
    end
    slices = slices(~cellfun(@isempty,slices));
    if isempty(slices)
        return
    end

    first = slices{1};
    geometry.readoutFOVMm = getScalarField(first,'dReadoutFOV',NaN);
    geometry.phaseFOVMm = getScalarField(first,'dPhaseFOV',NaN);
    geometry.sliceThicknessMm = getScalarField(first,'dThickness',NaN);

    positions = NaN(numel(slices),3);
    normals = NaN(numel(slices),3);
    for i = 1:numel(slices)
        slice = slices{i};
        if isfield(slice,'sPosition')
            positions(i,:) = readSagCorTra(slice.sPosition);
        end
        if isfield(slice,'sNormal')
            normals(i,:) = readSagCorTra(slice.sNormal);
        end
    end
    geometry.slicePositionsMm = positions;

    validNormal = find(all(isfinite(normals),2) & vecnorm(normals,2,2) > 0,1);
    if ~isempty(validNormal)
        normal = normals(validNormal,:);
        normal = normal/norm(normal);
        geometry.sliceNormal = normal;
    else
        normal = [NaN NaN NaN];
    end

    validPosition = all(isfinite(positions),2);
    if nnz(validPosition) > 1 && all(isfinite(normal))
        projectedPositions = sort(positions(validPosition,:)*normal.');
        separations = abs(diff(projectedPositions));
        separations = separations(separations > 100*eps(max(abs(projectedPositions))));
        if ~isempty(separations)
            geometry.sliceSpacingMm = median(separations);
        end
    end
    if ~isfinite(geometry.sliceSpacingMm) || geometry.sliceSpacingMm <= 0
        geometry.sliceSpacingMm = geometry.sliceThicknessMm;
    end
end

function values = readSagCorTra(s)
    values = [getScalarField(s,'dSag',0), ...
        getScalarField(s,'dCor',0), getScalarField(s,'dTra',0)];
end

function value = getScalarField(s,name,fallback)
    value = fallback;
    if isstruct(s) && isfield(s,name) && isnumeric(s.(name)) && ~isempty(s.(name))
        data = s.(name);
        value = double(data(1));
    end
end

function value = getNestedNumeric(s, fields, fallback)
    value = fallback;
    current = s;
    for i = 1:numel(fields)
        if ~isstruct(current) || ~isfield(current, fields{i})
            return;
        end
        current = current.(fields{i});
    end
    if isnumeric(current) || islogical(current)
        if ~isempty(current)
            value = double(current(1));
        end
    end
end
