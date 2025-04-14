function [fig] = plot_kspace(ktraj, ktraj_adc)
    color_facecolor = "#1F1F1F";
    color_label     = "#CCCCCC";
    font_label      = "Times New Roman";

    fig_width       = 800;
    fig_height      = 800;
    position = [(1920-fig_width)/2, (1080-fig_height)/2, fig_width, fig_height];

    % color_traj      = '#999999';
    % color_adc       = '#444444';

    color_traj      = '#1d6996';
    color_adc       = '#a85144';

    % color_traj      = '#636EFA';
    % color_adc       = '#EF553B';

    figname = '2D k-space';
    fig = figure('Name', figname, 'Position', position, 'Color', color_facecolor);
    subplot(1,1,1, 'color', color_facecolor, 'xcolor', color_label, 'ycolor', color_label, 'fontname', font_label), hold on;

    plot(ktraj(1,:),ktraj(2,:), 'color', color_traj); % a 2D plot
    hold on;plot(ktraj_adc(1,:),ktraj_adc(2,:), '.', 'MarkerSize', 5, 'MarkerEdgeColor', color_adc); 
    axis equal;

    % title('2D k-space', 'Color', color_label, 'fontname', font_label);
    % axis off;

    ax = gca;
    ax.Position = [0.05 0.05 0.95 0.95];      
    ax.LooseInset = [0 0 0 0]; 
    set(fig, 'Color', '#1F1F1F');  
    set(fig, 'InvertHardcopy', 'off');  
    
end

