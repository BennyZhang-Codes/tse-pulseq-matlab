classdef TestPEOrdering < matlab.unittest.TestCase
    methods (Test)
        function acceleratedPiUsesSiemensZeroBasedCenterConvention(testCase)
            nPE = 300;
            nEcho = 10;
            refLinesRatio = 30 / nPE;
            expectedFull = -150:149;
            expectedCenterLin = nPE / 2;

            for R = 2:5
                [nExcit, peSteps, peStepMin, peFull, peImg, peRef, peImgAndRef] = ...
                    prep_PE3DOrder_PI(nPE, nEcho, R, refLinesRatio);

                imageLin = peImg - peStepMin;
                acs = sort([peRef, peImgAndRef]);

                testCase.verifyEqual(peFull, expectedFull);
                testCase.verifyEqual(peStepMin, -150);
                testCase.verifyTrue(ismember(0, peImg));
                testCase.verifyEqual(expectedCenterLin, 150);
                testCase.verifyTrue(all(mod(imageLin - expectedCenterLin, R) == 0));
                testCase.verifyEqual(numel(peSteps), numel(unique(peSteps)));
                testCase.verifyEqual(peSteps, sort([peImg, peRef]));
                testCase.verifyEqual(nExcit * nEcho, numel(peImg) + numel(peRef));
                testCase.verifyGreaterThan(numel(acs), 0);
                testCase.verifyEqual(acs, min(acs):max(acs));
                testCase.verifyTrue(all(ismember(peImgAndRef, peImg)));
                testCase.verifyTrue(all(ismember(peRef, peFull)));
            end
        end

        function finalPiLabelsRemainInSiemensLinRange(testCase)
            for R = 2:5
                actual = TestPEOrdering.makeActual('PI', R);
                [pe3d, actual] = prep_PE3DOrder(actual);

                testCase.verifyEqual(pe3d.kSpaceCenterLine, floor(actual.nPE/2));
                testCase.verifyEqual(pe3d.PE3DLabel, pe3d.PE3DOrder + floor(actual.nPE/2));
                testCase.verifyGreaterThanOrEqual(min(pe3d.PE3DLabel(:)), 0);
                testCase.verifyLessThan(max(pe3d.PE3DLabel(:)), actual.nPE);
                testCase.verifyEqual(numel(unique(pe3d.PE3DLabel)), numel(pe3d.PE3DLabel));
                testCase.verifyEqual(actual.nAcq, numel(pe3d.PE3DOrder));
            end
        end

        function fullySampledOrderPreservesExistingLinMapping(testCase)
            actual = TestPEOrdering.makeActual('PI', 1);
            [pe3d, actual] = prep_PE3DOrder(actual);

            testCase.verifyEqual(pe3d.pe_full, -60:59);
            testCase.verifyEqual(sort(pe3d.PE3DLabel(:)).', 0:119);
            testCase.verifyEqual(pe3d.kSpaceCenterLine, 60);
            testCase.verifyEqual(actual.nAcq, 120);
        end
    end

    methods (Static, Access = private)
        function actual = makeActual(accelerationMode, R)
            actual = struct( ...
                'AxisPE', 'y', ...
                'SignCorr', struct('y', -1), ...
                'AccelerationMode', accelerationMode, ...
                'PEMode', 'CentricFull', ...
                'nPE', 120, ...
                'nEcho', 10, ...
                'TEeff', 10e-3, ...
                'TE1', 10e-3, ...
                'fovPE', 120e-3, ...
                'R', R, ...
                'RefLinesRatio', 30/120, ...
                'p', 20, ...
                'r', 0.1, ...
                'SeqDimension', '2D');
        end
    end
end