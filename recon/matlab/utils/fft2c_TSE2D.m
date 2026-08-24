function kspace = fft2c_TSE2D(image)
%FFT2C_TSE2D Centered unitary two-dimensional FFT over readout and phase.

    scale = sqrt(size(image,1)*size(image,2));
    kspace = fftshift(fftshift(fft(fft( ...
        ifftshift(ifftshift(image,1),2),[],1),[],2),1),2)/scale;
end
