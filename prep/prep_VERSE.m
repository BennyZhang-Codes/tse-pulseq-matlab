function [rfex, GSex] = prep_VERSE(Actual, sys)
    flipex          = Actual.flipex;
    SliceThickness  = Actual.SliceThickness;
    tExwd           = Actual.tExwd;
    dG              = Actual.dG;
    
    typeEx          = Actual.ActualRF.typeEx;
    tEx             = Actual.ActualRF.tEx;
    tbpEx           = Actual.ActualRF.tbpEx;
    phaseEx         = Actual.ActualRF.phaseEx;

    switch lower(typeEx)
        case 'sinc'
            [rfex, gz_ex]   = mr.makeSincPulse(flipex, sys, 'Duration', tEx,...
                'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', tbpEx, ...
                'PhaseOffset', phaseEx, 'use', 'excitation');
            amplitude = gz_ex.amplitude;
        case 'slr'
            % TODO
    end
    GSex         = mr.makeTrapezoid('z', sys, 'amplitude', amplitude, 'FlatTime', tExwd, 'riseTime', dG);
    rfex.delay   = rfex.deadTime;

    GSex_Arb = mr.makeArbitraryGrad('z', [amplitude, amplitude], sys, 'first', amplitude, 'last', amplitude);
end