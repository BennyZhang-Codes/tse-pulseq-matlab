function [g, t, T_total] = design_gradient_min_time(A, tMax, G0, G1, Gmax, Smax, dt)
% DESIGN_GRADIENT_MIN_TIME Find the shortest feasible rasterized waveform.
%
% Feasibility at a fixed duration is not generally monotonic when G0/G1 are
% nonzero: a short direct transition can be feasible, followed by an
% infeasible duration gap before an overshoot becomes possible. Therefore,
% the solver scans integer raster counts upward from rigorous lower bounds.
% Cheap continuous-time area envelopes reject impossible durations before
% invoking the full fixed-duration raster solver.

    validate_inputs(A, tMax, G0, G1, Gmax, Smax, dt);

    if abs(G0) > Gmax || abs(G1) > Gmax
        error('design_gradient_min_time:invalidEndpoint', ...
            'Initial or final gradient amplitude exceeds Gmax.');
    end

    maxRasterCount = tMax / dt;
    countTol = 64 * eps(max(1, abs(maxRasterCount)));
    nMax = floor(maxRasterCount + countTol);

    endpointSteps = ceil_raster_steps(abs(G1 - G0) / (Smax * dt));
    areaSteps = ceil_raster_steps(abs(A) / (Gmax * dt));
    nMin = max([1, endpointSteps, areaSteps]);
    if nMin > nMax
        throw_infeasible(A, tMax, G0, G1, Gmax, Smax);
    end

    areaTol = 1e-10 * max([1, abs(A), Gmax * nMax * dt]);
    for rasterCount = nMin:nMax
        duration = rasterCount * dt;
        [areaMin, areaMax] = continuous_area_bounds( ...
            duration, G0, G1, Gmax, Smax);
        if A < areaMin - areaTol || A > areaMax + areaTol
            continue;
        end

        [feasible, candidateG, candidateT] = try_fixed_duration( ...
            A, duration, G0, G1, Gmax, Smax, dt);
        if feasible
            T_total = duration;
            g = candidateG;
            t = candidateT;
            return;
        end
    end

    throw_infeasible(A, tMax, G0, G1, Gmax, Smax);
end


function [feasible, g, t] = try_fixed_duration( ...
        A, duration, G0, G1, Gmax, Smax, dt)
% Treat only the solver's explicit infeasible result as a search decision.

    try
        [g, t] = design_gradient_waveform( ...
            A, duration, G0, G1, Gmax, Smax, dt);
        feasible = true;
    catch ME
        if strcmp(ME.identifier, 'design_gradient_waveform:infeasible')
            feasible = false;
            g = [];
            t = [];
        else
            rethrow(ME);
        end
    end
end


function [areaMin, areaMax] = continuous_area_bounds(T, G0, G1, Gmax, Smax)
% Exact continuous-time area bounds from slew/amplitude endpoint envelopes.

    % Largest possible gradient at each time:
    % min(Gmax, G0 + S*t, G1 + S*(T-t)).
    upperSlopes = [0, Smax, -Smax];
    upperIntercepts = [Gmax, G0, G1 + Smax * T];
    areaMax = integrate_piecewise_envelope( ...
        upperSlopes, upperIntercepts, T, true);

    % Smallest possible gradient at each time:
    % max(-Gmax, G0 - S*t, G1 - S*(T-t)).
    lowerSlopes = [0, -Smax, Smax];
    lowerIntercepts = [-Gmax, G0, G1 - Smax * T];
    areaMin = integrate_piecewise_envelope( ...
        lowerSlopes, lowerIntercepts, T, false);
end


function area = integrate_piecewise_envelope(slopes, intercepts, T, takeMinimum)
% Integrate a min/max envelope of affine functions at all intersections.

    breakpoints = [0, T];
    for first = 1:(numel(slopes) - 1)
        for second = (first + 1):numel(slopes)
            slopeDifference = slopes(first) - slopes(second);
            if slopeDifference == 0
                continue;
            end
            crossing = (intercepts(second) - intercepts(first)) / ...
                slopeDifference;
            if crossing > 0 && crossing < T
                breakpoints(end + 1) = crossing; %#ok<AGROW>
            end
        end
    end

    breakpoints = unique(sort(breakpoints));
    values = slopes(:) * breakpoints + intercepts(:);
    if takeMinimum
        envelope = min(values, [], 1);
    else
        envelope = max(values, [], 1);
    end
    area = trapz(breakpoints, envelope);
end


function nSteps = ceil_raster_steps(value)
% Ceil a non-negative raster count without promoting an exact integer by one.

    value = max(0, value);
    valueTol = 64 * eps(max(1, abs(value)));
    nSteps = ceil(max(0, value - valueTol));
end


function throw_infeasible(A, tMax, G0, G1, Gmax, Smax)
    error('design_gradient_min_time:infeasible', ...
        ['Unable to accommodate area %.9g within tMax = %.6g ms.\n' ...
         'G0 = %.9g, G1 = %.9g, Gmax = %.9g, Smax = %.9g.\n' ...
         'Verify that all gradient amplitude, slew, area, and time units agree.'], ...
        A, tMax * 1e3, G0, G1, Gmax, Smax);
end


function validate_inputs(A, tMax, G0, G1, Gmax, Smax, dt)
    inputs = {A, tMax, G0, G1, Gmax, Smax, dt};
    scalarFiniteReal = cellfun(@(value) isnumeric(value) && isreal(value) && ...
        isscalar(value) && isfinite(value), inputs);
    if ~all(scalarFiniteReal) || ...
            tMax <= 0 || Gmax <= 0 || Smax <= 0 || dt <= 0
        error('design_gradient_min_time:invalidInput', ...
            ['All inputs must be finite real scalars, and tMax, Gmax, ' ...
             'Smax, and dt must be positive.']);
    end
end
