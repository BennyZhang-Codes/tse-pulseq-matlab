# MATLAB reconstruction

This folder contains the companion MATLAB reconstruction for **conventional Cartesian 2D TSE** data.

The maintained raw-data reader currently uses Siemens Twix through external `mapVBVD`. Offline gSlider decoding is not implemented.

Full documentation: <https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction>

## Quick start

Edit `examples/run_recon_TSE2D.m`, set the input/output paths, then run it.

Programmatic use:

```matlab
addpath(fullfile('recon', 'matlab'));

result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'Prewhiten', true, ...
    'PhaseCorrection', true, ...
    'EchoMagnitudeCorrection', false, ...
    'ReconstructionMethod', 'grappa', ...
    'OutputDir', outputDir, ...
    'SaveNifti', true);

imageTSE = result.images.reconstructed;
```

`ReconstructionMethod` supports:

```text
rss
grappa
sense
cs
```

## Processing pipeline

```text
raw data
→ prewhitening
→ navigator phase correction
→ optional echo magnitude correction
→ Cartesian k-space packing
→ RSS / GRAPPA / SENSE / CS
→ image / NIfTI output
```

## Methods

| Method | Current implementation |
| --- | --- |
| RSS | centered coil-wise IFFT + root-sum-of-squares |
| GRAPPA | ACS-calibrated Cartesian PE interpolation; acquired rows are preserved |
| SENSE | Cartesian multicoil SENSE with ESPIRiT sensitivity maps |
| CS | Cartesian multicoil reconstruction with TV + Haar-L1 regularization |

SENSE/CS can use ACS-derived PCA coil compression. ESPIRiT is the default sensitivity estimation method.

GRAPPA currently expects regular integer PE acceleration with contiguous integrated ACS. Detailed limits and options are documented on the main [Reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction) page.

## Optional processing

- **Echo magnitude correction** is disabled by default and is applied only when explicitly selected.
- **NLM, BM3D, SANLM, and TGV2** are separate image-domain post-processing tools and are not run automatically by `recon_TSE2D`.

See [Optional Echo Correction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections) and [Optional Denoising](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising).

## Main files

| File | Purpose |
| --- | --- |
| `recon_TSE2D.m` | main reconstruction entry point |
| `read_TSE2D_twix.m` | current Twix/mapVBVD reader |
| `estimate_TSE_phasecor.m` / `apply_TSE_phasecor.m` | navigator phase correction |
| `apply_TSE_echomagcor.m` | optional echo magnitude correction |
| `pack_TSE2D_kspace.m` | Cartesian k-space packing |
| `recon_TSE2D_RSS.m` | RSS |
| `recon_TSE2D_GRAPPA.m` | GRAPPA |
| `recon_TSE2D_SENSE.m` | SENSE |
| `recon_TSE2D_CS.m` | CS |
| `utils/estimate_TSE2D_espirit.m` | ESPIRiT sensitivity estimation |
| `denoising/denoise_TSE2D.m` | optional denoising interface |

For equations, defaults, source links, and method-specific limitations, use the main reconstruction documentation rather than this folder README.
