classdef TestSequenceAndReconOperators < matlab.unittest.TestCase
    methods (Test)
        function phaseCorrectionRemovesKnownLinearAndConstantPhase(testCase)
            nRO = 8;
            data = complex(ones(nRO,2,2));
            coefficients = zeros(1,2,2,2);
            coefficients(1,1,1,:) = [0.7, -0.3];
            coefficients(1,2,2,:) = [-0.5, 0.2];
            phaseCor = struct('coefficients', coefficients);
            mdh = struct('Sli', [1 1], 'Seg', [1 2]);
            normalizedKx = ((1:nRO).' - (nRO+1)/2) / nRO;
            data(:,1,1) = exp(1i*(0.7*normalizedKx - 0.3));
            data(:,2,2) = exp(1i*(-0.5*normalizedKx + 0.2));

            corrected = apply_TSE_phasecor(data, mdh, phaseCor);

            testCase.verifyEqual(corrected, complex(ones(size(data))), 'AbsTol', 2e-7);
        end

        function rssReconstructionCombinesCenteredCoilImages(testCase)
            image = reshape(single(1:16),4,4);
            coilImages = cat(3, image, 2*image);
            kspace = fftshift(fftshift(fft(fft( ...
                ifftshift(ifftshift(coilImages,1),2),[],1),[],2),1),2);
            [rss, reconstructedCoils] = recon_TSE2D_RSS(kspace);

            testCase.verifyEqual(reconstructedCoils, coilImages, 'AbsTol', 2e-6);
            testCase.verifyEqual(rss, sqrt(5)*image, 'AbsTol', 2e-6);
        end

        function senseForwardAndAdjointSatisfyInnerProductIdentity(testCase)
            rng(29);
            image = randn(6,5) + 1i*randn(6,5);
            sensitivities = randn(6,5,3) + 1i*randn(6,5,3);
            mask = repmat(mod(reshape(1:5,1,5),2)==1,6,1,3);
            data = randn(6,5,3) + 1i*randn(6,5,3);

            forward = sense_TSE2D_forward(image, sensitivities, mask);
            adjoint = sense_TSE2D_adjoint(data, sensitivities, mask);

            testCase.verifyEqual(sum(conj(forward(:)).*data(:)), ...
                sum(conj(image(:)).*adjoint(:)), 'AbsTol', 1e-10);
        end

        function sliceOrderingAndPositionsFollowConfiguredDirection(testCase)
            actual = struct('SeqDimension','2D','nSlice',5, ...
                'SliceThickness',2e-3,'SliceGap',0.5e-3, ...
                'MultiSliceMode','Interleaved','MultiSliceDir','Ascending');
            [labels, order, positions] = prep_SlicePositions(actual);

            testCase.verifyEqual(labels, [0 2 4 1 3]);
            testCase.verifyEqual(order, [-2 0 2 -1 1]);
            testCase.verifyEqual(positions, -2.5e-3*order, 'AbsTol', eps);
        end

        function threeDimensionalSlicePositionsSupportDescendingSequentialOrder(testCase)
            actual = struct('SeqDimension','3D','nSlab',4, ...
                'SlabThickness',5e-3,'SlabGap',1e-3, ...
                'MultiSliceMode','Sequential','MultiSliceDir','Descending');
            [labels, order, positions] = prep_SlicePositions(actual);

            testCase.verifyEqual(labels, 0:3);
            testCase.verifyEqual(order, [-1.5 -0.5 0.5 1.5]);
            testCase.verifyEqual(positions, 6e-3*order, 'AbsTol', eps);
        end

        function slicePositionsRejectUnsupportedOrdering(testCase)
            actual = struct('SeqDimension','2D','nSlice',2, ...
                'SliceThickness',1e-3,'SliceGap',0, ...
                'MultiSliceMode','Centric','MultiSliceDir','Ascending');
            didThrow = false;
            try
                prep_SlicePositions(actual);
            catch exception
                didThrow = true;
                testCase.verifyTrue(contains(exception.message, 'Unsupported multislicemode'));
            end
            testCase.verifyTrue(didThrow);
            actual.MultiSliceMode = 'Sequential';
            actual.MultiSliceDir = 'Sideways';
            didThrow = false;
            try
                prep_SlicePositions(actual);
            catch exception
                didThrow = true;
                testCase.verifyTrue(contains(exception.message, 'Unsupported MultiSliceDir'));
            end
            testCase.verifyTrue(didThrow);
        end

        function spoilerAreasScaleWithTheirPhysicalReferences(testCase)
            spec = @(cycles,reference) struct('Cycles',cycles,'Reference',reference);
            actual = struct('SliceThickness',2e-3,'SlabThickness',8e-3, ...
                'FOV',[0.24 0.20 0.01],'MatrixSize',[120 100 1]);
            actual.ActualSpoiling = struct( ...
                'PreExcitationSpoiler',spec(4,'Slice'), ...
                'RefocusingCrusher',spec(2,'RO'), ...
                'InversionCrusher',spec(3,'PE'), ...
                'ReadoutCrusher',spec(1,'3D'), ...
                'EndSpoiler',spec(5,'Slab'));

            grad = prep_SpoilingArea(struct(),actual);
            areas = grad.SpoilingArea;

            testCase.verifyEqual(areas.PreExcitationSpoiler, 4/2e-3);
            testCase.verifyEqual(areas.RefocusingCrusher, 2/(0.24/120));
            testCase.verifyEqual(areas.InversionCrusher, 3/(0.20/100));
            testCase.verifyEqual(areas.ReadoutCrusher, 1/(0.01/1));
            testCase.verifyEqual(areas.EndSpoiler, 5/8e-3);
        end

        function roundRasterHandlesDirectionsDefaultsAndErrors(testCase)
            [up, upError] = RoundRaster([0.10 0.20 0.20000000001], 0.1, 'up');
            testCase.verifyEqual(up, [0.10 0.20 0.20], 'AbsTol', eps);
            testCase.verifyEqual(upError, up - [0.10 0.20 0.20000000001], 'AbsTol', eps);
            testCase.verifyEqual(RoundRaster(0.24, 0.1, 'down'), 0.2, 'AbsTol', eps);
            testCase.verifyEqual(RoundRaster(0.26, [], []), 0, 'AbsTol', eps);
            testCase.verifyEqual(RoundRaster(0.24, 'up', 0.1), 0.3, 'AbsTol', eps);
            testCase.verifyError(@() RoundRaster(0.2, 0.1, 'sideways'), ...
                'RoundRasterTime:InvalidMethod');
        end
    end
end
