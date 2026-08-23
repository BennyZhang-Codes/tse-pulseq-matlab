function [filename, info, geometry] = write_TSE2D_nifti(volume, meta, outputDir, varargin)
%WRITE_TSE2D_NIFTI Write a reconstructed 2-D TSE magnitude volume as .nii.gz.
%
%   [FILENAME,INFO,GEOMETRY] = WRITE_TSE2D_NIFTI(VOLUME,META,OUTPUTDIR)
%   writes VOLUME in MATLAB array order [readout, phase encoding, slice].
%   Its complete RAS sform is derived from Siemens MDH slice centers and
%   scalar-first quaternions.
%
%   Name-value options:
%     Prefix       Output basename without .nii/.nii.gz (default "TSE2D")
%     VoxelSizeMm  Explicit [readout phase slice] voxel size override
%     Description  NIfTI header description
%     Overwrite    Permit replacement of an existing file (default false)

%   The sform maps zero-based voxel indices to scanner-patient RAS mm.

    p = inputParser;
    p.addParameter('Prefix','TSE2D',@(x) ischar(x) || isstring(x));
    p.addParameter('VoxelSizeMm',[],@(x) isempty(x) || ...
        (isnumeric(x) && isvector(x) && numel(x) == 3 && all(isfinite(x)) && all(x > 0)));
    p.addParameter('Description','Pulseq 2D TSE magnitude reconstruction', ...
        @(x) ischar(x) || isstring(x));
    p.addParameter('Overwrite',false,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(volume,{'numeric'},{'real','nonempty','finite'},mfilename,'volume');
    if ndims(volume) > 3
        error('write_TSE2D_nifti:InvalidVolume', ...
            'VOLUME must have no more than three dimensions.');
    end
    if ~isstruct(meta)
        error('write_TSE2D_nifti:InvalidMetadata','META must be a structure.');
    end

    outputDir = char(string(outputDir));
    if isempty(outputDir)
        error('write_TSE2D_nifti:EmptyOutputDir','OUTPUTDIR must not be empty.');
    end
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    prefix = char(string(opt.Prefix));
    prefix = regexprep(prefix,'(?i)\.nii(\.gz)?$','');
    if isempty(prefix) || any(contains(prefix,{filesep,'/','\'}))
        error('write_TSE2D_nifti:InvalidPrefix', ...
            'Prefix must be a nonempty filename without path separators.');
    end
    filename = fullfile(outputDir,[prefix '.nii.gz']);
    if isfile(filename) && ~opt.Overwrite
        error('write_TSE2D_nifti:FileExists', ...
            'Output already exists: %s. Set Overwrite=true to replace it.',filename);
    end

    geometry = build_TSE2D_nifti_geometry(meta,size3(volume), ...
        'VoxelSizeMm',opt.VoxelSizeMm);
    voxelSizeMm = geometry.voxelSizeMm;
    volume = single(volume);

    % Generate a complete MATLAB-compatible header, then update the fields
    % that describe this reconstruction. This avoids relying on undocumented
    % assumptions about the minimum niftiwrite metadata structure.
    temporaryDir = tempname;
    mkdir(temporaryDir);
    cleanup = onCleanup(@() cleanupTemporaryDirectory(temporaryDir));
    templateName = fullfile(temporaryDir,'header_template.nii');
    niftiwrite(zeros(1,1,1,'single'),templateName,'Compressed',false);
    info = niftiinfo(templateName);

    info.Filename = filename;
    info.Filemoddate = '';
    info.Filesize = 0;
    info.ImageSize = size3(volume);
    info.PixelDimensions = voxelSizeMm;
    info.Datatype = 'single';
    info.BitsPerPixel = 32;
    info.SpaceUnits = 'Millimeter';
    info.TimeUnits = 'Second';
    info.Description = char(string(opt.Description));
    info.AdditiveOffset = 0;
    info.MultiplicativeScaling = 1;
    info.FrequencyDimension = 1;
    info.PhaseDimension = 2;
    info.SpatialDimension = 3;
    info.TransformName = 'Sform';
    info.Transform = affine3d(geometry.affineRAS.');
    info.Qfactor = geometry.qfactor;

    uncompressedName = fullfile(outputDir,[prefix '.nii']);
    if isfile(uncompressedName)
        error('write_TSE2D_nifti:TemporaryNameExists', ...
            'Cannot safely create compressed output because this file exists: %s', ...
            uncompressedName);
    end
    niftiwrite(volume,uncompressedName,info,'Compressed',true);
    if ~isfile(filename)
        error('write_TSE2D_nifti:WriteFailed', ...
            'niftiwrite did not create the expected file: %s',filename);
    end

    verifyInfo = niftiinfo(filename);
    storedAffineRAS = verifyInfo.Transform.T.';
    affineError = max(abs(storedAffineRAS-geometry.affineRAS),[],'all');
    spacingError = max(abs(double(verifyInfo.PixelDimensions(1:3))-voxelSizeMm));
    if ~isfield(verifyInfo.raw,'sform_code') || verifyInfo.raw.sform_code <= 0 || ...
            affineError > 1e-5 || spacingError > 1e-6
        error('write_TSE2D_nifti:GeometryVerificationFailed', ...
            ['Written NIfTI geometry failed read-back validation ' ...
             '(affine error %.6g, spacing error %.6g mm).'], ...
            affineError,spacingError);
    end
    info = verifyInfo;
    geometry.storedAffineRAS = storedAffineRAS;
    geometry.affineReadbackError = affineError;
    geometry.spacingReadbackErrorMm = spacingError;
    clear cleanup
end

function dimensions = size3(volume)
    dimensions = size(volume);
    dimensions(end+1:3) = 1;
    dimensions = dimensions(1:3);
end

function cleanupTemporaryDirectory(pathname)
    templateName = fullfile(pathname,'header_template.nii');
    if isfile(templateName)
        delete(templateName);
    end
    if isfolder(pathname)
        rmdir(pathname);
    end
end
