# MATLAB reconstruction: Cartesian 2D TSE Twix reconstruction

This folder contains the MATLAB reconstruction path for the Siemens/Pulseq Cartesian **2D TSE** sequence in this repository. It is intended for reproducible offline reconstruction and controlled sequence/reconstruction comparisons. It does **not** implement gSlider decoding.

The current raw-data reader is Siemens Twix specific through `mapVBVD`. The reconstruction does not claim pixel-for-pixel equivalence with Siemens ICE, which may use proprietary raw-data scaling, coil processing, GRAPPA kernels, filtering, and intensity normalization.

Full documentation:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction>

## Quick start

Edit `examples/run_recon_TSE2D.m`, then run it. The programmatic entry point is:

```matlab
addpath(fullfile('recon', 'matlab'));

result = recon_TSE2D(twixFile, ...
    'MapVBVDPath','E:\Tools\mapVBVD', ...
    'Prewhiten',true, ...
    'PhaseCorrection',true, ...
    'EchoMagnitudeCorrection',false, ...
    'ReconstructionMethod','grappa', ...
    'OutputDir',outputDir, ...
    'SaveNifti',true);

imageTSE = result.images.reconstructed;
```

`ReconstructionMethod` accepts:

```text
auto
rss
grappa
sense
cs
```

For reproducible comparisons, prefer an explicit method rather than `auto`.

## Processing order

```text
Siemens Twix
→ prewhitening
→ phase correction
→ optional echo magnitude correction
→ k-space packing
→ RSS / GRAPPA / SENSE / CS
→ image and geometry export
→ optional image-domain denoising
```

## Reconstruction methods

### RSS

`recon_TSE2D_RSS.m` performs centered coil-wise 2D IFFT followed by root-sum-of-squares combination.

### GRAPPA

`recon_TSE2D_GRAPPA.m` implements GRAPPA. The current implementation:

- accelerates along phase encoding;
- supports integer acceleration `R >= 2`;
- calibrates from integrated contiguous ACS;
- uses separate kernels for missing PE residue/offset patterns;
- supports configurable PE source count and optional readout-neighbor offsets;
- uses relative Tikhonov regularization for kernel fitting;
- reports calibration NMSE and conditioning; and
- preserves acquired imaging and ACS rows, filling only missing rows.

Current limitations:

- partial-Fourier GRAPPA is not implemented;
- SMS/slice-GRAPPA is not implemented;
- non-Cartesian GRAPPA is not implemented;
- irregular variable-density/CS masks are not handled by this GRAPPA path; and
- Siemens ICE-specific kernel selection, scaling, coil processing, and filtering are not reproduced.

Defaults:

```matlab
'GrappaKySourceCount', 4
'GrappaKxKernel', 0
'GrappaRegularization', 1e-4
```

### SENSE

`recon_TSE2D_SENSE.m` uses the multicoil model

```text
A x = P F (S x)
```

and solves an L2-regularized least-squares problem by conjugate gradients. The default sensitivity estimation method is ESPIRiT.

### CS

`recon_TSE2D_CS.m` uses the same multicoil data-consistency model with isotropic TV and orthonormal Haar-L1 regularization solved by a Chambolle-Pock iteration.

Default regularization values are repository starting points, not universal optima. For matched comparisons, keep sampling, sensitivity estimation, solver settings, regularization, precision, and evaluation region fixed.

## Processing modules

| File | Purpose |
|---|---|
| `read_TSE2D_twix.m` | Read image, phasecor, refscan, refscanPC, and noise streams through mapVBVD; retain required MDH counters. |
| `estimate_noise_whitener.m` | Estimate complex receive-noise covariance and regularized inverse square root. |
| `apply_coil_matrix.m` | Apply the whitening matrix to multichannel streams. |
| `estimate_TSE_phasecor.m` | Fit per-slice/per-echo/per-coil navigator phase and estimate the measured echo envelope. |
| `apply_TSE_phasecor.m` | Apply phase correction. |
| `apply_TSE_echomagcor.m` | Apply optional echo magnitude correction. |
| `pack_TSE2D_kspace.m` | Pack acquisitions by one-based mapVBVD LIN. |
| `recon_TSE2D_RSS.m` | RSS. |
| `recon_TSE2D_GRAPPA.m` | GRAPPA. |
| `recon_TSE2D_SENSE.m` | SENSE. |
| `recon_TSE2D_CS.m` | CS. |
| `utils/prepare_TSE2D_sense_model.m` | Build coil-compressed k-space, masks, and sensitivity maps for SENSE/CS. |
| `utils/estimate_TSE2D_espirit.m` | Estimate an ESPIRiT sensitivity-map set from ACS. |
| `build_TSE2D_nifti_geometry.m` | Build and validate scanner-patient RAS geometry. |
| `save_TSE2D_results.m` | Save images and reconstruction diagnostics. |
| `batch_recon_TSE2D.m` | Batch reconstruction entry point. |
| `denoising/denoise_TSE2D.m` | Optional NLM, BM3D, SANLM, and TGV2 post-reconstruction interface. |

## Prewhitening

Noise is loaded without image-style readout-oversampling removal because image-domain cropping can correlate adjacent noise samples and bias the covariance estimate. The whitening transform is applied consistently to image, phase-correction, and compatible PAT-reference streams.

If no usable noise scan is present, the code warns and uses an identity transform; the fallback is not silent.

## Phase correction

For each SLC, SEG, and receive channel, the phase of

```text
navigatorEcho .* conj(referenceNavigatorEcho)
```

is fitted as a weighted linear function of normalized readout k-space. The same correction basis is applied to compatible imaging and PAT-reference data before k-space packing.

## Optional echo magnitude correction

Echo magnitude correction is **disabled by default**. When explicitly enabled, the measured navigator envelope can be converted to a power-law or Wiener-style regularized gain before k-space packing.

This is a navigator-derived global echo-envelope equalization, not a voxelwise quantitative T2 correction. It can alter noise, apparent sharpness, and contrast, so preserve an uncorrected reconstruction when evaluating it.

See:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections>

## Coil compression and ESPIRiT

The SENSE/CS path can use ACS-derived PCA coil compression. Default settings retain 99% calibration energy with at most 12 virtual coils.

The default sensitivity estimation method is ESPIRiT. The current implementation returns one map set; multiple ESPIRiT map sets are not implemented.

## Optional image-domain denoising

Image-domain denoising is **not part of `recon_TSE2D`** and is never applied automatically. The separate `denoising/` module exposes NLM, BM3D, SANLM, and TGV2 for user-selected post-processing and benchmarking.

BM3D and SANLM are optional third-party dependencies and are not vendored. Preserve the unfiltered reconstruction and report the selected method/parameters when filtered images are used.

See:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising>

## Scope and assumptions

- Conventional Cartesian 2D TSE only.
- Siemens Twix is the currently implemented raw-data input.
- MDH `LIN` is phase encoding and `SEG` is echo number.
- Repeated acquisitions at one LIN are averaged.
- Integrated contiguous ACS is expected for the maintained PI calibration paths.
- RSS, GRAPPA, SENSE, and CS are available; ESPIRiT is the default sensitivity estimation method for SENSE/CS.
- Echo magnitude correction is optional and disabled by default.
- Image-domain denoising is optional and separate from reconstruction.
- Partial Fourier, SMS, gSlider decoding, non-Cartesian reconstruction, multiple ESPIRiT map sets, and non-Siemens raw-data readers are not implemented in this workflow.
