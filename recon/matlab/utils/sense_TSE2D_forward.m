function kspace = sense_TSE2D_forward(image,sensitivities,mask)
%SENSE_TSE2D_FORWARD Apply the masked multicoil Cartesian SENSE operator.

    kspace = fft2c_TSE2D(sensitivities.*image).*mask;
end
