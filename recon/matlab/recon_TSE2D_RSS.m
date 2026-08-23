function [rssImage, coilImages] = recon_TSE2D_RSS(kspace)
%RECON_TSE2D_RSS Centered 2D inverse FFT followed by root-sum-of-squares.

% kspace is [readout, phase encode, coil]. If coils have been prewhitened,
% RSS is also a noise-normalized sum-of-squares combination.

    if ndims(kspace) < 3
        kspace = reshape(kspace,size(kspace,1),size(kspace,2),1);
    end
    coilImages = ifftshift(ifftshift(kspace,1),2);
    coilImages = ifft(ifft(coilImages,[],1),[],2);
    coilImages = fftshift(fftshift(coilImages,1),2);
    rssImage = single(sqrt(sum(abs(coilImages).^2,3)));
end
