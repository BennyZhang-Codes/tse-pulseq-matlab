function image = sense_TSE2D_adjoint(kspace,sensitivities,mask)
%SENSE_TSE2D_ADJOINT Apply the adjoint masked multicoil SENSE operator.

    image = sum(conj(sensitivities).*ifft2c_TSE2D(kspace.*mask),3);
end
