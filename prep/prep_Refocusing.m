function [...
    rfref, GSref ...
    ] = prep_Refocusing(flipref, rfref_phase, SliceThickness, tRef, tRefwd, dG, system)

    [rfref, gz_ref] = mr.makeSincPulse(flipref, system, 'Duration', tRef,... % it was a bug as 'gz' was owerwritten
        'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', rfref_phase, 'use', 'refocusing');
    GSref        = mr.makeTrapezoid('z', system, 'amplitude', gz_ref.amplitude, 'FlatTime', tRefwd, 'riseTime', dG);
    rfref.delay  = rfref.deadTime;
end
