function [fig] = plot_PE(pe_steps, nX, nY, nEcho)
    nExcit   = floor(nY / nEcho);
    pe_full = (1:(nEcho * nExcit)) - 0.5 * nEcho * nExcit - 1;

    im_PEOrder = zeros(nX, nY);
    for idx = 1:length(pe_steps)
        im_PEOrder(:, pe_full==pe_steps(idx)) = 1;
    end

    cmap = gray(2);
    fig = figure;
    imshow(im_PEOrder');      
    impixelinfo;
    colormap(cmap);          
    clim([0, 2]);
    cb = colorbar;   
    cb.Ticks = [0.5, 1.5]; 
    cb.TickLabels = ["un-Acq", "Acq"];         
    cb.TickLength = 0;
end