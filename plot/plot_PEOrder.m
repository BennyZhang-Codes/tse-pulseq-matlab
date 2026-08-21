function [fig] = plot_PEOrder(R, nRO, nPE, PE3DLabel)
    color_facecolor = "#FFFFFF";
    color_label     = "#CCCCCC";
    fig_width       = 800;
    fig_height      = 800;
    position = [(1920-fig_width)/2, (1080-fig_height)/2, fig_width, fig_height];

    fig_width_cm  = 10;
    fig_height_cm = 6;
    position_cm   = [5, 5, fig_width_cm, fig_height_cm];  % 显示位置

    figname = 'PE Order';
    fig = figure('Name', figname, 'Position', position, 'Color', color_facecolor);
    % fig = figure('Name', figname, ...
    %              'Units', 'centimeters', ...
    %              'Position', position_cm, ...
    %              'Color', color_facecolor);

    [nEcho, nExcit] = size(PE3DLabel);
    im_PEOrder = zeros(nRO, nPE);
    for iecho = 1:nEcho
        for iexcit = 1:nExcit
            im_PEOrder(:, PE3DLabel(iecho, iexcit) + 1) = nEcho - iecho+2;
        end
    end
    cmap = jet(nEcho+1);
    cmap(1,:) = [0,0,0];
    imshow(im_PEOrder');      % 显示矩阵

    title(sprintf('R = %d, nEcho = %d, nExcit = %d', R, nEcho, nExcit), 'FontWeight', 'bold', 'Color', 'r');

    % impixelinfo;
    colormap(cmap);          % 选择颜色映射
    clim([1, nEcho+1]);       % 设置颜色范围
    cb = colorbar;   
    cb.Ticks = (2*(1:nEcho)-1)*(nEcho-1)/2/nEcho+2; 
    cb.TickLabels = sort(1:nEcho, 'descend');         
    cb.TickLength = 0;

    % 设置 colorbar 样式
    cb.Box = 'on';              
    cb.EdgeColor = 'r';          
    cb.Label.String = 'Echo'; 
    cb.Label.Color = 'r';       
    cb.Color = '#CCCCCC';             
    cb.FontSize = 10;           


    ax = gca;
    ax.Position = [0. 0.03 0.85 0.9];      
    ax.LooseInset = [0 0 0 0]; 
    set(fig, 'Color', '#000000');  
    set(fig, 'InvertHardcopy', 'off');  
    set(fig, 'PaperUnits', 'centimeters');
    set(fig, 'PaperPosition', [0, 0, fig_width_cm, fig_height_cm]);
end