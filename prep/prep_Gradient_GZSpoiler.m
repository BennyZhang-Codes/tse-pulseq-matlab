function [...
    GSspr, GSspex ...
    ] = prep_Gradient_GZSpoiler(fspS, GSex, tSp, tSpex, dG, system)

    AGSex  = GSex.area/2;
    GSspr  = mr.makeTrapezoid('z', system, 'area', AGSex*(1+fspS), 'duration', tSp  , 'riseTime', dG);
    GSspex = mr.makeTrapezoid('z', system, 'area', AGSex*fspS    , 'duration', tSpex, 'riseTime', dG);
end
