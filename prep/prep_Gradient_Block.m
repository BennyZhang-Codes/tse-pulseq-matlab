function [Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, Actual, sys)
    % mapping of RO/PE/3D to X/Y/Z
    AxisRO   = Actual.AxisRO   ; 
    Axis3D   = Actual.Axis3D   ; 
    SignCorr = Actual.SignCorr ; 

    IR           = Actual.IR;
    nEcho        = Actual.nEcho;
    VERSE        = Actual.VERSE;
    SliceThickness = Actual.SliceThickness;

    amplitudeEx  = Grad.amplitudeEx;
    amplitudeRef = Grad.amplitudeRef;

    tEx          = Actual.ActualRF.tEx;
    tRef         = Actual.ActualRF.tRef;

    fspS         = Actual.fspS;
    tSp          = Actual.tSp;

    TE1          = Actual.TE1;
    TE1_gap      = RoundRaster((TE1 - tEx - tRef) / 2, sys.gradRasterTime, 'round');
    

    GRO_SpoilPre  = Grad.GRO_SpoilPre;
    GRO_SpoilPost = Grad.GRO_SpoilPost;


    %% IR
    if strcmpi(IR, 'on')
        amplitudeInv = Grad.amplitudeInv;
        tInv         = Actual.ActualRF.tInv;
  
        [g_InvSpoilPre, t_InvSpoilPre] = design_gradient_min_time(SignCorr.(Axis3D) * 4/SliceThickness, 10e-3, 0, amplitudeInv, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
        G3D_InvSpoilPre = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_InvSpoilPre, 'times', t_InvSpoilPre);    
        [g_InvSpoilPost, t_InvSpoilPost] = design_gradient_min_time(SignCorr.(Axis3D) * 4/SliceThickness, 10e-3, amplitudeInv, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
        G3D_InvSpoilPost = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_InvSpoilPost, 'times', t_InvSpoilPost);
        G3D_InvFlat = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'times', [0, tInv], 'amplitudes', [amplitudeInv, amplitudeInv]);
        G3D_Inv = concatGrads({G3D_InvSpoilPre, G3D_InvFlat, G3D_InvSpoilPost}, sys);

        Grad.G3D_Inv = G3D_Inv;
        RF.rfInv.delay  = mr.calcDuration(G3D_InvSpoilPre);
    end
    %% combine into blocks
    g = mr.makeTrapezoid(Axis3D, 'system', sys, 'Amplitude', amplitudeRef, 'FlatTime', tRef);
    gs = mr.splitGradient(g);
    G3D_RefCrusherL1       = gs(1); 
 
    area_G3D_RefSpoilLeft1 = G3D_RefCrusherL1.area;
    area_G3D_ExSpoilPre    = SignCorr.(Axis3D) * 40*1e-6*sys.gamma; % 40 mT/m·ms

    area_G3D_Crusher       = SignCorr.(Axis3D) * 4/SliceThickness;   % 8pi
    area_G3D_ExSpoilPost   = area_G3D_Crusher - amplitudeEx*tEx/2;
    area_G3D_RefSpoilLeft  = area_G3D_Crusher;
    area_G3D_RefSpoilRight = area_G3D_Crusher;

    % G3D_ExSpoilPre, G3D_ExFlat, G3D_ExSpoilPost
    [g_ExSpoilPre, t_ExSpoilPre, duExSpoilPre] = design_gradient_min_time(area_G3D_ExSpoilPre, 10e-3, 0, amplitudeEx, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    G3D_ExSpoilPre = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_ExSpoilPre, 'times', t_ExSpoilPre);

    [g_ExSpoilPost, t_ExSpoilPost] = design_gradient_waveform(area_G3D_ExSpoilPost, TE1_gap, amplitudeEx, amplitudeRef, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    G3D_ExSpoilPost = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_ExSpoilPost, 'times', t_ExSpoilPost);

    G3D_ExFlat      = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'times', [0, tEx], 'amplitudes', [amplitudeEx, amplitudeEx]);         
    RF.rfEx.delay  = G3D_ExSpoilPre.shape_dur;
 

    % G3D_RefCrusherL, G3D_RefFlat, G3D_RefCrusherR
    [g_G3D_RefCrusherL, t_G3D_RefCrusherL] = design_gradient_waveform(area_G3D_RefSpoilLeft , tSp, 0, amplitudeRef, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    G3D_RefCrusherL = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_G3D_RefCrusherL, 'times', t_G3D_RefCrusherL);

    [g_G3D_RefCrusherR, t_G3D_RefCrusherR] = design_gradient_waveform(area_G3D_RefSpoilRight, tSp, amplitudeRef, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    G3D_RefCrusherR = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_G3D_RefCrusherR, 'times', t_G3D_RefCrusherR);

    G3D_RefFlat      = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'times', [0, tRef], 'amplitudes', [amplitudeRef, amplitudeRef]);
   
    G3D_EndSpoil     = mr.makeTrapezoid(Axis3D, 'system', sys, 'duration', tSp, 'area', SignCorr.(Axis3D) * 4/SliceThickness);
  

    % Gx and its spoiler gradients
    GRO_pre     = mr.makeTrapezoid(AxisRO, 'system', sys, 'Area', ADC.Area_GROpreph, 'duration', TE1_gap);

    G3D_Ex_Ref1 = concatGrads({G3D_ExSpoilPre, G3D_ExFlat, G3D_ExSpoilPost, G3D_RefFlat, G3D_RefCrusherR}, sys); 
    G3D_Ref     = concatGrads({G3D_RefCrusherL, G3D_RefFlat, G3D_RefCrusherR}, sys); 

    [G3D_Ex, G3D_Ref1] = mr.splitGradientAt(G3D_Ex_Ref1, TE1_gap/2 + G3D_ExSpoilPre.shape_dur + tEx, 'system', sys);
    G3D_Ref1.delay = 0;
    [GRO_preL, GRO_preR] = mr.splitGradientAt(GRO_pre, TE1_gap/2, 'system', sys);

    GRO_preL.delay = G3D_ExSpoilPre.shape_dur + tEx;
    GRO_preR.delay = 0;

    GRO_SpoilPre1 = GRO_SpoilPre; GRO_SpoilPre1.delay = tRef;
    GRO_preR = concatGrads({GRO_preR, GRO_SpoilPre1}, sys);

    GRO_SpoilPre.delay = tRef;
    GRO_Spoil = concatGrads({GRO_SpoilPost, GRO_SpoilPre}, sys);

    % fill times
    tex  = mr.calcDuration(G3D_ExSpoilPre) + mr.calcDuration(G3D_ExFlat) + mr.calcDuration(G3D_ExSpoilPost);
    tETrain = tex + nEcho*TE1;


    Grad.G3D_ExSpoilPre  = G3D_ExSpoilPre;
    Grad.G3D_ExSpoilPost = G3D_ExSpoilPost;
    Grad.G3D_ExFlat      = G3D_ExFlat;

    Grad.G3D_Ex   = G3D_Ex;
    Grad.G3D_Ref1 = G3D_Ref1;
    Grad.G3D_Ref  = G3D_Ref;
    
    Grad.G3D_RefCrusherL = G3D_RefCrusherL;
    Grad.G3D_RefCrusherR = G3D_RefCrusherR;
    Grad.G3D_RefFlat     = G3D_RefFlat;

    Grad.G3D_EndSpoil    = G3D_EndSpoil;
    
    Grad.GRO_preL   = GRO_preL;
    Grad.GRO_preR   = GRO_preR;
    Grad.GRO_Spoil  = GRO_Spoil;
    Grad.tETrain = tETrain;
end