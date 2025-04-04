function [...
    nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef ...
    , mask, pdf...
    ] = prep_PEOrder_CS(nY, nEcho, R, p, r)

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
