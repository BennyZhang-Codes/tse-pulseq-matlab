clc; clear; close all;
% for R=2:2
R=2;
close all;
% R = 3;
%% 2D TSE Sequence
addpath(genpath('pulseq'));
addpath(genpath('prep'  ));
addpath(genpath('check' ));
addpath(genpath('plot'  ));
addpath(genpath('utils' ));
addpath(genpath('VERSE' ));
% Instantiation and gradient limits
sys = mr.opts('MaxGrad', 40, 'GradUnit', 'mT/m', ...
    'MaxSlew', 150, 'SlewUnit', 'T/m/s', 'rfRingdownTime', 20e-6, ...
    'rfDeadTime', 100e-6, 'adcDeadTime', 10e-6);
seq=mr.Sequence(sys);

Grad  = struct();
RF    = struct();
ADC   = struct();
Delay = struct(); 
%% Sequence Parameters
params.PEMode           = 'CentricFull'; % 'Centric', 'Linear'
params.AccelerationMode = 'PI';          % 'PI', 'CS'
params.MultiSliceMode   = 'Interleaved'; % 'Interleaved' or 'Sequential'

params.IR               = 'on';          % Inversion Recovery
params.IRMode           = 'Interleaved'; % 'Interleaved' or 'Sequential'
params.PhaseCorrection  = 'on';

params.TRAPS            = 'on';

params.NoiseScan        = 'on';  
params.VERSE            = 'off';

params.nDummy           = 1;             % number of pre-scans

params.fovRead          = 200e-3;
params.fovPhase         = 160e-3;
params.nX               = 500; 
params.nY               = 400; 
params.nEcho            = 10; 
params.nSlice           = 10; 
params.nRep             = 5;

params.SliceThickness   = 2e-3;
params.SliceGap         = 0/100 * params.SliceThickness;

params.TE1              = 13e-3; % echo time of the first echo in the train
params.TR               = 5600e-3;
params.TEeff            = 13e-3; % the desired echo time 

params.R                = R;              % Acceleration factor
params.RefLinesRatio    = 30/params.nY;          % PI
params.p                = 20;             % CS
params.r                = 0.1;            % CS

params.rflip = 180; if isscalar(params.rflip), params.rflip=params.rflip+zeros([1 params.nEcho]); end
if strcmpi(params.TRAPS, 'on')
    k0_echo = max(round(params.TEeff/params.TE1), 1); % echo to be aligned to the k-space center 
    [params.faRef, ~] = fliptraps(180,params.nEcho,5,'opt',0,2,0,70,70,[k0_echo k0_echo+4 k0_echo+4 params.nEcho]);
end

params.flipex           = 90 * pi / 180;
params.flipref          = params.rflip(1)*pi/180;
params.flipinv          = 180 * pi / 180;

params.roDuration       = 6.0e-3;

params.TI               = 2000e-3; % time of inversion recovery

paramsRF.typeEx         = 'gSlider'   ;
paramsRF.typeRef        = 'slr'   ;
paramsRF.typeInv        = 'slr'   ;
paramsRF.tEx            = 5.12e-3   ; 
paramsRF.tRef           = 3.84e-3     ; 
paramsRF.tInv           = 3.84e-3     ;
paramsRF.tbpEx          = 12       ;
paramsRF.tbpRef         = 6        ;
paramsRF.tbpInv         = 6        ;
paramsRF.phaseEx        = pi/2     ;   
paramsRF.phaseRef       = 0        ;
paramsRF.phaseInv       = 0        ;

params.fspR             = 0.5       ; % ratio of spoiling area to readout area
params.fspS             = 0.5      ; % ratio of spoiling area to Gz rephasing area
params.dG               = 250e-6   ; % 'standard' ramp time - makes sequence structure much simpler
params.readoutOS        = 2        ; % oversampling factor for readout direction

params.paramsRF         = paramsRF;
%% init
params.BWPerPixel       = 1 / params.roDuration;
params.readoutTime      = params.roDuration + 2 * sys.adcDeadTime;
params.tEx              = paramsRF.tEx ;
params.tRef             = paramsRF.tRef;
params.tSp              = 0.5 * (params.TE1 - params.readoutTime - params.tRef);
params.tSpex            = 0.5 * (params.TE1 - params.tEx       - params.tRef);

%% multi-slice
[Slice.SliceLabel, Slice.SliceOrder, Slice.SlicePositions] = prep_SlicePositions(params);
params.Slice = Slice;

%% Phase encoding
[params.nAcq, params.nExcit, PE] = prep_PEOrder(params);
params.PE = PE;
% plot_PE(params.R, params.nX, params.nY, PE.pe_Img, PE.pe_Ref, PE.pe_ImgAndRef, PE.pe_full)
% fig = plot_PEOrder(params.R, params.nX, params.nY, PE.PElabel);
% print(fig, '-dpng', '-loose', '-r300', '-image', sprintf('PEMode_%s_%s_R%s.png', params.PEMode, params.AccelerationMode, num2str(params.R)));
%% RF and Gz
[RF, Grad] = prep_Excitation(RF, Grad, params, sys);
[RF, Grad] = prep_Refocusing(RF, Grad, params, sys);
if strcmp(params.IR, 'on')
    [RF, Grad] = prep_Inversion(RF, Grad, params, sys);
end
%%
[ADC, Grad] = prep_Gradient_GR(Grad, ADC, params, sys); % readout gradients

[Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, params, sys);        % split gradients and recombine into blocks

%% Define sequence blocks
[seq, Label] = prep_Kernel(seq, params, ADC);


if strcmpi(params.IR, 'on')
    [seq] = prep_Seqloop_IR_gSlider(seq, params, RF, Grad, ADC, Delay, Label, sys);
else
    [seq] = prep_Seqloop_gSlider(seq, params, RF, Grad, ADC, Delay, Label, sys);
end

%% timing & PNS & definition
[seq] = check_Timing(seq);
disp(seq.getDefinition('TotalDuration'));
% check_Label(seq);
% check_PNS(seq);

[seq, prefix] = prep_Definition(seq, params, PE);
outpath = 'E:/pulseq/idea/pulseq_150/TSE_dev/';
% seqname = sprintf('IRTSE_Sequential_PC%s_%s_%s_%s_%s_r%s_nRef%s_sli%s', params.PhaseCorrection, paramsRF.typeEx, paramsRF.typeRef, paramsRF.typeInv, ...
%     prefix, num2str(params.R), num2str(PE.nRef), num2str(params.nSlice));

seqname = sprintf('gSliderT1_TRAPS70_TI%s%s%s_%s_r%s_nRef%s_sli%s', num2str(params.TI*1e3), paramsRF.typeInv, num2str(paramsRF.tbpInv),...
    prefix, num2str(params.R), num2str(PE.nRef), num2str(params.nSlice));
seq.write(strcat(outpath, seqname,'.seq'))

%% plot
% fig = seq.plot('Label', 'LIN,SLC,SEG,REP,NAV', 'timeRange', [0*params.TR, 2*params.TR+1] + 0);
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

