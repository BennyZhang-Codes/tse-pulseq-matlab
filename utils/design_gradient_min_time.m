function [g, t, T_total] = design_gradient_min_time(A, tMax, G0, G1, Gmax, Smax, dt)
% DESIGN_GRADIENT_MIN_TIME Finds the minimum rasterized time required to 
% execute a gradient waveform of area A without violating hardware limits.
%
% This function utilizes a discrete integer-grid binary search to permanently 
% eliminate infinite loop vulnerabilities caused by floating-point intervals.

    % Define search boundaries based on discrete raster points
    nMin = 0;
    nMax = ceil(tMax / dt);
    feasible_found = false;
    
    % Binary search over the integer number of raster grids
    while nMin < nMax
        nMid = floor((nMin + nMax) / 2);
        T_try = nMid * dt;
        
        try
            % Attempt to generate the waveform using the ultra-fast O(1) engine
            [~, ~] = design_gradient_waveform(A, T_try, G0, G1, Gmax, Smax, dt);
            
            % If successful, the required time might be shorter; compress upper bound
            nMax = nMid;
            feasible_found = true;
        catch
            % If an error is thrown (time too short), increase the lower bound
            nMin = nMid + 1;
        end
    end
    
    % nMin now represents the absolute minimum number of raster points required
    T_total = nMin * dt;
    
    % Final waveform generation and safety fallback
    try
        [g, t] = design_gradient_waveform(A, T_total, G0, G1, Gmax, Smax, dt);
    catch ME
        if feasible_found
            error('Binary search logic anomaly: Solution was found previously, but final generation failed.');
        else
            % Extremely detailed diagnostic error reporting for physics debugging
            error(['Unable to accommodate area %.3f within tMax = %.2f ms.\n' ...
                   '----------------- DIAGNOSTICS -----------------\n' ...
                   'G0   = %.1f, G1   = %.1f\n' ...
                   'Gmax = %.1f, Smax = %.1f\n' ...
                   '-----------------------------------------------\n' ...
                   'Hint: Verify that your units are completely consistent \n' ...
                   '(e.g., all inputs provided in Hz/m and Hz/m/s).'], ...
                   A, tMax*1e3, G0, G1, Gmax, Smax);
        end
    end
end