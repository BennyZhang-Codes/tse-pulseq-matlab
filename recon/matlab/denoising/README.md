# Image-domain denoising

This directory contains optional post-reconstruction image-domain denoising
and benchmarking code. It is not called by the Twix reconstruction pipeline.

- `denoise_TSE2D.m`: NLM, BM3D, SANLM, and TGV2 wrapper.
- `denoise_TGV2.m`: repository-local second-order TGV solver.
- `estimate_TSE2D_image_noise.m`: background noise and colored-noise PSD
  estimation.
- `measure_TSE2D_denoising.m`: signal, edge, residual, and anisotropy metrics.
- `benchmark_TSE2D_denoisers.m`: NIfTI batch benchmark and comparison reports.
- `THIRD_PARTY_DENOISERS.md`: optional dependency and license notes.

Add both the reconstruction and denoising folders before direct use:

```matlab
matlabDir = fullfile(repoRoot,'recon','matlab');
addpath(matlabDir,fullfile(matlabDir,'denoising'));
```

Optional downloaded dependencies remain in the Git-ignored sibling directory
`../third_party_local/`; moving the repository-local source files does not
duplicate or relocate third-party archives and binaries.
