function [fig] = plot_PEMode(PElabel, nX, nY, nExcit, nEcho)
    % [nEcho, nExcit]
    im_PEOrder = zeros(nX, nY);
    for iecho = 1:nEcho
        for iexcit = 1:1
            im_PEOrder(:, PElabel(iecho, iexcit) + 1) = nEcho - iecho+5;
        end
    end
    cmap = gray(nEcho+5);
    fig = figure;
    set(gcf,'position',[0 0 nX nY]);
    imshow(im_PEOrder');      % 显示矩阵
    impixelinfo;
    colormap(cmap);           % 选择颜色映射
    clim([1, nEcho+5]);       % 设置颜色范围
    axis off;
end

   