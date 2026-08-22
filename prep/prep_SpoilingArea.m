function [Grad] = prep_SpoilingArea(Grad, Actual)

    AreaPreExcitationSpoiler = resolveSpoilerArea(Actual.ActualSpoiling.PreExcitationSpoiler, Actual);
    AreaRefocusingCrusher    = resolveSpoilerArea(Actual.ActualSpoiling.RefocusingCrusher   , Actual);
    AreaInversionCrusher     = resolveSpoilerArea(Actual.ActualSpoiling.InversionCrusher    , Actual);
    AreaReadoutCrusher       = resolveSpoilerArea(Actual.ActualSpoiling.ReadoutCrusher      , Actual);
    AreaEndSpoiler           = resolveSpoilerArea(Actual.ActualSpoiling.EndSpoiler          , Actual);

    Grad.SpoilingArea.PreExcitationSpoiler = AreaPreExcitationSpoiler;
    Grad.SpoilingArea.RefocusingCrusher    = AreaRefocusingCrusher   ;
    Grad.SpoilingArea.InversionCrusher     = AreaInversionCrusher    ;
    Grad.SpoilingArea.ReadoutCrusher       = AreaReadoutCrusher      ;
    Grad.SpoilingArea.EndSpoiler           = AreaEndSpoiler          ;

end


function area = resolveSpoilerArea(spec, Actual)


    switch lower(spec.Reference)
    
        case 'slice'
            referenceLength = Actual.SliceThickness;
        case 'ro'
            referenceLength = Actual.FOV(1) / Actual.MatrixSize(1);
        case 'pe'
            referenceLength = Actual.FOV(2) / Actual.MatrixSize(2);
        case '3d'
            referenceLength = Actual.FOV(3) / Actual.MatrixSize(3);
        case 'slab'
            referenceLength = Actual.SlabThickness;
        otherwise
            error('Unknown spoiler reference: %s', spec.Reference);
    end
    
    area = spec.Cycles / referenceLength; % cycles/m

end