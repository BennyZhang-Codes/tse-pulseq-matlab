function dataOut = apply_TSE_phasecor(dataIn, mdh, phaseCor)
%APPLY_TSE_PHASECOR Apply fitted TSE phase correction to a Twix stream.
%
% The same fitted model should be applied to image and PAT reference data
% after both have been transformed into the same prewhitened coil basis.

    if isempty(dataIn)
        dataOut = dataIn;
        return;
    end
    if ~isfield(mdh,'Sli') || ~isfield(mdh,'Seg')
        error('apply_TSE_phasecor:MissingMdh', 'MDH fields Sli and Seg are required.');
    end

    coefficients = phaseCor.coefficients;
    nRO = size(dataIn,1);
    nCha = size(dataIn,2);
    normalizedKx = ((1:nRO).' - (nRO+1)/2) / nRO;
    dataOut = dataIn;

    for acquisition = 1:size(dataIn,3)
        slice = mdh.Sli(acquisition);
        echo = mdh.Seg(acquisition);
        if slice > size(coefficients,1) || echo > size(coefficients,2)
            warning('apply_TSE_phasecor:MissingCoefficient', ...
                'No coefficient for SLC=%d, SEG=%d; acquisition left unchanged.', slice, echo);
            continue;
        end
        for coil = 1:nCha
            beta = double(squeeze(coefficients(slice,echo,coil,:)));
            correction = exp(-1i*(beta(1)*normalizedKx + beta(2)));
            dataOut(:,coil,acquisition) = dataIn(:,coil,acquisition) .* ...
                cast(correction, 'like', dataIn);
        end
    end
end
