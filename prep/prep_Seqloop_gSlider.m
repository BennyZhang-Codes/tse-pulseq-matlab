function [seq] = prep_Seqloop_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
    tStart_loop = tic();
    MinTRActual = 0 ;
    
    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ;
    SignCorr = Actual.SignCorr ;

    PE3D         = Actual.PE3D;
    pe_Ref       = Actual.PE3D.pe_Ref;
    pe_ImgAndRef = Actual.PE3D.pe_ImgAndRef;

    if strcmpi(Actual.TRAPS, 'on')
        faRef          = Actual.faRef;
    end


    % filltimes
    SliceTime  = RoundRaster(Actual.TR / Actual.nSlice , sys.gradRasterTime, 'down');

    % Next, the blocks are put together to form the sequence
    seq.addBlock(Label.lblResetREP);
    for irep = 1:Actual.nRep
        if strcmpi(Actual.ActualRF.typeEx, 'gslider')
            RF.rfEx.signal = RF.rfex_gSlider(irep).signal;
        end
        TRStart = -Actual.nDummy+1;
        for TRCounter = TRStart:Actual.nExcit
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
                    if (TRCounter > 0)
                        phaseArea      = PE3D.phaseAreas(iseg  , TRCounter);
                        if iseg < Actual.nEcho
                            phaseArea_next = PE3D.phaseAreas(iseg+1, TRCounter);
                        end
                        seq.addBlock(mr.makeLabel('SET', 'LIN', PE3D.PE3DLabel(iseg, TRCounter)));

                        if ismember(PE3D.PE3DOrder(iseg, TRCounter), pe_Ref)
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblSetRefScan) ;
                        elseif ismember(PE3D.PE3DOrder(iseg, TRCounter),pe_ImgAndRef)
                            seq.addBlock(Label.lblSetRefAndImaScan, Label.lblSetRefScan) ;
                        else
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblResetRefScan) ;
                        end
                    else
                        [isegCenter, TRCounterCenter] = find(PE3D.PE3DLabel == Actual.PE3D.kSpaceCenterLine);
                        phaseArea      = PE3D.phaseAreas(isegCenter, TRCounterCenter);
                        phaseArea_next = 0;

                        seq.addBlock(mr.makeLabel('SET', 'LIN', PE3D.PE3DLabel(isegCenter, TRCounterCenter)));

                        if ismember(PE3D.PE3DOrder(isegCenter, TRCounterCenter), pe_Ref)
                            seq.addBlock(Label.lblResetRefAndImaScan, Label.lblSetRefScan) ;
                        elseif ismember(PE3D.PE3DOrder(isegCenter, TRCounterCenter),pe_ImgAndRef)
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
                        if strcmpi(Actual.TRAPS, 'on')
                            RF.rfRef.signal = RF.rfenvelopeRef * faRef(1)/180;
                        end
                        RF.rfRef.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp - RF.rfRef.shape_dur;
                        GPE_pre.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp;
                        seq.addBlock(RF.rfRef, Grad.GRO_preR, GPE_pre, Grad.G3D_Ref1);

                        RF.rfRef.delay = mr.calcDuration(Grad.G3D_RefCrusherL);

                        if TRCounter > 0
                            seq.addBlock(Grad.GRO_adc, ADC.adc);
                        else
                            if strcmpi(Actual.PhaseCorrection, 'on')
                                seq.addBlock(Grad.GRO_adc, ADC.adc, Label.lblSetNAV);
                            else
                                seq.addBlock(Grad.GRO_adc);
                            end
                        end
                        if strcmpi(Actual.TRAPS, 'on')
                            RF.rfRef.signal = RF.rfenvelopeRef * faRef(2)/180;
                        end

                        seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref);
                   
                        TimeInTR    = TimeInTR    + sum(seq.blockDurations(end-3:end)); % Update duration within TR
                        TimeInSlice = TimeInSlice + sum(seq.blockDurations(end-3:end)); % Update duration within Slice
                    else
                        if TRCounter > 0
                            seq.addBlock(Grad.GRO_adc, ADC.adc);
                        else
                            if strcmpi(Actual.PhaseCorrection, 'on')
                                seq.addBlock(Grad.GRO_adc, ADC.adc, Label.lblSetNAV);
                            else
                                seq.addBlock(Grad.GRO_adc);
                            end
                        end
                        if iseg == Actual.nEcho
                            seq.addBlock(Grad.GRO_SpoilPost, GPE_rew, Grad.G3D_EndSpoil);
                        else
                            if strcmpi(Actual.TRAPS, 'on')
                                RF.rfRef.signal = RF.rfenvelopeRef * faRef(iseg+1)/180;
                            end
                            seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref);
                        end
                        TimeInTR    = TimeInTR    + sum(seq.blockDurations(end-2:end)); % Update duration within TR
                        TimeInSlice = TimeInSlice + sum(seq.blockDurations(end-2:end)); % Update duration within Slice
                    end

                    seq.addBlock(Label.lblIncSEG1);
                end
                % -----------------------------------------------------------------------
                % Update minimum possible TR (for information only)
                % -----------------------------------------------------------------------
                MinTRActual = max(MinTRActual, TimeInSlice * Actual.nSlice) ; % update minimum possible TR (before adding the TR fill time)

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
                error('Total time (%f ms) of blocks within current TR (#%d) is longer than desired TR (%f ms)!', 1e3*TimeInTR, TRCounter, 1e3*Actual.TR);
            end

            Delay.Delay_TRFill.delay = TRFill ; % update delay of eTRFill
            seq.addBlock(Delay.Delay_TRFill)  ;  % Add delay to the sequence
            TimeInTR = TimeInTR + seq.blockDurations(end) ; % Update duration within TR
        end
        seq.addBlock(Label.lblIncREP1);
    end
    tStop_loop = toc(tStart_loop); fprintf('prep Seqloop gSlider >>> Total Time: %.3f [s]\n', tStop_loop);
end