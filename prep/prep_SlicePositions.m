function [SliceLabel, SliceOrder, SlicePositions] = prep_SlicePositions(params)
    MultiSliceMode  = params.MultiSliceMode;
    nSlice          = params.nSlice;
    SliceThickness  = params.SliceThickness;
    SliceGap        = params.SliceGap;
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
end
