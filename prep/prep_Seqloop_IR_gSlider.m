function [seq] = prep_Seqloop_IR_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys)
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

    GS_ExSpoilPre  = Grad.GS_ExSpoilPre;
    GS_ExSpoilPost = Grad.GS_ExSpoilPost;
    GS_ExFlat      = Grad.GS_ExFlat;

    GS_RefCrusherL = Grad.GS_RefCrusherL;
    GS_RefCrusherR = Grad.GS_RefCrusherR;
    GS_RefFlat     = Grad.GS_RefFlat;
    GS_EndSpoil    = Grad.GS_EndSpoil;
    
    GRpreL         = Grad.GRpreL;
    GRpreR         = Grad.GRpreR;
    GR_adc         = Grad.GRO_adc;
    GR_SpoilPre    = Grad.GRO_SpoilPre;
    GR_SpoilPost   = Grad.GRO_SpoilPost;
    GR_Spoil       = Grad.GR_Spoil;

    tETrain        = Grad.tETrain;

    adc            = ADC.adc;
 
    % IR specific
    IRMode         = Actual.IRMode;
    TI             = Actual.TI;
    GS_Inv         = Grad.GS_Inv;
    rfInv          = RF.rfInv;
    phaseInv       = Actual.ActualRF.phaseInv;
    amplitudeInv   = Grad.amplitudeInv;
    

    delayEtrain = mr.makeDelay(tETrain);
    
    switch lower(IRMode)
        case 'interleaved'
            fprintf('# IR-TSE >>> Interleaved mode\n');
            nSlice_even    = sum( mod(SliceLabel, 2) == 0);
            nSlice_odd     = sum( mod(SliceLabel, 2) == 1);  
            SliceIdx_even  = find(mod(SliceLabel, 2) == 0);
            SliceIdx_odd   = find(mod(SliceLabel, 2) ~= 0);
        
            TIfill  = TI - mr.calcDuration(GS_Inv)/2 - mr.calcDuration(GS_ExSpoilPre) - mr.calcDuration(GS_ExFlat)/2;
            TIfill  = round(TIfill/sys.gradRasterTime) * sys.gradRasterTime;
        
            TRfill = TR - (TIfill*2 + nSlice * (tETrain + mr.calcDuration(GS_Inv)));
        
        
            assert(TRfill >= 0, 'TRfill [%f ms] must be >= 0 ms, please increase TR or adjust other parameters', ...
                TRfill*1e3);
             
            fill_per_slice = RoundRaster(TRfill/nSlice, sys.gradRasterTime, 'round');  % delay between slices
            delayTI_slice = mr.makeDelay(fill_per_slice);
            delayETrain   = mr.makeDelay(fill_per_slice+mr.calcDuration(GS_Inv));
        
            TIfill_end_even = TIfill - (nSlice_even-1) * (tETrain + mr.calcDuration(GS_Inv)) - nSlice_even * fill_per_slice;
            TIfill_end_even = RoundRaster(TIfill_end_even, sys.gradRasterTime, 'down');

            TIfill_end_odd  = TIfill - (nSlice_odd -1) * (tETrain + mr.calcDuration(GS_Inv)) - nSlice_odd * fill_per_slice;
            TIfill_end_odd  = RoundRaster(TIfill_end_odd, sys.gradRasterTime, 'down');

            assert(TIfill_end_even >= 0, 'TIfill_end_even [%f ms] must be >= 0 ms, please increase TI or adjust other parameters', ...
                TIfill_end_even*1e3);

            delayTIfill_end_even = mr.makeDelay(TIfill_end_even);
            delayTIfill_end_odd  = mr.makeDelay(TIfill_end_odd);
        
            % compensate for accurate TR
            TRfill_end = TR - nSlice * (tETrain + fill_per_slice + mr.calcDuration(GS_Inv)) - 2*TIfill - 2* mr.calcDuration(GS_Inv);
            TRfill_end = RoundRaster(TRfill_end, sys.gradRasterTime, 'round');
            
        
            disp(strcat('TRfill : ',num2str(1000*TRfill),' ms')); 
            disp(strcat('TIfill_slice_even : ',num2str(1e3*TIfill_end_even),' ms')); 
            disp(strcat('TIfill_slice_odd  : ',num2str(1e3*TIfill_end_odd),' ms')); 
        case 'sequential'
            fprintf('# IR-TSE >>> Sequential mode\n');
            TIfill  = TI - mr.calcDuration(GS_Inv)/2 - mr.calcDuration(GS_ExSpoilPre) - mr.calcDuration(GS_ExFlat)/2;
            TIfill  = RoundRaster(TIfill, sys.gradRasterTime, 'round');

            TRfill = TR - (TIfill + nSlice * (tETrain + mr.calcDuration(GS_Inv)));

            assert(TIfill/nSlice >= tETrain, 'TI is too small to support %d slices in Sequential mode!', nSlice);
            assert(TRfill >= 0, 'TRfill [%f ms] must be >= 0 ms, please increase TR or adjust other parameters', ...
                TRfill*1e3);


            fill_per_slice  = (min(TIfill-tETrain*(nSlice-1), TRfill) - (nSlice-1)* mr.calcDuration(GS_Inv))/(nSlice);
            fill_per_slice  = RoundRaster(fill_per_slice, sys.gradRasterTime, 'down');
            
            delayTI_slice = mr.makeDelay(fill_per_slice);

            TIfill_end = TIfill - (nSlice-1) * (tETrain + mr.calcDuration(GS_Inv)) - nSlice * fill_per_slice;
            TIfill_end = RoundRaster(TIfill_end, sys.gradRasterTime, 'down');
            delayTIfill_end = mr.makeDelay(TIfill_end);

            delayETrain = mr.makeDelay(fill_per_slice+mr.calcDuration(GS_Inv));

            TRfill_end = TR - nSlice * (tETrain + fill_per_slice+mr.calcDuration(GS_Inv)) - TIfill - mr.calcDuration(GS_Inv);
            TRfill_end = RoundRaster(TRfill_end, sys.gradRasterTime, 'round');
        otherwise
            error('invalid IRMode %s', IRMode);
    end



    function addInversionBlock(isli, nSlice)
        rfInv.freqOffset  = amplitudeInv * SlicePositions(isli);
        rfInv.phaseOffset = phaseInv - 2 * pi * rfInv.freqOffset * mr.calcRfCenter(rfInv); % dito
        seq.addBlock(GS_Inv, rfInv);
        seq.addBlock(delayTI_slice);
        if idx < nSlice
            seq.addBlock(delayEtrain)
        end
    end


    function addReadoutBlock(isli, nSlice, TRfill_end, delayETrain, rfEx)
        rfEx.freqOffset   = amplitudeEx  * SlicePositions(isli);
        rfRef.freqOffset  = amplitudeRef * SlicePositions(isli);
        rfEx.phaseOffset  = phaseEx  - 2 * pi *  rfEx.freqOffset * mr.calcRfCenter(rfEx) ; % align the phase for off-center slices
        rfRef.phaseOffset = phaseRef - 2 * pi * rfRef.freqOffset * mr.calcRfCenter(rfRef); % dito
    
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
        if idx == nSlice
            seq.addBlock(mr.makeDelay(delayETrain.delay + TRfill_end));
        else
            seq.addBlock(delayETrain);
        end
        seq.addBlock(mr.makeLabel('INC', 'SLC', 1));
    end


    % Next, the blocks are put together to form the sequence
    seq.addBlock(mr.makeLabel('SET', 'REP', 0));
    for irep = 1:nRep
        if strcmpi(Actual.ActualRF.typeEx, 'gslider')
            rfEx.signal = RF.rfex_gSlider(irep).signal;
        end
        for iexcit = (1-nDummy):nExcit 
            seq.addBlock(mr.makeLabel('SET', 'SLC', 0));
            switch lower(IRMode)
                case 'interleaved'
                    for idx = 1:nSlice_even
                        isli = SliceIdx_even(idx);
                        addInversionBlock(isli, nSlice_even);
                    end
                    seq.addBlock(delayTIfill_end_even);
                    for idx = 1:nSlice_even
                        isli = SliceIdx_even(idx);
                        addReadoutBlock(isli, nSlice_even, 0, delayETrain, rfEx);
                    end
                    
                    for idx = 1:nSlice_odd
                        isli = SliceIdx_odd(idx);
                        addInversionBlock(isli, nSlice_odd);
                    end
                    seq.addBlock(delayTIfill_end_odd);
                    for idx = 1:nSlice_odd
                        isli = SliceIdx_odd(idx);
                        addReadoutBlock(isli, nSlice_odd, TRfill_end, delayETrain, rfEx);
                    end
                case 'sequential'
                    for idx = 1:nSlice
                        isli = idx;
                        addInversionBlock(isli, nSlice);
                    end
                    seq.addBlock(delayTIfill_end);
                    for idx = 1:nSlice
                        isli = idx;
                        addReadoutBlock(isli, nSlice, TRfill_end, delayETrain, rfEx);
                    end
            end
        end
        seq.addBlock(mr.makeLabel('INC', 'REP', 1));
    end
end


