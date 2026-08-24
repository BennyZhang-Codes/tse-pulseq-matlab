classdef TestPulseqSmoke < matlab.unittest.TestCase
    methods (Test)
        function pulseqSequencePassesBlockTiming(testCase)
            sys = mr.opts( ...
                'MaxGrad', 40, 'GradUnit', 'mT/m', ...
                'MaxSlew', 150, 'SlewUnit', 'T/m/s', ...
                'rfRingdownTime', 100e-6, ...
                'rfDeadTime', 100e-6, ...
                'adcDeadTime', 10e-6, ...
                'gradRasterTime', 10e-6);
            seq = mr.Sequence(sys);

            rf = mr.makeBlockPulse(pi / 2, 'Duration', 1e-3, ...
                'system', sys, 'use', 'excitation');
            gx = mr.makeTrapezoid('x', 'FlatArea', 40, 'FlatTime', 1e-3, ...
                'system', sys);
            adc = mr.makeAdc(100, 'Duration', 1e-3, 'system', sys);

            seq.addBlock(rf);
            seq.addBlock(gx, adc);

            [ok, report] = seq.checkTiming;
            testCase.verifyTrue(ok, strjoin(report, newline));
        end

        function systemPreparationDoesNotRequireAscAtBuildTime(testCase)
            actual = struct('ScannerType', 'Terra-XJ');
            [sys, sysSoft, seq, actual] = prep_System(actual);

            testCase.verifyClass(seq, 'mr.Sequence');
            testCase.verifyGreaterThan(sys.maxGrad, sysSoft.maxGrad);
            testCase.verifyEqual(actual.asc_file, ...
                'MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc');
        end
    end
end
