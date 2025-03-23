function [PEorder, PElabel, phaseAreas] = prep_PEOrder(PEMode, nY, nEcho, TEeff, TE1, deltak)
    switch lower(PEMode)
        case 'centric' % half
            nExcit   = floor(nY / nEcho);
            pe_steps = (1:(nEcho * nExcit)) - 0.5 * nEcho * nExcit - 1;
            half_l = pe_steps(1:nY/2);
            half_r = pe_steps(nY/2+1:end);
            
            pe_steps = [flipud(reshape(half_l, nExcit/2, nEcho)') reshape(half_r, nExcit/2, nEcho)'];
            
            k0prescr   = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
            PEorder    = circshift(pe_steps, k0prescr - 1);
            PElabel    = PEorder - min(PEorder(:));
            phaseAreas = PEorder * deltak;
        case 'centric2' % full
            nExcit   = floor(nY / nEcho);
            pe_steps = (1:(nEcho * nExcit)) - 0.5 * nEcho * nExcit - 1;
            A = reshape(pe_steps, [nExcit, nEcho])';
            [~, idx] = sort(abs(A), 1, 'ascend'); 
            
            pe_steps = A(sub2ind(size(A), idx, repmat(1:size(A,2), size(A,1), 1)));
            
            k0prescr   = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
            PEorder    = circshift(pe_steps, k0prescr - 1);
            PElabel    = PEorder - min(PEorder(:));
            phaseAreas = PEorder * deltak;
        case 'linear'
            nExcit   = floor(nY / nEcho);
            pe_steps = (1:(nEcho * nExcit)) - 0.5 * nEcho * nExcit - 1;
            if mod(nEcho, 2) == 0
                pe_steps=circshift(pe_steps, [0, -round(nExcit / 2)]); % for odd number of echoes we have to apply a shift to avoid a contrast jump at k=0
            end
            % TSE echo time magic
            [~,iPEmin] = min(abs(pe_steps));
            k0curr     = floor((iPEmin-1)/nExcit) + 1; % calculate the 'native' central echo index 
            k0prescr   = max(round(TEeff/TE1), 1); % echo to be aligned to the k-space center 
            PEorder    = circshift(reshape(pe_steps, [nExcit, nEcho])', k0prescr - k0curr);
            PElabel    = PEorder - min(PEorder(:));
            phaseAreas = PEorder * deltak;
        otherwise
            error('Invalid PEMode');
    end
end
