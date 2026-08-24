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
    end
end
