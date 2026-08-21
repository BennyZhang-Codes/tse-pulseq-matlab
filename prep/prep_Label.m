function [seq, Label] = prep_Label(seq, Actual, Label)

    % =========================================================================
    % Flags
    % =========================================================================
    % Set PAT scan flag
    % Marks GRAPPA line which is used as reference (center of k-space).
    lblSetRefScan            = mr.makeLabel('SET','REF', true ); 
    lblSetRefAndImaScan      = mr.makeLabel('SET','IMA', true );
    lblResetRefScan          = mr.makeLabel('SET','REF', false);
    lblResetRefAndImaScan    = mr.makeLabel('SET','IMA', false);

    lblSetRefScan.id         = seq.registerLabelEvent(lblSetRefScan        );
    lblSetRefAndImaScan.id   = seq.registerLabelEvent(lblSetRefAndImaScan  );
    lblResetRefScan.id       = seq.registerLabelEvent(lblResetRefScan      );
    lblResetRefAndImaScan.id = seq.registerLabelEvent(lblResetRefAndImaScan);

    Label.lblSetRefScan            = lblSetRefScan        ;
    Label.lblSetRefAndImaScan      = lblSetRefAndImaScan  ;
    Label.lblResetRefScan          = lblResetRefScan      ;
    Label.lblResetRefAndImaScan    = lblResetRefAndImaScan;
    
    
    % Flags to mark if ADC should be time reversed. Used in bipolar acquisitions.
    lblSetREV          = mr.makeLabel('SET', 'REV', true );
    lblResetREV        = mr.makeLabel('SET', 'REV', false);

    lblSetREV.id       = seq.registerLabelEvent(lblSetREV  );
    lblResetREV.id     = seq.registerLabelEvent(lblResetREV);

    Label.lblSetREV    = lblSetREV  ;
    Label.lblResetREV  = lblResetREV;

    % Flags to mark the navigator lines (N/2 Ghost correction)
    lblSetNAV          = mr.makeLabel('SET', 'NAV', true );
    lblResetNAV        = mr.makeLabel('SET', 'NAV', false);

    lblSetNAV.id       = seq.registerLabelEvent(lblSetNAV  );
    lblResetNAV.id     = seq.registerLabelEvent(lblResetNAV);

    Label.lblSetNAV    = lblSetNAV  ;
    Label.lblResetNAV  = lblResetNAV;


    % =========================================================================
    % Counters
    % =========================================================================
    % For 'LIN'
    lblResetLIN   = mr.makeLabel('SET', 'LIN', 0);
    lblIncLIN0    = mr.makeLabel('INC', 'LIN', 0);
    lblIncLIN1    = mr.makeLabel('INC', 'LIN', 1);

    lblResetLIN.id = seq.registerLabelEvent(lblResetLIN);
    lblIncLIN0.id  = seq.registerLabelEvent(lblIncLIN0 );
    lblIncLIN1.id  = seq.registerLabelEvent(lblIncLIN1 );

    Label.lblResetLIN = lblResetLIN;
    Label.lblIncLIN0  = lblIncLIN0 ;
    Label.lblIncLIN1  = lblIncLIN1 ;

    % [uniqueLIN, ~, ic] = unique(PE3DLabel(:, 1));
    % nUniqueLIN = length(uniqueLIN);
    % uniqueLblSetLIN(nUniqueLIN) = mr.makeLabel('SET', 'LIN', uniqueLIN(end)) ; 
    % for iPE = 1:(nUniqueLIN-1)
    %     uniqueLblSetLIN(iPE) = mr.makeLabel('SET', 'LIN', uniqueLIN(iPE)) ;
    % end
    % for iPE = 1:nUniqueLIN
    %     uniqueLblSetLIN(iPE).id = seq.registerLabelEvent(uniqueLblSetLIN(iPE)) ;
    % end
    % Label.lblSetLIN = uniqueLblSetLIN(ic);


    % For 'PAR'
    lblResetPAR   = mr.makeLabel('SET', 'PAR', 0);
    lblIncPAR0    = mr.makeLabel('INC', 'PAR', 0);
    lblIncPAR1    = mr.makeLabel('INC', 'PAR', 1);

    lblResetPAR.id = seq.registerLabelEvent(lblResetPAR);
    lblIncPAR0.id  = seq.registerLabelEvent(lblIncPAR0 );
    lblIncPAR1.id  = seq.registerLabelEvent(lblIncPAR1 );

    Label.lblResetPAR = lblResetPAR;
    Label.lblIncPAR0  = lblIncPAR0 ;
    Label.lblIncPAR1  = lblIncPAR1 ;

    % [uniquePAR, ~, ic] = unique(PE3DLabel(:, 2));
    % nUniquePAR = length(uniquePAR);
    % uniqueLblSetPAR(nUniquePAR) = mr.makeLabel('SET', 'PAR', uniquePAR(end)) ; 
    % for i3D = 1:(nUniquePAR-1)
    %     uniqueLblSetPAR(i3D) = mr.makeLabel('SET', 'PAR', uniquePAR(i3D)) ;
    % end
    % for i3D = 1:nUniquePAR
    %     uniqueLblSetPAR(i3D).id = seq.registerLabelEvent(uniqueLblSetPAR(i3D)) ;
    % end
    % Label.lblSetPAR = uniqueLblSetPAR(ic);

    % For 'SLC'
    lblResetSLC   = mr.makeLabel('SET', 'SLC', 0);
    lblIncSLC0    = mr.makeLabel('INC', 'SLC', 0);
    lblIncSLC1    = mr.makeLabel('INC', 'SLC', 1);

    lblResetSLC.id = seq.registerLabelEvent(lblResetSLC);
    lblIncSLC0.id  = seq.registerLabelEvent(lblIncSLC0 );
    lblIncSLC1.id  = seq.registerLabelEvent(lblIncSLC1 );

    Label.lblResetSLC = lblResetSLC;
    Label.lblIncSLC0  = lblIncSLC0 ;
    Label.lblIncSLC1  = lblIncSLC1 ;

    % For 'SEG'
    lblResetSEG   = mr.makeLabel('SET', 'SEG', 0);
    lblIncSEG0    = mr.makeLabel('INC', 'SEG', 0);
    lblIncSEG1    = mr.makeLabel('INC', 'SEG', 1);

    lblResetSEG.id = seq.registerLabelEvent(lblResetSEG);
    lblIncSEG0.id  = seq.registerLabelEvent(lblIncSEG0 );
    lblIncSEG1.id  = seq.registerLabelEvent(lblIncSEG1 );

    Label.lblResetSEG = lblResetSEG;
    Label.lblIncSEG0  = lblIncSEG0 ;
    Label.lblIncSEG1  = lblIncSEG1 ;


    % For 'REP'
    lblResetREP   = mr.makeLabel('SET', 'REP', 0);
    lblIncREP0    = mr.makeLabel('INC', 'REP', 0);
    lblIncREP1    = mr.makeLabel('INC', 'REP', 1);

    lblResetREP.id = seq.registerLabelEvent(lblResetREP);
    lblIncREP0.id  = seq.registerLabelEvent(lblIncREP0 );
    lblIncREP1.id  = seq.registerLabelEvent(lblIncREP1 );

    Label.lblResetREP = lblResetREP;
    Label.lblIncREP0  = lblIncREP0 ;
    Label.lblIncREP1  = lblIncREP1 ;


    % For 'AVG'
    lblResetAVG   = mr.makeLabel('SET', 'AVG', 0);
    lblIncAVG0    = mr.makeLabel('INC', 'AVG', 0);
    lblIncAVG1    = mr.makeLabel('INC', 'AVG', 1);

    lblResetAVG.id = seq.registerLabelEvent(lblResetAVG);
    lblIncAVG0.id  = seq.registerLabelEvent(lblIncAVG0 );
    lblIncAVG1.id  = seq.registerLabelEvent(lblIncAVG1 );

    Label.lblResetAVG = lblResetAVG;
    Label.lblIncAVG0  = lblIncAVG0 ;
    Label.lblIncAVG1  = lblIncAVG1 ;



    % For 'ECO'
    lblResetECO   = mr.makeLabel('SET', 'ECO', 0);
    lblIncECO0    = mr.makeLabel('INC', 'ECO', 0);
    lblIncECO1    = mr.makeLabel('INC', 'ECO', 1);

    lblResetECO.id = seq.registerLabelEvent(lblResetECO);
    lblIncECO0.id  = seq.registerLabelEvent(lblIncECO0 );
    lblIncECO1.id  = seq.registerLabelEvent(lblIncECO1 );

    Label.lblResetECO = lblResetECO;
    Label.lblIncECO0  = lblIncECO0 ;
    Label.lblIncECO1  = lblIncECO1 ;

    % % Allocate memory first by creating the last echo label (probably not very important).
    % % set last echo in array (to initialize structure array)
    % lblSetECO(Actual.nTE) = mr.makeLabel('SET', 'ECO', Actual.nTE-1) ; 
    % % set all remaining echo labels
    % for iTE = 1:(Actual.nTE-1)
    %     lblSetECO(iTE) = mr.makeLabel('SET', 'ECO', iTE-1) ;
    % end
    % % Add IDs to all labels (done separately after previous for-loop because
    % % once one ID is set the output of mr.makeLabel no longer has the same
    % % structure as eLabelEchos(n) (does not contain the 'id' field).
    % for iTE = 1:Actual.nTE
    %     lblSetECO(iTE).id = seq.registerLabelEvent(lblSetECO(iTE)) ;
    % end
    % Label.lblSetECO = lblSetECO;

end
