function [seq] = prep_Seqloop(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
    tStart_loop = tic();
    MinTRActual = 0 ;

    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ; 
    SignCorr = Actual.SignCorr ; 

    PhaseCorrection = Actual.PhaseCorrection;

    TR             = Actual.TR;
    nRep           = Actual.nRep;
    nSlice         = Actual.nSlice;
    nEcho          = Actual.nEcho;
    nExcit         = Actual.nExcit;
    nDummy         = Actual.nDummy;

    SlicePositions = Actual.Slice.SlicePositions;
    SliceLabel     = Actual.Slice.SliceLabel;
    phaseAreas     = Actual.PE3D.phaseAreas;
    PElabel        = Actual.PE3D.PElabel;
    PEorder        = Actual.PE3D.PEorder;
    pe_Ref         = Actual.PE3D.pe_Ref;
    pe_ImgAndRef   = Actual.PE3D.pe_ImgAndRef;

    tSp            = Actual.tSp;

    phaseEx        = Actual.ActualRF.phaseEx;
    phaseRef       = Actual.ActualRF.phaseRef;

    rfEx           = RF.rfEx;
    rfRef          = RF.rfRef;
    amplitudeEx    = Grad.amplitudeEx;
    amplitudeRef   = Grad.amplitudeRef;

    GS_Ex          = Grad.GS_Ex;
    GS_Ref1        = Grad.GS_Ref1;
    GS_Ref         = Grad.GS_Ref;

    GS_RefCrusherL = Grad.GS_RefCrusherL;
    GS_RefCrusherR = Grad.GS_RefCrusherR;
    GS_RefFlat     = Grad.GS_RefFlat;
    GS_EndSpoil    = Grad.GS_EndSpoil;
    
    GRpreL         = Grad.GRpreL;
    GRpreR         = Grad.GRpreR;
    GR_adc         = Grad.GR_adc;
    GR_SpoilPre    = Grad.GR_SpoilPre;
    GR_SpoilPost   = Grad.GR_SpoilPost;
    GR_Spoil       = Grad.GR_Spoil;

    tETrain        = Grad.tETrain;

    adc            = ADC.adc;

    lblSetRefScan            = Label.lblSetRefScan;
    lblSetRefAndImaScan      = Label.lblSetRefAndImaScan;
    lblResetRefScan          = Label.lblResetRefScan;
    lblResetRefAndImaScan    = Label.lblResetRefAndImaScan;


    % filltimes
    SliceTime  = RoundRaster(TR / nSlice, sys.gradRasterTime, 'down');


    % Next, the blocks are put together to form the sequence
    seq.addBlock(Label.lblResetREP);
    for irep = 1:nRep
        for iexcit = (1-nDummy):nExcit 
            % Reset duration of current TR
            TimeInTR = 0 ; % [s]

            seq.addBlock(Label.lblResetSLC);
            for isli = 1:nSlice
                % Reset duration of current Slice
                TimeInSlice = 0 ; % [s]

                rfEx.freqOffset   = amplitudeEx  * SlicePositions(isli);
                rfRef.freqOffset  = amplitudeRef * SlicePositions(isli);
                rfEx.phaseOffset  = phaseEx  - 2 * pi *  rfEx.freqOffset * mr.calcRfCenter(rfEx) ; % align the phase for off-center slices
                rfRef.phaseOffset = phaseRef - 2 * pi * rfRef.freqOffset * mr.calcRfCenter(rfRef); % dito
                               
                seq.addBlock(rfEx, GS_Ex, GRpreL);
                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
        
                seq.addBlock(Label.lblResetSEG);
                for iseg = 1:nEcho
                    if (iexcit > 0)
                        phaseArea      = phaseAreas(iseg  , iexcit);
                        if iseg < nEcho
                            phaseArea_next = phaseAreas(iseg+1, iexcit);
                        end
                        seq.addBlock(mr.makeLabel('SET', 'LIN', PElabel(iseg, iexcit)));
                        
                        if ismember(PEorder(iseg, iexcit), pe_Ref)
                            seq.addBlock(lblResetRefAndImaScan, lblSetRefScan) ;
                        elseif ismember(PEorder(iseg, iexcit),pe_ImgAndRef)
                            seq.addBlock(lblSetRefAndImaScan, lblSetRefScan) ;
                        else
                            seq.addBlock(lblResetRefAndImaScan, lblResetRefScan) ;
                        end
                    else
                        [isegCenter, iexcitCenter] = find(PElabel == Actual.PE3D.kSpaceCenterLine);
                        phaseArea      = phaseAreas(isegCenter, iexcitCenter);
                        phaseArea_next = 0;

                        seq.addBlock(mr.makeLabel('SET', 'LIN', PElabel(isegCenter, iexcitCenter)));
                        
                        if ismember(PEorder(isegCenter, iexcitCenter), pe_Ref)
                            seq.addBlock(lblResetRefAndImaScan, lblSetRefScan) ;
                        elseif ismember(PEorder(isegCenter, iexcitCenter),pe_ImgAndRef)
                            seq.addBlock(lblSetRefAndImaScan, lblSetRefScan) ;
                        else
                            seq.addBlock(lblResetRefAndImaScan, lblResetRefScan) ;
                        end
                    end
                    GPpre      = mr.makeTrapezoid(AxisPE, sys, 'Area',  phaseArea     , 'Duration', tSp, 'riseTime', 200e-6);
                    GPrew      = mr.makeTrapezoid(AxisPE, sys, 'Area', -phaseArea     , 'Duration', tSp, 'riseTime', 200e-6);
                    GPpre_next = mr.makeTrapezoid(AxisPE, sys, 'Area',  phaseArea_next, 'Duration', tSp, 'riseTime', 200e-6);
                    GPpre_next.delay = rfRef.shape_dur;
                    GP         = concatGrads({GPrew, GPpre_next}, sys);

                    if iseg == 1
                        rfRef.delay = mr.calcDuration(GS_Ref1) - tSp - rfRef.shape_dur;
                        GPpre.delay = mr.calcDuration(GS_Ref1) - tSp;
                        seq.addBlock(rfRef, GRpreR, GPpre, GS_Ref1);

                        rfRef.delay = mr.calcDuration(GS_RefCrusherL);

                        if iexcit > 0
                            seq.addBlock(GR_adc, adc);
                            TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                            TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                        else
                            if strcmpi(PhaseCorrection, 'on')
                                seq.addBlock(GR_adc, adc, Label.lblSetNAV);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            else
                                seq.addBlock(GR_adc);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            end
                        end

                        seq.addBlock(rfRef, GR_Spoil, GP, GS_Ref, Label.lblResetNAV);
                        TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                        TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                    else
                        if iexcit > 0
                            seq.addBlock(GR_adc, adc);
                            TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                            TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                        else
                            if strcmpi(PhaseCorrection, 'on')
                                seq.addBlock(GR_adc, adc, Label.lblSetNAV);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            else
                                seq.addBlock(GR_adc);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            end
                        end
                        if iseg == nEcho
                            seq.addBlock(GR_SpoilPost, GPrew, GS_EndSpoil, Label.lblResetNAV);
                        else
                            seq.addBlock(rfRef, GR_Spoil, GP, GS_Ref, Label.lblResetNAV);
                        end
                        TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                        TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                    end
                    seq.addBlock(Label.lblIncSEG1);
                end
                % -----------------------------------------------------------------------
                % SliceTime fill block
                % -----------------------------------------------------------------------
                SliceTRFill = RoundRaster(SliceTime - TimeInSlice, sys.gradRasterTime, 'down'); % Set filler delay to achieve requested TR (rounded up later)
               
                % Sanity check
                if (SliceTRFill < -eps(0))
                    error('Total time (%f ms) of blocks within current Slice (#%d) is longer than desired TR/nSlice (%f ms)!', 1e3*TimeInSlice, isli, 1e3*SliceTime);
                end

                Delay.Delay_SliceTRFill.delay = SliceTRFill ; % update delay of eTRFill
                seq.addBlock(Delay.Delay_SliceTRFill)  ;  % Add delay to the sequence

                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                seq.addBlock(Label.lblIncSLC1);
            end
            % -----------------------------------------------------------------------
            % TR Fill block
            % -----------------------------------------------------------------------
            TRFill = RoundRaster(Actual.TR - TimeInTR, sys.gradRasterTime, 'round'); % Set filler delay to achieve requested TR (rounded up later)
           
            % Sanity check
            if (TRFill < -eps(0))
                error('Total time (%f ms) of blocks within current TR (#%d) is longer than desired TR (%f ms)!', 1e3*TimeInTR, iexcit, 1e3*Actual.TR);
            end

            Delay.Delay_TRFill.delay = TRFill ; % update delay of eTRFill
            seq.addBlock(Delay.Delay_TRFill)  ;  % Add delay to the sequence
            
            TimeInTR = TimeInTR + seq.blockDurations(end) ; % Update duration within TR
        end
        seq.addBlock(Label.lblIncREP1);
    end
    tStop_loop = toc(tStart_loop); fprintf('Total Loop Time >>> %.3f [s]\n', tStop_loop);
end
