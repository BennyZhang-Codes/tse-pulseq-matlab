function [fig] = plot_PEMode2(PElabel, nY, nEcho)
    % [nEcho, nExcit]
    cmap = gray(nEcho+5);
    fig = figure;
    set(gcf, 'Position', [100, 100, 500, 500])
    for iecho = 1:nEcho
        for iexcit = 1:1
            % im_PEOrder(:, PElabel(iecho, iexcit) + 1) = nEcho - iecho+5;
            plot([0, 3], [PElabel(iecho, iexcit) + 1, PElabel(iecho, iexcit) + 1], ...
                Color=cmap( nEcho - iecho+5,:), LineWidth=8)
            hold on;
        end
    end
    ylim([-10, nY+10])
    xlim([1, 2])
    axis off;
    ax = gca;
    ax.Position = [0 0 1 1];      
    ax.LooseInset = [0 0 0 0]; 
    set(fig, 'Color', 'none');  
    set(fig, 'InvertHardcopy', 'off');  
end

