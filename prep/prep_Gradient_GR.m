function [ADC, Grad] = prep_Gradient_GR(Grad, params, sys)
    fovRead      = params.fovRead;
    nX           = params.nX;
    readoutOS    = params.readoutOS;
    readoutTime  = params.readoutTime;
    roDuration   = params.roDuration;
    fspR         = params.fspR;
    tSp          = params.tSp;
    tSpex        = params.tSpex;
    dG           = params.dG;

    % Readout gradient
    deltakX   = 1 / fovRead;
    GRacq    = mr.makeTrapezoid('x', sys, 'FlatArea', nX * deltakX, 'FlatTime', readoutTime, 'riseTime', dG);
    adc      = mr.makeAdc(nX*readoutOS, 'Duration', roDuration, 'Delay', sys.adcDeadTime, 'system', sys);%,'Delay',GRacq.riseTime);
    GRspr    = mr.makeTrapezoid('x', sys, 'area', GRacq.area*fspR    , 'duration', tSp  , 'riseTime', dG);
    GRspex   = mr.makeTrapezoid('x', sys, 'area', GRacq.area*(1+fspR), 'duration', tSpex, 'riseTime', dG);
    
    AGRspr   = GRspr.area;
    AGRpreph = GRacq.area/2+AGRspr;
    GRpreph  = mr.makeTrapezoid('x', sys, 'Area', AGRpreph, 'duration', tSpex, 'riseTime', dG);

    ADC.adc      = adc;
    Grad.GRacq   = GRacq;
    Grad.GRspr   = GRspr;
    Grad.GRspex  = GRspex;
    Grad.GRpreph = GRpreph;
end
