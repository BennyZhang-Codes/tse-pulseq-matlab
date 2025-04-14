function check_Label(seq)
    %% evaluate label settings more specifically
    lbls=seq.evalLabels('evolution','adc');
    lbl_names=fieldnames(lbls);
    figure; hold on;
    for n=1:length(lbl_names)
        plot(lbls.(lbl_names{n}));
    end
    legend(lbl_names(:));
    title('evolution of labels/counters/flags');
    xlabel('adc number');
end
