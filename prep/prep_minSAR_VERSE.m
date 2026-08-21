function [rf_verse_interp, t_rf_interp, ...
    g_verse_interp, t_g_interp] = prep_minSAR_VERSE(rf_pulseq, TBP, SliceThickness, B1max, Gmax, SRmax, sys)
% prep_minSAR_VERSE(RF.rfex, ActualRF.tbpEx, params, sys)
    gamma           = sys.gamma;
    rfRasterTime    = sys.rfRasterTime;        %<--- Raster Time for RF pulse [s]
    gradRasterTime  = sys.gradRasterTime;      %<--- Raster Time for gradient [s]  
    B1max           = B1max*1e-3;              %<--- Peak B1 amplitude [mT], 20*1e-3
    Gmax            = Gmax*1;                  %<--- Maximum gradient amplitude [mT/m], 30
    SRmax           = SRmax*1e3;               %<--- Maximum gradient amplitude [mT/m/s], 150*1e3

    signal          = rf_pulseq.signal;        %<--- RF waveform [Hz]
    rfDuration      = rf_pulseq.shape_dur;     %<--- Duration of RF pulse [s]
    nPoint          = length(signal);          %<--- number of RF points
    dt              = rfDuration / nPoint;     %<--- RF dwell time
    rf              = signal*dt*2*pi;          %<--- [Hz] to [rad]
    tb              = TBP;                     %<--- time bandwidth product
    rf_type         = rf_pulseq.use;           % 'excitation' 'inversion' 'refocusing'
    gamma_mT        = 2*pi*gamma*1e-3;         %<--- Gyromagnetric ratio [rad/mT/s]
    % SliceThickness  = SliceThickness;          %<--- SliceThickness [m]
    % nPoint_const          = 512;               

    eps             = rfRasterTime;
    nRF             = round(rfDuration /   rfRasterTime);
    nGrad           = round(rfDuration / gradRasterTime);
    assert(abs(mod(  nRF, 1)) < eps, 'Error: rfDuration must be an integer multiple of rfRasterTime.');
    assert(abs(mod(nGrad, 1)) < eps, 'Error: rfDuration must be an integer multiple of gradRasterTime.');
    t_rf  = linspace(0.5, nPoint-0.5, nPoint) * dt;
    t_g   = linspace(0.5, nGrad-0.5, nGrad) * gradRasterTime;
    
    % less points for faster calculation
    nPoint_const    = nGrad;                %<--- Number of time-points
    %% Design Singleband pulse

    dt_const = rfDuration / nPoint_const;
    t_const  = linspace(0.5, nPoint_const-0.5, nPoint_const) * dt_const;
    rf_const = (nPoint / nPoint_const) .* interp1(t_rf, rf, t_const)';
    
    
    rf_const = rf_const ./(gamma_mT*dt_const);      % convert to mT
    
    BW       = tb/(rfDuration);
    Gsel     = 2*pi*BW/(gamma_mT*SliceThickness);   % convert to mT                              
    Gz       = Gsel*ones(nPoint_const,1);
    g_const  = [0*Gz 0*Gz Gz];  
    
    figure; scatter(t_rf*1e3, abs(rf./(gamma_mT*dt))*1e4);
    hold on; scatter(t_const*1e3, abs(rf_const)*1e4);
    xlabel('Time [ms]'); ylabel('|B1| [mG]')
    
    %% Design VERSE pulse
    fprintf('Designing minSAR VERSE pulse...\n')
    
    dt_os   = 1;
    
    [rf_verse, g_verse] = minSAR_gz_verse(rf_const, Gz, dt_const, Gmax, SRmax, B1max, dt_os, eps, Gsel, gamma);
    nPoint_verse = length(rf_verse);
    dt_verse     = dt_const / dt_os;
    t_verse      = linspace(0.5, nPoint_verse-0.5, nPoint_verse) * dt_verse;
    
    %% re-interpolated to origin dwell time
    t_rf_interp     = t_rf;
    rf_verse_interp = interp1(t_verse, rf_verse, t_rf_interp, 'spline', 'extrap');  % mT
    
    t_g_interp      = t_g;
    g_verse_interp  = interp1(t_verse,  g_verse,  t_g_interp, 'spline', 'extrap');  % mT/m
    
    %% Run Bloch simulations.
    % fprintf('\nRunning Bloch simulations...\n')
    spos = (1:1)-(1+1)/2; 
    
    Nz  = 4096;
    FOV = 3*(floor(1/2)+1)*SliceThickness;
    z   = linspace(-FOV/2,FOV/2,Nz)';
    
    pos = [z(:)*0 z(:)*0 z(:)];
    
    m_fa =@(a,b)180/pi*acos(a.*conj(a)-b.*conj(b));
    
    switch rf_type
        case 'excitation'
            M0 = [0; 0; 1];
        case 'refocusing'
            M0 = [1; 0; 0];
        case 'inversion'
            M0 = [0; 0; 1];
    end
    
    % Simulate Constant gradient pulse
    % fprintf('Running for constant gradient pulses...\n')
    [Mxy_const, Mz_const, ~, ~, a, b] = blochsim_CK(rf_const, g_const, pos, ...
        ones([Nz 1]), zeros([Nz 1]),'M0', M0,'dt',dt_const);
    fa_const = m_fa(a(:,end),b(:,end));
    
    % fprintf('Running for VERSE pulses...\n')
    [Mxy_verse, Mz_verse, ~, ~, ~, ~] = blochsim_CK(rf_verse, g_verse, pos, ...
        ones([Nz 1]), zeros([Nz 1]),'M0', M0, 'dt', dt_verse);
    fa_verse = m_fa(a(:,end),b(:,end));
    
    if strcmp(rf_type, 'excitation')
        rephase = (Gsel * z * gamma_mT * rfDuration / 2);
        Mxy_const = Mxy_const .* exp(1j * rephase);
        Mxy_verse = Mxy_verse .* exp(1j * rephase);
    end
    
    %% Calculate SAR
    sar_const = calculate_SAR(rf_const*1e-3, rfDuration, nPoint_const);
    sar_verse = calculate_SAR(rf_verse*1e-3, rfDuration, nPoint_verse);
    
    %% Plot RF, gradient waveforms and slice-profiles
    fig = plot_rf_gradient_profiles(z, SliceThickness, t_const, rf_const, sar_const, g_const, Mxy_const, Mz_const, ...
               t_rf_interp, rf_verse_interp, sar_verse, t_g_interp, g_verse_interp, Mxy_verse, Mz_verse);

    disp(sum(Gz)*dt_const*gamma*1e-3);
    disp(sum(g_verse_interp(:,3))*dt*gamma*1e-3);
end
