function [...
    rfir, GSir ...
    ] = prep_Inversion(params, sys)
    flipir          = params.flipir;
    SliceThickness  = params.SliceThickness;
    tIrwd           = params.tIrwd;
    dG              = params.dG;
  
    tIr             = params.paramsRF.tIr;
    phaseIr         = params.paramsRF.phaseIr;

    [rfir, gz_ir]   = mr.makeSincPulse(flipir, sys, 'Duration', tIr,...
        'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset',  phaseIr,...
        'use', 'inversion');
    GSir         = mr.makeTrapezoid('z', sys, 'amplitude', gz_ir.amplitude, 'FlatTime', tIrwd, 'riseTime', dG);
    rfir.delay   = rfir.deadTime;
end
