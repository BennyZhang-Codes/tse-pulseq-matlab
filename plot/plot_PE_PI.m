function [fig] = plot_PE_PI(R, nX, nY, pe_Img, pe_Ref, pe_ImgAndRef, pe_full)

    im_PEOrder = zeros(nX, nY);
    for idx = 1:length(pe_Img)
        im_PEOrder(:, pe_full==pe_Img(idx)) = 1;
    end
    for idx = 1:length(pe_Ref)
        im_PEOrder(:, pe_full==pe_Ref(idx)) = 2;
    end
    for idx = 1:length(pe_ImgAndRef)
        im_PEOrder(:, pe_full==pe_ImgAndRef(idx)) = 3;
    end
    
    cmap = gray(4);
    fig = figure;
    imshow(im_PEOrder');      
    title(sprintf('R = %d, nAcq = %d, nRef = %d', R, length(pe_Img)+length(pe_Ref), ...
        length(pe_Ref)+length(pe_ImgAndRef)), 'FontWeight', 'bold', 'Color', 'r');

    % impixelinfo;
    colormap(cmap);          
    clim([0, 4]);
    cb = colorbar;   
    cb.Ticks = (1:(5-1))+0.5; 
    cb.TickLabels = ["Img", "Ref", "Img & Ref"];         
    cb.TickLength = 0;
    cb.Color = '#CCCCCC';             
    cb.FontSize = 10;  

    ax = gca;
    ax.Position = [0. 0.03 0.80 0.9];      
    ax.LooseInset = [0 0 0 0]; 
    set(fig, 'Color', '#1F1F1F');  
    set(fig, 'InvertHardcopy', 'off');  
end