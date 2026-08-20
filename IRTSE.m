clc; clear; close all;
%% 2D IR-TSE sequence
addpath(genpath('pulseq'));
addpath(genpath('plot'));
% Instantiation and gradient limits
system = mr.opts('MaxGrad', 40, 'GradUnit', 'mT/m', ...
    'MaxSlew', 180, 'SlewUnit', 'T/m/s', 'rfRingdownTime', 100e-6, ...
    'rfDeadTime', 100e-6, 'adcDeadTime', 10e-6);
seq=mr.Sequence(system);
%% Sequence Parameters
PEMode         = 'CentricHalf'; % 'CentricFull', 'CentricHalf', 'Linear'
MultiSliceMode = 'Interleaved'; % 'Interleaved' or 'Sequential'
fovRead  = 120e-3;
fovPhase = 120e-3;
nX=300; nY=300; nEcho=10; nSlice=5; nRep=1;
nDummy = 1;

R = 2;
RefLinesRatio =29/nY;

readoutOS = 2 ; % oversampling factor for readout direction
rflip = 180;
if isscalar(rflip), rflip=rflip+zeros([1 nEcho]); end
SliceThickness = 2e-3;
SliceGap       = SliceThickness * 0/100;

[SliceLabel, SliceOrder, SlicePositions] = prep_SlicePositions(MultiSliceMode, nSlice, SliceThickness, SliceGap);

TE1            = 14e-3; % echo time of the first echo in the train
TR             = 5000e-3;
TEeff          = 14e-3; % the desired echo time (can only be achieved approximately)

roDuration     = 6.3e-3;
BWPerPixel     = 1/roDuration;
readoutTime    = roDuration + 2 * system.adcDeadTime;
tIR            = 3e-3;
tIrwd          = tIR + system.rfRingdownTime + system.rfDeadTime;
tEx            = 2.5e-3; 
tExwd          = tEx + system.rfRingdownTime + system.rfDeadTime;
tRef           = 3e-3; 
tRefwd         = tRef + system.rfRingdownTime + system.rfDeadTime;
tSp            = 0.5*(TE1-readoutTime-tRefwd);
tSpex          = 0.5*(TE1-tExwd-tRefwd);
fspR           = 1.0;
fspS           = 0.5;
dG             = 250e-6; % 'standard' ramp time - makes sequence structure much simpler

rfex_phase     = pi/2; % MZ: we need to maintain these as variables because we will overwrtite phase offsets for multiple slice positions
rfref_phase    = 0;
rfir_phase     = 0;
%%
%%% Base gradients
%%% Slice selection
% First, the slice selective RF pulses (and corresponding slice gradient)
% are generated using the |makeSincPulse| function.
% Gradients are recalculated such that their flattime covers the pulse plus
% the rfdead- and rfringdown- times.
flipir      = 180*pi/180;
[rfir, gz]   = mr.makeSincPulse(flipir, system, 'Duration', tIR,...
    'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', rfir_phase, 'use', 'inversion');
GSir         = mr.makeTrapezoid('z', system, 'amplitude', gz.amplitude, 'FlatTime', tIrwd, 'riseTime', dG);
rfir.delay  = rfir.deadTime;


flipex       = 90 * pi / 180;
[rfex, gz_ex]   = mr.makeSincPulse(flipex, system, 'Duration', tEx,...
    'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', rfex_phase,...
    'use', 'excitation');
GSex         = mr.makeTrapezoid('z', system, 'amplitude', gz_ex.amplitude, 'FlatTime', tExwd, 'riseTime', dG);
rfex.delay   = rfex.deadTime;
% plotPulse(rfex,GSex);

flipref      = rflip(1)*pi/180;
[rfref, gz_ref] = mr.makeSincPulse(flipref, system, 'Duration', tRef,... % it was a bug as 'gz' was owerwritten
    'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', rfref_phase, 'use', 'refocusing');
GSref        = mr.makeTrapezoid('z', system, 'amplitude', gz_ref.amplitude, 'FlatTime', tRefwd, 'riseTime', dG);
rfref.delay  = rfref.deadTime;
% plotPulse(rfref,GSref);

AGir   = GSir.area; 
GSspir = mr.makeTrapezoid('z', system, 'area', AGir, 'Duration', tSp, 'riseTime', dG);

AGSex  = GSex.area/2;
GSspr  = mr.makeTrapezoid('z', system, 'area', AGSex*(1+fspS), 'duration', tSp  , 'riseTime', dG);
GSspex = mr.makeTrapezoid('z', system, 'area', AGSex*fspS    , 'duration', tSpex, 'riseTime', dG);

%%
%%% Readout gradient
deltakX   = 1 / fovRead;
deltakY   = 1 / fovPhase;

GRacq    = mr.makeTrapezoid('x', system, 'FlatArea', nX * deltakX, 'FlatTime', readoutTime, 'riseTime', dG);
adc      = mr.makeAdc(nX*readoutOS, 'Duration', roDuration, 'Delay', system.adcDeadTime, 'system', system);%,'Delay',GRacq.riseTime);
GRspr    = mr.makeTrapezoid('x', system, 'area', GRacq.area*fspR    , 'duration', tSp  , 'riseTime', dG);
GRspex   = mr.makeTrapezoid('x', system, 'area', GRacq.area*(1+fspR), 'duration', tSpex, 'riseTime', dG);

AGRspr   = GRspr.area;%GRacq.area/2*fspR;
AGRpreph = GRacq.area/2+AGRspr;%GRacq.area*(1+fspR)/2;
GRpreph  = mr.makeTrapezoid('x', system, 'Area', AGRpreph, 'duration', tSpex, 'riseTime', dG);

%%
%%% Phase encoding
% To move the $k$-space trajectory away from 0 prior to the readout a
% prephasing gradient must be used. Furthermore rephasing of the slice
% select gradient is required.
[PEorder, PElabel, phaseAreas, nAcq, nRef, nExcit, ...
pe_full, pe_Img, pe_Ref, pe_ImgAndRef, ...
kSpaceCenterLine, FirstRefLine] = ...
prep_PEOrder_PI(PEMode, nY, nEcho, TEeff, TE1, deltakY, R, RefLinesRatio);

%% split gradients and recombine into blocks
% Gz for excitation
GS1times = [0 GSex.riseTime];
GS1amp   = [0 GSex.amplitude];
GS1      = mr.makeExtendedTrapezoid('z', 'times', GS1times, 'amplitudes', GS1amp);

GS2times = [0              GSex.flatTime];
GS2amp   = [GSex.amplitude GSex.amplitude];
GS2      = mr.makeExtendedTrapezoid('z', 'times', GS2times, 'amplitudes', GS2amp);

GS3times = [0              GSspex.riseTime  GSspex.riseTime+GSspex.flatTime GSspex.riseTime+GSspex.flatTime+GSspex.fallTime];
GS3amp   = [GSex.amplitude GSspex.amplitude GSspex.amplitude                GSref.amplitude];
GS3      = mr.makeExtendedTrapezoid('z', 'times', GS3times, 'amplitudes', GS3amp);

GS4times = [0               GSref.flatTime];
GS4amp   = [GSref.amplitude GSref.amplitude];
GS4      = mr.makeExtendedTrapezoid('z', 'times', GS4times, 'amplitudes', GS4amp);

GS5times = [0               GSspr.riseTime  GSspr.riseTime+GSspr.flatTime GSspr.riseTime+GSspr.flatTime+GSspr.fallTime];
GS5amp   = [GSref.amplitude GSspr.amplitude GSspr.amplitude               0];
GS5      = mr.makeExtendedTrapezoid('z', 'times', GS5times, 'amplitudes', GS5amp);

GS7times = [0 GSspr.riseTime  GSspr.riseTime+GSspr.flatTime GSspr.riseTime+GSspr.flatTime+GSspr.fallTime];
GS7amp   = [0 GSspr.amplitude GSspr.amplitude               GSref.amplitude];
GS7      = mr.makeExtendedTrapezoid('z','times', GS7times, 'amplitudes', GS7amp);

% and now the readout gradient....
GR3      = GRpreph;

GR5times = [0 GRspr.riseTime  GRspr.riseTime+GRspr.flatTime GRspr.riseTime+GRspr.flatTime+GRspr.fallTime];
GR5amp   = [0 GRspr.amplitude GRspr.amplitude               GRacq.amplitude];
GR5      = mr.makeExtendedTrapezoid('x', 'times', GR5times, 'amplitudes', GR5amp);

GR6times = [0               readoutTime];
GR6amp   = [GRacq.amplitude GRacq.amplitude];
GR6      = mr.makeExtendedTrapezoid('x', 'times', GR6times, 'amplitudes', GR6amp);

GR7times = [0               GRspr.riseTime  GRspr.riseTime+GRspr.flatTime GRspr.riseTime+GRspr.flatTime+GRspr.fallTime];
GR7amp   = [GRacq.amplitude GRspr.amplitude GRspr.amplitude               0];
GR7      = mr.makeExtendedTrapezoid('x', 'times', GR7times, 'amplitudes', GR7amp);


TI = 1700e-3;
delayTI = mr.makeDelay(TI);

% and filltimes
tex  = mr.calcDuration(GS1) + mr.calcDuration(GS2) + mr.calcDuration(GS3);
tref = mr.calcDuration(GS4) + mr.calcDuration(GS5) + mr.calcDuration(GS7) + readoutTime;
tend = mr.calcDuration(GS4) + mr.calcDuration(GS5);
tir = mr.calcDuration(GSir);

Refbtw = 170e-3;
IRbtw = tex + nEcho*tref + tend + Refbtw - tir;
IRpst = TI - (nSlice-1) * tir - nSlice * IRbtw;
IRdur = (IRbtw+tir)*nSlice + IRpst;
tETrain = tex + nEcho*tref +  tend;
delayRefbtw = mr.makeDelay(Refbtw);
delayIRbtw = mr.makeDelay(IRbtw);
delayIRpst = mr.makeDelay(IRpst);
TRfill = TR - IRdur - nSlice * tETrain -nSlice * Refbtw;

% round to gradient raster
TRfill  = system.gradRasterTime * round(TRfill / system.gradRasterTime);
if TRfill<0, TRfill=1e-3; 
    disp(strcat('Warning!!! TR too short, adapted to include all slices to : ',num2str(1000*nSlice*(tETrain+TRfill)),' ms')); 
else
    disp(strcat('TRfill : ',num2str(1000*TRfill),' ms')); 
end
delayTR = mr.makeDelay(TRfill);

%% Define sequence blocks
% Set PAT scan flag
lblSetRefScan            = mr.makeLabel('SET','REF', true );
lblSetRefAndImaScan      = mr.makeLabel('SET','IMA', true );
lblResetRefScan          = mr.makeLabel('SET','REF', false);
lblResetRefAndImaScan    = mr.makeLabel('SET','IMA', false);
lblSetRefScan.id         = seq.registerLabelEvent(lblSetRefScan        );
lblSetRefAndImaScan.id   = seq.registerLabelEvent(lblSetRefAndImaScan  );
lblResetRefScan.id       = seq.registerLabelEvent(lblResetRefScan      );
lblResetRefAndImaScan.id = seq.registerLabelEvent(lblResetRefAndImaScan);

% Add noise scans.
seq.addBlock(mr.makeLabel('SET', 'LIN', 0), mr.makeLabel('SET','SLC', 0));
seq.addBlock(adc, mr.makeLabel('SET', 'NOISE', true), lblResetRefScan, lblResetRefAndImaScan);
seq.addBlock(mr.makeLabel('SET', 'NOISE', false));
seq.addBlock(mr.makeDelay(1 - mr.calcDuration(adc)));

% Next, the blocks are put together to form the sequence
seq.addBlock(mr.makeLabel('SET', 'REP', 0));
for irep = 1:nRep
    for iexcit = (1-nDummy):nExcit 
        seq.addBlock(mr.makeLabel('SET', 'SLC', 0));
        for isli = 1:nSlice
            rfir.freqOffset   = GSir.amplitude * SlicePositions(isli);     
            rfir.phaseOffset  = rfir_phase - 2 * pi * rfir.freqOffset * mr.calcRfCenter(rfir);

            seq.addBlock(GSir, rfir);
            seq.addBlock(delayIRbtw);
        end
        seq.addBlock(delayIRpst)
        for isli = 1:nSlice
            % seq.addBlock(mr.makeLabel('SET', 'SLC', SliceLabel(isli)));
            rfex.freqOffset   = GSex.amplitude  * SlicePositions(isli);
            rfref.freqOffset  = GSref.amplitude * SlicePositions(isli);
            rfex.phaseOffset  = rfex_phase  - 2 * pi *  rfex.freqOffset * mr.calcRfCenter(rfex); % align the phase for off-center slices
            rfref.phaseOffset = rfref_phase - 2 * pi * rfref.freqOffset * mr.calcRfCenter(rfref); % dito
        
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
                GPpre = mr.makeTrapezoid('y', system, 'Area',  phaseArea, 'Duration', tSp, 'riseTime', dG);
                GPrew = mr.makeTrapezoid('y', system, 'Area', -phaseArea, 'Duration', tSp, 'riseTime', dG);
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
            seq.addBlock(delayRefbtw);
            seq.addBlock(mr.makeLabel('INC', 'SLC', 1));
        end
        seq.addBlock(delayTR);
    end
    seq.addBlock(mr.makeLabel('INC', 'REP', 1));
end
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
seq.plot('Label', 'LIN,SLC,SEG,REP', 'timeRange', [0*TR, 5*TR] + 1);

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

%% Write to file
% prepare sequence export
res = round(1e3*fovRead/nX, 2);
a = fix(res);
b = (res - a)*100;
if mod(b, 10) == 0
    b = b/10;
end
prefix = [num2str(a),'p',num2str(b),'_',num2str(nX)];

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
seq.setDefinition('MultiSliceMode'       , MultiSliceMode            );
seq.setDefinition('PEMode'               , PEMode                    );

seq.setDefinition('Developer'            , 'Jinyuan Zhang'           );
seq.setDefinition('Name'                 , 'tse'                     );
  
outpath = '/Users/zhentianxiang/Desktop/seq/seq331/';
% seqname = sprintf('TSE_%s_sli%s_tr%s_te%s_t%s_bw%s_%s', prefix, num2str(nSlice), num2str(TR*1e3), num2str(TEeff*1e3), num2str(nEcho), num2str(round(BWPerPixel)), PEMode);
seqname = sprintf('TSE_%s_r%s_nRef%s_sli%s', prefix, num2str(R), num2str(nRef), num2str(nSlice));
% seq.write(strcat(outpath, seqname,'.seq'))
%% very optional slow step, but useful for testing during development e.g. for the real TE, TR or for staying within slew rate limits  
% end
% rep = seq.testReport; 
% fprintf([rep{:}]); 