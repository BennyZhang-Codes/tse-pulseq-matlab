function [seq] = prep_Seqloop(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
    tStart_loop = tic();
    MinTRActual = 0 ;

    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ; 
    SignCorr = Actual.SignCorr ; 

    SliceLabel     = Actual.Slice.SliceLabel;
    phaseAreas     = Actual.PE3D.phaseAreas;
    PElabel        = Actual.PE3D.PElabel;
    PEorder        = Actual.PE3D.PEorder;
    pe_Ref         = Actual.PE3D.pe_Ref;
    pe_ImgAndRef   = Actual.PE3D.pe_ImgAndRef;

    
    % filltimes
    SliceTime  = RoundRaster(Actual.TR / Actual.nSlice , sys.gradRasterTime, 'down');

    % Next, the blocks are put together to form the sequence
    seq.addBlock(Label.lblResetREP);
    for irep = 1:Actual.nRep
        for iexcit = (1-Actual.nDummy):Actual.nExcit 
            % Reset duration of current TR
            TimeInTR = 0 ; % [s]

            seq.addBlock(Label.lblResetSLC);
            for isli = 1:Actual.nSlice 
                % Reset duration of current Slice
                TimeInSlice = 0 ; % [s]

                RF.rfEx.freqOffset   = Grad.amplitudeEx  * Actual.Slice.SlicePositions(isli);
                RF.rfRef.freqOffset  = Grad.amplitudeRef * Actual.Slice.SlicePositions(isli);
                RF.rfEx.phaseOffset  = Actual.ActualRF.phaseEx  - 2 * pi *  RF.rfEx.freqOffset * mr.calcRfCenter(RF.rfEx) ; % align the phase for off-center slices
                RF.rfRef.phaseOffset = Actual.ActualRF.phaseRef - 2 * pi * RF.rfRef.freqOffset * mr.calcRfCenter(RF.rfRef); % dito
                               
                seq.addBlock(RF.rfEx, Grad.G3D_Ex, Grad.GRO_preL);
                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
        
                seq.addBlock(Label.lblResetSEG);
                for iseg = 1:Actual.nEcho
                    if (iexcit > 0)
                        phaseArea      = phaseAreas(iseg  , iexcit);
                        if iseg < Actual.nEcho
                            phaseArea_next = phaseAreas(iseg+1, iexcit);
                        end
                        seq.addBlock(mr.makeLabel('SET', 'LIN', PElabel(iseg, iexcit)));
                        
                        if ismember(PEorder(iseg, iexcit), pe_Ref)
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblSetRefScan) ;
                        elseif ismember(PEorder(iseg, iexcit),pe_ImgAndRef)
                            seq.addBlock(Label.lblSetRefAndImaScan, Label.lblSetRefScan) ;
                        else
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblResetRefScan) ;
                        end
                    else
                        [isegCenter, iexcitCenter] = find(PElabel == Actual.PE3D.kSpaceCenterLine);
                        phaseArea      = phaseAreas(isegCenter, iexcitCenter);
                        phaseArea_next = 0;

                        seq.addBlock(mr.makeLabel('SET', 'LIN', PElabel(isegCenter, iexcitCenter)));
                        
                        if ismember(PEorder(isegCenter, iexcitCenter), pe_Ref)
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblSetRefScan) ;
                        elseif ismember(PEorder(isegCenter, iexcitCenter),pe_ImgAndRef)
                            seq.addBlock(Label.lblSetRefAndImaScan, Label.lblSetRefScan) ;
                        else
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblResetRefScan) ;
                        end
                    end
                    GPE_pre      = mr.makeTrapezoid(AxisPE, sys, 'Area',  phaseArea     , 'Duration', Actual.tSp, 'riseTime', 200e-6);
                    GPE_rew      = mr.makeTrapezoid(AxisPE, sys, 'Area', -phaseArea     , 'Duration', Actual.tSp, 'riseTime', 200e-6);
                    GPE_pre_next = mr.makeTrapezoid(AxisPE, sys, 'Area',  phaseArea_next, 'Duration', Actual.tSp, 'riseTime', 200e-6);
                    GPE_pre_next.delay = RF.rfRef.shape_dur;
                    GPE         = concatGrads({GPE_rew, GPE_pre_next}, sys);

                    if iseg == 1
                        RF.rfRef.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp - RF.rfRef.shape_dur;
                        GPE_pre.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp;
                        seq.addBlock(RF.rfRef, Grad.GRO_preR, GPE_pre, Grad.G3D_Ref1);

                        RF.rfRef.delay = mr.calcDuration(Grad.G3D_RefCrusherL);

                        if iexcit > 0
                            seq.addBlock(Grad.GRO_adc, ADC.adc);
                            TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                            TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                        else
                            if strcmpi(Actual.PhaseCorrection, 'on')
                                seq.addBlock(Grad.GRO_adc, ADC.adc, Label.lblSetNAV);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            else
                                seq.addBlock(Grad.GRO_adc);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            end
                        end

                        seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref, Label.lblResetNAV);
                        TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                        TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                    else
                        if iexcit > 0
                            seq.addBlock(Grad.GRO_adc, ADC.adc);
                            TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                            TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                        else
                            if strcmpi(Actual.PhaseCorrection, 'on')
                                seq.addBlock(Grad.GRO_adc, ADC.adc, Label.lblSetNAV);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            else
                                seq.addBlock(Grad.GRO_adc);
                                TimeInTR    = TimeInTR    + seq.blockDurations(end); % Update duration within TR
                                TimeInSlice = TimeInSlice + seq.blockDurations(end); % Update duration within Slice
                            end
                        end
                        if iseg == Actual.nEcho
                            seq.addBlock(Grad.GRO_SpoilPost, GPE_rew, Grad.G3D_EndSpoil, Label.lblResetNAV);
                        else
                            seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref, Label.lblResetNAV);
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
