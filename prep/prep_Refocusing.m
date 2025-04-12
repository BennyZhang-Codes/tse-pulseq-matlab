function [RF, Grad] = prep_Refocusing(RF, Grad, params, sys)
    flipref          = params.flipref;
    SliceThickness   = params.SliceThickness;
    tRefwd           = params.tRefwd;
    dG               = params.dG;

    VERSE            = params.VERSE;

    typeRef          = params.paramsRF.typeRef;
    tRef             = params.paramsRF.tRef;
    tbpRef           = params.paramsRF.tbpRef;
    phaseRef         = params.paramsRF.phaseRef;

    switch lower(typeRef)
        case 'sinc'
            [rfref, gz_ref] = mr.makeSincPulse(flipref, sys, 'Duration', tRef,... 
                'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', tbpRef, ...
                'PhaseOffset', phaseRef, 'use', 'refocusing');
            amplitude = gz_ref.amplitude;
        case 'slr'
            load 'SLR_refoc_ls_0.01_0.01.mat' tbs pulses;
            rf = squeeze(pulses(tbs == tbpRef, :));
            assert(ismember(tbpRef, tbs), sprintf('no SLR pulse with a TBP of %.1f', tbpRef))

            % interpolate to fit gradRasterTime 
            nPoint_target  = round(tRef/sys.gradRasterTime);
            nPoint_origin  = length(rf);
            dt_target      = sys.gradRasterTime;
            dt_origin      = dt_target *  (nPoint_target / nPoint_origin);
            t_target       = linspace(0.5, nPoint_target-0.5, nPoint_target) * dt_target;
            t_origin       = linspace(0.5, nPoint_origin-0.5, nPoint_origin) * dt_origin;
            rf             = (nPoint_origin / nPoint_target) .* interp1(t_origin, rf, t_target);

            [rfref] = mr.makeArbitraryRf(rf, flipref, 'system', sys, ...
                'timeBwProduct', tbpRef, 'SliceThickness', SliceThickness, ...
                'center', tRef/2, 'dwell', dt_target, 'use', 'refocusing', ...
                'PhaseOffset', phaseRef);
            BW = tbpRef / tRef;
            amplitude = BW / SliceThickness;
    end
            
    GSref        = mr.makeTrapezoid('z', sys, 'amplitude', amplitude, 'FlatTime', tRefwd, 'riseTime', dG);
    rfref.delay  = rfref.deadTime;


    if strcmpi(VERSE, 'on')
        [rf_verse, t_rf, g_verse, t_g] = prep_minSAR_VERSE(rfref, tbpRef, SliceThickness, 15, 25, 100, sys);
        rf_verse = rf_verse * 1e-3 * sys.gamma; % [Hz]
        rfref.signal = rf_verse;
        rfref.t      = t_rf;
            
        g_verse  = g_verse(:, 3) *1e-3 * sys.gamma;   % [Hz]

        g_start = ones(sys.rfRingdownTime / sys.gradRasterTime, 1) * amplitude;
        g_end   = ones(sys.rfDeadTime     / sys.gradRasterTime, 1) * amplitude;

        g_verse = [g_start; g_verse; g_end];
        
        GSref = mr.makeArbitraryGrad('z', g_verse, sys, 'first', amplitude, 'last', amplitude);
        figure;plot(abs(g_verse(2:end)-g_verse(1:end-1))./sys.gradRasterTime/sys.gamma)
    end

    Grad.amplitudeRef = amplitude;
    RF.rfRef          = rfref;
    Grad.GSref        = GSref;
end
