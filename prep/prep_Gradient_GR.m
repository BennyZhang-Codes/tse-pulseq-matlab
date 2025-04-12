function [ADC, Grad] = prep_Gradient_GR(Grad, ADC, params, sys)
    fovRead      = params.fovRead;
    nX           = params.nX;
    readoutOS    = params.readoutOS;
    readoutTime  = params.readoutTime;
    roDuration   = params.roDuration;
    fspR         = params.fspR;

    TE1          = params.TE1;


    delay_GR_adc = (TE1 - readoutTime) / 2;


    % Readout gradient
    deltakX  = 1 / fovRead;
    GRacq    = mr.makeTrapezoid('x', sys, 'FlatArea', nX * deltakX, 'FlatTime', readoutTime);

    area_GR_Spoil = GRacq.flatArea/2*fspR;
    GR_SpoilPre   = mr.makeExtendedTrapezoidArea('x', 0, GRacq.amplitude, area_GR_Spoil , sys);
    GR_SpoilPost  = mr.makeExtendedTrapezoidArea('x', GRacq.amplitude, 0, area_GR_Spoil , sys);
    
    delay_adc = GR_SpoilPre.shape_dur+readoutTime;
    GR_adc_t = [GR_SpoilPre.tt'       delay_adc       GR_SpoilPost.tt(2:end)' + delay_adc];
    GR_adc_a = [GR_SpoilPre.waveform' GRacq.amplitude GR_SpoilPost.waveform(2:end)'];
    GR_adc   = mr.makeExtendedTrapezoid('x', 'times',GR_adc_t, 'amplitudes', GR_adc_a);
    GR_adc.delay = delay_GR_adc;

    adc      = mr.makeAdc(nX*readoutOS, 'Duration', roDuration, 'Delay', sys.adcDeadTime+mr.calcDuration(GR_SpoilPre)+delay_GR_adc, 'system', sys);%,'Delay',GRacq.riseTime);
    
    AGRpreph = GRacq.flatArea/2 * (1+fspR);

    ADC.adc           = adc;
    ADC.AGRpreph      = AGRpreph;
    Grad.GR_adc       = GR_adc;
    Grad.GR_SpoilPre  = GR_SpoilPre;
    Grad.GR_SpoilPost = GR_SpoilPost;
end
