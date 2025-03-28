function [PEorder, PElabel, phaseAreas, nAcq, nRef, nExcit, pe_full, pe_Img, ...
          pe_Ref, pe_ImgAndRef, kSpaceCenterLine, FirstRefLine] = prep_PEOrder_PI(PEMode, ...
          nY, nEcho, TEeff, TE1, deltak, R, RefLinesRatio)
    
    if R == 1
        nExcit  = floor(nY / nEcho);
        pe_full = (1:(nEcho * nExcit)) - floor(0.5 * nEcho * nExcit) -1;
        pe_Img = pe_full;
        pe_Ref = [];
        pe_ImgAndRef = [];
        pe_steps  = pe_full;
    elseif R > 1 % for parallel imaging
        % 1. determine nRef (to make mod(nRef+nImg, nEcho) == 0)
        pe_full   = (1:(nY)) - floor(0.5 * nY) - 1;
        
        nImg      = round(nY/R);
        nRef      = round(nY * RefLinesRatio * (R-1)/R);
        nRef      = round((nImg+nRef) / nEcho) * nEcho - nImg; 

        % 2. Img
        pe_Img    = fliplr(pe_full(end:-R:1)); 
        pe_Img    = pe_Img(1:nImg);

        % 3. Ref
        pe_Ref    = pe_full;          
        pe_Ref(end:-R:1) = [];
        n         = length(pe_Ref);
        mid_start = floor((n - nRef) / 2) + 1; 
        mid_end   = mid_start + nRef - 1;       
        pe_Ref    = pe_Ref(mid_start:mid_end);    

        % 4. Img & Ref
        pe_ImgAndRef = pe_Img(pe_Img > min(pe_Ref) & pe_Img < max(pe_Ref)); 

        % 5. reset nExcit and pe_steps
        nExcit    = round((nImg+nRef) / nEcho);
        pe_steps  = sort([pe_Img pe_Ref], "ascend");
    end
    nAcq    = nExcit * nEcho;
    nRef    = length(pe_Ref) + length(pe_ImgAndRef);

    k0prescr = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
    k0curr   = 1;
    switch lower(PEMode)
        case 'centric'
            half_l = pe_steps(1:(floor(nExcit/2)*nEcho));
            half_r = pe_steps((floor(nExcit/2)*nEcho)+1:end);
            
            pe_steps = [flipud(reshape(half_l, floor(nExcit/2), nEcho)') reshape(half_r, ceil(nExcit/2), nEcho)'];
        case 'centric2'
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
    PElabel    = PEorder - min(PEorder(:));

    if R > 1
        PElabel = PElabel + (nY-1-max(PElabel(:)));
    end

    [row, col] = find(PEorder == 0);
    kSpaceCenterLine = PElabel(row, col);
    if R > 1
        [row, col] = find(PEorder == min(union(pe_ImgAndRef, pe_Ref)));
        FirstRefLine = PElabel(row, col);
    else
        FirstRefLine = -1;
    end
end
