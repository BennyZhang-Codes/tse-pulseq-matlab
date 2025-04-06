function [RF, Grad] = prep_Excitation(RF, Grad, params, sys)
    flipex          = params.flipex;
    SliceThickness  = params.SliceThickness;
    tExwd           = params.tExwd;
    dG              = params.dG;

    VERSE           = params.VERSE;
    
    typeEx          = params.paramsRF.typeEx;
    tEx             = params.paramsRF.tEx;
    tbpEx           = params.paramsRF.tbpEx;
    phaseEx         = params.paramsRF.phaseEx;

    switch lower(typeEx)
        case 'sinc'
            [rfex, gz_ex]   = mr.makeSincPulse(flipex, sys, 'Duration', tEx,...
                'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', tbpEx, ...
                'PhaseOffset', phaseEx, 'use', 'excitation');
            amplitude = gz_ex.amplitude;
        case 'slr'
            % TODO
        case 'gslider'
            load 'gSlider_excit_0.01_0.01.mat' tbs pulses;
            rf = squeeze(pulses(tbs == tbpEx, 1, :));
            assert(ismember(tbpEx, tbs), sprintf('no gSlider pulse with a TBP of %.1f', tbpEx))

            % interpolate to fit gradRasterTime 
            nPoint_target  = round(tEx/sys.gradRasterTime);
            nPoint_origin  = length(rf);
            dt_target      = sys.gradRasterTime;
            dt_origin      = dt_target *  (nPoint_target / nPoint_origin);
            t_target       = linspace(0.5, nPoint_target-0.5, nPoint_target) * dt_target;
            t_origin       = linspace(0.5, nPoint_origin-0.5, nPoint_origin) * dt_origin;
            rf             = (nPoint_origin / nPoint_target) .* interp1(t_origin, rf, t_target);

            [rfex] = mr.makeArbitraryRf(rf, flipex, 'system', sys, ...
                'timeBwProduct', tbpEx, 'SliceThickness', SliceThickness, ...
                'center', tEx/2, 'dwell', dt_target, 'use', 'excitation', ...
                'PhaseOffset', phaseEx);
            BW = tbpEx / tEx;
            amplitude = BW / SliceThickness;
    end
    
    GSex         = mr.makeTrapezoid('z', sys, 'amplitude', amplitude, 'FlatTime', tExwd, 'riseTime', dG);
    rfex.delay   = rfex.deadTime;

    if strcmpi(VERSE, 'on')
        [rf_verse, t_rf, g_verse, t_g] = prep_minSAR_VERSE(rfex, tbpEx, SliceThickness, 15, 25, 100, sys);
        rf_verse = rf_verse * 1e-3 * sys.gamma; % [Hz]
        rfex.signal = rf_verse;
        rfex.t      = t_rf;
            
        g_verse  = g_verse(:, 3) *1e-3 * sys.gamma;   % [Hz]

        g_start = ones(sys.rfRingdownTime / sys.gradRasterTime, 1) * amplitude;
        g_end   = ones(sys.rfDeadTime     / sys.gradRasterTime, 1) * amplitude;

        g_verse = [g_start; g_verse; g_end];
        
        GSex = mr.makeArbitraryGrad('z', g_verse, sys, 'first', amplitude, 'last', amplitude);
        figure;plot(abs(g_verse(2:end)-g_verse(1:end-1))./sys.gradRasterTime/sys.gamma)
    end

    Grad.amplitudeEx = amplitude;
    RF.rfex          = rfex;
    Grad.GSex        = GSex;
end
