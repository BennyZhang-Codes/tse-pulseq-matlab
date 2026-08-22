function [seq, Actual] = prep_Definition(seq, Actual)
    PE3D = Actual.PE3D;
  
    seq.setDefinition('Rot_Matrix'           , [1, 0, 0, 0, 1, 0, 0, 0, 1]);

    % readout oversampling 
    seq.setDefinition('ReadoutOversamplingFactor', Actual.readoutOS      );
    
    % sequence definitions: enable 2D multi-slice mode
    seq.setDefinition('SliceThickness'       , Actual.SliceThickness     );
    seq.setDefinition('SliceGap'             , Actual.SliceGap           );
    seq.setDefinition('SlicePositions'       , Actual.Slice.SlicePositions);
    seq.setDefinition('SliceLabel'           , Actual.Slice.SliceLabel   );
    
    % sequence definitions: additional information required by GRAPPA

    % Full encoded PE matrix size.
    % Required because accelerated acquisitions may not contain LIN=nPE-1.
    seq.setDefinition('kSpacePhaseEncodingLines', Actual.nPE             ); 
    % Zero-based central PE line.
    seq.setDefinition('kSpaceCenterLine'     , PE3D.kSpaceCenterLine     ); 
    % phase resolution
    seq.setDefinition('PhaseResolution'      , (Actual.fovRO/Actual.nRO)/(Actual.fovPE/Actual.nPE)); 
    seq.setDefinition('AccelerationFactor3D' , 1                         );          
    seq.setDefinition('AccelerationFactorPE' , Actual.R                  );
    % First line belonging to the regular accelerated imaging lattice.
    seq.setDefinition('FirstFourierLine'     , PE3D.FirstFourierLine     ); 
    % First ACS line.
    seq.setDefinition('FirstRefLine'         , PE3D.FirstRefLine         );
    % Total ACS width, including REF-only and REF+IMA lines.
    % This is recorded for bookkeeping; the Siemens iPAT card must
    % still be set to the same number manually.
    seq.setDefinition('nRefLine'             , PE3D.nRef                 ); 
    
    seq.setDefinition('FOV'                  , Actual.FOV                );
    seq.setDefinition('MatrixSize'           , Actual.MatrixSize         );
    seq.setDefinition('TR'                   , Actual.TR                 );
    seq.setDefinition('TE'                   , Actual.TEeff              );
    
    seq.setDefinition('nSlice'               , Actual.nSlice             );
    seq.setDefinition('nDummy'               , Actual.nDummy             );
    seq.setDefinition('BW'                   , Actual.BWPerPixel         );
    seq.setDefinition('nExcit'               , Actual.nExcit             );
    seq.setDefinition('nRep'                 , Actual.nRep               );
   
    seq.setDefinition('MultiSliceMode'       , Actual.MultiSliceMode     );
    seq.setDefinition('MultiSliceDir'        , Actual.MultiSliceDir      );
    seq.setDefinition('PEMode'               , Actual.PEMode             );
    seq.setDefinition('AccelerationMode'     , Actual.AccelerationMode   );
    seq.setDefinition('IRMode'               , Actual.IRMode             );
    seq.setDefinition('IR'                   , Actual.IR                 );

    seq.setDefinition('TurboFactor'          , Actual.nEcho              );
    seq.setDefinition('PhaseCorrection'      , lower(Actual.PhaseCorrection));

    seq.setDefinition('Developer'            , 'Jinyuan Zhang'           );
    seq.setDefinition('Name'                 , 'tse'                     );


    res = round(1e3*Actual.fovRO/Actual.nRO, 2);
    a = fix(res);
    b = (res - a)*100;
    if b > 0 && b < 10
        str_res_RO = [num2str(a),'p0',num2str(b)];
    else
        if mod(b, 10) == 0; b = b / 10; end
        str_res_RO = [num2str(a),'p',num2str(b)];
    end

    res = round(1e3*Actual.fovPE/Actual.nPE, 2);
    a = fix(res);
    b = (res - a)*100;
    if b > 0 && b < 10
        str_res_PE = [num2str(a),'p0',num2str(b)];
    else
        if mod(b, 10) == 0; b = b / 10; end
        str_res_PE = [num2str(a),'p',num2str(b)];
    end

    res = round(1e3*Actual.SliceThickness, 2);
    a = fix(res);
    b = (res - a)*100;
    if b > 0 && b < 10
        str_res_3D = [num2str(a),'p0',num2str(b)];
    else
        if mod(b, 10) == 0; b = b / 10; end
        str_res_3D = [num2str(a),'p',num2str(b)];
    end

    str_res    = [str_res_RO, 'x', str_res_PE, 'x', str_res_3D];
    str_mat    = [num2str(Actual.nRO), 'x', num2str(Actual.nPE), 'x', num2str(Actual.nSlice)];


    gap = round(1e3*Actual.SliceGap, 2);
    a = fix(gap);
    b = (gap - a)*100;
    if b > 0 && b < 10
        str_gap = [num2str(a),'p0',num2str(b)];
    else
        if mod(b, 10) == 0; b = b / 10; end
        str_gap = [num2str(a),'p',num2str(b)];
    end


    te = round(Actual.TE1 * 1e3, 2); 
    te = te(:);
    a = fix(te);
    b = round((te - a) * 100);
    TE_str = cell(size(te));
    for i = 1:numel(te)
        if b(i) > 0 && b(i) < 10
            TE_str{i} = [num2str(a(i)), 'p0', num2str(b(i))];
        else
            if mod(b(i), 10) == 0; b(i) = b(i) / 10; end
            TE_str{i} = [num2str(a(i)), 'p', num2str(b(i))];
        end
    end
    TE_str = char(strjoin(TE_str, '_'));


    seqname = sprintf('TSE2D_%s_%s_%s_%s_%s_%s_%s', str_res, str_mat, str_gap, ...
    num2str(Actual.TR*1e3), TE_str, num2str(Actual.R), num2str(PE3D.nRef));

    Actual.seqname = seqname;
end