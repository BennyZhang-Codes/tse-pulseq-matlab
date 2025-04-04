clc; clear; close all;
% for R=1:5
%% 2D TSE Sequence
addpath(genpath('pulseq'));
addpath(genpath('plot'));
% Instantiation and gradient limits
sys = mr.opts('MaxGrad', 40, 'GradUnit', 'mT/m', ...
    'MaxSlew', 180, 'SlewUnit', 'T/m/s', 'rfRingdownTime', 100e-6, ...
    'rfDeadTime', 100e-6, 'adcDeadTime', 10e-6);
seq=mr.Sequence(sys);
%% Sequence Parameters
params.PEMode           = 'CentricFull'; % 'Centric', 'Linear'
params.AccelerationMode = 'PI';          % 'PI', 'CS'
params.MultiSliceMode   = 'Interleaved'; % 'Interleaved' or 'Sequential'

params.IR               = 'on';          % Inversion Recovery
params.IRMode           = 'Interleaved'; % 'Interleaved' or 'Sequential'

params.NoiseScan        = 'on';      

params.nDummy           = 1;             % number of pre-scans

params.fovRead          = 120e-3;
params.fovPhase         = 120e-3;
params.nX               = 300; 
params.nY               = 300; 
params.nEcho            = 10; 
params.nSlice           = 5; 
params.nRep             = 1;

params.SliceThickness   = 2e-3;
params.SliceGap         = 0/100 * params.SliceThickness;

params.TE1              = 14e-3; % echo time of the first echo in the train
params.TR               = 5000e-3;
params.TEeff            = 14e-3; % the desired echo time 

params.R                = 3;              % Acceleration factor
params.RefLinesRatio    = 29/params.nY;          % PI
params.p                = 20;             % CS
params.r                = 0.1;            % CS

params.rflip = 180; if isscalar(params.rflip), params.rflip=params.rflip+zeros([1 params.nEcho]); end
params.flipex           = 90 * pi / 180;
params.flipref          = params.rflip(1)*pi/180;
params.flipir           = 180 * pi / 180;

params.roDuration       = 6.3e-3;

params.TI               = 1700e-3; % time of inversion recovery
paramsRF.tIr            = 3e-3;    % duration of IR RF pulse
paramsRF.tIrwd          = paramsRF.tIr + sys.rfRingdownTime + sys.rfDeadTime;
paramsRF.rfir_phase     = 0;

paramsRF.typeEx         = 'sinc'   ;
paramsRF.typeRef        = 'sinc'   ;
paramsRF.typeInv        = 'sinc'   ;
paramsRF.tEx            = 2.5e-3   ; 
paramsRF.tRef           = 3e-3     ; 
paramsRF.tInv           = 3e-3     ;
paramsRF.tbpEx          = 4        ;
paramsRF.tbpRef         = 4        ;
paramsRF.tbpInv         = 4        ;
paramsRF.phaseEx        = pi/2     ;   
paramsRF.phaseRef       = 0        ;
paramsRF.phaseInv       = 0        ;

params.fspR             = 1.0      ; % ratio of spoiling area to readout area
params.fspS             = 0.5      ; % ratio of spoiling area to Gz rephasing area
params.dG               = 250e-6   ; % 'standard' ramp time - makes sequence structure much simpler
params.readoutOS        = 2        ; % oversampling factor for readout direction

params.paramsRF         = paramsRF;
%% init
params.BWPerPixel       = 1/params.roDuration;
params.readoutTime      = params.roDuration + 2 * sys.adcDeadTime;
params.tExwd            = paramsRF.tEx + sys.rfRingdownTime + sys.rfDeadTime;
params.tRefwd           = paramsRF.tRef + sys.rfRingdownTime + sys.rfDeadTime;
params.tSp              = 0.5*(params.TE1-params.readoutTime-params.tRefwd);
params.tSpex            = 0.5*(params.TE1-params.tExwd-params.tRefwd);

%% multi-slice
[Slice.SliceLabel, Slice.SliceOrder, Slice.SlicePositions] = prep_SlicePositions(params);
params.Slice = Slice;

%% Phase encoding
[params.nAcq, params.nExcit, PE] = prep_PEOrder(params);
params.PE = PE;
plot_PE(params.R, params.nX, params.nY, PE.pe_Img, PE.pe_Ref, PE.pe_ImgAndRef, PE.pe_full)
plot_PEOrder(params.R, params.nX, params.nY, PE.PElabel);

%% RF and Gz
[RF.rfex,    Grad.GSex  ] = prep_Excitation(params, sys);
[RF.rfref,   Grad.GSref ] = prep_Refocusing(params, sys);
[Grad.GSspr, Grad.GSspex] = prep_Gradient_GZSpoiler(Grad, params, sys);
if strcmp(params.IR, 'on')
    [RF.rfir, Grad.GSir] = prep_Refocusing(params, sys);
end

[ADC, Grad] = prep_Gradient_GR(Grad, params, sys); % readout gradients

[Grad] = prep_Gradient_Block(Grad, params);        % split gradients and recombine into blocks

%% Define sequence blocks
[seq, Label] = prep_Kernel(seq, params, ADC);

[seq] = prep_Seqloop(seq, params, RF, Grad, ADC, Label, sys);

%% check whether the timing of the sequence is correct
[ok, error_report]=seq.checkTiming;

if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

%% k-space trajectory calculation
[ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();

% plot k-spaces
figure; plot(t_ktraj,ktraj'); title('k-space components as functions of time'); % plot the entire k-space trajectory
figure; plot(ktraj(1,:),ktraj(2,:),'b',...
             ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % a 2D plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
title('2D k-space');

%%
% Display the first few lines of the output file
seq.plot('Label', 'LIN,SLC,SEG,REP', 'timeRange', [0*params.TR, 5*params.TR] + 1);

%% evaluate label settings more specifically

lbls=seq.evalLabels('evolution','adc');
lbl_names=fieldnames(lbls);
figure; hold on;
for n=1:length(lbl_names)
    plot(lbls.(lbl_names{n}));
end
legend(lbl_names(:));
title('evolution of labels/counters/flags');
xlabel('adc number');

%% PNS calc
warning('OFF', 'mr:restoreShape');
[pns_ok, pns_n, pns_c, tpns] = seq.calcPNS('MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc'); % TERRA-XJ

if (pns_ok)
    fprintf('PNS check passed successfully\n');
else
    fprintf('PNS check failed! The sequence will probably be stopped by the Gradient Watchdog\n');
end

%% Write to file
[seq, prefix] = prep_Definition(seq, params, PE);
outpath = 'E:/pulseq/idea/pulseq_150/TSE/';
% seqname = sprintf('TSE_%s_sli%s_tr%s_te%s_t%s_bw%s_%s', prefix, num2str(nSlice), num2str(TR*1e3), num2str(TEeff*1e3), num2str(nEcho), num2str(round(BWPerPixel)), PEMode);
seqname = sprintf('TSE_%s_r%s_nRef%s_sli%s', prefix, num2str(params.R), num2str(PE.nRef), num2str(params.nSlice));
% seq.write(strcat(outpath, seqname,'.seq'))
%% very optional slow step, but useful for testing during development e.g. for the real TE, TR or for staying within slew rate limits  
% end
% rep = seq.testReport; 
% fprintf([rep{:}]); 