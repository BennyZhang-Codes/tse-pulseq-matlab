function [RF, Grad] = prep_Inversion(RF, Grad, Actual, sys)
    % mapping of RO/PE/3D to X/Y/Z
    Axis3D   = Actual.Axis3D   ; 
    SignCorr = Actual.SignCorr ; 

    flipinv         = Actual.flipinv;
    SliceThickness  = Actual.SliceThickness;

    VERSE           = Actual.VERSE;
  
    typeInv          = Actual.ActualRF.typeInv;
    tInv             = Actual.ActualRF.tInv;
    tbpInv           = Actual.ActualRF.tbpInv;
    phaseInv         = Actual.ActualRF.phaseInv;

    switch lower(typeInv)
        case 'sinc'
            [rfInv, gz_inv]   = mr.makeSincPulse(flipinv, sys, 'Duration', tInv,...
                'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', tbpInv, ...
                'PhaseOffset',  phaseInv, 'use', 'inversion');
            amplitude = gz_inv.amplitude;
        case 'slr'
            load 'SLR_inver_ls_0.01_0.01.mat' tbs pulses;
            rf = squeeze(pulses(tbs == tbpInv, :));
            assert(ismember(tbpInv, tbs), sprintf('no SLR pulse with a TBP of %.1f', tbpInv))

            % interpolate to fit gradRasterTime 
            nPoint_target  = round(tInv/sys.gradRasterTime);
            nPoint_origin  = length(rf);
            dt_target      = sys.gradRasterTime;
            dt_origin      = dt_target *  (nPoint_target / nPoint_origin);
            t_target       = linspace(0.5, nPoint_target-0.5, nPoint_target) * dt_target;
            t_origin       = linspace(0.5, nPoint_origin-0.5, nPoint_origin) * dt_origin;
            rf             = (nPoint_origin / nPoint_target) .* interp1(t_origin, rf, t_target);

            [rfInv] = mr.makeArbitraryRf(rf, flipinv, 'system', sys, ...
                'timeBwProduct', tbpInv, 'SliceThickness', SliceThickness, ...
                'center', tInv/2, 'dwell', dt_target, 'use', 'inversion', ...
                'PhaseOffset', phaseInv);
            BW = tbpInv / tInv;
            amplitude = BW / SliceThickness;
    end

    rfInv.delay   = rfInv.deadTime;


    if strcmpi(VERSE, 'on')
        [rf_verse, t_rf, g_verse, t_g] = prep_minSAR_VERSE(rfInv, tbpInv, SliceThickness, 15, 25, 100, sys);
        rf_verse = rf_verse * 1e-3 * sys.gamma; % [Hz]
        rfInv.signal = rf_verse;
        rfInv.t      = t_rf;
            
        g_verse  = g_verse(:, 3) *1e-3 * sys.gamma;   % [Hz]

        g_start = ones(sys.rfRingdownTime / sys.gradRasterTime, 1) * amplitude;
        g_end   = ones(sys.rfDeadTime     / sys.gradRasterTime, 1) * amplitude;

        g_verse = [g_start; g_verse; g_end];
        
        GSinv = mr.makeArbitraryGrad('z', g_verse, sys, 'first', amplitude, 'last', amplitude);
        figure;plot(abs(g_verse(2:end)-g_verse(1:end-1))./sys.gradRasterTime/sys.gamma)
    end

    Grad.amplitudeInv  = SignCorr.(Axis3D) * amplitude;
    RF.rfInv           = rfInv;
end
