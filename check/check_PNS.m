function [seq] = check_PNS(seq, Actual)

    asc_file = Actual.asc_file;
    
    [pns_ok, pns_n, pns_c, tpns] = seq.calcPNS(asc_file);

    if (pns_ok)
        fprintf('PNS check passed successfully\n');
    else
        fprintf('PNS check failed! The sequence will probably be stopped by the Gradient Watchdog\n');
    end
end
