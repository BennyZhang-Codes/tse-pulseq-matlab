function [seq, Label] = prep_Kernel(seq, params, ADC)
    NoiseScan  = params.NoiseScan;
    adc        = ADC.adc;


    %% Define sequence blocks
    % Set PAT scan flag
    lblSetRefScan            = mr.makeLabel('SET','REF', true );
    lblSetRefAndImaScan      = mr.makeLabel('SET','IMA', true );
    lblResetRefScan          = mr.makeLabel('SET','REF', false);
    lblResetRefAndImaScan    = mr.makeLabel('SET','IMA', false);
    lblSetRefScan.id         = seq.registerLabelEvent(lblSetRefScan        );
    lblSetRefAndImaScan.id   = seq.registerLabelEvent(lblSetRefAndImaScan  );
    lblResetRefScan.id       = seq.registerLabelEvent(lblResetRefScan      );
    lblResetRefAndImaScan.id = seq.registerLabelEvent(lblResetRefAndImaScan);
    
    % Add noise scans.
    if strcmpi(NoiseScan, 'on')
        seq.addBlock(mr.makeLabel('SET', 'LIN', 0), mr.makeLabel('SET','SLC', 0));
        seq.addBlock(adc, mr.makeLabel('SET', 'NOISE', true), lblResetRefScan, lblResetRefAndImaScan);
        seq.addBlock(mr.makeLabel('SET', 'NOISE', false));
        seq.addBlock(mr.makeDelay(1 - mr.calcDuration(adc)));
    end


    Label.lblSetRefScan            = lblSetRefScan;
    Label.lblSetRefAndImaScan      = lblSetRefAndImaScan;
    Label.lblResetRefScan          = lblResetRefScan;
    Label.lblResetRefAndImaScan    = lblResetRefAndImaScan;
end
