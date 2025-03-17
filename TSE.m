%% Create a TSE sequence and export for execution
% 
% The |Sequence| class provides functionality to create magnetic
% resonance sequences (MRI or NMR) from basic building blocks.
%
% This provides an implementation of the open file format for MR sequences
% described here: http://pulseq.github.io/specification.pdf
%
% This example performs the following steps:
% 
% # Create slice selective RF pulse for imaging.
% # Create readout gradient and phase encode strategy.
% # Loop through phase encoding and generate sequence blocks.
% # Write the sequence to an open file format suitable for execution on a
% scanner.
% 
%   Juergen Hennig <juergen.hennig@uniklinik-freiburg.de>
%   Maxim Zaitsev  <maxim.zaitsev@uniklinik-freiburg.de>
 
clc; clear; close all;
%% Instantiation and gradient limits
% The system gradient limits can be specified in various units _mT/m_,
% _Hz/cm_, or _Hz/m_. However the limits will be stored internally in units
% of _Hz/m_ for amplitude and _Hz/m/s_ for slew. Unspecificied hardware
% parameters will be assigned default values.

system = mr.opts('MaxGrad', 40, 'GradUnit', 'mT/m', ...
    'MaxSlew', 180, 'SlewUnit', 'T/m/s', 'rfRingdownTime', 100e-6, ...
    'rfDeadTime', 100e-6, 'adcDeadTime', 10e-6);

seq=mr.Sequence(system);

%% Sequence events
MultiSliceMode = 'Interleaved'; % 'Interleaved' or 'Sequential'
fov = 120e-3;
nX=120; nY=120; nEcho=10; nSlice=9;
rflip = 180;
if isscalar(rflip), rflip=rflip+zeros([1 nEcho]); end
SliceThickness = 2e-3;
SliceGap       = SliceThickness * 0/100;

switch MultiSliceMode
    case 'Sequential'
        SliceLabel = -1 + (1:nSlice);
    case 'Interleaved'
        SliceLabel = -1 + [1:2:nSlice, 2:2:nSlice];
    otherwise
        error('Invalid MultiSliceMode');
end
SliceOrder = SliceLabel - (nSlice-1)/2;
SlicePositions = (SliceThickness + SliceGap) * SliceOrder;

TE1            = 14e-3; % echo time of the first echo in the train
TR             = 5000e-3;
TEeff          = 14e-3; % the desired echo time (can only be achieved approximately)

roDuration     = 6.3e-3;
BWPerPixel     = 1/roDuration;
readoutTime    = roDuration + 2 * system.adcDeadTime;
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

%%
%%% Base gradients
%%% Slice selection
% Key concepts in the sequence description are *blocks* and *events*.
% Blocks describe a group of events that are executed simultaneously. This
% hierarchical structure means that one event can be used in multiple
% blocks, a common occurrence in MR sequences, particularly in imaging
% sequences. 
%
% First, the slice selective RF pulses (and corresponding slice gradient)
% are generated using the |makeSincPulse| function.
% Gradients are recalculated such that their flattime covers the pulse plus
% the rfdead- and rfringdown- times.
%
flipex       = 90 * pi / 180;
[rfex, gz]   = mr.makeSincPulse(flipex, system, 'Duration', tEx,...
    'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', rfex_phase,...
    'use', 'excitation');
GSex         = mr.makeTrapezoid('z', system, 'amplitude', gz.amplitude, 'FlatTime', tExwd, 'riseTime', dG);
rfex.delay   = rfex.deadTime;
% plotPulse(rfex,GSex);

flipref      = rflip(1)*pi/180;
[rfref, gz2] = mr.makeSincPulse(flipref, system, 'Duration', tRef,... % it was a bug as 'gz' was owerwritten
    'SliceThickness', SliceThickness, 'apodization', 0.5, 'timeBwProduct', 4, 'PhaseOffset', rfref_phase, 'use', 'refocusing');
GSref        = mr.makeTrapezoid('z', system, 'amplitude', GSex.amplitude, 'FlatTime', tRefwd, 'riseTime', dG);
rfref.delay  = rfref.deadTime;
% plotPulse(rfref,GSref);

AGSex  = GSex.area/2;
GSspr  = mr.makeTrapezoid('z', system, 'area', AGSex*(1+fspS), 'duration', tSp  , 'riseTime', dG);
GSspex = mr.makeTrapezoid('z', system, 'area', AGSex*fspS    , 'duration', tSpex, 'riseTime', dG);

%%
%%% Readout gradient
% To define the remaining encoding gradients we need to calculate the
% $k$-space sampling. The Fourier relationship
%
% $$\Delta k = \frac{1}{FOV}$$
% 
% Therefore the area of the readout gradient is $n\Delta k$.
deltak   = 1 / fov;
kWidth   = nX * deltak;

GRacq    = mr.makeTrapezoid('x', system, 'FlatArea', kWidth, 'FlatTime', readoutTime, 'riseTime', dG);
adc      = mr.makeAdc(nX, 'Duration', roDuration, 'Delay', system.adcDeadTime);%,'Delay',GRacq.riseTime);
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
% TODO: 1. parallel imaging
%       2. phase encoding order

nExcit   = floor(nY / nEcho);
pe_steps = (1:(nEcho * nExcit)) - 0.5 * nEcho * nExcit - 1;
if mod(nEcho, 2) == 0
    pe_steps=circshift(pe_steps, [0, -round(nExcit / 2)]); % for odd number of echoes we have to apply a shift to avoid a contrast jump at k=0
end
% TSE echo time magic
[~,iPEmin] = min(abs(pe_steps));
k0curr     = floor((iPEmin-1)/nExcit) + 1; % calculate the 'native' central echo index 
k0prescr   = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
PEorder    = circshift(reshape(pe_steps, [nExcit, nEcho])', k0prescr - k0curr);
PElabel    = PEorder - min(PEorder(:));
phaseAreas = PEorder * deltak;

% A = reshape(pe_steps, [nExcit, nEcho])';
% [B, idx] = sort(abs(A), 1, 'ascend'); % 按列排序，升序
% 
% % 使用排序索引重新排列原矩阵
% pe_steps = A(sub2ind(size(A), idx, repmat(1:size(A,2), size(A,1), 1)));
% 
% k0prescr   = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
% PEorder    = circshift(pe_steps, k0prescr - 1);
% PElabel    = PEorder - min(PEorder(:));
% phaseAreas = PEorder * deltak;
plot_PEOrder(PElabel, nX, nY, nExcit, nEcho)
%% split gradients and recombine into blocks
% lets start with slice selection....

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

GR3      = GRpreph;%GRspex;

GR5times = [0 GRspr.riseTime  GRspr.riseTime+GRspr.flatTime GRspr.riseTime+GRspr.flatTime+GRspr.fallTime];
GR5amp   = [0 GRspr.amplitude GRspr.amplitude               GRacq.amplitude];
GR5      = mr.makeExtendedTrapezoid('x', 'times', GR5times, 'amplitudes', GR5amp);

GR6times = [0               readoutTime];
GR6amp   = [GRacq.amplitude GRacq.amplitude];
GR6      = mr.makeExtendedTrapezoid('x', 'times', GR6times, 'amplitudes', GR6amp);

GR7times = [0               GRspr.riseTime  GRspr.riseTime+GRspr.flatTime GRspr.riseTime+GRspr.flatTime+GRspr.fallTime];
GR7amp   = [GRacq.amplitude GRspr.amplitude GRspr.amplitude               0];
GR7      = mr.makeExtendedTrapezoid('x', 'times', GR7times, 'amplitudes', GR7amp);


% and filltimes
%tex=GS1.t(end)+GS2.t(end)+GS3.t(end);
%tref=GS4.t(end)+GS5.t(end)+GS7.t(end)+readoutTime;
%tend=GS4.t(end)+GS5.t(end);
tex  = mr.calcDuration(GS1) + mr.calcDuration(GS2) + mr.calcDuration(GS3);
tref = mr.calcDuration(GS4) + mr.calcDuration(GS5) + mr.calcDuration(GS7) + readoutTime;
tend = mr.calcDuration(GS4) + mr.calcDuration(GS5);


tETrain = tex + nEcho*tref + tend;
TRfill  = (TR - nSlice * tETrain) / nSlice;
% round to gradient raster
TRfill  = system.gradRasterTime * round(TRfill / system.gradRasterTime);
if TRfill<0, TRfill=1e-3; 
    disp(strcat('Warning!!! TR too short, adapted to include all slices to : ',num2str(1000*nSlice*(tETrain+TRfill)),' ms')); 
else
    disp(strcat('TRfill : ',num2str(1000*TRfill),' ms')); 
end
delayTR = mr.makeDelay(TRfill);

%% Define sequence blocks
% Next, the blocks are put together to form the sequence

for iexcit = 0:nExcit % MZ: we start at 0 to have one dummy
    seq.addBlock(mr.makeLabel('SET', 'SLC', 0));
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
        seq.addBlock(delayTR);
        seq.addBlock(mr.makeLabel('INC', 'SLC', 1));
    end
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
% [ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();
% 
% % plot k-spaces
% figure; plot(t_ktraj,ktraj'); title('k-space components as functions of time'); % plot the entire k-space trajectory
% figure; plot(ktraj(1,:),ktraj(2,:),'b',...
%              ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % a 2D plot
% axis('equal'); % enforce aspect ratio for the correct trajectory display
% title('2D k-space');

%%
% Display the first few lines of the output file
% seq.plot('Label', 'LIN,SLC,SEG');

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
% prepare sequence export
res = round(1e3*fov/nX, 2);
a = fix(res);
b = (res - a)*100;
if mod(b, 10) == 0
    b = b/10;
end
prefix = [num2str(a),'p',num2str(b),'_',num2str(nX)];

% sequence definitions: enable 2D multi-slice mode
seq.setDefinition('SliceThickness'   , SliceThickness  );
seq.setDefinition('SliceGap'         , SliceGap        );
seq.setDefinition('SlicePositions'   , SlicePositions );

seq.setDefinition('SliceLabel'       , SliceLabel      );

% sequence definitions: additional information required by GRAPPA
% seq.setDefinition('kSpaceCenterLine' , centerLineIdx-1 ); % PE center line
% seq.setDefinition('PhaseResolution'  , phaseResoluion  ); % phase resolution
fov_z = nSlice*(SliceThickness+SliceGap) - SliceGap;
seq.setDefinition('FOV'              , [fov fov fov_z] );
seq.setDefinition('MatrixSize'       , [nX nY nSlice]  );
seq.setDefinition('TR'               , TR              );
seq.setDefinition('TE'               , TEeff           );

% seq.setDefinition('FlipAngle', alpha);

% seq.setDefinition('Dummy', prepscans);
% seq.setDefinition('ESP', esp);
seq.setDefinition('nSlice'           , nSlice          );
seq.setDefinition('BW'               , BWPerPixel      );
seq.setDefinition('TuborFactor'      , nEcho           );
seq.setDefinition('MultiSliceMode'   , MultiSliceMode  );


seq.setDefinition('Developer'        , 'Jinyuan Zhang' );
seq.setDefinition('Name'             , 'tse'           );

outpath = 'E:/pulseq/idea/pulseq_150/TSE/';
seqname = sprintf('TSE_%s_sli%s_tr%s_te%s_t%s_bw%s', prefix, num2str(nSlice), num2str(TR*1e3), num2str(TEeff*1e3), num2str(nEcho), num2str(round(BWPerPixel)));
seq.write(strcat(outpath, seqname,'.seq'))

%% very optional slow step, but useful for testing during development e.g. for the real TE, TR or for staying within slew rate limits  

% rep = seq.testReport; 
% fprintf([rep{:}]); 