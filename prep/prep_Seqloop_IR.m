function [seq] = prep_Seqloop_IR(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
    tStart_loop = tic();

    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ;
    SignCorr = Actual.SignCorr ;
    SliceLabel     = Actual.Slice.SliceLabel;

    PE3D         = Actual.PE3D;
    pe_Ref       = Actual.PE3D.pe_Ref;
    pe_ImgAndRef = Actual.PE3D.pe_ImgAndRef;


    delayEtrain = mr.makeDelay(Grad.tETrain);

    switch lower(Actual.IRMode)
        case 'interleaved'
            fprintf('# IR-TSE >>> Interleaved mode\n');
            nSlice_even    = sum( mod(SliceLabel, 2) == 0);
            nSlice_odd     = sum( mod(SliceLabel, 2) == 1);
            SliceIdx_even  = find(mod(SliceLabel, 2) == 0);
            SliceIdx_odd   = find(mod(SliceLabel, 2) ~= 0);

            TIfill  = Actual.TI - mr.calcDuration(Grad.G3D_Inv)/2 - mr.calcDuration(Grad.G3D_ExSpoilPre) - mr.calcDuration(Grad.G3D_ExFlat)/2;
            TIfill  = RoundRaster(TIfill, sys.gradRasterTime, 'round');

            TRfill = Actual.TR - (TIfill*2 + Actual.nSlice * (Grad.tETrain + mr.calcDuration(Grad.G3D_Inv)));


            assert(TRfill >= 0, 'TRfill [%f ms] must be >= 0 ms, please increase Actual.TR or adjust other parameters', ...
                TRfill*1e3);

            fill_per_slice = RoundRaster(TRfill/Actual.nSlice, sys.gradRasterTime, 'round');  % delay between slices
            delayTI_slice = mr.makeDelay(fill_per_slice);
            delayETrain   = mr.makeDelay(fill_per_slice+mr.calcDuration(Grad.G3D_Inv));

            TIfill_end_even = TIfill - (nSlice_even-1) * (Grad.tETrain + mr.calcDuration(Grad.G3D_Inv)) - nSlice_even * fill_per_slice;
            TIfill_end_even = RoundRaster(TIfill_end_even, sys.gradRasterTime, 'down');

            TIfill_end_odd  = TIfill - (nSlice_odd -1) * (Grad.tETrain + mr.calcDuration(Grad.G3D_Inv)) - nSlice_odd * fill_per_slice;
            TIfill_end_odd  = RoundRaster(TIfill_end_odd, sys.gradRasterTime, 'down');

            assert(TIfill_end_even >= 0, 'TIfill_end_even [%f ms] must be >= 0 ms, please increase Actual.TI or adjust other parameters', ...
                TIfill_end_even*1e3);

            delayTIfill_end_even = mr.makeDelay(TIfill_end_even);
            delayTIfill_end_odd  = mr.makeDelay(TIfill_end_odd);

            % compensate for accurate Actual.TR
            TRfill_end = Actual.TR - Actual.nSlice * (Grad.tETrain + fill_per_slice + mr.calcDuration(Grad.G3D_Inv)) - 2*TIfill - 2* mr.calcDuration(Grad.G3D_Inv);
            TRfill_end = RoundRaster(TRfill_end, sys.gradRasterTime, 'round');

            disp(strcat('TRfill : ',num2str(1000*TRfill),' ms'));
            disp(strcat('TIfill_slice_even : ',num2str(1e3*TIfill_end_even),' ms'));
            disp(strcat('TIfill_slice_odd  : ',num2str(1e3*TIfill_end_odd),' ms'));
        case 'sequential'
            fprintf('# IR-TSE >>> Sequential mode\n');
            TIfill  = Actual.TI - mr.calcDuration(Grad.G3D_Inv)/2 - mr.calcDuration(Grad.G3D_ExSpoilPre) - mr.calcDuration(Grad.G3D_ExFlat)/2;
            TIfill  = RoundRaster(TIfill, sys.gradRasterTime, 'round');

            TRfill = Actual.TR - (TIfill + Actual.nSlice * (Grad.tETrain + mr.calcDuration(Grad.G3D_Inv)));

            assert(TIfill/Actual.nSlice >= Grad.tETrain, 'Actual.TI is too small to support %d slices in Sequential mode!', Actual.nSlice);
            assert(TRfill >= 0, 'TRfill [%f ms] must be >= 0 ms, please increase Actual.TR or adjust other parameters', ...
                TRfill*1e3);


            fill_per_slice  = (min(TIfill-Grad.tETrain*(Actual.nSlice-1), TRfill) - (Actual.nSlice-1)* mr.calcDuration(Grad.G3D_Inv))/(Actual.nSlice);
            fill_per_slice  = RoundRaster(fill_per_slice, sys.gradRasterTime, 'down');

            delayTI_slice = mr.makeDelay(fill_per_slice);

            TIfill_end = TIfill - (Actual.nSlice-1) * (Grad.tETrain + mr.calcDuration(Grad.G3D_Inv)) - Actual.nSlice * fill_per_slice;
            TIfill_end = RoundRaster(TIfill_end, sys.gradRasterTime, 'down');
            delayTIfill_end = mr.makeDelay(TIfill_end);

            delayETrain = mr.makeDelay(fill_per_slice+mr.calcDuration(Grad.G3D_Inv));

            TRfill_end = Actual.TR - Actual.nSlice * (Grad.tETrain + fill_per_slice+mr.calcDuration(Grad.G3D_Inv)) - TIfill - mr.calcDuration(Grad.G3D_Inv);
            TRfill_end = RoundRaster(TRfill_end, sys.gradRasterTime, 'round');
        otherwise
            error('invalid Actual.IRMode %s', Actual.IRMode);
    end



    function addInversionBlock(isli, Actual.nSlice)
        RF.rfInv.freqOffset  = Grad.amplitudeInv * Actual.Slice.SlicePositions(isli);
        RF.rfInv.phaseOffset = Actual.ActualRF.phaseInv - 2 * pi * RF.rfInv.freqOffset * mr.calcRfCenter(RF.rfInv); % dito
        seq.addBlock(Grad.G3D_Inv, RF.rfInv);
        seq.addBlock(delayTI_slice);
        if idx < Actual.nSlice
            seq.addBlock(delayEtrain)
        end
    end


    function addReadoutBlock(isli, Actual.nSlice, TRfill_end, delayETrain)
        RF.rfEx.freqOffset   = Grad.amplitudeEx  * Actual.Slice.SlicePositions(isli);
        RF.rfRef.freqOffset  = Grad.amplitudeRef * Actual.Slice.SlicePositions(isli);
        RF.rfEx.phaseOffset  = Actual.ActualRF.phaseEx  - 2 * pi *  RF.rfEx.freqOffset * mr.calcRfCenter(RF.rfEx) ; % align the phase for off-center slices
        RF.rfRef.phaseOffset = Actual.ActualRF.phaseRef - 2 * pi * RF.rfRef.freqOffset * mr.calcRfCenter(RF.rfRef); % dito

        seq.addBlock(RF.rfEx, Grad.G3D_Ex, Grad.GRO_preL);

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
                RF.rfRef.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp - RF.rfRef.shape_dur;
                GPE_pre.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp;
                seq.addBlock(RF.rfRef, Grad.GRO_preR, GPE_pre, Grad.G3D_Ref1);

                RF.rfRef.delay = mr.calcDuration(Grad.G3D_RefCrusherL);

                if TRCounter > 0
                    seq.addBlock(Grad.GRO_adc, ADC.adc);

                else
                   if strcmpi(Actual.PhaseCorrection, 'on')
                        seq.addBlock(Label.lblSetNAV);
                        seq.addBlock(Grad.GRO_adc, ADC.adc);
                        seq.addBlock(Label.lblResetNAV);
                    else
                        seq.addBlock(Grad.GRO_adc);
                    end
                end
                seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref);
            else
                if TRCounter > 0
                    seq.addBlock(Grad.GRO_adc, ADC.adc);
                else
                   if strcmpi(Actual.PhaseCorrection, 'on')
                        seq.addBlock(Label.lblSetNAV);
                        seq.addBlock(Grad.GRO_adc, ADC.adc);
                        seq.addBlock(Label.lblResetNAV);
                    else
                        seq.addBlock(Grad.GRO_adc);
                    end
                end
                if iseg == Actual.nEcho
                    seq.addBlock(Grad.GRO_SpoilPost, GPE_rew, Grad.G3D_EndSpoil);
                else
                    seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref);
                end
            end
            seq.addBlock(Label.lblIncSEG1);
        end
        if idx == Actual.nSlice
            seq.addBlock(mr.makeDelay(delayETrain.delay + TRfill_end));
        else
            seq.addBlock(delayETrain);
        end
        seq.addBlock(Label.lblIncSLC1);
    end


    % Next, the blocks are put together to form the sequence
    seq.addBlock(Label.lblResetREP);
    for irep = 1:Actual.nRep
        TRStart = -Actual.nDummy+1;
        for TRCounter = TRStart:Actual.nExcit
            seq.addBlock(Label.lblResetSLC);
            switch lower(Actual.IRMode)
                case 'interleaved'
                    for idx = 1:nSlice_even
                        isli = SliceIdx_even(idx);
                        addInversionBlock(isli, nSlice_even);
                    end
                    seq.addBlock(delayTIfill_end_even);
                    for idx = 1:nSlice_even
                        isli = SliceIdx_even(idx);
                        addReadoutBlock(isli, nSlice_even, 0, delayETrain);
                    end

                    for idx = 1:nSlice_odd
                        isli = SliceIdx_odd(idx);
                        addInversionBlock(isli, nSlice_odd);
                    end
                    seq.addBlock(delayTIfill_end_odd);
                    for idx = 1:nSlice_odd
                        isli = SliceIdx_odd(idx);
                        addReadoutBlock(isli, nSlice_odd, TRfill_end, delayETrain);
                    end
                case 'sequential'
                    for idx = 1:Actual.nSlice
                        isli = idx;
                        addInversionBlock(isli, Actual.nSlice);
                    end
                    seq.addBlock(delayTIfill_end);
                    for idx = 1:Actual.nSlice
                        isli = idx;
                        addReadoutBlock(isli, Actual.nSlice, TRfill_end, delayETrain);
                    end
            end
        end
        seq.addBlock(Label.lblIncREP1);
    end
    tStop_loop = toc(tStart_loop); fprintf('prep Seqloop IR >>> Total Time: %.3f [s]\n', tStop_loop);
end