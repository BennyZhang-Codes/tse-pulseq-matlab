function [PE3D, Actual] = prep_PE3DOrder(Actual)
    % mapping of RO/PE/3D to X/Y/Z
    AxisPE   = Actual.AxisPE   ; 
    SignCorr = Actual.SignCorr ; 

    AccelerationMode = Actual.AccelerationMode;
    PEMode           = Actual.PEMode;
    nPE               = Actual.nPE;
    nEcho            = Actual.nEcho;
    TEeff            = Actual.TEeff;
    TE1              = Actual.TE1;
    fovPE            = Actual.fovPE;
    R                = Actual.R;
    RefLinesRatio    = Actual.RefLinesRatio;  % PI
    p                = Actual.p;              % CS
    r                = Actual.r;              % CS

    if strcmpi(Actual.SeqDimension, '2d')
        deltak   = 1 / fovPE;
        if R == 1
            fprintf('prep PE3DOrder >>> Fully-Sampled\n');
            nExcit  = floor(nPE / nEcho);
            pe_full = (1:(nEcho * nExcit)) - floor(0.5 * nEcho * nExcit) -1;
            pe_step_min = min(pe_full(:));
            pe_Img = pe_full;
            pe_Ref = [];
            pe_ImgAndRef = [];
            pe_steps  = pe_full;
        elseif R > 1 % for Acceleration
            fprintf('prep PE3DOrder >>> Under-Sampled: %s\n', upper(AccelerationMode));
            switch lower(AccelerationMode)
                case 'pi'
                    [nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef] = ...
                        prep_PE3DOrder_PI(nPE, nEcho, R, RefLinesRatio);
                case 'cs'
                    [nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef, ~, ~] = ...
                        prep_PE3DOrder_CS(nPE, nEcho, R, p, r);
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
       
        FirstFourierLine = 0;
        
        % Only apply the Siemens Cartesian LIN mapping to parallel imaging.
        % CS contains null/sentinel PE entries and must retain its old mapping.
        isPI = R > 1 && strcmpi(AccelerationMode, 'PI');

        if isPI
            % Zero-based Siemens center convention. For nPE=300, ky=0 must be LIN=150.
            centerLIN = floor(nPE/2);
        
            % Circular mapping from signed logical ky to Siemens LIN.
            % nPE=300 examples:
            % ky =    0 -> LIN 150
            % ky = +150 -> LIN   0
            % ky = -149 -> LIN   1
            PElabel = PEorder + floor(nPE/2);
        else
            PElabel = PEorder - pe_step_min; % Preserve the existing R=1 and CS behavior.
        end
        
        % Locate the unique physical ky=0 acquisition.
        [row, col] = find(PEorder == 0);
        
        if numel(row) ~= 1; error('PE order must contain exactly one ky=0 line.'); end
        
        kSpaceCenterLine = PElabel(row, col);
        
        if isPI
            imageLIN = mod(pe_Img(:) + centerLIN, nPE); % Regular accelerated imaging lines, excluding added ACS-only lines.
        
            refPE = union(pe_Ref(:), pe_ImgAndRef(:)); % All ACS lines, including reference-only and reference-and-image.
            refLIN = mod(refPE + centerLIN, nPE);
        
            FirstFourierLine = min(imageLIN);
            FirstRefLine     = min(refLIN);
        
            % Siemens consistency checks.
            if kSpaceCenterLine ~= centerLIN; error('Incorrect PI center LIN: got %d, expected %d.', kSpaceCenterLine, centerLIN); end
            if any(mod(imageLIN-kSpaceCenterLine, R) ~= 0); error('PI imaging LINs do not satisfy mod(LIN-center,R)==0.'); end
            if any(PElabel(:) < 0 | PElabel(:) >= nPE); error('PI LIN labels must be in [0,nPE-1].'); end
            if numel(unique(PElabel(:))) ~= numel(PElabel); error('Duplicate PI LIN labels detected.'); end
        
        elseif R > 1
            [row, col] = find(PEorder == min(union(pe_ImgAndRef, pe_Ref))); % Preserve the existing non-PI accelerated behavior.
            FirstRefLine = PElabel(row, col);
        else
            FirstFourierLine = 0;
            FirstRefLine     = -1;
        end


        PE3D.PEorder           = PEorder;
        PE3D.PElabel           = PElabel;
        PE3D.phaseAreas        = SignCorr.(AxisPE) * phaseAreas;
        PE3D.nRef              = nRef;
        PE3D.pe_full           = pe_full;
        PE3D.pe_Img            = pe_Img;
        PE3D.pe_Ref            = pe_Ref;
        PE3D.pe_ImgAndRef      = pe_ImgAndRef;
        PE3D.kSpaceCenterLine  = kSpaceCenterLine;
        PE3D.FirstFourierLine  = FirstFourierLine;
        PE3D.FirstRefLine      = FirstRefLine;
    end

    Actual.nAcq   = nAcq;
    Actual.nExcit = nExcit; 
    Actual.PE3D   = PE3D;


    fprintf('prep PE3DOrder >>> R                   = %s\n', num2str(R               ));
    fprintf('prep PE3DOrder >>> nPE                 = %s\n', num2str(nPE             ));
    fprintf('prep PE3DOrder >>> nAcq (nExcit*nEcho) = %s\n', num2str(nAcq            ));

    fprintf('prep PE3DOrder >>> kSpaceCenterLine    = %s\n', num2str(kSpaceCenterLine));
    fprintf('prep PE3DOrder >>> FirstFourierLine    = %s\n', num2str(FirstFourierLine));
    fprintf('prep PE3DOrder >>> ACS Lines           = %s (%s-%s)\n', num2str(nRef), num2str(FirstRefLine), num2str(FirstRefLine+nRef-1));
    fprintf('prep PE3DOrder >>> Imaging Lines       = %s:%s:%s (%s:%s:%s)\n', ...
        num2str(min(PEorder(:))), num2str(R), num2str(max(PEorder(:))), ...
        num2str(min(PElabel(:))), num2str(R), num2str(max(PElabel(:))));

end 