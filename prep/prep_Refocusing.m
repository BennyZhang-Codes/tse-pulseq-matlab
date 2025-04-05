function [rfref, GSref] = prep_Refocusing(params, sys)
    flipref          = params.flipref;
    SliceThickness   = params.SliceThickness;
    tRefwd           = params.tRefwd;
    dG               = params.dG;

    typeRef          = params.paramsRF.typeRef;
    tRef             = params.paramsRF.tRef;
    tbpRef           = params.paramsRF.tbpRef;
    phaseRef         = params.paramsRF.phaseRef;

    switch lower(typeRef)
        case 'sinc'
            [rfref, gz_ref] = mr.makeSincPulse(flipref, sys, 'Duration', tRef,... 
                'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', tbpRef, ...
                'PhaseOffset', phaseRef, 'use', 'refocusing');
        case 'slr'
            % TODO
    end
            
    GSref        = mr.makeTrapezoid('z', sys, 'amplitude', gz_ref.amplitude, 'FlatTime', tRefwd, 'riseTime', dG);
    rfref.delay  = rfref.deadTime;
end
