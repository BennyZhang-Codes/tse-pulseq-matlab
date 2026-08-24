function files = create_TSE2D_CS_comparison_figure(comparisons,summary,outputDir,varargin)
%CREATE_TSE2D_CS_COMPARISON_FIGURE Publication-style CS versus full TSE figure.

    p = inputParser;
    p.addParameter('SliceIndex',3,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 1 && mod(x,1) == 0);
    p.addParameter('Prefix','CS_vs_full_TSE_figure', ...
        @(x) ischar(x) || isstring(x));
    p.addParameter('DPI',600,@(x) isnumeric(x) && isscalar(x) && ...
        isfinite(x) && x >= 72);
    p.addParameter('ErrorPercentile',99.5,@(x) isnumeric(x) && ...
        isscalar(x) && isfinite(x) && x > 50 && x <= 100);
    p.parse(varargin{:});
    opt = p.Results;

    if ~iscell(comparisons) || isempty(comparisons)
        error('create_TSE2D_CS_comparison_figure:InvalidComparisons', ...
            'COMPARISONS must be a nonempty cell array.');
    end
    if height(summary) ~= numel(comparisons)
        error('create_TSE2D_CS_comparison_figure:SummarySize', ...
            'SUMMARY must contain one row per comparison.');
    end
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    slice = opt.SliceIndex;
    reference = double(comparisons{1}.referenceNormalized(:,:,slice));
    mask = comparisons{1}.mask(:,:,slice);
    [rows,columns] = cropFromMask(mask,8);
    reference = reference(rows,columns);
    imageLimit = percentile(reference(mask(rows,columns)),99.7);

    allErrors = [];
    for q = 1:numel(comparisons)
        errorImage = double(comparisons{q}.absoluteError(:,:,slice));
        errorMask = comparisons{q}.mask(:,:,slice);
        allErrors = [allErrors; errorImage(errorMask)]; %#ok<AGROW>
    end
    errorLimit = percentile(allErrors,opt.ErrorPercentile);
    errorLimit = max(errorLimit,0.01);

    nRow = numel(comparisons);
    figureHandle = figure('Visible','off','Color','w','Units','inches', ...
        'Position',[0.5 0.5 7.2 2.05*nRow]);
    layout = tiledlayout(figureHandle,nRow,3,'Padding','compact', ...
        'TileSpacing','compact');
    letters = char('a'+(0:3*nRow-1));
    errorAxis = gobjects(1);
    for q = 1:nRow
        images = {reference, ...
            double(comparisons{q}.reconstructedAligned(rows,columns,slice)), ...
            double(comparisons{q}.absoluteError(rows,columns,slice))};
        for column = 1:3
            axisHandle = nexttile(layout);
            if column < 3
                imagesc(axisHandle,images{column},[0 imageLimit]);
                colormap(axisHandle,gray(256));
            else
                imagesc(axisHandle,100*images{column},[0 100*errorLimit]);
                colormap(axisHandle,turbo(256));
                errorAxis = axisHandle;
            end
            axis(axisHandle,'image','off');
            text(axisHandle,0.02,0.97,sprintf('(%c)',letters((q-1)*3+column)), ...
                'Units','normalized','Color','w','FontName','Arial', ...
                'FontSize',9,'FontWeight','bold','VerticalAlignment','top');
            if q == 1
                headings = {'Fully sampled TSE (R=1)', ...
                    'CS reconstruction','Absolute error'};
                title(axisHandle,headings{column},'FontName','Arial', ...
                    'FontSize',10,'FontWeight','bold');
            end
            if column == 1
                text(axisHandle,-0.06,0.5,sprintf('R = %d',summary.R(q)), ...
                    'Units','normalized','HorizontalAlignment','right', ...
                    'VerticalAlignment','middle','FontName','Arial', ...
                    'FontSize',10,'FontWeight','bold','Color','k');
            elseif column == 2
                label = sprintf('NRMSE %.2f%%   SSIM %.3f', ...
                    100*summary.NRMSE(q),summary.SSIM(q));
                text(axisHandle,0.5,0.025,label,'Units','normalized', ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom', ...
                    'FontName','Arial','FontSize',8,'FontWeight','bold', ...
                    'Color','w','BackgroundColor',[0 0 0],'Margin',2);
            end
        end
    end
    colorbarHandle = colorbar(errorAxis,'eastoutside');
    colorbarHandle.Label.String = '|CS - reference| (% of reference signal)';
    colorbarHandle.Label.FontName = 'Arial';
    colorbarHandle.FontName = 'Arial';
    title(layout,sprintf(['2-D TSE compressed-sensing reconstruction ' ...
        '(TV = %.4g, wavelet = %.4g)'],summary.TVWeight(1), ...
        summary.WaveletWeight(1)),'FontName','Arial','FontSize',11, ...
        'FontWeight','bold');

    prefix = char(string(opt.Prefix));
    files = struct();
    files.png = string(fullfile(outputDir,[prefix '_600dpi.png']));
    files.tiff = string(fullfile(outputDir,[prefix '_600dpi.tif']));
    files.pdf = string(fullfile(outputDir,[prefix '.pdf']));
    exportgraphics(figureHandle,files.png,'Resolution',opt.DPI, ...
        'BackgroundColor','white');
    exportgraphics(figureHandle,files.tiff,'Resolution',opt.DPI, ...
        'BackgroundColor','white');
    exportgraphics(figureHandle,files.pdf,'ContentType','vector', ...
        'BackgroundColor','white');
    close(figureHandle);
end

function [rows,columns] = cropFromMask(mask,margin)
    [rowIndex,columnIndex] = find(mask);
    if isempty(rowIndex)
        rows = 1:size(mask,1);
        columns = 1:size(mask,2);
        return
    end
    rows = max(1,min(rowIndex)-margin):min(size(mask,1),max(rowIndex)+margin);
    columns = max(1,min(columnIndex)-margin): ...
        min(size(mask,2),max(columnIndex)+margin);
end

function value = percentile(values,percent)
    values = sort(double(values(isfinite(values))));
    if isempty(values)
        value = NaN;
        return
    end
    index = 1+(numel(values)-1)*percent/100;
    lower = floor(index);
    upper = ceil(index);
    if lower == upper
        value = values(lower);
    else
        value = values(lower)+(index-lower)*(values(upper)-values(lower));
    end
end
