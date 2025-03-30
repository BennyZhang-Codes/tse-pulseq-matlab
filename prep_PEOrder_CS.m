function [...
    PEorder, PElabel, phaseAreas, ...
    nAcq, nRef, nExcit, ...
    pe_full, pe_Img, pe_Ref, pe_ImgAndRef, ...
    kSpaceCenterLine, FirstRefLine...
    ] = prep_PEOrder_CS(PEMode, nY, nEcho, TEeff, TE1, deltakY, R, p, r)

    if R == 1
        nExcit  = floor(nY / nEcho);
        pe_full = (1:(nEcho * nExcit)) - floor(0.5 * nEcho * nExcit) -1;
        pe_Img = pe_full;
        pe_Ref = [];
        pe_ImgAndRef = [];
        pe_steps  = pe_full;
    elseif R > 1 % for parallel imaging
        pe_full   = (1:(nY)) - floor(0.5 * nY) - 1;
        pe_step_min = min(pe_full(:));
        
        nAcq      = round(nY/R/nEcho)*nEcho;
        R1        = nAcq / nY;
        [pdf, ~]  = genPDF(nY, p, R1, 2, r, 1);
        mask      = genSampling_TSE(pdf,500,0.3,nAcq);

        % [pdf, ~]  = genPDF(nY, p, 1/R, 2, r, 1);
        % mask      = genSampling(pdf,500,1);
        % mask(end) = 1;
        
        pe_acq = pe_full(mask);
        
        pe_ImgAndRef = pe_full(pdf==1);
        pe_Img = pe_acq(~ismember(pe_acq, pe_ImgAndRef));
        pe_Ref = [];
        
        pe_steps    = sort([pe_Img pe_ImgAndRef], "ascend");
        
        nExcit      = ceil(sum(mask)/nEcho);
        pe_null     = (min(pe_step_min)-1) * ones(nExcit*nEcho - sum(mask), 1);
        pe_steps    = [pe_steps pe_null'];
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

    %%
    PEorder    = circshift(pe_steps, k0prescr - k0curr);
    phaseAreas = PEorder * deltakY;
    PElabel    = PEorder - pe_step_min;

    [row, col] = find(PEorder == 0);
    kSpaceCenterLine = PElabel(row, col);
    if R > 1
        [row, col] = find(PEorder == min(union(pe_ImgAndRef, pe_Ref)));
        FirstRefLine = PElabel(row, col);
    else
        FirstRefLine = -1;
    end
end

% plot_PE(R, nX, nY, pe_Img, pe_Ref, pe_ImgAndRef, pe_full)
% plot_PEOrder(R, nX, nY, PElabel);

% %%
% % R1 = round(nY/R/nEcho)*nEcho / nY;
% % 
% % r = 0.15 + 0.001 * count;
% % [pdf, ~]  = genPDF(nY, 10, R1, 2, r, 1);
% % i = find(pdf==1);
% % pdf(i(1)) = pdf(i(1)-1);
% % pdf(end) = 1;
% % 
% % mask      = genSampling(pdf,500,1);
% % disp(sum(mask))
% 
% 
% R1 = round(nY/R/nEcho)*nEcho / nY;
% [pdf, ~]  = genPDF(nY, p, R1, 2, r, 1);
% mask      = genSampling_TSE(pdf,500,0.3,round(nY/R/nEcho)*nEcho);
% % mask(end) = 1;
% disp(sum(mask))
