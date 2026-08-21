function [fig] = plot_PEMode(PElabel, nRO, nPE, nEcho)
    % [nEcho, nExcit]
    im_PEOrder = zeros(nRO, nPE);
    for iecho = 1:nEcho
        for iexcit = 1:1
            im_PEOrder(:, PElabel(iecho, iexcit) + 1) = nEcho - iecho+5;
        end
    end
    cmap = gray(nEcho+5);
    fig = figure;
    set(gcf,'position',[0 0 nRO nPE]);
    imshow(im_PEOrder');      % 显示矩阵
    impixelinfo;
    colormap(cmap);           % 选择颜色映射
    clim([1, nEcho+5]);       % 设置颜色范围
    axis off;
end

   