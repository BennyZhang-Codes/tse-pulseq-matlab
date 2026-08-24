function [summary,metrics] = benchmark_TSE2D_denoisers(inputDir,outputDir,varargin)
%BENCHMARK_TSE2D_DENOISERS Compare mature image-domain TSE denoisers.
%
% The default benchmark runs conservative NLM, colored-noise BM3D, and
% second-order TGV. CAT12 Gaussian SANLM remains available through
% 'Methods',["nlm","bm3d","sanlm","tgv2"], but is not enabled by default:
% its isotropic-neighbourhood model is a poor match for strongly anisotropic,
% few-slice 2-D TSE volumes. Source NIfTI geometry is preserved and verified
% for every output.

    p = inputParser;
    p.addParameter('Pattern','*_EchoMagCorrWiener.nii.gz', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    p.addParameter('Methods',["nlm","bm3d","tgv2"], ...
        @(x) ischar(x) || isstring(x) || iscellstr(x));
    p.addParameter('NLMStrength',0.6,@isPositiveScalar);
    p.addParameter('BM3DNoiseScale',0.6,@isPositiveScalar);
    p.addParameter('TGVStrength',0.2,@isPositiveScalar);
    p.addParameter('Overwrite',false,@(x) islogical(x) && isscalar(x));
    p.addParameter('SaveComparisons',true,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    inputDir = char(string(inputDir));
    outputDir = char(string(outputDir));
    if ~isfolder(inputDir)
        error('benchmark_TSE2D_denoisers:InputMissing', ...
            'Input directory not found: %s',inputDir);
    end
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end
    methods = lower(string(opt.Methods));
    methods = arrayfun(@(x) string(validatestring(char(x), ...
        {'nlm','bm3d','sanlm','tgv2'})),methods);

    files = dir(fullfile(inputDir,char(string(opt.Pattern))));
    [~,order] = sort(lower(string({files.name})));
    files = files(order);
    if isempty(files)
        error('benchmark_TSE2D_denoisers:NoInput','No input files match %s.',opt.Pattern);
    end
    comparisonDir = fullfile(outputDir,'comparisons');
    if opt.SaveComparisons && ~isfolder(comparisonDir)
        mkdir(comparisonDir);
    end

    metricRows = cell(0,27);
    for iFile = 1:numel(files)
        sourceFile = fullfile(files(iFile).folder,files(iFile).name);
        sourceInfo = niftiinfo(sourceFile);
        original = single(niftiread(sourceInfo));
        imageSize = size3(original);
        original = reshape(original,imageSize);
        spacing = double(sourceInfo.PixelDimensions(1:3));
        acceleration = parseAcceleration(files(iFile).name);
        sourceStem = regexprep(files(iFile).name,'(?i)\.nii\.gz$','');
        denoisedVolumes = cell(1,numel(methods));
        methodLabels = strings(1,numel(methods));

        fprintf('[%d/%d] %s\n',iFile,numel(files),files(iFile).name);
        for iMethod = 1:numel(methods)
            method = methods(iMethod);
            methodLabel = makeMethodLabel(method,opt);
            methodLabels(iMethod) = methodLabel;
            methodDir = fullfile(outputDir,char(methodLabel));
            if ~isfolder(methodDir)
                mkdir(methodDir);
            end

            [denoised,runReport] = denoise_TSE2D(original,method, ...
                'VoxelSpacing',spacing,'NLMStrength',opt.NLMStrength, ...
                'BM3DNoiseScale',opt.BM3DNoiseScale, ...
                'TGVStrength',opt.TGVStrength,'Verbose',true);
            outputStem = sprintf('%s_%s',sourceStem,char(methodLabel));
            description = sprintf('Pulseq TSE2D image denoising: %s',char(methodLabel));
            outputFile = write_TSE2D_nifti(denoised,sourceInfo,methodDir, ...
                'Prefix',outputStem,'Description',description, ...
                'Overwrite',opt.Overwrite);
            denoisedVolumes{iMethod} = denoised;

            for iSlice = 1:imageSize(3)
                noise = runReport.noise(iSlice);
                m = measure_TSE2D_denoising(original(:,:,iSlice), ...
                    denoised(:,:,iSlice),noise);
                metricRows(end+1,:) = {string(files(iFile).name),method, ...
                    methodLabel,acceleration,spacing(1),spacing(2),spacing(3), ...
                    iSlice,noise.sigma,noise.stationarityCV, ...
                    m.backgroundStdBefore,m.backgroundStdAfter, ...
                    m.noiseReductionPercent,m.backgroundMeanRatio, ...
                    m.foregroundSignalRatio,m.edgeGradientRatio, ...
                    m.ssimToOriginal,m.edgeResidualEnrichment, ...
                    m.residualRmsOverNoiseSigma,m.backgroundResidualLag1RO, ...
                    m.backgroundResidualLag1PE,m.residualPEtoROGradientEnergy, ...
                    m.negativeVoxelFraction,runReport.clippedNegativeFraction(iSlice), ...
                    runReport.elapsedSecondsPerSlice(iSlice), ...
                    string(runReport.dependencyPath),string(outputFile)}; %#ok<AGROW>
            end
            fprintf('  wrote %s\n',outputFile);
        end

        if opt.SaveComparisons
            comparisonFile = fullfile(comparisonDir,[sourceStem '_mature_denoisers.png']);
            saveComparison(original,denoisedVolumes,methodLabels,comparisonFile);
        end
        clear original denoisedVolumes
    end

    variableNames = {'SourceFile','Method','MethodLabel','AccelerationPE', ...
        'VoxelROmm','VoxelPEmm','VoxelSliceMm','Slice','NoiseSigma', ...
        'NoiseStationarityCV','BackgroundStdBefore','BackgroundStdAfter', ...
        'NoiseReductionPercent','BackgroundMeanRatio','ForegroundSignalRatio', ...
        'EdgeGradientRatio','SSIMToOriginal','EdgeResidualEnrichment', ...
        'ResidualRmsOverNoiseSigma','BackgroundResidualLag1RO', ...
        'BackgroundResidualLag1PE','ResidualPEtoROGradientEnergy', ...
        'NegativeVoxelFraction','InternalClippedNegativeFraction', ...
        'ElapsedSeconds','DependencyPath','OutputFile'};
    metrics = cell2table(metricRows,'VariableNames',variableNames);
    writetable(metrics,fullfile(outputDir,'mature_denoiser_metrics_by_slice.csv'));

    groups = findgroups(metrics.SourceFile,metrics.MethodLabel);
    summary = table();
    summary.SourceFile = splitapply(@(x) x(1),metrics.SourceFile,groups);
    summary.Method = splitapply(@(x) x(1),metrics.Method,groups);
    summary.MethodLabel = splitapply(@(x) x(1),metrics.MethodLabel,groups);
    summary.AccelerationPE = splitapply(@(x) x(1),metrics.AccelerationPE,groups);
    summary.VoxelROmm = splitapply(@(x) x(1),metrics.VoxelROmm,groups);
    summary.NoiseReductionPercent = splitapply(@mean,metrics.NoiseReductionPercent,groups);
    summary.BackgroundMeanRatio = splitapply(@mean,metrics.BackgroundMeanRatio,groups);
    summary.ForegroundSignalRatio = splitapply(@mean,metrics.ForegroundSignalRatio,groups);
    summary.EdgeGradientRatio = splitapply(@mean,metrics.EdgeGradientRatio,groups);
    summary.SSIMToOriginal = splitapply(@mean,metrics.SSIMToOriginal,groups);
    summary.EdgeResidualEnrichment = splitapply(@mean,metrics.EdgeResidualEnrichment,groups);
    summary.ResidualRmsOverNoiseSigma = splitapply(@mean,metrics.ResidualRmsOverNoiseSigma,groups);
    summary.BackgroundResidualLag1RO = splitapply(@meanOmitNaN,metrics.BackgroundResidualLag1RO,groups);
    summary.BackgroundResidualLag1PE = splitapply(@meanOmitNaN,metrics.BackgroundResidualLag1PE,groups);
    summary.ResidualPEtoROGradientEnergy = splitapply(@mean,metrics.ResidualPEtoROGradientEnergy,groups);
    summary.ElapsedSeconds = splitapply(@sum,metrics.ElapsedSeconds,groups);
    writetable(summary,fullfile(outputDir,'mature_denoiser_summary.csv'));
    saveTradeoffPlot(summary,fullfile(outputDir,'mature_denoiser_tradeoff.png'));
    writeTextReport(summary,fullfile(outputDir,'mature_denoiser_report.txt'));
end

function label = makeMethodLabel(method,opt)
    switch method
        case "nlm"
            label = "NLM_"+numberLabel(opt.NLMStrength)+"sigma";
        case "bm3d"
            label = "BM3D_colored_"+numberLabel(opt.BM3DNoiseScale)+"sigma";
        case "sanlm"
            label = "SANLM_Gaussian_2D";
        case "tgv2"
            label = "TGV2_"+numberLabel(opt.TGVStrength)+"sigma";
    end
end

function label = numberLabel(value)
    label = string(strrep(sprintf('%.3g',value),'.','p'));
end

function saveComparison(original,denoisedVolumes,labels,filename)
    slice = ceil(size(original,3)/2);
    source = double(original(:,:,slice));
    displayMax = percentileSorted(sort(source(:)),0.995);
    residualMax = 0;
    for i = 1:numel(denoisedVolumes)
        residual = abs(double(denoisedVolumes{i}(:,:,slice))-source);
        residualMax = max(residualMax,percentileSorted(sort(residual(:)),0.995));
    end
    residualMax = max(residualMax,eps);

    fig = figure('Visible','off','Color','k','Position',[50 50 1800 720]);
    layout = tiledlayout(fig,2,numel(labels)+1, ...
        'TileSpacing','compact','Padding','compact');
    showImage(nexttile(layout),source,[0 displayMax],'Original');
    for i = 1:numel(labels)
        showImage(nexttile(layout),denoisedVolumes{i}(:,:,slice), ...
            [0 displayMax],strrep(char(labels(i)),'_',' '));
    end
    ax = nexttile(layout);
    axis(ax,'off');
    text(ax,0.5,0.5,'Absolute residual','Color','w', ...
        'HorizontalAlignment','center','FontSize',12);
    for i = 1:numel(labels)
        residual = abs(double(denoisedVolumes{i}(:,:,slice))-source);
        showImage(nexttile(layout),residual,[0 residualMax], ...
            ['|' strrep(char(labels(i)),'_',' ') ' - original|']);
    end
    title(layout,sprintf('Central slice %d; common image/residual windows',slice), ...
        'Color','w','FontWeight','normal');
    exportgraphics(fig,filename,'Resolution',180);
    close(fig);
end

function showImage(ax,image,limits,label)
    imagesc(ax,image,limits);
    axis(ax,'image','off');
    colormap(ax,'gray');
    title(ax,label,'Color','w','FontWeight','normal');
end

function saveTradeoffPlot(summary,filename)
    labels = unique(summary.MethodLabel,'stable');
    colors = lines(numel(labels));
    markers = {'o','s','^','d','v','>'};
    fig = figure('Visible','off','Color','w','Position',[50 50 1150 500]);
    layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
    ax1 = nexttile(layout); hold(ax1,'on'); grid(ax1,'on');
    ax2 = nexttile(layout); hold(ax2,'on'); grid(ax2,'on');
    for i = 1:numel(labels)
        rows = summary.MethodLabel == labels(i);
        marker = markers{1+mod(i-1,numel(markers))};
        scatter(ax1,summary.NoiseReductionPercent(rows),summary.EdgeGradientRatio(rows), ...
            45,colors(i,:),marker,'filled','DisplayName',strrep(labels(i),'_',' '));
        scatter(ax2,summary.NoiseReductionPercent(rows),summary.EdgeResidualEnrichment(rows), ...
            45,colors(i,:),marker,'filled','DisplayName',strrep(labels(i),'_',' '));
    end
    xlabel(ax1,'Background STD reduction (%)');
    ylabel(ax1,'Edge-gradient retention');
    yline(ax1,1,':','Original');
    xlabel(ax2,'Background STD reduction (%)');
    ylabel(ax2,'Edge residual enrichment');
    legend(ax2,'Location','eastoutside');
    title(layout,'Mature TSE2D image-domain denoiser trade-off');
    exportgraphics(fig,filename,'Resolution',180);
    close(fig);
end

function writeTextReport(summary,filename)
    fid = fopen(filename,'w');
    if fid < 0
        error('benchmark_TSE2D_denoisers:ReportWriteFailed','Cannot write %s.',filename);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid,'TSE2D mature image-domain denoiser benchmark\n');
    fprintf(fid,'Generated: %s\n',char(datetime('now')));
    fprintf(fid,['Metrics compare each output with its noisy input and do not ', ...
        'constitute clean-reference accuracy.\n\n']);
    labels = unique(summary.MethodLabel,'stable').';
    for label = labels
        rows = summary.MethodLabel == label;
        fprintf(fid,'%s\n',char(label));
        fprintf(fid,'  Mean background STD reduction: %.3f %%\n', ...
            mean(summary.NoiseReductionPercent(rows)));
        fprintf(fid,'  Mean foreground signal ratio: %.6f\n', ...
            mean(summary.ForegroundSignalRatio(rows)));
        fprintf(fid,'  Mean edge-gradient retention: %.6f\n', ...
            mean(summary.EdgeGradientRatio(rows)));
        fprintf(fid,'  Mean SSIM to noisy input: %.6f\n', ...
            mean(summary.SSIMToOriginal(rows)));
        fprintf(fid,'  Mean edge residual enrichment: %.6f\n', ...
            mean(summary.EdgeResidualEnrichment(rows)));
        fprintf(fid,'  Total processing time: %.3f s\n\n', ...
            sum(summary.ElapsedSeconds(rows)));
    end
    clear cleaner
end

function acceleration = parseAcceleration(filename)
    token = regexp(filename,'_14p0_([1-9][0-9]*)_','tokens','once');
    if isempty(token)
        acceleration = NaN;
    else
        acceleration = str2double(token{1});
    end
end

function value = percentileSorted(sortedValues,fraction)
    if isempty(sortedValues)
        value = 0;
        return
    end
    index = max(1,min(numel(sortedValues),round(fraction*numel(sortedValues))));
    value = sortedValues(index);
end

function value = meanOmitNaN(values)
    value = mean(values,'omitnan');
end

function tf = isPositiveScalar(value)
    tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end

function dimensions = size3(volume)
    dimensions = size(volume);
    dimensions(end+1:3) = 1;
    dimensions = dimensions(1:3);
end
