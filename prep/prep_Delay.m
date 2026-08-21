function [Delay] = prep_Delay(Actual, Delay)

    % SessionDelay = Actual.SessionDelay;


    % Initialize a zero delay that will be modified later on
    % to ensure we get the desired TR (if possible).
    Delay_TRFill = mr.makeDelay(1) ; % dummy time. (Delay of zero is not allowed)
    Delay_TRFill.delay = 0 ; % [s] force delay of zero.
    
    Delay_SliceTRFill = mr.makeDelay(1) ; % dummy time. (Delay of zero is not allowed)
    Delay_SliceTRFill.delay = 0 ; % [s] force delay of zero.

    % % For inter-session delay
    % Delay_InterSession = mr.makeDelay(SessionDelay);



    % Delay.Delay_InterSession   = Delay_InterSession;
    Delay.Delay_TRFill         = Delay_TRFill;
    Delay.Delay_SliceTRFill    = Delay_SliceTRFill;
end
