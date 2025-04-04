function [...
    rfex, GSex ...
    ] = prep_Excitation(params, sys)
    flipex          = params.flipex;
    SliceThickness  = params.SliceThickness;
    tExwd           = params.tExwd;
    dG              = params.dG;
    
    tEx             = params.paramsRF.tEx;
    phaseEx         = params.paramsRF.phaseEx;

    % Readout gradient
    [rfex, gz_ex]   = mr.makeSincPulse(flipex, sys, 'Duration', tEx,...
        'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', phaseEx,...
        'use', 'excitation');
    GSex         = mr.makeTrapezoid('z', sys, 'amplitude', gz_ex.amplitude, 'FlatTime', tExwd, 'riseTime', dG);
    rfex.delay   = rfex.deadTime;
end
