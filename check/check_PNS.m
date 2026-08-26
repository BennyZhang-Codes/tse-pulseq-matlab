function [seq] = check_PNS(seq, Actual)
%CHECK_PNS Run Pulseq PNS prediction for the selected scanner model.
%
% Pulseq Sequence.calcPNS uses the external safe_pns_prediction MATLAB
% package (https://github.com/filip-szczepankiewicz/safe_pns_prediction)
% to evaluate the SAFE model. The package must be installed on the MATLAB
% path. A scanner-specific Siemens MP_GPA*.asc hardware model is also
% required for the current Siemens 7 T implementation.

    if exist('safe_gwf_to_pns', 'file') ~= 2
        error('check_PNS:MissingSafePNSPrediction', [ ...
            'PNS prediction requires the external safe_pns_prediction MATLAB package. ' ...
            'Download https://github.com/filip-szczepankiewicz/safe_pns_prediction ' ...
            'and add it to the MATLAB path before running check_PNS.']);
    end

    asc_file = Actual.asc_file;

    if isempty(asc_file) || exist(asc_file, 'file') ~= 2
        error('check_PNS:MissingHardwareModel', [ ...
            'The scanner-specific SAFE/PNS hardware model was not found: %s. ' ...
            'Provide the appropriate Siemens MP_GPA*.asc file for the target gradient system.'], ...
            char(string(asc_file)));
    end

    [pns_ok, pns_n, pns_c, tpns] = seq.calcPNS(asc_file); %#ok<ASGLU>

    if pns_ok
        fprintf('PNS check passed successfully\n');
    else
        fprintf(['PNS check failed! The sequence will probably be stopped ' ...
            'by the Gradient Watchdog\n']);
    end
end
