function [g, t] = design_gradient_waveform(A, T_total, G0, G1, Gmax, Smax, GradRasterTime)
% DESIGN_GRADIENT_WAVEFORM Design a fixed-duration rasterized gradient.
%
% The continuous analytical solution is used only as a fast seed. The final
% waveform is solved on the integer gradient raster: for each pair of ramp
% lengths the plateau amplitude is recomputed exactly from the target area.
% A small local search is attempted first, followed by a complete raster
% fallback when necessary.
%
% Inputs:
%   A              : Target gradient area
%   T_total        : Total waveform duration (s), on the gradient raster
%   G0             : Initial gradient amplitude
%   G1             : Final gradient amplitude
%   Gmax           : Maximum absolute gradient amplitude
%   Smax           : Maximum absolute slew rate
%   GradRasterTime : Gradient raster time (s)

    validate_inputs(A, T_total, G0, G1, Gmax, Smax, GradRasterTime);

    dt = GradRasterTime;
    nTotal = round(T_total / dt);
    rasterTol = max(1e-12, 64 * eps(max(1, abs(T_total))));
    if nTotal < 1 || abs(T_total - nTotal * dt) > rasterTol
        error('design_gradient_waveform:invalidDuration', ...
            'T_total must be a positive integer multiple of GradRasterTime.');
    end
    T_total = nTotal * dt;

    if abs(G0) > Gmax || abs(G1) > Gmax
        error('design_gradient_waveform:invalidEndpoint', ...
            'Initial or final gradient amplitude exceeds Gmax.');
    end

    % Reject inexpensive necessary-condition failures before any grid search.
    feasibilityTol = 1e-10 * max([1, abs(A), Gmax * T_total]);
    if abs(G1 - G0) > Smax * T_total || ...
            abs(A) > Gmax * T_total + feasibilityTol
        error('design_gradient_waveform:infeasible', ...
            'Requested area or endpoint transition is infeasible in T_total.');
    end

    % Continuous maximum-slew solution: fast initial estimate only.
    GpSeed = solve_continuous_Gp(A, T_total, G0, G1, Smax);
    if isfinite(GpSeed)
        nUpSeed = ceil_raster_steps(abs(GpSeed - G0) / (Smax * dt));
        nDownSeed = ceil_raster_steps(abs(GpSeed - G1) / (Smax * dt));
        nUpSeed = min(nTotal, nUpSeed);
        nDownSeed = min(nTotal, nDownSeed);
    else
        nUpSeed = floor(nTotal / 2);
        nDownSeed = nTotal - nUpSeed;
    end

    % The local search is normally sufficient and keeps the solver fast.
    localRadius = min(32, nTotal);
    solution = search_seeded_grid(A, nTotal, G0, G1, Gmax, Smax, dt, ...
        GpSeed, nUpSeed, nDownSeed, localRadius);

    % The analytical seed can be on the wrong side of a discrete boundary.
    % Fall back to the complete triangular raster domain for correctness.
    if isempty(solution)
        solution = search_interval_grid(A, nTotal, G0, G1, Gmax, Smax, dt, ...
            GpSeed, nUpSeed, nDownSeed);
    end

    if isempty(solution)
        error('design_gradient_waveform:infeasible', ...
            ['No rasterized gradient satisfies area, duration, endpoint, ' ...
             'gradient-amplitude, and slew-rate constraints.']);
    end

    nUp = solution.nUp;
    nDown = solution.nDown;
    nFlat = nTotal - nUp - nDown;
    Gp = solution.Gp;

    % Remove zero-duration segments; Pulseq requires strictly increasing time.
    tSteps = [0, nUp, nUp + nFlat, nTotal];
    gPoints = [G0, Gp, Gp, G1];
    keep = [true, diff(tSteps) > 0];
    t = tSteps(keep) * dt;
    g = gPoints(keep);

    validate_solution(g, t, A, T_total, G0, G1, Gmax, Smax);
end


function solution = search_seeded_grid(A, nTotal, G0, G1, Gmax, Smax, dt, ...
        GpSeed, nUpSeed, nDownSeed, radius)
% Search an L1 neighbourhood around the continuous analytical seed.

    pairCount = 1 + 2 * radius * (radius + 1);
    pairs = zeros(pairCount, 2);
    firstRow = 1;
    for dUp = -radius:radius
        remaining = radius - abs(dUp);
        dDown = (-remaining:remaining).';
        rowCount = numel(dDown);
        rows = firstRow:(firstRow + rowCount - 1);
        pairs(rows, :) = [repmat(nUpSeed + dUp, rowCount, 1), ...
            nDownSeed + dDown];
        firstRow = firstRow + rowCount;
    end

    validPair = pairs(:, 1) >= 0 & pairs(:, 2) >= 0 & ...
        sum(pairs, 2) <= nTotal;
    pairs = pairs(validPair, :);

    solution = [];
    bestScore = [];
    [solution, ~] = select_best_candidate(solution, bestScore, pairs(:, 1), ...
        pairs(:, 2), A, nTotal, G0, G1, Gmax, Smax, dt, ...
        GpSeed, nUpSeed, nDownSeed);
end


function solution = search_interval_grid(A, nTotal, G0, G1, Gmax, Smax, dt, ...
        GpSeed, nUpSeed, nDownSeed)
% Search the complete triangular raster domain in O(nTotal) time.
%
% For a fixed total number of ramp samples R = nUp + nDown, the area-derived
% peak Gp is affine in nUp. Gradient and slew limits therefore reduce to an
% interval of feasible nUp values. A constant number of representative
% integer points is scored from every non-empty interval.

    solution = [];
    bestScore = [];
    chunkSize = 4096;

    for firstRampTotal = 0:chunkSize:nTotal
        lastRampTotal = min(nTotal, firstRampTotal + chunkSize - 1);
        rampTotal = (firstRampTotal:lastRampTotal).';
        [nUp, nDown] = interval_candidate_pairs(A, nTotal, rampTotal, ...
            G0, G1, Gmax, Smax, dt, GpSeed, nUpSeed);

        [solution, bestScore] = select_best_candidate(solution, bestScore, ...
            nUp, nDown, A, nTotal, G0, G1, Gmax, Smax, dt, ...
            GpSeed, nUpSeed, nDownSeed);
    end
end


function [nUpCandidates, nDownCandidates] = interval_candidate_pairs( ...
        A, nTotal, rampTotal, G0, G1, Gmax, Smax, dt, GpSeed, nUpSeed)
% Return guaranteed-feasible integer representatives for each ramp total.

    denominator = 2 * nTotal - rampTotal;
    peakIntercept = (2 * A / dt - rampTotal * G1) ./ denominator;
    peakSlope = (G1 - G0) ./ denominator;
    slewPerRaster = Smax * dt;

    lower = zeros(size(rampTotal));
    upper = rampTotal;
    possible = true(size(rampTotal));

    % Each column represents coefficient*nUp <= rightHandSide.
    coefficients = [peakSlope, ...
                    -peakSlope, ...
                    peakSlope - slewPerRaster, ...
                    -peakSlope - slewPerRaster, ...
                    peakSlope + slewPerRaster, ...
                    slewPerRaster - peakSlope];
    rightHandSides = [Gmax - peakIntercept, ...
                      Gmax + peakIntercept, ...
                      G0 - peakIntercept, ...
                      peakIntercept - G0, ...
                      slewPerRaster * rampTotal + G1 - peakIntercept, ...
                      slewPerRaster * rampTotal + peakIntercept - G1];

    constraintTol = 1e-10 * max(1, Gmax);
    for constraint = 1:size(coefficients, 2)
        coefficient = coefficients(:, constraint);
        rightHandSide = rightHandSides(:, constraint) + constraintTol;

        positive = coefficient > 0;
        negative = coefficient < 0;
        zero = ~(positive | negative);

        upper(positive) = min(upper(positive), ...
            rightHandSide(positive) ./ coefficient(positive));
        lower(negative) = max(lower(negative), ...
            rightHandSide(negative) ./ coefficient(negative));
        possible(zero & rightHandSide < 0) = false;
    end

    lowerTol = 64 * eps(max(1, abs(lower)));
    upperTol = 64 * eps(max(1, abs(upper)));
    nUpMin = max(0, ceil(lower - lowerTol));
    nUpMax = min(rampTotal, floor(upper + upperTol));

    possible = possible & isfinite(nUpMin) & isfinite(nUpMax) & ...
        nUpMin <= nUpMax;
    if ~any(possible)
        nUpCandidates = zeros(0, 1);
        nDownCandidates = zeros(0, 1);
        return;
    end

    rampTotal = rampTotal(possible);
    peakIntercept = peakIntercept(possible);
    peakSlope = peakSlope(possible);
    nUpMin = nUpMin(possible);
    nUpMax = nUpMax(possible);

    span = nUpMax - nUpMin;
    midpoint = nUpMin + 0.5 * span;

    projectedSeed = midpoint;
    nonzeroSlope = peakSlope ~= 0;
    if isfinite(GpSeed)
        projectedSeed(nonzeroSlope) = ...
            (GpSeed - peakIntercept(nonzeroSlope)) ./ peakSlope(nonzeroSlope);
    end

    projectedZero = midpoint;
    projectedG0 = midpoint;
    projectedG1 = midpoint;
    projectedZero(nonzeroSlope) = ...
        -peakIntercept(nonzeroSlope) ./ peakSlope(nonzeroSlope);
    projectedG0(nonzeroSlope) = ...
        (G0 - peakIntercept(nonzeroSlope)) ./ peakSlope(nonzeroSlope);
    projectedG1(nonzeroSlope) = ...
        (G1 - peakIntercept(nonzeroSlope)) ./ peakSlope(nonzeroSlope);

    nUpMatrix = [nUpMin, nUpMin + 1, ...
                 nUpMin + 0.25 * span, midpoint, nUpMin + 0.75 * span, ...
                 nUpMax - 1, nUpMax, ...
                 repmat(nUpSeed, numel(nUpMin), 1), projectedSeed, ...
                 projectedZero, projectedG0, projectedG1];
    nUpMatrix = round(nUpMatrix);

    lowerMatrix = repmat(nUpMin, 1, size(nUpMatrix, 2));
    upperMatrix = repmat(nUpMax, 1, size(nUpMatrix, 2));
    nUpMatrix = max(lowerMatrix, min(upperMatrix, nUpMatrix));

    rampMatrix = repmat(rampTotal, 1, size(nUpMatrix, 2));
    nUpCandidates = nUpMatrix(:);
    nDownCandidates = rampMatrix(:) - nUpCandidates;
end


function [solution, bestScore] = select_best_candidate(solution, bestScore, ...
        nUp, nDown, A, nTotal, G0, G1, Gmax, Smax, dt, ...
        GpSeed, nUpSeed, nDownSeed)
% Compute the exact plateau amplitude and rank all feasible candidates.

    if isempty(nUp)
        return;
    end

    nFlat = nTotal - nUp - nDown;
    denominator = nUp + 2 * nFlat + nDown;
    Gp = (2 * A / dt - nUp * G0 - nDown * G1) ./ denominator;

    gradTol = 1e-10 * max(1, Gmax);
    areaTol = 1e-10 * max([1, abs(A), Gmax * nTotal * dt]);

    % A zero-duration ramp is legal only when its two amplitudes coincide.
    zeroUp = nUp == 0;
    zeroDown = nDown == 0;
    validZeroUp = ~zeroUp | abs(Gp - G0) <= gradTol;
    validZeroDown = ~zeroDown | abs(Gp - G1) <= gradTol;

    % Snap only degenerate zero-duration endpoints. Recheck area afterwards.
    Gp(zeroUp & validZeroUp) = G0;
    Gp(zeroDown & validZeroDown) = G1;

    slewUp = zeros(size(Gp));
    slewDown = zeros(size(Gp));
    positiveUp = nUp > 0;
    positiveDown = nDown > 0;
    slewUp(positiveUp) = abs(Gp(positiveUp) - G0) ./ ...
        (nUp(positiveUp) * dt);
    slewDown(positiveDown) = abs(Gp(positiveDown) - G1) ./ ...
        (nDown(positiveDown) * dt);

    areaActual = 0.5 * dt .* (nUp .* (G0 + Gp) + ...
        2 * nFlat .* Gp + nDown .* (Gp + G1));

    feasible = isfinite(Gp) & nFlat >= 0 & validZeroUp & validZeroDown & ...
        abs(areaActual - A) <= areaTol & abs(Gp) <= Gmax & ...
        slewUp <= Smax & slewDown <= Smax;
    if ~any(feasible)
        return;
    end

    nUp = nUp(feasible);
    nDown = nDown(feasible);
    nFlat = nFlat(feasible);
    Gp = Gp(feasible);
    slewUp = slewUp(feasible);
    slewDown = slewDown(feasible);

    if isfinite(GpSeed)
        seedDistance = abs(Gp - GpSeed) / max(1, Gmax);
    else
        seedDistance = zeros(size(Gp));
    end

    polarityPenalty = double(abs(A) > areaTol & sign(A) .* Gp < -gradTol);
    scores = [polarityPenalty, ...
              max(slewUp, slewDown) / Smax, ...
              (slewUp + slewDown) / Smax, ...
              seedDistance, ...
              (nUp + nDown) / max(1, nTotal), ...
              (abs(nUp - nUpSeed) + abs(nDown - nDownSeed)) / max(1, nTotal)];

    index = lexicographic_min_index(scores);
    candidateScore = scores(index, :);

    if isempty(bestScore) || score_is_better(candidateScore, bestScore)
        solution = struct('nUp', nUp(index), 'nDown', nDown(index), ...
            'nFlat', nFlat(index), 'Gp', Gp(index), ...
            'slewUp', slewUp(index), 'slewDown', slewDown(index));
        bestScore = candidateScore;
    end
end


function index = lexicographic_min_index(scores)
% Find the lexicographic minimum in linear time.

    remaining = (1:size(scores, 1)).';
    for column = 1:size(scores, 2)
        values = scores(remaining, column);
        bestValue = min(values);
        remaining = remaining(values == bestValue);
        if isscalar(remaining)
            break;
        end
    end
    index = remaining(1);
end


function better = score_is_better(score, reference)
% Lexicographic comparison without sorting.

    better = false;
    for column = 1:numel(score)
        if score(column) < reference(column)
            better = true;
            return;
        elseif score(column) > reference(column)
            return;
        end
    end
end


function nSteps = ceil_raster_steps(value)
% Ceil a non-negative raster count without promoting an exact integer by one.

    value = max(0, value);
    valueTol = 64 * eps(max(1, abs(value)));
    nSteps = ceil(max(0, value - valueTol));
end


function validate_solution(g, t, A, T_total, G0, G1, Gmax, Smax)
% Independent postcondition checks on the waveform actually returned.

    areaTol = 1e-10 * max([1, abs(A), Gmax * T_total]);
    gradTol = 1e-10 * max(1, Gmax);
    slewTol = 1e-10 * max(1, Smax);
    timeTol = max(1e-12, 1e-9 * T_total);

    if any(~isfinite(g)) || any(~isfinite(t)) || ...
            numel(g) ~= numel(t) || numel(t) < 2 || any(diff(t) <= 0)
        error('design_gradient_waveform:internalValidation', ...
            'Generated waveform contains invalid or non-increasing samples.');
    end
    if abs(t(1)) > timeTol || abs(t(end) - T_total) > timeTol
        error('design_gradient_waveform:internalValidation', ...
            'Generated waveform duration is inconsistent with T_total.');
    end
    if abs(g(1) - G0) > gradTol || abs(g(end) - G1) > gradTol
        error('design_gradient_waveform:internalValidation', ...
            'Generated waveform endpoints are inconsistent with G0/G1.');
    end
    if max(abs(g)) > Gmax + gradTol
        error('design_gradient_waveform:internalValidation', ...
            'Generated waveform exceeds Gmax.');
    end

    slew = abs(diff(g) ./ diff(t));
    if any(slew > Smax + slewTol)
        error('design_gradient_waveform:internalValidation', ...
            'Generated waveform exceeds Smax.');
    end
    if abs(trapz(t, g) - A) > areaTol
        error('design_gradient_waveform:internalValidation', ...
            'Generated waveform does not preserve the requested area.');
    end
end


function Gp = solve_continuous_Gp(A, T, G0, G1, S)
% Solve the four possible peak-amplitude regions at maximum continuous slew.

    candidateBuffer = zeros(1, 6);
    candidateCount = 0;
    regionTol = 1e-10 * max([1, abs(G0), abs(G1), abs(S * T)]);

    % Gp >= G0 and Gp >= G1.
    a = 2;
    b = -2 * (S * T + G0 + G1);
    c = 2 * S * A + G0^2 + G1^2;
    roots = real_quadratic_roots(a, b, c);
    valid = roots >= G0 - regionTol & roots >= G1 - regionTol;
    newCandidates = roots(valid);
    indices = candidateCount + (1:numel(newCandidates));
    candidateBuffer(indices) = newCandidates;
    candidateCount = candidateCount + numel(newCandidates);

    % Gp <= G0 and Gp <= G1.
    b = 2 * (S * T - G0 - G1);
    c = G0^2 + G1^2 - 2 * S * A;
    roots = real_quadratic_roots(a, b, c);
    valid = roots <= G0 + regionTol & roots <= G1 + regionTol;
    newCandidates = roots(valid);
    indices = candidateCount + (1:numel(newCandidates));
    candidateBuffer(indices) = newCandidates;
    candidateCount = candidateCount + numel(newCandidates);

    % G0 <= Gp <= G1.
    denominator = T - (G1 - G0) / S;
    if abs(denominator) > 64 * eps(max(1, abs(T)))
        root = (A - (G1^2 - G0^2) / (2 * S)) / denominator;
        if root >= G0 - regionTol && root <= G1 + regionTol
            candidateCount = candidateCount + 1;
            candidateBuffer(candidateCount) = root;
        end
    end

    % G1 <= Gp <= G0.
    denominator = T - (G0 - G1) / S;
    if abs(denominator) > 64 * eps(max(1, abs(T)))
        root = (A - (G0^2 - G1^2) / (2 * S)) / denominator;
        if root >= G1 - regionTol && root <= G0 + regionTol
            candidateCount = candidateCount + 1;
            candidateBuffer(candidateCount) = root;
        end
    end

    candidates = candidateBuffer(1:candidateCount);

    if isempty(candidates)
        Gp = NaN;
        return;
    end

    plateauTime = T - abs(candidates - G0) / S - abs(candidates - G1) / S;
    areaCheck = candidates * T ...
        - (candidates - G0) .* abs(candidates - G0) / (2 * S) ...
        - (candidates - G1) .* abs(candidates - G1) / (2 * S);
    timeTol = 1e-10 * max(1, T);
    areaTol = 1e-9 * max([1, abs(A), max(abs(candidates)) * T]);
    valid = plateauTime >= -timeTol & abs(areaCheck - A) <= areaTol;
    candidates = candidates(valid);

    if isempty(candidates)
        Gp = NaN;
        return;
    end

    % Prefer a peak with the target-area polarity, then the smallest magnitude.
    polarityPenalty = double(abs(A) > areaTol & sign(A) .* candidates < 0);
    [~, order] = sortrows([polarityPenalty(:), abs(candidates(:))], [1, 2]);
    Gp = candidates(order(1));
end


function roots = real_quadratic_roots(a, b, c)
% Numerically guarded real roots for a quadratic equation.

    discriminant = b^2 - 4 * a * c;
    discriminantTol = 128 * eps(max([1, abs(b^2), abs(4 * a * c)]));
    if discriminant < -discriminantTol
        roots = zeros(1, 0);
        return;
    end

    sqrtDiscriminant = sqrt(max(0, discriminant));
    roots = [(-b - sqrtDiscriminant) / (2 * a), ...
             (-b + sqrtDiscriminant) / (2 * a)];
    roots = unique(roots(isfinite(roots)));
end


function validate_inputs(A, T_total, G0, G1, Gmax, Smax, dt)
% Reject invalid values before the analytical and raster calculations.

    inputs = {A, T_total, G0, G1, Gmax, Smax, dt};
    scalarFiniteReal = cellfun(@(value) isnumeric(value) && isreal(value) && ...
        isscalar(value) && isfinite(value), inputs);
    if ~all(scalarFiniteReal) || ...
            Gmax <= 0 || Smax <= 0 || dt <= 0 || T_total <= 0
        error('design_gradient_waveform:invalidInput', ...
            ['All inputs must be finite real scalars, and T_total, Gmax, ' ...
             'Smax, and GradRasterTime must be positive.']);
    end
end
