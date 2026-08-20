function [seq] = prep_Seqloop_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
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
    phaseAreas     = Actual.PE.phaseAreas;
    PElabel        = Actual.PE.PElabel;
    PEorder        = Actual.PE.PEorder;
    pe_Ref         = Actual.PE.pe_Ref;
    pe_ImgAndRef   = Actual.PE.pe_ImgAndRef;

    tSp            = Actual.tSp;

    phaseEx        = Actual.paramsRF.phaseEx;
    phaseRef       = Actual.paramsRF.phaseRef;

    if strcmpi(Actual.TRAPS, 'on')
        faRef          = Actual.faRef;
    end

    rfEx           = RF.rfEx;
    rfRef          = RF.rfRef;
    rfenvelopeRef  = RF.rfenvelopeRef;
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
    TRfill  = (TR - nSlice * tETrain) / nSlice;
    % round to gradient raster
    TRfill  = sys.gradRasterTime * round(TRfill / sys.gradRasterTime);
    if TRfill<0, TRfill=1e-3; 
        disp(strcat('Warning!!! TR too short, adapted to include all slices to : ',num2str(1000*nSlice*(tETrain+TRfill)),' ms')); 
    else
        disp(strcat('TRfill : ',num2str(1000*TRfill),' ms')); 
    end
    delayTR = mr.makeDelay(TRfill);

    % Next, the blocks are put together to form the sequence
    seq.addBlock(mr.makeLabel('SET', 'REP', 0));
    for irep = 1:nRep
        if strcmpi(Actual.paramsRF.typeEx, 'gslider')
            rfEx.signal = RF.rfex_gSlider(irep).signal;
        end
        for iexcit = (1-nDummy):nExcit 
            seq.addBlock(mr.makeLabel('SET', 'SLC', 0));
            for isli = 1:nSlice
                rfEx.freqOffset   = amplitudeEx  * SlicePositions(isli);
                rfRef.freqOffset  = amplitudeRef * SlicePositions(isli);
                rfEx.phaseOffset  = phaseEx  - 2 * pi *  rfEx.freqOffset * mr.calcRfCenter(rfEx) ; % align the phase for off-center slices
                rfRef.phaseOffset = phaseRef - 2 * pi * rfRef.freqOffset * mr.calcRfCenter(rfRef); % dito
                
                % dPhi = rfEx.phaseOffset - rfRef.phaseOffset;
                % fprintf('Ex: %f, Ref: %f, %f\n', rfEx.phaseOffset/pi*180, rfRef.phaseOffset/pi*180, dPhi/pi*180);

                
                seq.addBlock(rfEx, GS_Ex, GRpreL);
        
                seq.addBlock(mr.makeLabel('SET', 'SEG', 0));
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
                        [isegCenter, iexcitCenter] = find(PElabel == Actual.PE.kSpaceCenterLine);
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
                        if strcmpi(Actual.TRAPS, 'on')
                            rfRef.signal = rfenvelopeRef * faRef(1)/180;
                        end
                        rfRef.delay = mr.calcDuration(GS_Ref1) - tSp - rfRef.shape_dur;
                        GPpre.delay = mr.calcDuration(GS_Ref1) - tSp;
                        seq.addBlock(rfRef, GRpreR, GPpre, GS_Ref1);

                        rfRef.delay = mr.calcDuration(GS_RefCrusherL);

                        if iexcit > 0
                            seq.addBlock(GR_adc, adc);
                        else
                            if strcmpi(PhaseCorrection, 'on')
                                seq.addBlock(mr.makeLabel('SET', 'NAV', 1));
                                seq.addBlock(GR_adc, adc);
                                seq.addBlock(mr.makeLabel('SET', 'NAV', 0));
                            else
                                seq.addBlock(GR_adc);
                            end
                        end
                        if strcmpi(Actual.TRAPS, 'on')
                            rfRef.signal = rfenvelopeRef * faRef(2)/180;
                        end
                        seq.addBlock(rfRef, GR_Spoil, GP, GS_Ref);
                    else
                        if iexcit > 0
                            seq.addBlock(GR_adc, adc);
                        else
                            if strcmpi(PhaseCorrection, 'on')
                                seq.addBlock(mr.makeLabel('SET', 'NAV', 1));
                                seq.addBlock(GR_adc, adc);
                                seq.addBlock(mr.makeLabel('SET', 'NAV', 0));
                            else
                                seq.addBlock(GR_adc);
                            end
                        end
                        if iseg == nEcho
                            seq.addBlock(GR_SpoilPost, GPrew, GS_EndSpoil);
                        else
                            if strcmpi(Actual.TRAPS, 'on')
                                rfRef.signal = rfenvelopeRef * faRef(iseg+1)/180;
                            end
                            seq.addBlock(rfRef, GR_Spoil, GP, GS_Ref);
                        end
                    end
                    seq.addBlock(mr.makeLabel('INC', 'SEG', 1));
                end
                seq.addBlock(delayTR);
                seq.addBlock(mr.makeLabel('INC', 'SLC', 1));
            end
        end
        seq.addBlock(mr.makeLabel('INC', 'REP', 1));
    end
end
