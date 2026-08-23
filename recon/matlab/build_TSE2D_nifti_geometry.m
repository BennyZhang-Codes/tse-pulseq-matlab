function geometry = build_TSE2D_nifti_geometry(meta,imageSize,varargin)
%BUILD_TSE2D_NIFTI_GEOMETRY Build a scanner-patient RAS NIfTI sform.
%
% Geometry is derived from Siemens MDH SliceData positions and scalar-first
% quaternions. Voxel indices follow MATLAB array order [readout, phase,
% slice], while the returned affine uses the NIfTI zero-based column-vector
% convention: ras_mm = affineRAS * [i j k 1].'

    p = inputParser;
    p.addParameter('VoxelSizeMm',[],@(x) isempty(x) || ...
        (isnumeric(x) && isvector(x) && numel(x) == 3 && ...
        all(isfinite(x)) && all(x > 0)));
    p.parse(varargin{:});

    validateattributes(imageSize,{'numeric'},{'vector','nonempty','finite','positive'});
    imageSize = double(reshape(imageSize,1,[]));
    imageSize(end+1:3) = 1;
    imageSize = imageSize(1:3);
    if any(imageSize ~= round(imageSize))
        error('build_TSE2D_nifti_geometry:InvalidImageSize', ...
            'Image dimensions must be positive integers.');
    end
    if ~isstruct(meta)
        error('build_TSE2D_nifti_geometry:InvalidMetadata','META must be a structure.');
    end

    sliceIndices = resolveSliceIndices(meta,imageSize(3));
    [centersSCT,quaternions] = selectMdhGeometry(meta,sliceIndices);
    voxelSizeMm = resolveVoxelSize(meta,imageSize,p.Results.VoxelSizeMm);

    rotationSCT = quaternionToRotation(quaternions(1,:));
    % Siemens MDH quaternion columns describe phase, read, slice after the
    % documented PRS sign convention. Reorder to the stored MATLAB axes.
    readDirectionSCT = normalizeVector(-rotationSCT(:,2));
    phaseDirectionSCT = normalizeVector(-rotationSCT(:,1));
    quaternionSliceDirectionSCT = normalizeVector(rotationSCT(:,3));

    if imageSize(3) > 1
        deltas = diff(centersSCT,1,1);
        separations = vecnorm(deltas,2,2);
        if any(~isfinite(separations) | separations <= 0)
            error('build_TSE2D_nifti_geometry:InvalidSlicePositions', ...
                'Adjacent reconstructed slices do not have distinct finite centers.');
        end
        sliceSpacingMm = median(separations);
        sliceDirectionSCT = normalizeVector(mean(deltas,1).');
        projectedSpacing = deltas*sliceDirectionSCT;
        transverseError = vecnorm(deltas-projectedSpacing*sliceDirectionSCT.',2,2);
        spacingError = abs(projectedSpacing-sliceSpacingMm);
        toleranceMm = max(1e-3,1e-4*sliceSpacingMm);
        if max(transverseError) > toleranceMm || max(spacingError) > toleranceMm
            error('build_TSE2D_nifti_geometry:NonuniformSliceStack', ...
                ['Slice centers are not a uniform collinear stack (maximum ' ...
                 'transverse/spacing errors %.6g/%.6g mm).'], ...
                max(transverseError),max(spacingError));
        end
        if abs(dot(sliceDirectionSCT,quaternionSliceDirectionSCT)) < 0.999
            error('build_TSE2D_nifti_geometry:SliceQuaternionMismatch', ...
                'MDH slice-center direction conflicts with its quaternion.');
        end
        if dot(sliceDirectionSCT,quaternionSliceDirectionSCT) < 0
            quaternionSliceDirectionSCT = -quaternionSliceDirectionSCT;
        end
        if ~isempty(p.Results.VoxelSizeMm) && ...
                abs(voxelSizeMm(3)-sliceSpacingMm) > toleranceMm
            error('build_TSE2D_nifti_geometry:SliceSpacingOverrideMismatch', ...
                ['VoxelSizeMm(3)=%.9g mm conflicts with the %.9g-mm spacing ' ...
                 'measured from the MDH slice centers.'], ...
                voxelSizeMm(3),sliceSpacingMm);
        end
        voxelSizeMm(3) = sliceSpacingMm;
    else
        sliceDirectionSCT = quaternionSliceDirectionSCT;
        sliceSpacingMm = voxelSizeMm(3);
    end

    validateOrientationAcrossSlices(quaternions,readDirectionSCT, ...
        phaseDirectionSCT,quaternionSliceDirectionSCT);

    % Siemens SCT/LPH is DICOM-LPS-equivalent. NIfTI world coordinates are RAS.
    sctToRAS = diag([-1 -1 1]);
    readDirectionRAS = sctToRAS*readDirectionSCT;
    phaseDirectionRAS = sctToRAS*phaseDirectionSCT;
    sliceDirectionRAS = sctToRAS*sliceDirectionSCT;
    centersRAS = (sctToRAS*centersSCT.').';

    firstVoxelCenterSCT = centersSCT(1,:).' ...
        - readDirectionSCT*((imageSize(1)-1)*voxelSizeMm(1)/2) ...
        - phaseDirectionSCT*((imageSize(2)-1)*voxelSizeMm(2)/2);
    firstVoxelCenterRAS = sctToRAS*firstVoxelCenterSCT;

    affineRAS = eye(4);
    affineRAS(1:3,1) = readDirectionRAS*voxelSizeMm(1);
    affineRAS(1:3,2) = phaseDirectionRAS*voxelSizeMm(2);
    affineRAS(1:3,3) = sliceDirectionRAS*voxelSizeMm(3);
    affineRAS(1:3,4) = firstVoxelCenterRAS;

    centerIndices = repmat([(imageSize(1)-1)/2 (imageSize(2)-1)/2 0 1], ...
        imageSize(3),1);
    centerIndices(:,3) = (0:imageSize(3)-1).';
    mappedCentersRAS = (affineRAS*centerIndices.').';
    centerErrorsMm = vecnorm(mappedCentersRAS(:,1:3)-centersRAS,2,2);
    if max(centerErrorsMm) > 1e-3
        error('build_TSE2D_nifti_geometry:CenterValidationFailed', ...
            'Affine-to-MDH slice-center error is %.6g mm.',max(centerErrorsMm));
    end

    geometry = struct();
    geometry.source = 'Siemens MDH SliceData.slicePos';
    geometry.patientCoordinateSystem = ...
        'Siemens SCT/LPH: +Sag=left, +Cor=posterior, +Tra=head';
    geometry.niftiCoordinateSystem = 'RAS+ millimetres';
    geometry.imageSize = imageSize;
    geometry.sliceIndices = sliceIndices;
    geometry.voxelSizeMm = voxelSizeMm;
    geometry.affineRAS = affineRAS;
    geometry.qfactor = sign(det(affineRAS(1:3,1:3)));
    geometry.readDirectionSCT = readDirectionSCT.';
    geometry.phaseDirectionSCT = phaseDirectionSCT.';
    geometry.sliceDirectionSCT = sliceDirectionSCT.';
    geometry.readDirectionRAS = readDirectionRAS.';
    geometry.phaseDirectionRAS = phaseDirectionRAS.';
    geometry.sliceDirectionRAS = sliceDirectionRAS.';
    geometry.sliceCentersSCTMm = centersSCT;
    geometry.sliceCentersRASMm = centersRAS;
    geometry.firstVoxelCenterRASMm = firstVoxelCenterRAS.';
    geometry.sliceSpacingMm = sliceSpacingMm;
    geometry.maxSliceCenterErrorMm = max(centerErrorsMm);
end

function sliceIndices = resolveSliceIndices(meta,nImageSlices)
    if isfield(meta,'reconstructedSlices') && ~isempty(meta.reconstructedSlices)
        sliceIndices = double(meta.reconstructedSlices(:).');
    elseif isfield(meta,'sliceIndices') && ~isempty(meta.sliceIndices)
        sliceIndices = double(meta.sliceIndices(:).');
    else
        sliceIndices = 1:nImageSlices;
    end
    if numel(sliceIndices) ~= nImageSlices || any(sliceIndices < 1) || ...
            any(sliceIndices ~= round(sliceIndices)) || numel(unique(sliceIndices)) ~= nImageSlices
        error('build_TSE2D_nifti_geometry:SliceIndexMismatch', ...
            'Reconstructed slice indices must uniquely match volume dimension 3.');
    end
end

function [centers,quaternions] = selectMdhGeometry(meta,sliceIndices)
    required = {'sliceCentersSCTMm','sliceQuaternionsWXYZ'};
    if ~all(isfield(meta,required))
        error('build_TSE2D_nifti_geometry:MissingMdhGeometry', ...
            ['Complete patient-space geometry requires Twix MDH slicePos. ' ...
             'Re-read the data with read_TSE2D_twix.']);
    end
    centersAll = double(meta.sliceCentersSCTMm);
    quaternionsAll = double(meta.sliceQuaternionsWXYZ);
    if size(centersAll,2) ~= 3 || size(quaternionsAll,2) ~= 4 || ...
            max(sliceIndices) > size(centersAll,1) || ...
            max(sliceIndices) > size(quaternionsAll,1)
        error('build_TSE2D_nifti_geometry:InvalidMdhGeometry', ...
            'MDH slice position/quaternion arrays do not cover reconstructed slices.');
    end
    centers = centersAll(sliceIndices,:);
    quaternions = quaternionsAll(sliceIndices,:);
    if any(~isfinite(centers),'all') || any(~isfinite(quaternions),'all')
        error('build_TSE2D_nifti_geometry:InvalidMdhGeometry', ...
            'Reconstructed slices have missing MDH positions or quaternions.');
    end
    norms = vecnorm(quaternions,2,2);
    if any(norms <= 0)
        error('build_TSE2D_nifti_geometry:InvalidQuaternion', ...
            'MDH slice quaternion has zero norm.');
    end
    quaternions = quaternions./norms;
end

function voxelSizeMm = resolveVoxelSize(meta,imageSize,override)
    if ~isempty(override)
        voxelSizeMm = double(reshape(override,1,3));
        return
    end
    voxelSizeMm = [NaN NaN NaN];
    if isfield(meta,'voxelSizeMm') && isnumeric(meta.voxelSizeMm) && ...
            numel(meta.voxelSizeMm) >= 3
        voxelSizeMm = double(reshape(meta.voxelSizeMm(1:3),1,3));
    end
    if isfield(meta,'readoutFOVMm') && isfiniteScalar(meta.readoutFOVMm)
        voxelSizeMm(1) = double(meta.readoutFOVMm)/imageSize(1);
    end
    if isfield(meta,'phaseFOVMm') && isfiniteScalar(meta.phaseFOVMm)
        voxelSizeMm(2) = double(meta.phaseFOVMm)/imageSize(2);
    end
    if ~isfinite(voxelSizeMm(3)) && isfield(meta,'sliceSpacingMm') && ...
            isfiniteScalar(meta.sliceSpacingMm)
        voxelSizeMm(3) = double(meta.sliceSpacingMm);
    elseif ~isfinite(voxelSizeMm(3)) && isfield(meta,'sliceThicknessMm') && ...
            isfiniteScalar(meta.sliceThicknessMm)
        voxelSizeMm(3) = double(meta.sliceThicknessMm);
    end
    if any(~isfinite(voxelSizeMm) | voxelSizeMm <= 0)
        error('build_TSE2D_nifti_geometry:MissingVoxelSize', ...
            'Cannot determine positive voxel dimensions in millimetres.');
    end
end

function tf = isfiniteScalar(value)
    tf = isnumeric(value) && isscalar(value) && isfinite(value);
end

function rotation = quaternionToRotation(q)
    q = double(q(:).');
    q = q/norm(q);
    w = q(1); x = q(2); y = q(3); z = q(4);
    rotation = [ ...
        1-2*(y*y+z*z), 2*(x*y-z*w),   2*(x*z+y*w); ...
        2*(x*y+z*w),   1-2*(x*x+z*z), 2*(y*z-x*w); ...
        2*(x*z-y*w),   2*(y*z+x*w),   1-2*(x*x+y*y)];
end

function vector = normalizeVector(vector)
    vector = double(vector(:));
    magnitude = norm(vector);
    if ~isfinite(magnitude) || magnitude <= 0
        error('build_TSE2D_nifti_geometry:InvalidDirection', ...
            'Orientation contains a non-finite or zero direction vector.');
    end
    vector = vector/magnitude;
end

function validateOrientationAcrossSlices(quaternions,readDirection,phaseDirection,sliceDirection)
    tolerance = 1e-5;
    for i = 2:size(quaternions,1)
        rotation = quaternionToRotation(quaternions(i,:));
        directions = [-rotation(:,2) -rotation(:,1) rotation(:,3)];
        reference = [readDirection phaseDirection sliceDirection];
        if max(1-abs(sum(directions.*reference,1))) > tolerance
            error('build_TSE2D_nifti_geometry:NonparallelSlices', ...
                'MDH quaternions indicate nonparallel reconstructed slices.');
        end
    end
end
