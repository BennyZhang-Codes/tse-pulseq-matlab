clc; clear; close all;
%% 2D TSE-gSlider Sequence
addpath(genpath('pulseq'));
addpath(genpath('prep'  ));
addpath(genpath('check' ));
addpath(genpath('plot'  ));
addpath(genpath('utils' ));
addpath(genpath('VERSE' ));

RF    = struct();
Grad  = struct();
ADC   = struct();
Delay = struct();
Label = struct();
Trig  = struct();

Setup.SeqDimension     = '2D';
%% Setup
% Scanner
Setup.ScannerType      = 'Terra-XJ';  % for pns_check
Setup.MaxGrad_soft     = 40;
Setup.MaxSlew_soft     = 150;

% Sequence events
Setup.NoiseScan        = 'on';  
Setup.VERSE            = 'off';
Setup.PhaseCorrection  = 'on';

Setup.IR               = 'off';         % Inversion Recovery
Setup.IRMode           = 'Interleaved'; % 'Interleaved' or 'Sequential'

Setup.PEMode           = 'CentricFull'; % 'Centric', 'Linear'
Setup.AccelerationMode = 'PI';          % 'PI', 'CS'
Setup.MultiSliceMode   = 'Interleaved'; % 'Interleaved' or 'Sequential'

Setup.TRAPS            = 'on';

Setup.nDummy           = 1;             % number of pre-scans

Setup.fovRO            = 120e-3;
Setup.fovPE            = 120e-3;
Setup.nRO              = 120; 
Setup.nPE              = 120; 
Setup.nEcho            = 10; 
Setup.nSlice           = 10; 
Setup.nRep             = 5;

Setup.SliceThickness   = 2e-3;
Setup.SliceGap         = 0/100 * Setup.SliceThickness;

Setup.TE1              = 13e-3; % echo time of the first echo in the train
Setup.TR               = 5600e-3;
Setup.TEeff            = 13e-3; % the desired echo time 

Setup.R                = 2;              % Acceleration factor
Setup.RefLinesRatio    = 30/Setup.nPE;    % PI
Setup.p                = 20;             % CS
Setup.r                = 0.1;            % CS

Setup.rflip = 180; if isscalar(Setup.rflip), Setup.rflip=Setup.rflip+zeros([1 Setup.nEcho]); end
if strcmpi(Setup.TRAPS, 'on')
    k0_echo = max(round(Setup.TEeff/Setup.TE1), 1); % echo to be aligned to the k-space center 
    [Setup.faRef, ~] = fliptraps(180,Setup.nEcho,5,'opt',0,2,0,70,70,[k0_echo k0_echo+4 k0_echo+4 Setup.nEcho]);
end

Setup.flipex           = 90 * pi / 180;
Setup.flipref          = Setup.rflip(1)*pi/180;
Setup.flipinv          = 180 * pi / 180;

Setup.roDuration       = 6.0e-3;

Setup.TI               = 2000e-3; % time of inversion recovery

SetupRF.typeEx         = 'gSlider';
SetupRF.typeRef        = 'slr'    ;
SetupRF.typeInv        = 'slr'    ;
SetupRF.tEx            = 5.12e-3  ; 
SetupRF.tRef           = 3.84e-3  ; 
SetupRF.tInv           = 3.84e-3  ;
SetupRF.tbpEx          = 12       ;
SetupRF.tbpRef         = 6        ;
SetupRF.tbpInv         = 6        ;
SetupRF.phaseEx        = pi/2     ;   
SetupRF.phaseRef       = 0        ;
SetupRF.phaseInv       = 0        ;

Setup.dG               = 250e-6    ; % 'standard' ramp time - makes sequence structure much simpler
Setup.readoutOS        = 2         ; % oversampling factor for readout direction

%% init
Setup.BWPerPixel       = 1 / Setup.roDuration;
Setup.ReadoutTime      = RoundRaster(Setup.roDuration + 2 * 10e-6, 10e-6, 'round'); % + 2 x adcDeadTime
Setup.tEx              = RoundRaster(SetupRF.tEx , 10e-6, 'round');
Setup.tRef             = RoundRaster(SetupRF.tRef, 10e-6, 'round');
Setup.tSp              = RoundRaster(0.5 * (Setup.TE1 - Setup.ReadoutTime - Setup.tRef), 10e-6, 'round');
Setup.tSpex            = RoundRaster(0.5 * (Setup.TE1 - Setup.tEx         - Setup.tRef), 10e-6, 'round');

% Crusher and spoiler configuration
% relative to the net area of gradients required to achieve desired resolution. 
SetupSpoiling.PreExcitationSpoiler.Cycles = 4;
SetupSpoiling.PreExcitationSpoiler.Reference = 'Slice';
SetupSpoiling.PreExcitationSpoiler.MaxSlew = 75;
SetupSpoiling.RefocusingCrusher.Cycles = 4;
SetupSpoiling.RefocusingCrusher.Reference = 'Slice';
SetupSpoiling.InversionCrusher.Cycles = 4;
SetupSpoiling.InversionCrusher.Reference = 'Slice';
SetupSpoiling.ReadoutCrusher.Cycles = 1;
SetupSpoiling.ReadoutCrusher.Reference = 'RO';
SetupSpoiling.EndSpoiler.Cycles = 4;
SetupSpoiling.EndSpoiler.Reference = 'Slice';
SetupSpoiling.EndSpoiler.Duration = 4e-3;
SetupSpoiling.EndSpoiler.MaxSlew = 75;

Setup.fovSG            = Setup.nSlice * (Setup.SliceThickness + Setup.SliceGap) - Setup.SliceGap;
Setup.n3D              = 1;
Setup.FOV              = [Setup.fovRO, Setup.fovPE, Setup.fovSG]; % [m] RO x PE x SliceGroup
Setup.MatrixSize       = [Setup.nRO, Setup.nPE, Setup.nSlice]; % [a.u.] RO x PE x nSlice

%% Set orienation (non-oblique)
% Set axes (X/Y/Z vs. RO/PE/3D - oblique not supported) 
% In Siemens interpreter the defintions here must agree with the

% mapping of RO/PE/3D to X/Y/Z
Setup.AxisRO = 'x' ;
Setup.AxisPE = 'y' ;
Setup.Axis3D = 'z' ; 

% Flip or not X/Y/Z to match patient positive/negative directions. Usefull if reconstruction is done by system to get correct orientation of images.
Setup.SignCorr.x = -1 ;
Setup.SignCorr.y = -1 ;
Setup.SignCorr.z = -1 ;

%% Initialize Actual Params
% Initialize Actual to be the same as Setup
Actual = Setup ;
Actual.ActualRF = SetupRF;
Actual.ActualSpoiling = SetupSpoiling;

%% prep system
[sys, sys_soft, seq, Actual] = prep_System(Actual);

%% prep Slice
[Slice.SliceLabel, Slice.SliceOrder, Slice.SlicePositions] = prep_SlicePositions(Actual);
Actual.Slice = Slice;

%% Phase encoding
[PE3D, Actual] = prep_PE3DOrder(Actual);
% plot_PE(Actual.R, Actual.nRO, Actual.nPE, PE.pe_Img, PE.pe_Ref, PE.pe_ImgAndRef, PE.pe_full)
% fig = plot_PEOrder(Actual.R, Actual.nRO, Actual.nPE, PE.PE3DLabel);
% print(fig, '-dpng', '-loose', '-r300', '-image', sprintf('PEMode_%s_%s_R%s.png', Actual.PEMode, Actual.AccelerationMode, num2str(Actual.R)));
%% RF and Gz
[RF, Grad] = prep_Excitation(RF, Grad, Actual, sys_soft);
[RF, Grad] = prep_Refocusing(RF, Grad, Actual, sys_soft);
if strcmp(Actual.IR, 'on')
    [RF, Grad] = prep_Inversion(RF, Grad, Actual, sys_soft);
end

%% Gradient events
[Grad] = prep_SpoilingArea(Grad, Actual);
[ADC, Grad] = prep_Gradient_GR(Grad, ADC, Actual, sys_soft); % readout gradients
[Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, Actual, sys_soft);        % split gradients and recombine into blocks

%% Prephaser & Rephaser
% [Grad] = prep_PreRephaser(Actual, Grad, PE3D, sys);

%% Label
[seq, Label] = prep_Label(seq, Actual, Label);

%% Delay
[Delay] = prep_Delay(Actual, Delay);

%% Noise Scan
[seq, Label] = prep_NoiseScan(seq, Actual, PE3D, ADC, Label, sys);

%% Seqloop
if strcmpi(Actual.IR, 'on')
    [seq] = prep_Seqloop_IR_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft);
else
    [seq] = prep_Seqloop_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft);
end

%% timing & PNS & definition
[seq] = check_Timing(seq);
check_Label(seq);
check_PNS(seq, Actual);

[seq, Actual] = prep_Definition(seq, Actual);
%%
outpath = 'seq/';
seqname = Actual.seqname; % seqname = [seqname, '_', num2str(Actual.TypeInv)];
save(strcat(outpath, seqname), 'Setup', 'Actual');
seq.write(strcat(outpath, seqname,'.seq'))

%% plot
timeRange = [(Actual.nDummy)*Actual.TR, (Actual.nDummy+1)*Actual.TR];
if strcmp(Actual.NoiseScan, 'on'); timeRange = timeRange + Actual.TR; end
fig = seq.plot('showBlock',true,'showGuides',1,'stacked',0,'timeDisp','s', 'timeRange', timeRange); %'Label', 'LIN,PAR,ECO,REP';

%% test report
% rep = seq.testReport; 
% fprintf([rep{:}]); 