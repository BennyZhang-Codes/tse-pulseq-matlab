function [Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, params, sys)

    readoutTime  = params.readoutTime;
    nEcho        = params.nEcho;
    VERSE        = params.VERSE;

    amplitudeEx  = Grad.amplitudeEx;
    amplitudeRef = Grad.amplitudeRef;

    tEx          = params.paramsRF.tEx;
    tRef         = params.paramsRF.tRef;

    fspS         = params.fspS;


    TE1          = params.TE1;

    TE1_gap      = TE1 - (tEx+tRef) / 2;

    %% split gradients and recombine into blocks
    g = mr.makeTrapezoid('z', 'system', sys, 'Amplitude', amplitudeRef, 'FlatTime', tRef);
    gs = mr.splitGradient(g);
    GS_RefCrusherL1       = gs(1); 
    if mr.calcDuration(GS_RefCrusherL1) < sys.rfDeadTime
        GS_RefCrusherL1.delay = sys.rfDeadTime - mr.calcDuration(GS_RefCrusherL1);
    end
    area_GS_RefSpoilLeft1 = GS_RefCrusherL1.area;


    % 40 mT/m·ms
    area_GS_ExSpoilPre  = 40*1e-6*sys.gamma;
    area_GS_ExSpoilPost = (amplitudeEx*tEx/2) * fspS - area_GS_RefSpoilLeft1;

    area_GS_RefSpoilLeft  = (amplitudeEx*tEx/2) * (1 + fspS);
    area_GS_RefSpoilRight = (amplitudeEx*tEx/2) * (1 + fspS);

    GS_ExSpoilPre  = mr.makeExtendedTrapezoidArea('z', 0, amplitudeEx, area_GS_ExSpoilPre , sys);
    GS_ExSpoilPost = mr.makeExtendedTrapezoidArea('z', amplitudeEx, 0, area_GS_ExSpoilPost, sys);

    delay_GSex  = GS_ExSpoilPre.shape_dur + tEx;

    GSex_t = [GS_ExSpoilPre.tt'       delay_GSex   GS_ExSpoilPost.tt(2:end)'+delay_GSex];
    GSex_a = [GS_ExSpoilPre.waveform' amplitudeEx  GS_ExSpoilPost.waveform(2:end)'];
    GSex          = mr.makeExtendedTrapezoid('z', 'times', GSex_t, 'amplitudes', GSex_a);
    RF.rfEx.delay = GS_ExSpoilPre.shape_dur;

    assert(mr.calcDuration(GS_ExSpoilPost)            < (TE1_gap - mr.calcDuration(GS_RefCrusherL1)));
    delay_TE1 = TE1_gap - mr.calcDuration(GS_RefCrusherL1) - mr.calcDuration(GS_ExSpoilPost);

    delay_GSref1 = GSex.shape_dur + delay_TE1;
    GS_exref_t = [GSex.tt'       delay_GSref1  GS_RefCrusherL1.tt(2:end)'+delay_GSref1];
    GS_exref_a = [GSex.waveform' 0             GS_RefCrusherL1.waveform(2:end)'];
    GS_exref   = mr.makeExtendedTrapezoid('z', 'times', GS_exref_t, 'amplitudes', GS_exref_a);


    GS_RefCrusherL  = mr.makeExtendedTrapezoidArea('z', 0, amplitudeRef, area_GS_RefSpoilLeft , sys);
    GS_RefCrusherR  = mr.makeExtendedTrapezoidArea('z', amplitudeRef, 0, area_GS_RefSpoilRight, sys);
    GS_RefFlat      = mr.makeExtendedTrapezoid('z', 'times', [0, tRef], 'amplitudes', [amplitudeRef, amplitudeRef]);
    RF.rfRef.delay = 0;
   

    % Gx and its spoiler gradients
    GRpre    = mr.makeTrapezoid('x', sys, 'Area', ADC.AGRpreph, 'duration', TE1_gap, 'delay', delay_GSex);

    

    % fill times
    tex  = mr.calcDuration(GSex);
    tref = mr.calcDuration(GS_RefCrusherL) + mr.calcDuration(GS_RefFlat) + mr.calcDuration(GS_RefCrusherR) + readoutTime;
    tend = mr.calcDuration(GS_RefCrusherL) + mr.calcDuration(GS_RefFlat) + mr.calcDuration(GS_RefCrusherR);
    tETrain = tex + nEcho*tref + tend;

    Grad.GS_exref = GS_exref;
    
    Grad.GS_RefCrusherL = GS_RefCrusherL;
    Grad.GS_RefCrusherR = GS_RefCrusherR;
    Grad.GS_RefFlat     = GS_RefFlat;
    
    Grad.GRpre   = GRpre;
    Grad.tETrain = tETrain;
end
