function [roundedVal, roundErr] = RoundRaster(val, precision, method)
% ROUNDRASTERTIME Round a value to the specified precision (raster time) and direction.
% 
% Input arguments:
%   val       - The value(s) to be rounded (supports scalar, vector, or matrix).
%   precision - The rounding precision / grid size (e.g., 10e-6 for 10us). Default: 1.
%   method    - The rounding direction: 'up' (ceiling), 'down' (floor), 'round' (nearest). Default: 'round'.
%
% Output arguments:
%   roundedVal - The rounded value.
%   roundErr   - The rounding error (roundedVal - val).
%
% Example usage:
%   t = RoundRasterTime(1.234, 0.1, 'up')    % Returns 1.300
%   t = RoundRasterTime(1.234, 'down', 0.1)  % Returns 1.200 (supports parameter swapping)

    %% 1. Check input arguments and set default values
    if nargin < 2 || isempty(precision)
        precision = 1; 
    end
    if nargin < 3 || isempty(method)
        method = 'round'; 
    end

    %% 2. Smart parameter swap (Fault tolerance)
    % Handle the case where the user swaps 'method' and 'precision' 
    % (e.g., passing 'up' first, then 10e-6)
    if ischar(precision) || isstring(precision)
        temp = precision;
        precision = method;
        method = temp;
        
        % If precision is still a string after swapping, default it to 1
        if ischar(precision) || isstring(precision)
            precision = 1; 
        end
    end

    %% 3. Floating-point tolerance protection
    % Crucial for MRI sequences to prevent floating-point inaccuracies
    % (e.g., preventing 10.0000000000001 from being rounded up to 11)
    tol = 1e-9; 

    %% 4. Core rounding logic
    switch lower(method)
        case 'up'
            % Ceiling
            roundedVal = ceil(val ./ precision - tol) .* precision;
            
        case 'down'
            % Floor
            roundedVal = floor(val ./ precision + tol) .* precision;
            
        case 'round'
            % Round to nearest
            roundedVal = round(val ./ precision) .* precision;
            
        otherwise
            error('RoundRasterTime:InvalidMethod', ...
                'Invalid rounding method! Please use ''up'', ''down'', or ''round''.');
    end

    %% 5. Calculate rounding error (only if requested)
    if nargout > 1
        roundErr = roundedVal - val;
    end
end