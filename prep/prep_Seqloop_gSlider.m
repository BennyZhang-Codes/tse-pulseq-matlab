function [seq] = prep_Seqloop_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ;
    SignCorr = Actual.SignCorr ;
    SliceLabel     = Actual.Slice.SliceLabel;
    phaseAreas     = Actual.PE3D.phaseAreas;
    PElabel        = Actual.PE3D.PElabel;
    PEorder        = Actual.PE3D.PEorder;
    pe_Ref         = Actual.PE3D.pe_Ref;
    pe_ImgAndRef   = Actual.PE3D.pe_ImgAndRef;

    if strcmpi(Actual.TRAPS, 'on')
        faRef          = Actual.faRef;
    end


    % filltimes
    TRfill  = RoundRaster((Actual.TR - Actual.nSlice * Grad.tETrain) / Actual.nSlice, sys.gradRasterTime, 'down');

    if TRfill<0, TRfill=1e-3;
        disp(strcat('Warning!!! Actual.TR too short, adapted to include all slices to : ',num2str(1000*Actual.nSlice*(Grad.tETrain+TRfill)),' ms'));
    else
        disp(strcat('TRfill : ',num2str(1000*TRfill),' ms'));
    end
    delayTR = mr.makeDelay(TRfill);

    % Next, the blocks are put together to form the sequence
    seq.addBlock(Label.lblResetREP);
    for irep = 1:Actual.nRep
        if strcmpi(Actual.ActualRF.typeEx, 'gslider')
            RF.rfEx.signal = RF.rfex_gSlider(irep).signal;
        end
        for iexcit = (1-Actual.nDummy):Actual.nExcit
            seq.addBlock(Label.lblResetSLC);
            for isli = 1:Actual.nSlice
                RF.rfEx.freqOffset   = Grad.amplitudeEx  * Actual.Slice.SlicePositions(isli);
                RF.rfRef.freqOffset  = Grad.amplitudeRef * Actual.Slice.SlicePositions(isli);
                RF.rfEx.phaseOffset  = Actual.ActualRF.phaseEx  - 2 * pi *  RF.rfEx.freqOffset * mr.calcRfCenter(RF.rfEx) ; % align the phase for off-center slices
                RF.rfRef.phaseOffset = Actual.ActualRF.phaseRef - 2 * pi * RF.rfRef.freqOffset * mr.calcRfCenter(RF.rfRef); % dito

                % dPhi = RF.rfEx.phaseOffset - RF.rfRef.phaseOffset;
                % fprintf('Ex: %f, Ref: %f, %f\n', RF.rfEx.phaseOffset/pi*180, RF.rfRef.phaseOffset/pi*180, dPhi/pi*180);


                seq.addBlock(RF.rfEx, Grad.G3D_Ex, Grad.GRO_preL);

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
                        if strcmpi(Actual.TRAPS, 'on')
                            RF.rfRef.signal = RF.rfenvelopeRef * faRef(1)/180;
                        end
                        RF.rfRef.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp - RF.rfRef.shape_dur;
                        GPE_pre.delay = mr.calcDuration(Grad.G3D_Ref1) - Actual.tSp;
                        seq.addBlock(RF.rfRef, Grad.GRO_preR, GPE_pre, Grad.G3D_Ref1);

                        RF.rfRef.delay = mr.calcDuration(Grad.G3D_RefCrusherL);

                        if iexcit > 0
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
                        if strcmpi(Actual.TRAPS, 'on')
                            RF.rfRef.signal = RF.rfenvelopeRef * faRef(2)/180;
                        end
                        seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref);
                    else
                        if iexcit > 0
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
                            if strcmpi(Actual.TRAPS, 'on')
                                RF.rfRef.signal = RF.rfenvelopeRef * faRef(iseg+1)/180;
                            end
                            seq.addBlock(RF.rfRef, Grad.GRO_Spoil, GPE, Grad.G3D_Ref);
                        end
                    end
                    seq.addBlock(Label.lblIncSEG1);
                end
                seq.addBlock(delayTR);
                seq.addBlock(Label.lblIncSLC1);
            end
        end
        seq.addBlock(Label.lblIncREP1);
    end
end