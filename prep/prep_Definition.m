function [seq, prefix] = prep_Definition(seq, params, PE)
    MultiSliceMode   = params.MultiSliceMode;
    PEMode           = params.PEMode;
    AccelerationMode = params.AccelerationMode;
    IRMode           = params.IRMode;
    IR               = params.IR;

    fovRead          = params.fovRead;
    fovPhase         = params.fovPhase;
    nX               = params.nX;
    nY               = params.nY;

    TR               = params.TR;
    TEeff            = params.TEeff;
    nRep             = params.nRep;
    nSlice           = params.nSlice;
    nEcho            = params.nEcho;
    nExcit           = params.nExcit;
    nDummy           = params.nDummy;

    BWPerPixel       = params.BWPerPixel;
    readoutOS        = params.readoutOS;

    SliceThickness   = params.SliceThickness;
    SliceGap         = params.SliceGap;

    SlicePositions   = params.Slice.SlicePositions;
    SliceLabel       = params.Slice.SliceLabel;

    R                = params.R;
    kSpaceCenterLine = PE.kSpaceCenterLine;
    FirstRefLine     = PE.FirstRefLine;
    nRef             = PE.nRef;


    % prepare sequence export
    res = round(1e3*fovRead/nX, 2);
    a = fix(res);
    b = (res - a)*100;
    if mod(b, 10) == 0
        b = b/10;
    end
    prefix = [num2str(a),'p',num2str(b),'_',num2str(nX)];

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
    seq.setDefinition('PhaseResolution'      , (fovRead/nX)/(fovPhase/nY)); % phase resolution
    seq.setDefinition('AccelerationFactor3D' , 1                         );          
    seq.setDefinition('AccelerationFactorPE' , R                         );          
    seq.setDefinition('FirstRefLine'         , FirstRefLine              );          
    seq.setDefinition('nRefLine'             , nRef                      ); % number of ACS line
    
    fov_z = nSlice*(SliceThickness+SliceGap) - SliceGap;
    seq.setDefinition('FOV'                  , [fovRead fovPhase fov_z]  );
    seq.setDefinition('MatrixSize'           , [nX nY nSlice]            );
    seq.setDefinition('TR'                   , TR                        );
    seq.setDefinition('TE'                   , TEeff                     );
    
    seq.setDefinition('nSlice'               , nSlice                    );
    seq.setDefinition('nDummy'               , nDummy                    );
    seq.setDefinition('BW'                   , BWPerPixel                );
    seq.setDefinition('TuborFactor'          , nEcho                     );
    seq.setDefinition('nExcit'               , nExcit                    );
    seq.setDefinition('nRep'                 , nRep                      );
   
    seq.setDefinition('MultiSliceMode'       , MultiSliceMode            );
    seq.setDefinition('PEMode'               , PEMode                    );
    seq.setDefinition('AccelerationMode'     , AccelerationMode          );
    seq.setDefinition('IRMode'               , IRMode                    );
    seq.setDefinition('IR'                   , IR                        );

    seq.setDefinition('Developer'            , 'Jinyuan Zhang'           );
    seq.setDefinition('Name'                 , 'tse'                     );
end
