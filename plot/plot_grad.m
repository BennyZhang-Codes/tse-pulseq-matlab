function [fig] = plot_grad(g)
    fig = figure;
    subplot(1,2,1); plot(g.tt, g.waveform);
    subplot(1,2,2); plot(g.tt(2:end), g.waveform(2:end) - g.waveform(1:end-1));
end

