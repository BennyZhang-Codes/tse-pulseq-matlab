# Reconstruction examples

These editable scripts demonstrate the public reconstruction entry points and
are not required by `recon_TSE2D` at runtime.

- `run_recon_TSE2D.m`: conventional RSS/GRAPPA workflow with optional phase
  and echo-magnitude correction.
- `run_recon_TSE2D_iterative.m`: matched ESPIRiT-SENSE and TV/Haar-L1 CS
  reconstructions.

Both scripts locate `recon/matlab` from their own file location. Edit the input
Twix file, output directory, and `mapVBVDPath` before running them.
