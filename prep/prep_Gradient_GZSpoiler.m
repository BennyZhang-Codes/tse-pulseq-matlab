function [Grad] = prep_Gradient_GZSpoiler(Grad, Actual, sys)
    % mapping of RO/PE/3D to X/Y/Z
    Axis3D   = Actual.Axis3D   ; 
    SignCorr = Actual.SignCorr ; 

    fspS   = Actual.fspS;
    tSp    = Actual.tSp;
    tSpex  = Actual.tSpex;
    dG     = Actual.dG;
    GSex   = Grad.GSex;


    AGSex  = GSex.area/2;
    GSspr  = mr.makeTrapezoid(Axis3D, sys, 'area', SignCorr.(Axis3D) * AGSex*(1+fspS), 'duration', tSp  , 'riseTime', dG);
    GSspex = mr.makeTrapezoid(Axis3D, sys, 'area', SignCorr.(Axis3D) * AGSex*fspS    , 'duration', tSpex, 'riseTime', dG);
    Grad.GSspr  = GSspr;
    Grad.GSspex = GSspex;
end
