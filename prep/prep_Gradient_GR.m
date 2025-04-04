function [...
    GRacq, adc, GRspr, GRspex, GRpreph ...
    ] = prep_Gradient_GR(fovRead, nX, readoutOS, readoutTime, roDuration, fspR, tSp, tSpex, dG, system)
    % Readout gradient
    deltakX   = 1 / fovRead;
    GRacq    = mr.makeTrapezoid('x', system, 'FlatArea', nX * deltakX, 'FlatTime', readoutTime, 'riseTime', dG);
    adc      = mr.makeAdc(nX*readoutOS, 'Duration', roDuration, 'Delay', system.adcDeadTime, 'system', system);%,'Delay',GRacq.riseTime);
    GRspr    = mr.makeTrapezoid('x', system, 'area', GRacq.area*fspR    , 'duration', tSp  , 'riseTime', dG);
    GRspex   = mr.makeTrapezoid('x', system, 'area', GRacq.area*(1+fspR), 'duration', tSpex, 'riseTime', dG);
    
    AGRspr   = GRspr.area;
    AGRpreph = GRacq.area/2+AGRspr;
    GRpreph  = mr.makeTrapezoid('x', system, 'Area', AGRpreph, 'duration', tSpex, 'riseTime', dG);
end
