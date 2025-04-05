function [rfex, GSex] = prep_Excitation(params, sys)
    flipex          = params.flipex;
    SliceThickness  = params.SliceThickness;
    tExwd           = params.tExwd;
    dG              = params.dG;
    
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
end
