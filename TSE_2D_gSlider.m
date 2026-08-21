clc; clear; close all;
%% 2D TSE-gSlider Sequence
addpath(genpath('pulseq'));
addpath(genpath('prep'  ));
addpath(genpath('check' ));
addpath(genpath('plot'  ));
addpath(genpath('utils' ));
addpath(genpath('VERSE' ));

Grad  = struct();
RF    = struct();
ADC   = struct();
Delay = struct(); 

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

Setup.fspR             = 0.5       ; % ratio of spoiling area to readout area
Setup.fspS             = 0.5       ; % ratio of spoiling area to Gz rephasing area
Setup.dG               = 250e-6    ; % 'standard' ramp time - makes sequence structure much simpler
Setup.readoutOS        = 2         ; % oversampling factor for readout direction


%% init
Setup.BWPerPixel       = 1 / Setup.roDuration;
Setup.readoutTime      = Setup.roDuration + 2 * 10e-6; % + 2 x adcDeadTime
Setup.tEx              = SetupRF.tEx ;
Setup.tRef             = SetupRF.tRef;
Setup.tSp              = 0.5 * (Setup.TE1 - Setup.readoutTime - Setup.tRef);
Setup.tSpex            = 0.5 * (Setup.TE1 - Setup.tEx       - Setup.tRef);

% Spoiler area
% [1] explicitly in mT*us/m
% [2] relative to the net area of gradients required to achieve desired resolution. 
% Two sets of variables are given at least one must be empty.
Setup.SpoilerArea_RO = [] ; % [mT*us/m]
Setup.SpoilerArea_PE = [] ; % [mT*us/m]
Setup.SpoilerArea_3D = [] ; % [mT*us/m]
Setup.SpoilerAreaFactor_RO = 4 ;
Setup.SpoilerAreaFactor_PE = 4 ;
Setup.SpoilerAreaFactor_3D = 4 ;

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

%% prep system
[sys, sys_soft, seq, Actual] = prep_System(Actual);

%% multi-slice
[Slice.SliceLabel, Slice.SliceOrder, Slice.SlicePositions] = prep_SlicePositions(Actual);
Actual.Slice = Slice;

%% Phase encoding
[Actual.nAcq, Actual.nExcit, PE3D] = prep_PE3DOrder(Actual);
Actual.PE3D = PE3D;
% plot_PE(Actual.R, Actual.nRO, Actual.nPE, PE.pe_Img, PE.pe_Ref, PE.pe_ImgAndRef, PE.pe_full)
% fig = plot_PEOrder(Actual.R, Actual.nRO, Actual.nPE, PE.PElabel);
% print(fig, '-dpng', '-loose', '-r300', '-image', sprintf('PEMode_%s_%s_R%s.png', Actual.PEMode, Actual.AccelerationMode, num2str(Actual.R)));
%% RF and Gz
[RF, Grad] = prep_Excitation(RF, Grad, Actual, sys_soft);
[RF, Grad] = prep_Refocusing(RF, Grad, Actual, sys_soft);
if strcmp(Actual.IR, 'on')
    [RF, Grad] = prep_Inversion(RF, Grad, Actual, sys_soft);
end
%%
[ADC, Grad] = prep_Gradient_GR(Grad, ADC, Actual, sys_soft); % readout gradients

[Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, Actual, sys_soft);        % split gradients and recombine into blocks

%% Define sequence blocks
[seq, Label] = prep_Kernel(seq, Actual, ADC, sys_soft);


if strcmpi(Actual.IR, 'on')
    [seq] = prep_Seqloop_IR_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft);
else
    [seq] = prep_Seqloop_gSlider(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft);
end

%% timing & PNS & definition
[seq] = check_Timing(seq);
disp(seq.getDefinition('TotalDuration'));
check_Label(seq);
check_PNS(seq, Actual);
[seq, prefix] = prep_Definition(seq, Actual, PE);

%%
outpath = 'seq/';
seqname = sprintf('gSliderT1_TRAPS70_TI%s%s%s_%s_r%s_nRef%s_sli%s', num2str(Actual.TI*1e3), SetupRF.typeInv, num2str(SetupRF.tbpInv),...
    prefix, num2str(Actual.R), num2str(PE.nRef), num2str(Actual.nSlice));
seq.write(strcat(outpath, seqname,'.seq'))

%% plot
timeRange = [(Actual.nDummy)*Actual.TR, (Actual.nDummy+1)*Actual.TR];
if strcmp(Actual.NoiseScan, 'on'); timeRange = timeRange + Actual.TR; end
fig = seq.plot('showBlock',true,'showGuides',1,'stacked',0,'timeDisp','s', 'timeRange', timeRange); %'Label', 'LIN,PAR,ECO,REP';

% fig = seq.plot('Label', 'LIN,SLC,SEG,REP,NAV', 'timeRange', [0*Actual.TR, 2*Actual.TR+1] + 0);
% fig = fig.f;
%%
% % set(fig, 'InvertHardcopy', 'off');  
% set(fig, 'PaperUnits', 'centimeters');
% set(fig, 'PaperPosition', [0, 0, 7, 5]);
% ax = findall(fig, 'Type', 'axes');  % 如果有多个 axes，也能同时处理
% set(findall(fig, '-property', 'FontSize'), 'FontSize',5);
% lgds = findall(fig, 'Type', 'legend');
% for i = 1:length(lgds)
%     % lgds(i).Location = 'northeast';
%     lgds(i).FontSize = 3;
%     % lgds(i).Box = 'off';  % 去掉边框
%     lgds(i).ItemTokenSize = [2, 2];
% end
% 
% % for i = 1:length(ax)
% %     outerpos = ax(i).OuterPosition;
% %     ti = ax(i).TightInset;
% %     left = outerpos(1) + ti(1);
% %     bottom = outerpos(2) + ti(2);
% %     width = outerpos(3) - ti(1) - ti(3);
% %     height = outerpos(4) - ti(2) - ti(4);
% %     ax(i).Position = [left, bottom, width, height];
% % end
% outpath = sprintf('D:/0_/中期报告_2025/gSliderTSE/%s_1TR.png', seqname);
% % exportgraphics(fig, outpath, 'Resolution', 300, 'ContentType', 'image', 'BackgroundColor', 'none');
% print(fig, '-dpng', '-loose', '-r300', '-image', outpath);

% [ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();
% % figure; plot(t_ktraj,ktraj'); title('k-space components as functions of time');
% plot_kspace(ktraj, ktraj_adc);


%% very optional slow step, but useful for testing during development e.g. for the real TE, TR or for staying within slew rate limits  
% end
% rep = seq.testReport; 
% fprintf([rep{:}]); 

%%
% gw = seq.waveforms_and_times();
% figure;
% plot(gw{1}(1,:),gw{1}(2,:),gw{2}(1,:),gw{2}(2,:),gw{3}(1,:),gw{3}(2,:)); % plot the entire gradient shape
% title('gradient wave form, in T/m');

