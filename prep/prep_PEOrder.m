function [nAcq, nExcit, PE] = prep_PEOrder(Actual)
    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ; 
    SignCorr = Actual.SignCorr ; 

    AccelerationMode = Actual.AccelerationMode;
    PEMode           = Actual.PEMode;
    nY               = Actual.nY;
    nEcho            = Actual.nEcho;
    TEeff            = Actual.TEeff;
    TE1              = Actual.TE1;
    fovPhase         = Actual.fovPhase;
    R                = Actual.R;
    RefLinesRatio    = Actual.RefLinesRatio;  % PI
    p                = Actual.p;              % CS
    r                = Actual.r;              % CS

    deltak   = 1 / fovPhase;
    if R == 1
        nExcit  = floor(nY / nEcho);
        pe_full = (1:(nEcho * nExcit)) - floor(0.5 * nEcho * nExcit) -1;
        pe_step_min = min(pe_full(:));
        pe_Img = pe_full;
        pe_Ref = [];
        pe_ImgAndRef = [];
        pe_steps  = pe_full;
    elseif R > 1 % for Acceleration
        switch lower(AccelerationMode)
            case 'pi'
                [nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef] = ...
                    prep_PEOrder_PI(nY, nEcho, R, RefLinesRatio);
            case 'cs'
                [nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef, ~, ~] = ...
                    prep_PEOrder_CS(nY, nEcho, R, p, r);
            otherwise
                error('Invalid Acceleration Mode');
        end
    end
    nAcq    = nExcit * nEcho;
    nRef    = length(pe_Ref) + length(pe_ImgAndRef);

    k0prescr = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
    k0curr   = 1;
    switch lower(PEMode)
        case 'centrichalf'
            half_l = pe_steps(1:(floor(nExcit/2)*nEcho));
            half_r = pe_steps((floor(nExcit/2)*nEcho)+1:end);
            pe_steps = [flipud(reshape(half_l, floor(nExcit/2), nEcho)') reshape(half_r, ceil(nExcit/2), nEcho)'];
        case 'centricfull'
            A = reshape(pe_steps, [nExcit, nEcho])';
            [~, idx] = sort(abs(A), 1, 'ascend'); 
            pe_steps = A(sub2ind(size(A), idx, repmat(1:size(A,2), size(A,1), 1)));
        case 'linear'
            if mod(nEcho, 2) == 0
                pe_steps=circshift(pe_steps, [0, -round(nExcit / 2)]); % for odd number of echoes we have to apply a shift to avoid a contrast jump at k=0
            end
            % TSE echo time magic
            [~,iPEmin] = min(abs(pe_steps));
            k0curr     = floor((iPEmin-1)/nExcit) + 1; % calculate the 'native' central echo index 
            pe_steps   = reshape(pe_steps, [nExcit, nEcho])';
        otherwise
            error('Invalid PEMode');
    end
    PEorder    = circshift(pe_steps, k0prescr - k0curr);
    phaseAreas = PEorder * deltak;
    PElabel    = PEorder - pe_step_min;

    [row, col] = find(PEorder == 0);
    kSpaceCenterLine = PElabel(row, col);
    if R > 1
        [row, col] = find(PEorder == min(union(pe_ImgAndRef, pe_Ref)));
        FirstRefLine = PElabel(row, col);
    else
        FirstRefLine = -1;
    end


    PE.PEorder           = PEorder;
    PE.PElabel           = PElabel;
    PE.phaseAreas        = SignCorr.(AxisPE) * phaseAreas;
    PE.nRef              = nRef;
    PE.pe_full           = pe_full;
    PE.pe_Img            = pe_Img;
    PE.pe_Ref            = pe_Ref;
    PE.pe_ImgAndRef      = pe_ImgAndRef;
    PE.kSpaceCenterLine  = kSpaceCenterLine;
    PE.FirstRefLine      = FirstRefLine;
end 
