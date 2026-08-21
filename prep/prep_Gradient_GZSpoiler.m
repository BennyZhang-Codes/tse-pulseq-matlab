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
    G3D_Spoilr  = mr.makeTrapezoid(Axis3D, sys, 'area', SignCorr.(Axis3D) * AGSex*(1+fspS), 'duration', tSp  , 'riseTime', dG);
    G3D_Spoilex = mr.makeTrapezoid(Axis3D, sys, 'area', SignCorr.(Axis3D) * AGSex*fspS    , 'duration', tSpex, 'riseTime', dG);
    Grad.G3D_Spoilr  = G3D_Spoilr;
    Grad.G3D_Spoilex = G3D_Spoilex;
end
