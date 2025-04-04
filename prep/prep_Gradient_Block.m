function [Grad] = prep_Gradient_Block(Grad, params)
    GSex         = Grad.GSex;
    GSspex       = Grad.GSspex;
    GSref        = Grad.GSref;
    GSspr        = Grad.GSspr;
    GRpreph      = Grad.GRpreph;
    GRacq        = Grad.GRacq;
    GRspr        = Grad.GRspr;

    readoutTime  = params.readoutTime;
    nEcho        = params.nEcho;


    %% split gradients and recombine into blocks
    % Gz for excitation
    GS1times = [0 GSex.riseTime];
    GS1amp   = [0 GSex.amplitude];
    GS1      = mr.makeExtendedTrapezoid('z', 'times', GS1times, 'amplitudes', GS1amp);
    
    GS2times = [0              GSex.flatTime];
    GS2amp   = [GSex.amplitude GSex.amplitude];
    GS2      = mr.makeExtendedTrapezoid('z', 'times', GS2times, 'amplitudes', GS2amp);
    
    % Gz spoiling for excitation
    GS3times = [0              GSspex.riseTime  GSspex.riseTime+GSspex.flatTime GSspex.riseTime+GSspex.flatTime+GSspex.fallTime];
    GS3amp   = [GSex.amplitude GSspex.amplitude GSspex.amplitude                GSref.amplitude];
    GS3      = mr.makeExtendedTrapezoid('z', 'times', GS3times, 'amplitudes', GS3amp);
    
    % Gz for refocusing
    GS4times = [0               GSref.flatTime];
    GS4amp   = [GSref.amplitude GSref.amplitude];
    GS4      = mr.makeExtendedTrapezoid('z', 'times', GS4times, 'amplitudes', GS4amp);
    
    % Gz right spoiler
    GS5times = [0               GSspr.riseTime  GSspr.riseTime+GSspr.flatTime GSspr.riseTime+GSspr.flatTime+GSspr.fallTime];
    GS5amp   = [GSref.amplitude GSspr.amplitude GSspr.amplitude               0];
    GS5      = mr.makeExtendedTrapezoid('z', 'times', GS5times, 'amplitudes', GS5amp);
    
    % Gz left spoiler
    GS7times = [0 GSspr.riseTime  GSspr.riseTime+GSspr.flatTime GSspr.riseTime+GSspr.flatTime+GSspr.fallTime];
    GS7amp   = [0 GSspr.amplitude GSspr.amplitude               GSref.amplitude];
    GS7      = mr.makeExtendedTrapezoid('z','times', GS7times, 'amplitudes', GS7amp);
    
    % Gx and its spoiler gradients
    GR3      = GRpreph;
    
    GR5times = [0 GRspr.riseTime  GRspr.riseTime+GRspr.flatTime GRspr.riseTime+GRspr.flatTime+GRspr.fallTime];
    GR5amp   = [0 GRspr.amplitude GRspr.amplitude               GRacq.amplitude];
    GR5      = mr.makeExtendedTrapezoid('x', 'times', GR5times, 'amplitudes', GR5amp);
    
    GR6times = [0               readoutTime];
    GR6amp   = [GRacq.amplitude GRacq.amplitude];
    GR6      = mr.makeExtendedTrapezoid('x', 'times', GR6times, 'amplitudes', GR6amp);
    
    GR7times = [0               GRspr.riseTime  GRspr.riseTime+GRspr.flatTime GRspr.riseTime+GRspr.flatTime+GRspr.fallTime];
    GR7amp   = [GRacq.amplitude GRspr.amplitude GRspr.amplitude               0];
    GR7      = mr.makeExtendedTrapezoid('x', 'times', GR7times, 'amplitudes', GR7amp);

    % fill times
    tex  = mr.calcDuration(GS1) + mr.calcDuration(GS2) + mr.calcDuration(GS3);
    tref = mr.calcDuration(GS4) + mr.calcDuration(GS5) + mr.calcDuration(GS7) + readoutTime;
    tend = mr.calcDuration(GS4) + mr.calcDuration(GS5);
    tETrain = tex + nEcho*tref + tend;



    Grad.GS1     = GS1;
    Grad.GS2     = GS2;
    Grad.GS3     = GS3;
    Grad.GS4     = GS4;
    Grad.GS5     = GS5;
    Grad.GS7     = GS7;
    Grad.GR3     = GR3;
    Grad.GR5     = GR5;
    Grad.GR6     = GR6;
    Grad.GR7     = GR7;
    Grad.tETrain = tETrain;
end
