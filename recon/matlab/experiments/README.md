# Reconstruction experiments and evaluation

This directory contains parameter tuning, quantitative evaluation, figure
generation, and dataset-specific reproduction scripts. None of these files is
required by the production `recon_TSE2D` reconstruction entry point.

## Contents

- `tune_TSE2D_CS_parameters.m`: reusable TV/Haar parameter sweep on a fixed
  prewhitened ESPIRiT model.
- `evaluate_TSE2D_reconstruction.m`: reference registration and masked
  NRMSE/SSIM/PSNR/error-map evaluation.
- `create_TSE2D_CS_comparison_figure.m`: publication-style reference/CS/error
  figures.
- `run_compare_TSE2D_CS_20250331.m`: dataset-specific R=1--5 reconstruction,
  NIfTI export, metrics, and figure reproduction.

The dataset-specific `run_compare_TSE2D_CS_20250331.m` script locates the
repository from its own file location and adds the reconstruction and utility
folders to the MATLAB path. Update `mapVBVDPath` and the input-data settings
when using another workstation or dataset. For direct function use, add:

```matlab
addpath(genpath(fullfile(repoRoot,'recon','matlab')));
```
