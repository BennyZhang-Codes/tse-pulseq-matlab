# Reconstruction examples

These scripts demonstrate the public MATLAB reconstruction entry points:

- `run_recon_TSE2D.m` — conventional Cartesian 2D TSE reconstruction with RSS/GRAPPA and optional phase/echo magnitude correction.
- `run_recon_TSE2D_iterative.m` — SENSE and CS reconstruction with ESPIRiT sensitivity estimation.

Edit the input raw-data path, output directory, and `mapVBVDPath` before running them. The current reader uses Siemens Twix through `mapVBVD`.

The examples follow the same conventional 2D TSE scope as the main reconstruction pipeline; offline gSlider decoding is not currently implemented.

Full documentation: <https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction>
