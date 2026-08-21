function [...
    nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef ...
    ] = prep_PEOrder_PI(nPE, nEcho, R, RefLinesRatio)

    % for parallel imaging
    % 1. determine nRef (to make mod(nRef+nImg, nEcho) == 0)
    pe_full   = (1:(nPE)) - floor(0.5 * nPE);
    pe_step_min = min(pe_full(:));


    % left   = 0:-R:min(pe_full(:)); 
    % right  = R:R:max(pe_full(:));
    % pe_Img = [fliplr(left(2:end)), 0, right, pe_full(end)];
    % pe_Img = sort(pe_Img, "ascend");


    % pe_Img    = fliplr(pe_full(end:-R:1));
    % pe_Img    = sort([pe_Img 0], "ascend");


    iLine = 0 : (nPE - 1);
    KSpaceCenterLine = find(pe_full == 0)-1;
    pe_Img = pe_full(mod(iLine - KSpaceCenterLine, R) == 0);

    
    nImg      = length(pe_Img);
    nRef      = round(nPE * RefLinesRatio * (R-1)/R);

    nExcit    = ceil((nImg+nRef) / nEcho);
    nRef      = nExcit * nEcho - nImg; 

    

    % 2. Ref
    pe_Ref    = pe_full(~ismember(pe_full, pe_Img));
    n         = length(pe_Ref);

    mid_start = floor((n - nRef) / 2) + 1; 
    mid_end   = mid_start + nRef - 1;       
    pe_Ref    = pe_Ref(mid_start:mid_end);    

    % 3. Img & Ref
    pe_ImgAndRef = pe_Img(pe_Img > min(pe_Ref) & pe_Img < max(pe_Ref)); 

    % new
    nPATRefLine  = length(pe_Ref) + length(pe_ImgAndRef);
    while true
        halfWidth    = floor((nPATRefLine - 1)/2);
        minPATRefLin = KSpaceCenterLine - halfWidth;
        maxPATRefLin = KSpaceCenterLine + (nPATRefLine - 1 - halfWidth);
    
        pe_PATRefLine = pe_full(minPATRefLin+1:maxPATRefLin+1);
        pe_Ref       = pe_PATRefLine(~ismember(pe_PATRefLine, pe_Img));
        pe_ImgAndRef = pe_PATRefLine(ismember(pe_PATRefLine, pe_Img));
        if length(pe_Ref) == nRef
            break;
        else
            nPATRefLine = nPATRefLine + (nRef - length(pe_Ref));
        end
    end


    % 4. reset pe_steps
    pe_steps  = sort([pe_Img pe_Ref], "ascend");
end
