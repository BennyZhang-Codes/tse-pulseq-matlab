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
    

    GR_SpoilPre  = Grad.GR_SpoilPre;
    GR_SpoilPost = Grad.GR_SpoilPost;


    %% IR
    if strcmpi(IR, 'on')
        amplitudeInv = Grad.amplitudeInv;
        tInv         = Actual.ActualRF.tInv;
  
        [g_InvSpoilPre, t_InvSpoilPre] = design_gradient_min_time(SignCorr.(Axis3D) * 4/SliceThickness, 10e-3, 0, amplitudeInv, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
        GS_InvSpoilPre = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_InvSpoilPre, 'times', t_InvSpoilPre);    
        [g_InvSpoilPost, t_InvSpoilPost] = design_gradient_min_time(SignCorr.(Axis3D) * 4/SliceThickness, 10e-3, amplitudeInv, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
        GS_InvSpoilPost = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_InvSpoilPost, 'times', t_InvSpoilPost);
        GS_InvFlat = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'times', [0, tInv], 'amplitudes', [amplitudeInv, amplitudeInv]);
        GS_Inv = concatGrads({GS_InvSpoilPre, GS_InvFlat, GS_InvSpoilPost}, sys);

        Grad.GS_Inv = GS_Inv;
        RF.rfInv.delay  = mr.calcDuration(GS_InvSpoilPre);
    end
    %% combine into blocks
    g = mr.makeTrapezoid(Axis3D, 'system', sys, 'Amplitude', amplitudeRef, 'FlatTime', tRef);
    gs = mr.splitGradient(g);
    GS_RefCrusherL1       = gs(1); 
 
    area_GS_RefSpoilLeft1 = GS_RefCrusherL1.area;
    area_GS_ExSpoilPre    = SignCorr.(Axis3D) * 40*1e-6*sys.gamma; % 40 mT/m·ms

    area_GS_Crusher       = SignCorr.(Axis3D) * 4/SliceThickness;   % 8pi
    area_GS_ExSpoilPost   = area_GS_Crusher - amplitudeEx*tEx/2;
    area_GS_RefSpoilLeft  = area_GS_Crusher;
    area_GS_RefSpoilRight = area_GS_Crusher;

    % GS_ExSpoilPre, GS_ExFlat, GS_ExSpoilPost
    [g_ExSpoilPre, t_ExSpoilPre, duExSpoilPre] = design_gradient_min_time(area_GS_ExSpoilPre, 10e-3, 0, amplitudeEx, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GS_ExSpoilPre = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_ExSpoilPre, 'times', t_ExSpoilPre);

    [g_ExSpoilPost, t_ExSpoilPost] = design_gradient_waveform(area_GS_ExSpoilPost, TE1_gap, amplitudeEx, amplitudeRef, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GS_ExSpoilPost = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_ExSpoilPost, 'times', t_ExSpoilPost);

    GS_ExFlat      = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'times', [0, tEx], 'amplitudes', [amplitudeEx, amplitudeEx]);         
    RF.rfEx.delay  = GS_ExSpoilPre.shape_dur;
 

    % GS_RefCrusherL, GS_RefFlat, GS_RefCrusherR
    [g_GS_RefCrusherL, t_GS_RefCrusherL] = design_gradient_waveform(area_GS_RefSpoilLeft , tSp, 0, amplitudeRef, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GS_RefCrusherL = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_GS_RefCrusherL, 'times', t_GS_RefCrusherL);

    [g_GS_RefCrusherR, t_GS_RefCrusherR] = design_gradient_waveform(area_GS_RefSpoilRight, tSp, amplitudeRef, 0, sys.maxGrad, sys.maxSlew, sys.gradRasterTime);
    GS_RefCrusherR = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'amplitudes', g_GS_RefCrusherR, 'times', t_GS_RefCrusherR);

    GS_RefFlat      = mr.makeExtendedTrapezoid(Axis3D, 'system', sys, 'times', [0, tRef], 'amplitudes', [amplitudeRef, amplitudeRef]);
   
    GS_EndSpoil     = mr.makeTrapezoid(Axis3D, 'system', sys, 'duration', tSp, 'area', SignCorr.(Axis3D) * 4/SliceThickness);
  

    % Gx and its spoiler gradients
    GRpre    = mr.makeTrapezoid(AxisRO, 'system', sys, 'Area', ADC.AGRpreph, 'duration', TE1_gap);

    GS_Ex_Ref1 = concatGrads({GS_ExSpoilPre, GS_ExFlat, GS_ExSpoilPost, GS_RefFlat, GS_RefCrusherR}, sys); 
    GS_Ref     = concatGrads({GS_RefCrusherL, GS_RefFlat, GS_RefCrusherR}, sys); 

    [GS_Ex, GS_Ref1] = mr.splitGradientAt(GS_Ex_Ref1, TE1_gap/2 + GS_ExSpoilPre.shape_dur + tEx, 'system', sys);
    GS_Ref1.delay = 0;
    [GRpreL, GRpreR] = mr.splitGradientAt(GRpre, TE1_gap/2, 'system', sys);

    GRpreL.delay = GS_ExSpoilPre.shape_dur + tEx;
    GRpreR.delay = 0;

    GR_SpoilPre1 = GR_SpoilPre; GR_SpoilPre1.delay = tRef;
    GRpreR = concatGrads({GRpreR, GR_SpoilPre1}, sys);

    GR_SpoilPre.delay = tRef;
    GR_Spoil = concatGrads({GR_SpoilPost, GR_SpoilPre}, sys);

    % fill times
    tex  = mr.calcDuration(GS_ExSpoilPre) + mr.calcDuration(GS_ExFlat) + mr.calcDuration(GS_ExSpoilPost);
    tETrain = tex + nEcho*TE1;


    Grad.GS_ExSpoilPre  = GS_ExSpoilPre;
    Grad.GS_ExSpoilPost = GS_ExSpoilPost;
    Grad.GS_ExFlat = GS_ExFlat;

    Grad.GS_Ex   = GS_Ex;
    Grad.GS_Ref1 = GS_Ref1;
    Grad.GS_Ref = GS_Ref;
    
    Grad.GS_RefCrusherL = GS_RefCrusherL;
    Grad.GS_RefCrusherR = GS_RefCrusherR;
    Grad.GS_RefFlat     = GS_RefFlat;

    Grad.GS_EndSpoil    = GS_EndSpoil;
    
    Grad.GRpreL   = GRpreL;
    Grad.GRpreR   = GRpreR;
    Grad.GR_Spoil = GR_Spoil;
    Grad.tETrain = tETrain;
end
