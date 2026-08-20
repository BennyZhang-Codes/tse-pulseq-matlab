function [sys, sys_soft, seq, Actual] = prep_System(Actual)
% PREP_SYSTEM Initializes Pulseq system hardware limits and sequence object
% Added Actual to outputs to pass back the asc_file information

   


    % 2. Flexible Settings (Allows overriding via Actual struct)
    rfRingdownTime = 100e-6; if isfield(Actual, 'rfRingdownTime'), rfRingdownTime = Actual.rfRingdownTime; end
    rfDeadTime     = 100e-6; if isfield(Actual, 'rfDeadTime'    ), rfDeadTime     = Actual.rfDeadTime; end
    rfRasterTime   = 1e-6  ; if isfield(Actual, 'rfRasterTime'  ), rfRasterTime   = Actual.rfRasterTime; end

    adcDeadTime    = 10e-6 ; if isfield(Actual, 'adcDeadTime'   ), adcDeadTime    = Actual.adcDeadTime; end
    adcRasterTime  = 100e-9; if isfield(Actual, 'adcRasterTime' ), adcRasterTime  = Actual.adcRasterTime; end

    gradRasterTime = 10e-6 ; if isfield(Actual, 'gradRasterTime'), gradRasterTime = Actual.gradRasterTime; end

    adcSamplesDivisor = 4 ; if isfield(Actual, 'adcSamplesDivisor'), adcSamplesDivisor = Actual.adcSamplesDivisor; end

    MaxGrad_soft = 40 ; if isfield(Actual, 'MaxGrad_soft'), MaxGrad_soft = Actual.MaxGrad_soft; end
    MaxSlew_soft = 150; if isfield(Actual, 'MaxSlew_soft'), MaxSlew_soft = Actual.MaxSlew_soft; end


    % Parse Scanner Hardware Parameters
    switch lower(Actual.ScannerType)
        case 'terra-xr'
            B0       = 6.98;  
            MaxGrad  = 80;
            MaxSlew  = 200; 
            asc_file = 'MP_GPA_K2298_2250V_793A_SC72CD_EGA.asc';
        case 'terra-xj'
            B0       = 6.98; 
            MaxGrad  = 70;
            MaxSlew  = 200; 
            asc_file = 'MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc';
        otherwise
            error('Unsupported ScannerType: %s', Actual.ScannerType);
    end

    % Define Absolute Hardware Limits (sys)
    sys = mr.opts('MaxGrad', MaxGrad, 'GradUnit', 'mT/m', ...
        'MaxSlew', MaxSlew, 'SlewUnit', 'T/m/s', ...
        'rfRingdownTime', rfRingdownTime, 'rfDeadTime', rfDeadTime, ...
        'adcDeadTime', adcDeadTime, 'adcRasterTime', adcRasterTime, ...
        'rfRasterTime', rfRasterTime, 'gradRasterTime', gradRasterTime, ...
        'B0', B0, 'adcSamplesDivisor', adcSamplesDivisor);
    
    % Define Soft Limits (sys_soft) for Arbitrary 3D Trajectories (e.g., Spiral)
    % Derating by sqrt(3) ensures that ANY 3D rotation will never exceed physical max limits

    sys_soft = mr.opts('MaxGrad', MaxGrad_soft, 'GradUnit', 'mT/m', ...
        'MaxSlew', MaxSlew_soft, 'SlewUnit', 'T/m/s', ...
        'rfRingdownTime', rfRingdownTime, 'rfDeadTime', rfDeadTime, ...
        'adcDeadTime', adcDeadTime, 'adcRasterTime', adcRasterTime, ...
        'rfRasterTime', rfRasterTime, 'gradRasterTime', gradRasterTime, ...
        'B0', B0, 'adcSamplesDivisor', adcSamplesDivisor);

    % Initialize Sequence Object
    % Note: Sequence is initialized with the absolute system limits. 
    seq = mr.Sequence(sys);

    warning('OFF', 'mr:restoreShape');

    % Save asc_file back to Actual for future PNS prediction / Export
    Actual.asc_file = asc_file;

    fprintf('prep System >>> ScannerType: %s\n', Actual.ScannerType);
    fprintf('prep System >>> B0: %.3f\n', B0);
    fprintf('prep System >>> Hard limits: %.3f [mT/m] %.3f [T/m/s]\n', MaxGrad, MaxSlew);
    fprintf('prep System >>> Soft limits: %.3f [mT/m] %.3f [T/m/s]\n', MaxGrad_soft, MaxSlew_soft);
end