function [g, t] = design_gradient_waveform(A, T_total, G0, G1, Gmax, Smax, GradRasterTime)
% DESIGN_GRADIENT_WAVEFORM Pure analytical, O(1) complexity waveform generation engine.
% Features an adaptive "Self-Healing Loop" to prevent Slew Rate violations 
% caused by discrete rasterization and floating-point precision leaps.
%
% Inputs:
%   A              : Target gradient area (1/m or Hz/m*s)
%   T_total        : Total waveform duration (s)
%   G0             : Initial gradient amplitude (Hz/m or mT/m)
%   G1             : Final gradient amplitude (Hz/m or mT/m)
%   Gmax           : Maximum gradient amplitude (absolute value)
%   Smax           : Maximum slew rate (absolute value)
%   GradRasterTime : System gradient raster time (s)

    dt = GradRasterTime;
    
    % Align the total time strictly to the system raster grid
    T_total = round(T_total / dt) * dt;

    % =====================================================================
    % 🛡️ Floating-Point Boundary Stabilization
    % Mitigates minor overflows caused by rotation matrix calculations
    % =====================================================================
    tol_G = max(1e-4, Gmax * 1e-6);
    if abs(G0) <= Gmax + tol_G, G0 = max(min(G0, Gmax), -Gmax); end
    if abs(G1) <= Gmax + tol_G, G1 = max(min(G1, Gmax), -Gmax); end

    if abs(G0) > Gmax || abs(G1) > Gmax
        error('Initial or final gradient amplitude exceeds the maximum limit (Gmax).');
    end

    % =====================================================================
    % 1. O(1) Analytical Solution (Continuous Domain)
    % =====================================================================
    Gp_cont = solve_continuous_Gp(A, T_total, G0, G1, Smax);
    if isnan(Gp_cont)
        error('Analytical step failed: No physical roots exist for the given constraints.');
    end

    % Magnetic Snap: Eliminate microscopic floating-point errors near boundaries
    if abs(Gp_cont - G0) < 1e-6 * (abs(G0) + 1), Gp_cont = G0; end
    if abs(Gp_cont - G1) < 1e-6 * (abs(G1) + 1), Gp_cont = G1; end

    % =====================================================================
    % 2. Initial Discretization (Raster Alignment)
    % =====================================================================
    t_ramp1 = ceil(abs(Gp_cont - G0) / (Smax * dt)) * dt;
    t_ramp2 = ceil(abs(Gp_cont - G1) / (Smax * dt)) * dt;
    t_plat  = T_total - t_ramp1 - t_ramp2;

    % =====================================================================
    % 🌟 Core Engine Upgrade: Area Recalculation & Slew Rate Self-Healing
    % =====================================================================
    % Due to 'ceil' extending the ramp times, the plateau is shortened. 
    % The amplitude (Gp_discrete) must bounce higher to preserve the exact area.
    % This loop adaptively extends ramp times if the bounce violates Smax.
    
    tol_S_Pulseq = Smax * 1e-4; % Tolerance for underlying Pulseq float jitter
    
    for iter = 1:10
        % Recalculate discrete amplitude required for 100% area fidelity
        a = 0.5 * (t_ramp1 + t_ramp2) + t_plat;
        if a > 1e-12
            b = 0.5 * (G0 * t_ramp1 + G1 * t_ramp2);
            Gp_discrete = (A - b) / a;
        else
            Gp_discrete = G0; 
        end

        % Validate current Slew Rate
        S1 = 0; S2 = 0;
        if t_ramp1 > 0, S1 = abs(Gp_discrete - G0) / t_ramp1; end
        if t_ramp2 > 0, S2 = abs(Gp_discrete - G1) / t_ramp2; end

        needs_recalc = false;
        
        % If amplitude bounce causes Slew Rate violation, adaptively extend 
        % the ramp time by one raster unit (dt) to relax the waveform slope.
        if S1 > Smax + tol_S_Pulseq
            t_ramp1 = t_ramp1 + dt;
            t_plat  = t_plat - dt;
            needs_recalc = true;
        end
        if S2 > Smax + tol_S_Pulseq
            t_ramp2 = t_ramp2 + dt;
            t_plat  = t_plat - dt;
            needs_recalc = true;
        end
        
        if t_plat < -1e-9
            error('Hardware limits breached: Plateau squeezed out during rasterization correction.');
        end
        
        % Exit loop gracefully if no correction is needed
        if ~needs_recalc
            break;
        end
    end

    % Final safety validation
    if needs_recalc || abs(Gp_discrete) > Gmax + tol_G
        error('Hardware limits breached after adaptive recalculation.');
    end
    
    % Strict clipping to prevent Pulseq's bottom-level assert failures
    Gp_discrete = max(min(Gp_discrete, Gmax), -Gmax);

    % =====================================================================
    % 3. Output Waveform Structure
    % =====================================================================
    Gp = Gp_discrete;
    t = [0, t_ramp1, t_ramp1 + t_plat, T_total];
    g = [G0, Gp, Gp, G1];
end


function Gp = solve_continuous_Gp(A, T, G0, G1, S)
% SOLVE_CONTINUOUS_GP Directly captures the valid analytical solution for Gp 
% across 4 physical quadrants using 1D quadratic equations.

    candidates = [];
    tol = 1e-5 * (abs(G0) + abs(G1) + 1); 
    
    % Allow generous floating-point tolerance for the discriminant 
    % to handle O(10^16) truncation errors in large-scale Hz/m units
    tol_delta = 1e-4; 
    
    % Case 1: Gp >= G0 and Gp >= G1 (Large positive area, trapezoid/triangle)
    a = 2; b = -2*(S*T + G0 + G1); c = 2*S*A + G0^2 + G1^2;
    delta = b^2 - 4*a*c;
    if delta >= -tol_delta
        gp = (-b - sqrt(max(0, delta)))/(2*a);
        if gp >= G0 - tol && gp >= G1 - tol, candidates(end+1) = gp; end
    end

    % Case 2: Gp <= G0 and Gp <= G1 (Negative overshoot or large negative area)
    a = 2; b = 2*(S*T - G0 - G1); c = G0^2 + G1^2 - 2*S*A;
    delta = b^2 - 4*a*c;
    if delta >= -tol_delta
        % CRITICAL FIX: Must use '+ sqrt' here to select the physical root 
        % that naturally approaches 0, representing the physical overshoot dip.
        gp = (-b + sqrt(max(0, delta)))/(2*a);
        if gp <= G0 + tol && gp <= G1 + tol, candidates(end+1) = gp; end
    end

    % Case 3: G0 < Gp < G1 (Mid-ramp up, no plateau)
    denom = T - (G1 - G0)/S;
    if abs(denom) > 1e-9
        gp = (A - (G1^2 - G0^2)/(2*S)) / denom;
        if gp > G0 - tol && gp < G1 + tol, candidates(end+1) = gp; end
    end

    % Case 4: G1 < Gp < G0 (Mid-ramp down, no plateau)
    denom = T - (G0 - G1)/S;
    if abs(denom) > 1e-9
        gp = (A - (G0^2 - G1^2)/(2*S)) / denom;
        if gp > G1 - tol && gp < G0 + tol, candidates(end+1) = gp; end
    end

    % Validate candidates and return the first legitimate solution
    for i = 1:length(candidates)
        gp_test = candidates(i);
        t_plat = T - abs(gp_test - G0)/S - abs(gp_test - G1)/S;
        
        % Relax tolerance for tiny negative plateau times; 
        % the outer discretization wrapper will naturally absorb it.
        if t_plat >= -1e-5 
            Gp = gp_test;
            return; 
        end
    end
    
    Gp = NaN; 
end