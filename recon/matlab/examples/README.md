# Reconstruction examples

These editable scripts demonstrate the public MATLAB reconstruction entry points. They are examples only and are not required by `recon_TSE2D` at runtime.

- `run_recon_TSE2D.m` — conventional Cartesian 2D TSE workflow with RSS or regular 1D PE-GRAPPA and optional navigator phase / echo-magnitude correction.
- `run_recon_TSE2D_iterative.m` — matched ESPIRiT-SENSE and Cartesian TV/Haar-L1 CS reconstructions.

Both scripts locate `recon/matlab` from their own file location. Edit the input Siemens Twix file, output directory, and `mapVBVDPath` before running them.

The examples follow the same scope as the main reconstruction documentation: conventional Cartesian 2D TSE only; no gSlider decoding, partial Fourier, SMS, non-Cartesian reconstruction, or non-Siemens raw-data reader is currently implemented.

Full reconstruction documentation:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction>
