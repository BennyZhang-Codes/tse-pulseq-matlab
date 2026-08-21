function [ADC, Grad] = prep_Gradient_GR(Grad, ADC, Actual, sys)
    % mapping of RO/PE/3D to X/Y/Z
    AxisRO       = Actual.AxisRO   ; 
    SignCorr     = Actual.SignCorr ; 

    fovRO        = Actual.fovRO;
    nRO          = Actual.nRO;
    readoutOS    = Actual.readoutOS;
    ReadoutTime  = Actual.ReadoutTime;
    roDuration   = Actual.roDuration;
    fspR         = Actual.fspR;

    tSp          = Actual.tSp;


    % Readout gradient
    deltakX  = 1 / fovRO;
    GROacq    = mr.makeTrapezoid(AxisRO, sys, 'FlatArea', SignCorr.(AxisRO) * nRO * deltakX, 'FlatTime', ReadoutTime);

    area_GRO_Spoil = GROacq.flatArea*fspR;

    [g_GRO_SpoilPre,  t_GRO_SpoilPre ] = design_gradient_waveform(area_GRO_Spoil, tSp, 0, GROacq.amplitude, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GRO_SpoilPre = mr.makeExtendedTrapezoid(AxisRO, 'system', sys, 'amplitudes', g_GRO_SpoilPre, 'times', t_GRO_SpoilPre); 

    [g_GRO_SpoilPost, t_GRO_SpoilPost] = design_gradient_waveform(area_GRO_Spoil, tSp, GROacq.amplitude, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GRO_SpoilPost = mr.makeExtendedTrapezoid(AxisRO, 'system', sys, 'amplitudes', g_GRO_SpoilPost, 'times', t_GRO_SpoilPost); 

    GRO_adc  = mr.makeExtendedTrapezoid(AxisRO, 'times', [0, ReadoutTime], 'amplitudes', [GROacq.amplitude, GROacq.amplitude]);

    adc      = mr.makeAdc(nRO*readoutOS, 'Duration', roDuration, 'Delay', sys.adcDeadTime, 'system', sys);%,'Delay',GRacq.riseTime);
    
    Area_GROpreph = GROacq.flatArea * (0.5+fspR);

    ADC.adc            = adc;
    ADC.Area_GROpreph  = Area_GROpreph;
    Grad.GRO_adc       = GRO_adc;
    Grad.GRO_SpoilPre  = GRO_SpoilPre;
    Grad.GRO_SpoilPost = GRO_SpoilPost;
end