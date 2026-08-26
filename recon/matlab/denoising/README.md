# Image-domain denoising

This directory contains **optional post-reconstruction** image-domain denoising and benchmarking code. It is not called by `recon_TSE2D` and is not part of the Cartesian encoding model.

Available paths:

- `denoise_TSE2D.m` — NLM, BM3D, SANLM, and TGV2 wrapper.
- `denoise_TGV2.m` — repository-local second-order TGV solver.
- `estimate_TSE2D_image_noise.m` — background noise and colored-noise PSD estimation.
- `measure_TSE2D_denoising.m` — signal, edge, residual, and anisotropy metrics.
- `benchmark_TSE2D_denoisers.m` — NIfTI batch benchmark and comparison reports.
- `THIRD_PARTY_DENOISERS.md` — optional dependency, provenance, and license notes.

Add both reconstruction and denoising folders before direct use:

```matlab
matlabDir = fullfile(repoRoot,'recon','matlab');
addpath(matlabDir,fullfile(matlabDir,'denoising'));
```

BM3D and CAT12 SANLM are optional third-party dependencies and are not vendored. Downloaded dependencies remain under the Git-ignored `../third_party_local/` location. TGV2 is implemented locally in this repository.

Denoising should be reported as a separate post-processing step. Preserve the original unfiltered reconstruction for comparisons.

Full documentation:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising>
