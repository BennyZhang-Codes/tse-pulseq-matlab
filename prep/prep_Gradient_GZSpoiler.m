function [...
    GSspr, GSspex ...
    ] = prep_Gradient_GZSpoiler(Grad, params, sys)

    fspS   = params.fspS;
    tSp    = params.tSp;
    tSpex  = params.tSpex;
    dG     = params.dG;
    GSex   = Grad.GSex;


    AGSex  = GSex.area/2;
    GSspr  = mr.makeTrapezoid('z', sys, 'area', AGSex*(1+fspS), 'duration', tSp  , 'riseTime', dG);
    GSspex = mr.makeTrapezoid('z', sys, 'area', AGSex*fspS    , 'duration', tSpex, 'riseTime', dG);
end
