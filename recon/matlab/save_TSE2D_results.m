function files = save_TSE2D_results(result, outputDir, varargin)
%SAVE_TSE2D_RESULTS Save reconstruction data and compact diagnostics.

    p = inputParser;
    p.addParameter('Prefix','',@(x) ischar(x) || isstring(x));
    p.addParameter('SaveMat',true,@(x) islogical(x) && isscalar(x));
    p.addParameter('SaveFigures',true,@(x) islogical(x) && isscalar(x));
    p.addParameter('SaveNifti',false,@(x) islogical(x) && isscalar(x));
    p.addParameter('NiftiVoxelSizeMm',[],@(x) isempty(x) || ...
        (isnumeric(x) && isvector(x) && numel(x) == 3 && all(isfinite(x)) && all(x > 0)));
    p.addParameter('Overwrite',false,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    outputDir = char(string(outputDir));
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end
    prefix = char(string(opt.Prefix));
    if isempty(prefix)
        [~,prefix] = fileparts(char(result.sourceFile));
    end
    prefix = regexprep(prefix,'[^A-Za-z0-9._-]','_');
    files = struct();
    if opt.SaveNifti
        [files.nifti,niftiInfo,niftiGeometry] = write_TSE2D_nifti( ...
            result.images.reconstructed,result.meta,outputDir, ...
            'Prefix',prefix, ...
            'VoxelSizeMm',opt.NiftiVoxelSizeMm, ...
            'Description',sprintf('Pulseq 2D TSE magnitude; R=%d', ...
                result.meta.accelerationFactorPE), ...
            'Overwrite',opt.Overwrite);
    end

    if opt.SaveMat
        files.mat = fullfile(outputDir,[prefix '_recon.mat']);
        save(files.mat,'result','-v7.3');
    end

    if isfield(result.phaseCorrection,'metrics') && ~isempty(result.phaseCorrection.metrics)
        files.phaseCsv = fullfile(outputDir,[prefix '_phasecor.csv']);
        writetable(result.phaseCorrection.metrics,files.phaseCsv);
    end

    files.summary = fullfile(outputDir,[prefix '_summary.txt']);
    fid = fopen(files.summary,'w');
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid,'Source: %s\n',result.sourceFile);
    fprintf(fid,'Matrix: %d x %d\n',result.meta.nRO,result.meta.nPE);
    fprintf(fid,'Slices: %s\n',sprintf('%d ',result.meta.reconstructedSlices));
    if opt.SaveNifti
        fprintf(fid,'NIfTI: %s\n',files.nifti);
        fprintf(fid,'NIfTI voxel size (mm): %.9g %.9g %.9g\n',niftiInfo.PixelDimensions);
        fprintf(fid,'NIfTI geometry source: %s\n',niftiGeometry.source);
        fprintf(fid,'NIfTI coordinate system: %s\n',niftiGeometry.niftiCoordinateSystem);
        fprintf(fid,'NIfTI sform RAS (mm; rows):\n');
        for row = 1:4
            fprintf(fid,'  %.12g %.12g %.12g %.12g\n', ...
                niftiGeometry.affineRAS(row,:));
        end
        fprintf(fid,'NIfTI maximum slice-center error (mm): %.12g\n', ...
            niftiGeometry.maxSliceCenterErrorMm);
    end
    fprintf(fid,'Acceleration PE: %d\n',result.meta.accelerationFactorPE);
    fprintf(fid,'Image/phasecor/refscan/noise acquisitions: %d / %d / %d / %d\n', ...
        result.meta.imageAcquisitions,result.meta.phaseCorAcquisitions, ...
        result.meta.refscanAcquisitions,result.meta.noiseAcquisitions);
    fprintf(fid,'Prewhitening applied: %d, samples: %d, condition: %.6g -> %.6g\n', ...
        result.prewhitening.applied,result.prewhitening.nSamples, ...
        result.prewhitening.conditionBefore,result.prewhitening.conditionAfter);
    fprintf(fid,'Phase correction applied: %d\n',result.phaseCorrection.applied);
    if isfield(result,'echoMagnitudeCorrection')
        echoMag = result.echoMagnitudeCorrection;
        fprintf(fid,'Echo-magnitude correction applied: %d, method: %s, alpha: %.9g\n', ...
            echoMag.applied,echoMag.method,echoMag.alpha);
        if echoMag.applied
            fprintf(fid,'Echo-magnitude gain range: %.9g %.9g\n', ...
                echoMag.minimumGain,echoMag.maximumGain);
            fprintf(fid,'Maximum predicted noise variance gain: %.9g\n', ...
                echoMag.maximumNoiseVarianceGain);
            if echoMag.method == "wiener"
                fprintf(fid,'Wiener lambda mode: %s\n',echoMag.lambdaMode);
                fprintf(fid,'Wiener lambda by slice: %s\n', ...
                    sprintf('%.9g ',echoMag.lambdaBySlice(isfinite(echoMag.lambdaBySlice))));
                fprintf(fid,'Wiener noise lambda by slice: %s\n', ...
                    sprintf('%.9g ',echoMag.lambdaNoiseBySlice(isfinite(echoMag.lambdaNoiseBySlice))));
                fprintf(fid,'Wiener gain-limit lambda by slice: %s\n', ...
                    sprintf('%.9g ',echoMag.lambdaGainBySlice(isfinite(echoMag.lambdaGainBySlice))));
                fprintf(fid,'Wiener maximum-gain target: %.9g\n',echoMag.maximumGainTarget);
            end
        end
    end
    reconstructionMethod = "auto";
    if isfield(result,'reconstructionMethod')
        reconstructionMethod = string(result.reconstructionMethod);
    end
    fprintf(fid,'Reconstruction method: %s\n',reconstructionMethod);
    if reconstructionMethod == "grappa" && result.meta.accelerationFactorPE > 1
        nmse = cellfun(@(x) x.calibrationNMSE,result.grappa);
        fprintf(fid,'GRAPPA calibration NMSE by slice: %s\n',sprintf('%.6g ',nmse));
    elseif reconstructionMethod == "sense" || reconstructionMethod == "cs"
        iterativeInfo = result.(char(reconstructionMethod));
        residual = cellfun(@(x) x.finalRelativeDataResidual,iterativeInfo);
        iterations = cellfun(@(x) x.iterations,iterativeInfo);
        fprintf(fid,'Iterative data residual by slice: %s\n', ...
            sprintf('%.6g ',residual));
        fprintf(fid,'Iterative iteration count by slice: %s\n', ...
            sprintf('%d ',iterations));
    end
    clear cleaner;

    if ~opt.SaveFigures
        return;
    end

    files.finalPng = fullfile(outputDir,[prefix '_final.png']);
    saveMontage(result.images.reconstructed,result.meta.reconstructedSlices, ...
        sprintf('2D TSE reconstruction: %s',prefix),files.finalPng);

    if ~isempty(result.images.reconstructedNoPhaseCorrection)
        files.phaseComparisonPng = fullfile(outputDir,[prefix '_phasecor_comparison.png']);
        savePhaseComparison(result,files.phaseComparisonPng);
    end

    if isfield(result.phaseCorrection,'metrics') && ~isempty(result.phaseCorrection.metrics)
        files.phasePlotPng = fullfile(outputDir,[prefix '_phasecor_metrics.png']);
        savePhaseMetrics(result.phaseCorrection.metrics,files.phasePlotPng);
    end
end

function saveMontage(images,slices,mainTitle,filename)
    n = size(images,3);
    nCol = ceil(sqrt(n));
    nRow = ceil(n/nCol);
    fig = figure('Color','k','Position',[100 100 350*nCol 350*nRow]);
    layout = tiledlayout(nRow,nCol,'TileSpacing','compact','Padding','compact');
    limit = robustLimit(images);
    for i = 1:n
        ax = nexttile(layout);
        imagesc(ax,images(:,:,i),[0 limit]); axis(ax,'image','off'); colormap(ax,'gray');
        title(ax,sprintf('SLC %d',slices(i)),'Color','w','FontWeight','normal');
    end
    title(layout,mainTitle,'Color','w','Interpreter','none');
    exportgraphics(fig,filename,'Resolution',180);
    close(fig);
end

function savePhaseComparison(result,filename)
    corrected = result.images.reconstructed;
    uncorrected = result.images.reconstructedNoPhaseCorrection;
    n = size(corrected,3);
    fig = figure('Color','k','Position',[100 100 1000 320*n]);
    layout = tiledlayout(n,3,'TileSpacing','compact','Padding','compact');
    for i = 1:n
        limit = robustLimit(cat(3,uncorrected(:,:,i),corrected(:,:,i)));
        show(nexttile(layout),uncorrected(:,:,i),[0 limit],sprintf('SLC %d: no PC',result.meta.reconstructedSlices(i)));
        show(nexttile(layout),corrected(:,:,i),[0 limit],sprintf('SLC %d: PC',result.meta.reconstructedSlices(i)));
        difference = abs(double(corrected(:,:,i))-double(uncorrected(:,:,i)));
        show(nexttile(layout),difference,[0 robustLimit(difference)],'|difference|');
    end
    title(layout,'TSE navigator phase-correction comparison','Color','w');
    exportgraphics(fig,filename,'Resolution',180);
    close(fig);
end

function savePhaseMetrics(metrics,filename)
    slices = unique(metrics.Slice);
    echoes = unique(metrics.Echo);
    fields = {'AmplitudeNorm','ConstantPhaseDeg','LinearPhaseAcrossFOVDeg'};
    labels = {'NAV amplitude / reference echo','Constant phase (deg)', ...
        'Linear phase across readout FOV (deg)'};
    if ismember('NavigatorSNR',metrics.Properties.VariableNames)
        fields = {'AmplitudeNorm','NavigatorSNR','ConstantPhaseDeg', ...
            'LinearPhaseAcrossFOVDeg'};
        labels = {'NAV amplitude / reference echo','Prewhitened NAV SNR', ...
            'Constant phase (deg)','Linear phase across readout FOV (deg)'};
    end

    nPanel = numel(fields);
    fig = figure('Color','w','Position',[100 100 1000 260*nPanel]);
    layout = tiledlayout(nPanel,1,'TileSpacing','compact','Padding','compact');
    for j = 1:nPanel
        ax = nexttile(layout); hold(ax,'on');
        for slice = reshape(slices,1,[])
            rows = metrics.Slice == slice;
            [~,order] = sort(metrics.Echo(rows));
            currentEchoes = metrics.Echo(rows);
            currentEchoes = currentEchoes(order);
            values = metrics.(fields{j});
            values = values(rows);
            plot(ax,currentEchoes,values(order),'-o','LineWidth',1.2,'MarkerSize',3, ...
                'DisplayName',sprintf('SLC %d',slice));
        end
        grid(ax,'on'); ylabel(ax,labels{j}); xlim(ax,[min(echoes) max(echoes)]);
        if j == 1, legend(ax,'Location','best'); end
        if j == nPanel, xlabel(ax,'Echo / SEG'); end
    end
    title(layout,'TSE phase-correction navigator metrics');
    exportgraphics(fig,filename,'Resolution',180);
    close(fig);
end

function show(ax,image,limits,label)
    imagesc(ax,image,limits); axis(ax,'image','off'); colormap(ax,'gray');
    title(ax,label,'Color','w','FontWeight','normal');
end

function limit = robustLimit(values)
    values = sort(double(values(isfinite(values))));
    if isempty(values)
        limit = 1;
        return;
    end
    index = max(1,min(numel(values),round(0.997*numel(values))));
    limit = values(index);
    if ~isfinite(limit) || limit <= 0
        limit = max(values);
    end
    if ~isfinite(limit) || limit <= 0
        limit = 1;
    end
end
