function [fig] = plot_PEOrder(R, nX, nY, PElabel)
    [nEcho, nExcit] = size(PElabel);
    im_PEOrder = zeros(nX, nY);
    for iecho = 1:nEcho
        for iexcit = 1:nExcit
            im_PEOrder(:, PElabel(iecho, iexcit) + 1) = nEcho - iecho+2;
        end
    end
    cmap = jet(nEcho+1);
    cmap(1,:) = [0,0,0];
    fig = figure;
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
    set(fig, 'Color', '#1F1F1F');  
    set(fig, 'InvertHardcopy', 'off');  
end