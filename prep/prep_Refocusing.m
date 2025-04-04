function [...
    rfref, GSref ...
    ] = prep_Refocusing(params, sys)
    flipref          = params.flipref;
    SliceThickness  = params.SliceThickness;
    tRefwd           = params.tRefwd;
    dG              = params.dG;
  
    tRef             = params.paramsRF.tRef;
    phaseRef         = params.paramsRF.phaseRef;

    [rfref, gz_ref] = mr.makeSincPulse(flipref, sys, 'Duration', tRef,... % it was a bug as 'gz' was owerwritten
        'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', phaseRef, 'use', 'refocusing');
    GSref        = mr.makeTrapezoid('z', sys, 'amplitude', gz_ref.amplitude, 'FlatTime', tRefwd, 'riseTime', dG);
    rfref.delay  = rfref.deadTime;
end
