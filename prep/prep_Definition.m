function [seq, prefix] = prep_Definition(seq, Actual, PE)
    MultiSliceMode   = Actual.MultiSliceMode;
    PEMode           = Actual.PEMode;
    AccelerationMode = Actual.AccelerationMode;
    IRMode           = Actual.IRMode;
    IR               = Actual.IR;

    fovRO          = Actual.fovRO;
    fovPE         = Actual.fovPE;
    nRO               = Actual.nRO;
    nPE               = Actual.nPE;

    TR               = Actual.TR;
    TEeff            = Actual.TEeff;
    nRep             = Actual.nRep;
    nSlice           = Actual.nSlice;
    nEcho            = Actual.nEcho;
    nExcit           = Actual.nExcit;
    nDummy           = Actual.nDummy;

    BWPerPixel       = Actual.BWPerPixel;
    readoutOS        = Actual.readoutOS;

    SliceThickness   = Actual.SliceThickness;
    SliceGap         = Actual.SliceGap;

    SlicePositions   = Actual.Slice.SlicePositions;
    SliceLabel       = Actual.Slice.SliceLabel;

    R                = Actual.R;
    kSpaceCenterLine = PE.kSpaceCenterLine;
    FirstRefLine     = PE.FirstRefLine;
    nRef             = PE.nRef;

    PhaseCorrection  = Actual.PhaseCorrection;

    % prepare sequence export
    res = round(1e3*fovRO/nRO, 2);
    a = fix(res);
    b = (res - a)*100;
    if mod(b, 10) == 0
        b = b/10;
    end
    prefix = [num2str(a),'p',num2str(b),'_',num2str(nRO)];

    Rot_Matrix = [-1, 0, 0, 0, -1, 0, 0, 0, -1];    % reverse the polarity of gradients.
    seq.setDefinition('Rot_Matrix'           , Rot_Matrix                );

    % readout oversampling 
    seq.setDefinition('ReadoutOversamplingFactor', readoutOS             );
    
    % sequence definitions: enable 2D multi-slice mode
    seq.setDefinition('SliceThickness'       , SliceThickness            );
    seq.setDefinition('SliceGap'             , SliceGap                  );
    seq.setDefinition('SlicePositions'       , SlicePositions            );
    seq.setDefinition('SliceLabel'           , SliceLabel                );
    
    % sequence definitions: additional information required by GRAPPA
    seq.setDefinition('kSpaceCenterLine'     , kSpaceCenterLine          ); % PE center line index
    seq.setDefinition('PhaseResolution'      , (fovRO/nRO)/(fovPE/nPE)); % phase resolution
    seq.setDefinition('AccelerationFactor3D' , 1                         );          
    seq.setDefinition('AccelerationFactorPE' , R                         );          
    seq.setDefinition('FirstRefLine'         , FirstRefLine              );          
    seq.setDefinition('nRefLine'             , nRef                      ); % number of ACS line
    
    fov_z = nSlice*(SliceThickness+SliceGap) - SliceGap;
    seq.setDefinition('FOV'                  , [fovRO fovPE fov_z]  );
    seq.setDefinition('MatrixSize'           , [nRO nPE nSlice]            );
    seq.setDefinition('TR'                   , TR                        );
    seq.setDefinition('TE'                   , TEeff                     );
    
    seq.setDefinition('nSlice'               , nSlice                    );
    seq.setDefinition('nDummy'               , nDummy                    );
    seq.setDefinition('BW'                   , BWPerPixel                );
    seq.setDefinition('nExcit'               , nExcit                    );
    seq.setDefinition('nRep'                 , nRep                      );
   
    seq.setDefinition('MultiSliceMode'       , MultiSliceMode            );
    seq.setDefinition('PEMode'               , PEMode                    );
    seq.setDefinition('AccelerationMode'     , AccelerationMode          );
    seq.setDefinition('IRMode'               , IRMode                    );
    seq.setDefinition('IR'                   , IR                        );

    seq.setDefinition('TuborFactor'          , nEcho                     );
    seq.setDefinition('PhaseCorrection'      , lower(PhaseCorrection)    );

    seq.setDefinition('Developer'            , 'Jinyuan Zhang'           );
    seq.setDefinition('Name'                 , 'tse'                     );
end
