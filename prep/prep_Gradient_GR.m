function [ADC, Grad] = prep_Gradient_GR(Grad, ADC, params, sys)
    fovRead      = params.fovRead;
    nX           = params.nX;
    readoutOS    = params.readoutOS;
    readoutTime  = params.readoutTime;
    roDuration   = params.roDuration;
    fspR         = params.fspR;

    TE1          = params.TE1;
    tSp          = params.tSp;

    delay_GR_adc = (TE1 - readoutTime) / 2;


    % Readout gradient
    deltakX  = 1 / fovRead;
    GRacq    = mr.makeTrapezoid('x', sys, 'FlatArea', nX * deltakX, 'FlatTime', readoutTime);

    area_GR_Spoil = GRacq.flatArea*fspR;

    [g_GR_SpoilPre,  t_GR_SpoilPre ] = design_gradient_waveform(area_GR_Spoil, tSp, 0, GRacq.amplitude, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GR_SpoilPre = mr.makeExtendedTrapezoid('x', 'system', sys, 'amplitudes', g_GR_SpoilPre, 'times', t_GR_SpoilPre); 

    [g_GR_SpoilPost, t_GR_SpoilPost] = design_gradient_waveform(area_GR_Spoil, tSp, GRacq.amplitude, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GR_SpoilPost = mr.makeExtendedTrapezoid('x', 'system', sys, 'amplitudes', g_GR_SpoilPost, 'times', t_GR_SpoilPost); 

    GR_adc   = mr.makeExtendedTrapezoid('x', 'times', [0, readoutTime], 'amplitudes', [GRacq.amplitude, GRacq.amplitude]);

    adc      = mr.makeAdc(nX*readoutOS, 'Duration', roDuration, 'Delay', sys.adcDeadTime, 'system', sys);%,'Delay',GRacq.riseTime);
    
    AGRpreph = GRacq.flatArea * (0.5+fspR);

    ADC.adc           = adc;
    ADC.AGRpreph      = AGRpreph;
    Grad.GR_adc       = GR_adc;
    Grad.GR_SpoilPre  = GR_SpoilPre;
    Grad.GR_SpoilPost = GR_SpoilPost;
end
