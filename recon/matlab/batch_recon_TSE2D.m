%% Batch reconstruction of Siemens/Pulseq Cartesian 2D TSE Twix files
% Reconstructs every .dat file in inputDir and writes one magnitude .nii.gz
% per input. This workflow intentionally excludes gSlider.

clear; clc;

reconDir = fileparts(mfilename('fullpath'));
addpath(reconDir);

%% Configuration
inputDir = "F:\TSE_2D\dat";
outputDir = "F:\TSE_2D\out";
mapVBVDPath = "E:\Tools\mapVBVD";
overwriteExisting = false;

applyPrewhitening = true;
applyPhaseCorrection = true;
runGrappa = true;
applyEchoMagnitudeCorrection = true;
echoMagnitudeMethod = "wiener";
echoMagnitudeAlpha = 0;
echoMagnitudeLambda = "auto";
echoMagnitudeMaxGain = 2;

if applyEchoMagnitudeCorrection
    outputSuffix = sprintf('_EchoMag_%s_a%.3g',echoMagnitudeMethod,echoMagnitudeAlpha);
    if echoMagnitudeMethod == "wiener"
        if isstring(echoMagnitudeLambda) || ischar(echoMagnitudeLambda)
            lambdaLabel = char(string(echoMagnitudeLambda));
        else
            lambdaLabel = sprintf('%.3g',echoMagnitudeLambda);
        end
        outputSuffix = sprintf('%s_l%s_g%.3g', ...
            outputSuffix,lambdaLabel,echoMagnitudeMaxGain);
    end
    outputSuffix = string(regexprep(outputSuffix,'[^A-Za-z0-9_-]','p'));
else
    outputSuffix = "";
end

%% Discover inputs
inputs = dir(fullfile(inputDir,'*.dat'));
[~,order] = sort(lower(string({inputs.name})));
inputs = inputs(order);
if isempty(inputs)
    error('batch_recon_TSE2D:NoInput','No .dat files found in %s.',inputDir);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

nFile = numel(inputs);
source = strings(nFile,1);
output = strings(nFile,1);
status = strings(nFile,1);
message = strings(nFile,1);
matrixRO = NaN(nFile,1);
matrixPE = NaN(nFile,1);
nSlice = NaN(nFile,1);
accelerationPE = NaN(nFile,1);
voxelROmm = NaN(nFile,1);
voxelPEmm = NaN(nFile,1);
voxelSliceMm = NaN(nFile,1);
elapsedSeconds = NaN(nFile,1);

%% Reconstruction
for iFile = 1:nFile
    source(iFile) = fullfile(inputs(iFile).folder,inputs(iFile).name);
    [~,sourcePrefix] = fileparts(inputs(iFile).name);
    outputPrefix = string(sourcePrefix) + outputSuffix;
    output(iFile) = fullfile(outputDir,outputPrefix + ".nii.gz");
    fprintf('\n[%d/%d] %s\n',iFile,nFile,inputs(iFile).name);

    if isfile(output(iFile)) && ~overwriteExisting
        status(iFile) = "skipped";
        message(iFile) = "Output exists and overwriteExisting=false.";
        fprintf('  skipped: %s already exists\n',output(iFile));
        continue
    end

    fileTimer = tic;
    try
        result = recon_TSE2D(source(iFile), ...
            'MapVBVDPath',mapVBVDPath, ...
            'Prewhiten',applyPrewhitening, ...
            'NoiseShrinkage',0.02, ...
            'PhaseCorrection',applyPhaseCorrection, ...
            'EchoMagnitudeCorrection',applyEchoMagnitudeCorrection, ...
            'EchoMagnitudeMethod',echoMagnitudeMethod, ...
            'EchoMagnitudeAlpha',echoMagnitudeAlpha, ...
            'EchoMagnitudeLambda',echoMagnitudeLambda, ...
            'EchoMagnitudeMaxGain',echoMagnitudeMaxGain, ...
            'GRAPPA',runGrappa, ...
            'GrappaKySourceCount',4, ...
            'GrappaKxKernel',0, ...
            'GrappaRegularization',1e-4, ...
            'ComparePhaseCorrection',false, ...
            'Slices',[], ...
            'KeepKspace',false, ...
            'OutputDir','', ...
            'Verbose',true);

        output(iFile) = write_TSE2D_nifti( ...
            result.images.reconstructed,result.meta,outputDir, ...
            'Prefix',outputPrefix, ...
            'Description',sprintf( ...
                'Pulseq 2D TSE; R=%d; EchoMag %s alpha=%.3g gain<=%.3g', ...
                result.meta.accelerationFactorPE,result.echoMagnitudeCorrection.method, ...
                result.echoMagnitudeCorrection.alpha, ...
                result.echoMagnitudeCorrection.maximumGain), ...
            'Overwrite',overwriteExisting);

        info = niftiinfo(output(iFile));
        matrixRO(iFile) = result.meta.nRO;
        matrixPE(iFile) = result.meta.nPE;
        nSlice(iFile) = numel(result.meta.reconstructedSlices);
        accelerationPE(iFile) = result.meta.accelerationFactorPE;
        voxelROmm(iFile) = info.PixelDimensions(1);
        voxelPEmm(iFile) = info.PixelDimensions(2);
        voxelSliceMm(iFile) = info.PixelDimensions(3);
        status(iFile) = "complete";
        message(iFile) = "";
        elapsedSeconds(iFile) = toc(fileTimer);
        fprintf('  wrote: %s (%dx%dx%d, R=%d, %.1f s)\n', ...
            output(iFile),matrixRO(iFile),matrixPE(iFile),nSlice(iFile), ...
            accelerationPE(iFile),elapsedSeconds(iFile));
        clear result
    catch ME
        elapsedSeconds(iFile) = toc(fileTimer);
        status(iFile) = "failed";
        message(iFile) = string(getReport(ME,'extended','hyperlinks','off'));
        fprintf(2,'  failed: %s\n',ME.message);
    end
end

%% Save and report batch status
batchLog = table(source,output,status,message,matrixRO,matrixPE,nSlice, ...
    accelerationPE,voxelROmm,voxelPEmm,voxelSliceMm,elapsedSeconds);
logFile = fullfile(outputDir,"batch_recon_TSE2D" + outputSuffix + "_log.csv");
writetable(batchLog,logFile);

nComplete = nnz(status == "complete");
nSkipped = nnz(status == "skipped");
nFailed = nnz(status == "failed");
fprintf('\nBatch complete: %d reconstructed, %d skipped, %d failed.\nLog: %s\n', ...
    nComplete,nSkipped,nFailed,logFile);
if nFailed > 0
    error('batch_recon_TSE2D:FailedFiles', ...
        '%d file(s) failed. Inspect %s for details.',nFailed,logFile);
end
