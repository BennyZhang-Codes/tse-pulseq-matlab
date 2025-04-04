function [seq] = prep_Seqloop(seq, params, RF, Grad, ADC, Label, sys)
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

    rfex           = RF.rfex;
    rfref          = RF.rfref;

    GSex           = Grad.GSex;
    GSref          = Grad.GSref;
    GS1            = Grad.GS1;
    GS2            = Grad.GS2;
    GS3            = Grad.GS3;
    GS4            = Grad.GS4;
    GS5            = Grad.GS5;
    GS7            = Grad.GS7;
    
    GR3            = Grad.GR3;
    GR5            = Grad.GR5;
    GR6            = Grad.GR6;
    GR7            = Grad.GR7;
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
        for iexcit = (1-nDummy):nExcit 
            seq.addBlock(mr.makeLabel('SET', 'SLC', 0));
            for isli = 1:nSlice
                rfex.freqOffset   = GSex.amplitude  * SlicePositions(isli);
                rfref.freqOffset  = GSref.amplitude * SlicePositions(isli);
                rfex.phaseOffset  = phaseEx  - 2 * pi *  rfex.freqOffset * mr.calcRfCenter(rfex); % align the phase for off-center slices
                rfref.phaseOffset = phaseRef - 2 * pi * rfref.freqOffset * mr.calcRfCenter(rfref); % dito
            
                seq.addBlock(GS1);
                seq.addBlock(GS2, rfex);
                seq.addBlock(GS3, GR3);
        
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
                    seq.addBlock(GS4, rfref);
                    seq.addBlock(GS5, GR5, GPpre);
                    if (iexcit > 0)
                        seq.addBlock(GR6, adc);
                    else
                        seq.addBlock(GR6);
                    end
                    seq.addBlock(GS7, GR7, GPrew);
                    seq.addBlock(mr.makeLabel('INC', 'SEG', 1));
                end
                seq.addBlock(GS4);
                seq.addBlock(GS5);
                seq.addBlock(delayTR);
                seq.addBlock(mr.makeLabel('INC', 'SLC', 1));
            end
        end
        seq.addBlock(mr.makeLabel('INC', 'REP', 1));
    end
end
