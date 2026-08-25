classdef TestReconstructionCore < matlab.unittest.TestCase
    methods (Test)
        function whiteningProducesUnitRegularizedCovariance(testCase)
            rng(17);
            covariance = [1.0, 0.35-0.12i; 0.35+0.12i, 2.0];
            transform = chol(covariance, 'lower');
            samples = (randn(8000,2) + 1i*randn(8000,2)) / sqrt(2) * transform.';
            noiseData = permute(reshape(samples, 100, 80, 2), [1 3 2]);

            [W, info] = estimate_noise_whitener(noiseData, 2, ...
                'Shrinkage', 0, 'EigenvalueFloor', 1e-12);

            testCase.verifyTrue(info.applied);
            testCase.verifyEqual(info.nSamples, 8000);
            testCase.verifyEqual(double(W') * info.covarianceRegularized * double(W), eye(2), ...
                'AbsTol', 2e-5);
        end

        function coilMatrixIsAppliedToEveryReadoutAndAcquisition(testCase)
            data = complex(reshape(1:24, 3, 2, 4));
            matrix = [1, 2; -1i, 0.5];
            output = apply_coil_matrix(data, matrix, 'ChunkAcquisitions', 2);

            expected = zeros(size(data), 'like', data);
            for acquisition = 1:size(data,3)
                expected(:,:,acquisition) = data(:,:,acquisition) * matrix;
            end
            testCase.verifyEqual(output, expected);
        end

        function packKspaceAveragesImagesAndPrefersReferenceLines(testCase)
            imageData = complex(zeros(2,2,4));
            imageData(:,:,1) = 1; imageData(:,:,2) = 2;
            imageData(:,:,3) = 4; imageData(:,:,4) = 8;
            imageMdh = struct('Lin', [1 2 2 4], 'Sli', [1 1 1 1]);
            refData = complex(zeros(2,2,2));
            refData(:,:,1) = 10; refData(:,:,2) = 14;
            refMdh = struct('Lin', [2 3], 'Sli', [1 1]);

            [kspace, imageMask, refMask, counts] = pack_TSE2D_kspace( ...
                imageData, imageMdh, refData, refMdh, 4, 1);

            testCase.verifyEqual(imageMask, logical([1 1 0 1]));
            testCase.verifyEqual(refMask, logical([0 1 1 0]));
            testCase.verifyEqual(counts.image, [1 2 0 1]);
            testCase.verifyEqual(counts.reference, [0 1 1 0]);
            testCase.verifyEqual(squeeze(kspace(:,1,:)), imageData(:,:,1));
            testCase.verifyEqual(squeeze(kspace(:,2,:)), refData(:,:,1));
            testCase.verifyEqual(squeeze(kspace(:,3,:)), refData(:,:,2));
            testCase.verifyEqual(squeeze(kspace(:,4,:)), imageData(:,:,4));
        end

        function wienerEchoMagnitudeCorrectionMatchesClosedFormGain(testCase)
            phaseCor = struct('referenceEcho', 1, 'amplitudeNorm', [1, 0.5, 0.25]);
            data = ones(2,1,3);
            mdh = struct('Sli', [1 1 1], 'Seg', [1 2 3]);

            [output, correction] = apply_TSE_echomagcor(data, mdh, phaseCor, 0, ...
                'Method', 'wiener', 'Lambda', 0.1, 'MaximumGain', 2);
            amplitude = phaseCor.amplitudeNorm;
            expectedGain = 1.1 .* amplitude ./ (amplitude.^2 + 0.1);

            testCase.verifyEqual(correction.gain, expectedGain, 'AbsTol', 1e-12);
            testCase.verifyEqual(reshape(output(1,1,:), 1, []), expectedGain, ...
                'AbsTol', 1e-12);
            testCase.verifyLessThanOrEqual(correction.maximumGain, 2);
        end

        function powerEchoMagnitudeCorrectionUsesPerSlicePerEchoGains(testCase)
            phaseCor = struct('referenceEcho', 1, ...
                'amplitudeNorm', [1 0.5; 0.25 1]);
            data = ones(3,2,4);
            mdh = struct('Sli', [1 2 1 2], 'Seg', [2 1 1 2]);

            [output, correction] = apply_TSE_echomagcor(data, mdh, phaseCor, 0);

            testCase.verifyEqual(correction.method, "power");
            testCase.verifyEqual(correction.gain, [1 2; 4 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(squeeze(output(1,1,:)).', [2 4 1 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(correction.correctedAmplitude, ones(2), 'AbsTol', 1e-12);
        end

        function autoWienerCorrectionUsesNoiseAndGainRegularization(testCase)
            phaseCor = struct('referenceEcho', 1, ...
                'amplitudeNorm', [1 0.5 0.25; 1 0.75 0.5], ...
                'referenceNoiseToSignalRatio', [0.05; NaN]);
            data = ones(2,1,6);
            mdh = struct('Sli', [1 1 1 2 2 2], 'Seg', [1 2 3 1 2 3]);

            [output, correction] = apply_TSE_echomagcor(data, mdh, phaseCor, 0, ...
                'Method', 'wiener', 'Lambda', 'auto', 'MaximumGain', 1.3);

            testCase.verifyEqual(correction.lambdaMode, "auto");
            testCase.verifyEqual(correction.lambdaNoiseBySlice(1), 0.05, 'AbsTol', eps);
            testCase.verifyEqual(correction.lambdaNoiseBySlice(2), 0, 'AbsTol', eps);
            testCase.verifyGreaterThanOrEqual(correction.lambdaBySlice, ...
                correction.lambdaNoiseBySlice);
            testCase.verifyLessThanOrEqual(correction.maximumGain, 1.3 + 1e-12);
            testCase.verifyEqual(squeeze(output(1,1,:)).', ...
                [correction.gain(1,:) correction.gain(2,:)], 'AbsTol', 1e-12);
        end

        function echoMagnitudeCorrectionRejectsMalformedMetadata(testCase)
            phaseCor = struct('referenceEcho', 1, 'amplitudeNorm', [1 0.5]);
            testCase.verifyEqual(apply_TSE_echomagcor([], struct(), phaseCor, 0), []);
            testCase.verifyError(@() apply_TSE_echomagcor(ones(1,1,1), ...
                struct('Sli',1), phaseCor, 0), 'apply_TSE_echomagcor:MissingMdh');
            testCase.verifyError(@() apply_TSE_echomagcor(ones(1,1,2), ...
                struct('Sli',[1 1], 'Seg',1), phaseCor, 0), ...
                'apply_TSE_echomagcor:MdhSizeMismatch');
            testCase.verifyError(@() apply_TSE_echomagcor(ones(1,1,1), ...
                struct('Sli',1, 'Seg',3), phaseCor, 0), ...
                'apply_TSE_echomagcor:MissingGain');
        end
    end
end
