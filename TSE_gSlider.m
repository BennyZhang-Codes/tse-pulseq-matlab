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
params.nSlice           = 5; 
params.nRep             = 5;

params.SliceThickness   = 2e-3;
params.SliceGap         = 0/100 * params.SliceThickness;

params.TE1              = 13e-3; % echo time of the first echo in the train
params.TR               = 5000e-3;
params.TEeff            = 13e-3; % the desired echo time 

params.R                = R;              % Acceleration factor
params.RefLinesRatio    = 30/params.nY;          % PI
params.p                = 20;             % CS
params.r                = 0.1;            % CS

params.rflip = 180; if isscalar(params.rflip), params.rflip=params.rflip+zeros([1 params.nEcho]); end
if strcmpi(params.TRAPS, 'on')
    [params.faRef, ~] = fliptraps(180,params.nEcho,5,'opt',0,2,0,120,90,[1 5 5 params.nEcho]);
end

params.flipex           = 90 * pi / 180;
params.flipref          = params.rflip(1)*pi/180;
params.flipinv          = 180 * pi / 180;

params.roDuration       = 6.0e-3;

params.TI               = 1700e-3; % time of inversion recovery

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
% plot_PEOrder(params.R, params.nX, params.nY, PE.PElabel);

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

% seqname = sprintf('gSlider_%s%s_%s_r%s_nRef%s_sli%s', paramsRF.typeInv, num2str(paramsRF.tbpInv), ...
%     prefix, num2str(params.R), num2str(PE.nRef), num2str(params.nSlice));
% seq.write(strcat(outpath, seqname,'.seq'))

%% plot
seq.plot('Label', 'LIN,SLC,SEG,REP,NAV', 'timeRange', [0*params.TR, 2*params.TR+1] + 0);

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

