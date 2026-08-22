function [SliceLabel, SliceOrder, SlicePositions] = prep_SlicePositions(Actual)

    MultiSliceMode  = Actual.MultiSliceMode;
    MultiSliceDir   = Actual.MultiSliceDir;

    if strcmpi(Actual.SeqDimension, '2d')
        nSlice          = Actual.nSlice;
        SliceThickness  = Actual.SliceThickness;
        SliceGap        = Actual.SliceGap;
    elseif strcmpi(Actual.SeqDimension, '3d')
        nSlice          = Actual.nSlab;
        SliceThickness  = Actual.SlabThickness;
        SliceGap        = Actual.SlabGap;
    end

    switch lower(MultiSliceMode)
        case 'sequential'
            SliceLabel = -1 + (1:nSlice);
        case 'interleaved'
            SliceLabel = -1 + [1:2:nSlice, 2:2:nSlice];
        otherwise
            error('Unsupported multislicemode. Choose from sequential, centric, or interleaved.');
    end
    SliceOrder = SliceLabel - (nSlice-1)/2;
    SlicePositions = (SliceThickness + SliceGap) * SliceOrder;

    switch lower(MultiSliceDir)
        case 'ascending'
            SlicePositions = -1 * SlicePositions;
        case 'descending'
            SlicePositions = 1 * SlicePositions;
        otherwise
            error('Unsupported MultiSliceDir. Choose from Ascending or Descending.');
    end
end
