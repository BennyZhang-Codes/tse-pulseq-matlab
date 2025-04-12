function [seq] = prep_Seqloop(seq, params, RF, Grad, ADC, Delay, Label, sys)
    TR             = params.TR;
    nRep           = params.nRep;
    nSlice         = params.nSlice;
    nEcho          = params.nEcho;
    nExcit         = params.nExcit;
    nDummy         = params.nDummy;

    tSp            = params.tSp;
    dG             = params.dG;
    
    SlicePositions = params.Slice.SlicePositions;
    phaseAreas     = params.PE.phaseAreas;
    PElabel        = params.PE.PElabel;
    PEorder        = params.PE.PEorder;
    pe_Ref         = params.PE.pe_Ref;
    pe_ImgAndRef   = params.PE.pe_ImgAndRef;

    phaseEx        = params.paramsRF.phaseEx;
    phaseRef       = params.paramsRF.phaseRef;

    rfex           = RF.rfEx;
    rfref          = RF.rfRef;

    amplitudeEx    = Grad.amplitudeEx;
    amplitudeRef   = Grad.amplitudeRef;

    GS_exref        = Grad.GS_exref;
    GS_RefCrusherL = Grad.GS_RefCrusherL;
    GS_RefCrusherR = Grad.GS_RefCrusherR;
    GS_RefFlat     = Grad.GS_RefFlat;
    
    GRpre          = Grad.GRpre;
    GR_adc         = Grad.GR_adc;

    tETrain        = Grad.tETrain;

    adc            = ADC.adc;

    % delay_TE1      = Delay.delay_TE1;

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
        for iexcit = (1-nDummy):nExcit 
            seq.addBlock(mr.makeLabel('SET', 'SLC', 0));
            for isli = 1:nSlice
                rfex.freqOffset   = amplitudeEx  * SlicePositions(isli);
                rfref.freqOffset  = amplitudeRef * SlicePositions(isli);
                rfex.phaseOffset  = phaseEx  - 2 * pi *  rfex.freqOffset * mr.calcRfCenter(rfex) ; % align the phase for off-center slices
                rfref.phaseOffset = phaseRef - 2 * pi * rfref.freqOffset * mr.calcRfCenter(rfref); % dito
                
                % dPhi = rfex.phaseOffset - rfref.phaseOffset;
                % fprintf('Ex: %f, Ref: %f, %f\n', rfex.phaseOffset/pi*180, rfref.phaseOffset/pi*180, dPhi/pi*180);

                seq.addBlock(GS_exref, rfex, GRpre);
        
                seq.addBlock(mr.makeLabel('SET', 'SEG', 0));
                for iseg = 1:nEcho
                    if (iexcit > 0)
                        phaseArea = phaseAreas(iseg, iexcit);
                        seq.addBlock(mr.makeLabel('SET', 'LIN', PElabel(iseg, iexcit)));
                        
                        if ismember(PEorder(iseg, iexcit), pe_Ref)
                            seq.addBlock(lblResetRefAndImaScan, lblSetRefScan) ;
                        elseif ismember(PEorder(iseg, iexcit),pe_ImgAndRef)
                            seq.addBlock(lblSetRefAndImaScan, lblSetRefScan) ;
                        else
                            seq.addBlock(lblResetRefAndImaScan, lblResetRefScan) ;
                        end
                    else
                        phaseArea = 0;
                    end
                    GPpre = mr.makeTrapezoid('y', sys, 'Area',  phaseArea, 'Duration', tSp, 'riseTime', dG);
                    GPrew = mr.makeTrapezoid('y', sys, 'Area', -phaseArea, 'Duration', tSp, 'riseTime', dG);
                    if iseg == 1
                        seq.addBlock(GS_RefFlat, rfref);
                    else
                        seq.addBlock(GS_RefCrusherL);
                        seq.addBlock(GS_RefFlat, rfref);
                    end

                    if (iexcit > 0)
                        seq.addBlock(GS_RefCrusherR, GPpre, GR_adc, adc);
                    else
                        seq.addBlock(GS_RefCrusherR, GPpre, GR_adc);
                    end
                    seq.addBlock(GPrew);
                    seq.addBlock(mr.makeLabel('INC', 'SEG', 1));
                end

                seq.addBlock(delayTR);
                seq.addBlock(mr.makeLabel('INC', 'SLC', 1));
            end
        end
        seq.addBlock(mr.makeLabel('INC', 'REP', 1));
    end
end
