classdef TestGradientDesign < matlab.unittest.TestCase
    methods (Test)
        function fixedDurationMeetsRasterAndHardwareConstraints(testCase)
            dt = 1e-4;
            targetArea = 6e-3;
            duration = 10e-3;
            g0 = 0.15;
            g1 = -0.10;
            gmax = 1.0;
            smax = 1e3;

            [g, t] = design_gradient_waveform( ...
                targetArea, duration, g0, g1, gmax, smax, dt);

            testCase.verifyEqual(t(1), 0, 'AbsTol', eps);
            testCase.verifyEqual(t(end), duration, 'AbsTol', 64 * eps(duration));
            testCase.verifyEqual(g(1), g0, 'AbsTol', eps);
            testCase.verifyEqual(g(end), g1, 'AbsTol', eps);
            testCase.verifyEqual(trapz(t, g), targetArea, 'AbsTol', 1e-12);
            testCase.verifyLessThanOrEqual(max(abs(g)), gmax + 1e-12);
            testCase.verifyLessThanOrEqual(max(abs(diff(g) ./ diff(t))), smax + 1e-9);
            testCase.verifyEqual(t ./ dt, round(t ./ dt), 'AbsTol', 1e-12);
        end

        function minimumTimeMeetsConstraints(testCase)
            dt = 1e-4;
            targetArea = 4e-3;
            tMax = 20e-3;
            g0 = 0;
            g1 = 0;
            gmax = 1.0;
            smax = 1e3;

            [g, t, duration] = design_gradient_min_time( ...
                targetArea, tMax, g0, g1, gmax, smax, dt);

            testCase.verifyLessThanOrEqual(duration, tMax);
            testCase.verifyEqual(t(end), duration, 'AbsTol', 64 * eps(duration));
            testCase.verifyEqual(trapz(t, g), targetArea, 'AbsTol', 1e-12);
            testCase.verifyLessThanOrEqual(max(abs(g)), gmax + 1e-12);
            testCase.verifyLessThanOrEqual(max(abs(diff(g) ./ diff(t))), smax + 1e-9);
            testCase.verifyEqual(duration / dt, round(duration / dt), 'AbsTol', 1e-12);
        end

        function infeasibleAreaRaisesDocumentedError(testCase)
            testCase.verifyError(@() design_gradient_waveform( ...
                2, 10e-3, 0, 0, 1, 1e3, 1e-4), ...
                'design_gradient_waveform:infeasible');
        end
    end
end
