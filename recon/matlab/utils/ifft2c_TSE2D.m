function image = ifft2c_TSE2D(kspace)
%IFFT2C_TSE2D Centered unitary two-dimensional inverse FFT.

    scale = sqrt(size(kspace,1)*size(kspace,2));
    image = fftshift(fftshift(ifft(ifft( ...
        ifftshift(ifftshift(kspace,1),2),[],1),[],2),1),2)*scale;
end
