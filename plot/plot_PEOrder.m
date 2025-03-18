function [] = plot_PEOrder(PElabel, nX, nY, nExcit, nEcho)
    % [nEcho, nExcit]
    im_PEOrder = zeros(nX, nY);
    for iecho = 1:nEcho
        for iexcit = 1:nExcit
            im_PEOrder(:, PElabel(iecho, iexcit) + 1) = iecho;
        end
    end
    cmap = jet(nEcho);
    figure;
    imshow(im_PEOrder');      % 显示矩阵
    impixelinfo;
    colormap(cmap);          % 选择颜色映射
    clim([1, nEcho]);       % 设置颜色范围
    cb = colorbar;   
    cb.Ticks = (2*(1:nEcho)-1)*(nEcho-1)/2/nEcho+1; 
    cb.TickLabels = 1:nEcho;         
    cb.TickLength = 0;
    

end