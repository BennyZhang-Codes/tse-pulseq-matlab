function [ADC, Grad] = prep_Gradient_GR(Grad, ADC, Actual, sys)
    % mapping of RO/PE/3D to X/Y/Z
    AxisRO       = Actual.AxisRO   ; 
    SignCorr     = Actual.SignCorr ; 

    fovRO        = Actual.fovRO;
    nRO          = Actual.nRO;
    readoutOS    = Actual.readoutOS;
    readoutTime  = Actual.readoutTime;
    roDuration   = Actual.roDuration;
    fspR         = Actual.fspR;

    tSp          = Actual.tSp;


    % Readout gradient
    deltakX  = 1 / fovRO;
    GRacq    = mr.makeTrapezoid(AxisRO, sys, 'FlatArea', SignCorr.(AxisRO) * nRO * deltakX, 'FlatTime', readoutTime);

    area_GR_Spoil = GRacq.flatArea*fspR;

    [g_GR_SpoilPre,  t_GR_SpoilPre ] = design_gradient_waveform(area_GR_Spoil, tSp, 0, GRacq.amplitude, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GR_SpoilPre = mr.makeExtendedTrapezoid(AxisRO, 'system', sys, 'amplitudes', g_GR_SpoilPre, 'times', t_GR_SpoilPre); 

    [g_GR_SpoilPost, t_GR_SpoilPost] = design_gradient_waveform(area_GR_Spoil, tSp, GRacq.amplitude, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GR_SpoilPost = mr.makeExtendedTrapezoid(AxisRO, 'system', sys, 'amplitudes', g_GR_SpoilPost, 'times', t_GR_SpoilPost); 

    GR_adc   = mr.makeExtendedTrapezoid(AxisRO, 'times', [0, readoutTime], 'amplitudes', [GRacq.amplitude, GRacq.amplitude]);

    adc      = mr.makeAdc(nRO*readoutOS, 'Duration', roDuration, 'Delay', sys.adcDeadTime, 'system', sys);%,'Delay',GRacq.riseTime);
    
    AGRpreph = GRacq.flatArea * (0.5+fspR);

    ADC.adc           = adc;
    ADC.AGRpreph      = AGRpreph;
    Grad.GR_adc       = GR_adc;
    Grad.GR_SpoilPre  = GR_SpoilPre;
    Grad.GR_SpoilPost = GR_SpoilPost;
end
