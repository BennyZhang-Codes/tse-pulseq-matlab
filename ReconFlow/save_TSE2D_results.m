function files = save_TSE2D_results(result, outputDir, varargin)
%SAVE_TSE2D_RESULTS Save reconstruction data and compact diagnostics.

    p = inputParser;
    p.addParameter('Prefix','',@(x) ischar(x) || isstring(x));
    p.addParameter('SaveMat',true,@(x) islogical(x) && isscalar(x));
    p.addParameter('SaveFigures',true,@(x) islogical(x) && isscalar(x));
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
    fprintf(fid,'Acceleration PE: %d\n',result.meta.accelerationFactorPE);
    fprintf(fid,'Image/phasecor/refscan/noise acquisitions: %d / %d / %d / %d\n', ...
        result.meta.imageAcquisitions,result.meta.phaseCorAcquisitions, ...
        result.meta.refscanAcquisitions,result.meta.noiseAcquisitions);
    fprintf(fid,'Prewhitening applied: %d, samples: %d, condition: %.6g -> %.6g\n', ...
        result.prewhitening.applied,result.prewhitening.nSamples, ...
        result.prewhitening.conditionBefore,result.prewhitening.conditionAfter);
    fprintf(fid,'Phase correction applied: %d\n',result.phaseCorrection.applied);
    if result.meta.accelerationFactorPE > 1
        nmse = cellfun(@(x) x.calibrationNMSE,result.grappa);
        fprintf(fid,'GRAPPA calibration NMSE by slice: %s\n',sprintf('%.6g ',nmse));
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
    fig = figure('Color','w','Position',[100 100 1000 850]);
    layout = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
    fields = {'AmplitudeNorm','ConstantPhaseDeg','LinearPhaseAcrossFOVDeg'};
    labels = {'NAV amplitude / reference echo','Constant phase (deg)', ...
        'Linear phase across readout FOV (deg)'};
    for j = 1:3
        ax = nexttile(layout); hold(ax,'on');
        for slice = reshape(slices,1,[])
            rows = metrics.Slice == slice;
            [~,order] = sort(metrics.Echo(rows));
            values = metrics.(fields{j}); values = values(rows);
            plot(ax,echoes,values(order),'-o','LineWidth',1.2,'MarkerSize',3, ...
                'DisplayName',sprintf('SLC %d',slice));
        end
        grid(ax,'on'); ylabel(ax,labels{j}); xlim(ax,[min(echoes) max(echoes)]);
        if j == 1, legend(ax,'Location','best'); end
        if j == 3, xlabel(ax,'Echo / SEG'); end
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
