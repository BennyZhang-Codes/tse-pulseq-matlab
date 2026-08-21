function [...
    nExcit, pe_steps, pe_step_min, pe_full, pe_Img, pe_Ref, pe_ImgAndRef ...
    , mask, pdf...
    ] = prep_PE3DOrder_CS(nPE, nEcho, R, p, r)

    pe_full   = (1:(nPE)) - floor(0.5 * nPE) - 1;
    pe_step_min = min(pe_full(:));
    
    nAcq      = round(nPE/R/nEcho)*nEcho;
    R1        = nAcq / nPE;
    [pdf, ~]  = genPDF(nPE, p, R1, 2, r, 1);
    mask      = genSampling_TSE(pdf,500,0.3,nAcq);

    % [pdf, ~]  = genPDF(nPE, p, 1/R, 2, r, 1);
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

% plot_PE(R, nRO, nPE, pe_Img, pe_Ref, pe_ImgAndRef, pe_full)
% plot_PEOrder(R, nRO, nPE, PE3DLabel);

% %%
% % R1 = round(nPE/R/nEcho)*nEcho / nPE;
% % 
% % r = 0.15 + 0.001 * count;
% % [pdf, ~]  = genPDF(nPE, 10, R1, 2, r, 1);
% % i = find(pdf==1);
% % pdf(i(1)) = pdf(i(1)-1);
% % pdf(end) = 1;
% % 
% % mask      = genSampling(pdf,500,1);
% % disp(sum(mask))
% 
% 
% R1 = round(nPE/R/nEcho)*nEcho / nPE;
% [pdf, ~]  = genPDF(nPE, p, R1, 2, r, 1);
% mask      = genSampling_TSE(pdf,500,0.3,round(nPE/R/nEcho)*nEcho);
% % mask(end) = 1;
% disp(sum(mask))
