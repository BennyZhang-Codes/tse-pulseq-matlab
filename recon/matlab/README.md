# MATLAB reconstruction: Cartesian 2D TSE Twix reconstruction

This folder contains a transparent MATLAB reconstruction path for the Siemens/Pulseq Cartesian **2D TSE** sequence in this repository. It does not implement gSlider decoding.

The workflow is intended for sequence development, reproducible offline reconstruction, and controlled A/B comparisons. It does not claim pixel-for-pixel equivalence with Siemens ICE, which may use proprietary raw-data scaling, coil processing, GRAPPA kernels, filtering, and intensity normalization.

The full scientific documentation is available at:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction>

## Quick start

Edit the configuration block in `examples/run_recon_TSE2D.m`, then run it.

The programmatic entry point is:

```matlab
addpath(fullfile('recon', 'matlab'));

result = recon_TSE2D(twixFile, ...
    'MapVBVDPath','E:\Tools\mapVBVD', ...
    'Prewhiten',true, ...
    'PhaseCorrection',true, ...
    'EchoMagnitudeCorrection',false, ...
    'GRAPPA',true, ...
    'OutputDir',outputDir, ...
    'SaveNifti',true);

imageTSE = result.images.reconstructed;
```

Echo-magnitude equalization is an **optional reconstruction choice** and is disabled by default. To evaluate it explicitly:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath','E:\Tools\mapVBVD', ...
    'Prewhiten',true, ...
    'PhaseCorrection',true, ...
    'EchoMagnitudeCorrection',true, ...
    'EchoMagnitudeMethod','wiener', ...
    'EchoMagnitudeAlpha',0, ...
    'EchoMagnitudeLambda','auto', ...
    'EchoMagnitudeMaxGain',2, ...
    'ReconstructionMethod','sense');
```

This option is provided for user-controlled comparison; enabling it is not required for a valid reconstruction. See the documentation page **Echo phase and magnitude correction** for the equations, MRI-specific references, and limitations.

For a phase-correction A/B reconstruction, add:

```matlab
'ComparePhaseCorrection',true
```

For a faster single-slice diagnostic reconstruction:

```matlab
'Slices',3, 'ComparePhaseCorrection',false
```

## Processing order

```text
Siemens Twix
→ receive-noise prewhitening
→ navigator phase correction
→ optional navigator-derived echo-envelope equalization
→ LIN-based Cartesian k-space packing
→ RSS / diagnostic GRAPPA / ESPIRiT-SENSE / CS
→ image and geometry export
→ optional image-domain denoising as a separate step
```

## Processing modules

| File | Purpose |
|---|---|
| `read_TSE2D_twix.m` | Reads image, phasecor, refscan, refscanPC, and noise streams with mapVBVD; copies required MDH counters. |
| `estimate_noise_whitener.m` | Estimates the complex receive-noise covariance and regularized inverse square root. |
| `apply_coil_matrix.m` | Applies the whitening matrix to multichannel streams. |
| `estimate_TSE_phasecor.m` | Fits per-slice, per-echo, per-coil navigator phase and estimates the measured echo envelope. |
| `apply_TSE_phasecor.m` | Applies the fitted navigator phase model. |
| `apply_TSE_echomagcor.m` | Applies optional power-law or Wiener-style echo-envelope equalization. |
| `pack_TSE2D_kspace.m` | Packs acquisitions by one-based mapVBVD LIN. |
| `recon_TSE2D_RSS.m` | Centered 2D IFFT and RSS coil combination. |
| `recon_TSE2D_GRAPPA.m` | Diagnostic 1D PE-GRAPPA for regular integer acceleration. |
| `recon_TSE2D_SENSE.m` | ESPIRiT-SENSE using CG on the normal equations. |
| `recon_TSE2D_CS.m` | SENSE encoding with TV and Haar-L1 regularization. |
| `utils/prepare_TSE2D_sense_model.m` | Builds coil-compressed k-space, masks, and sensitivity maps. |
| `utils/sense_TSE2D_forward.m`, `utils/sense_TSE2D_adjoint.m` | Common Cartesian multicoil forward/adjoint operator. |
| `utils/estimate_TSE2D_espirit.m` | Estimates a single ESPIRiT map set from ACS. |
| `build_TSE2D_nifti_geometry.m` | Builds and validates scanner-patient RAS geometry. |
| `save_TSE2D_results.m` | Saves reconstruction and diagnostics. |
| `batch_recon_TSE2D.m` | Batch reconstruction entry point. |
| `denoising/denoise_TSE2D.m` | Optional NLM, BM3D, SANLM, and TGV2 post-reconstruction interface. |
| `denoising/benchmark_TSE2D_denoisers.m` | Optional denoiser comparison and reporting. |

## Prewhitening

Noise is loaded without image-style readout-oversampling removal because image-domain cropping can correlate adjacent noise samples and bias the covariance estimate.

For a sample-by-coil noise matrix `N`, the covariance is estimated after channel-wise mean removal and regularized toward its diagonal. Its Hermitian inverse square root is then applied consistently to image, phase-correction, and PAT-reference streams.

If no usable noise scan is present, the code warns and uses an identity transform. The fallback is not silent.

## TSE navigator phase correction

For each SLC, SEG, and receive channel, the phase of

```text
navigatorEcho .* conj(referenceNavigatorEcho)
```

is fitted as a weighted linear function of normalized readout k-space. The constant term models echo-to-echo phase offsets and the slope models readout-linear phase variation.

The same correction basis is applied to compatible imaging and PAT-reference data before k-space packing.

## Optional echo-magnitude correction

When `EchoMagnitudeCorrection=true`, the normalized measured navigator envelope `A_e` is converted to an echo-specific gain and applied before Cartesian packing.

The power model is

```text
g_e = A_e^(EchoMagnitudeAlpha - 1)
```

and the normalized Wiener-style model is

```text
g_e = (1 + lambda) * A_e^(EchoMagnitudeAlpha + 1) / (A_e^2 + lambda)
```

with optional automatic regularization derived from navigator noise and the configured smooth maximum-gain target.

This is a **navigator-derived global echo-envelope equalizer**, not a voxelwise quantitative T2 correction. It can change noise, apparent sharpness, and contrast, so users should preserve and compare an uncorrected reconstruction when evaluating it.

The MRI-specific methodological basis and implementation differences are documented at:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections>

## Reconstruction methods

`ReconstructionMethod` accepts:

```text
auto
rss
grappa
sense
cs
```

The two iterative methods share the Cartesian encoding model

```text
E x = P F (S x)
```

where `P` is the measured LIN mask, `F` is a centered unitary 2D FFT, and `S` contains complex coil sensitivity maps.

- `sense` solves an L2-regularized least-squares problem with CG.
- `cs` uses the same data-consistency model with isotropic TV and orthonormal Haar-L1 regularization through a Chambolle-Pock iteration.

Default regularization values are starting points rather than universal optima. For matched comparisons, keep the sampling, CSM, solver, regularization, precision, and evaluation region fixed.

## Optional image-domain denoising

Image-domain denoising is **not part of `recon_TSE2D`** and is never applied automatically. It is exposed through the separate `denoising/` module for users who choose to evaluate post-processing.

Available methods include:

```text
NLM
BM3D
SANLM
TGV2
```

BM3D and SANLM are optional third-party dependencies and are not vendored. BM3D support includes an optional correlated-noise PSD path, but the package does not designate BM3D—or any other denoiser—as the universal default for TSE or human-brain reconstruction.

A typical explicit comparison is:

```matlab
matlabDir = fullfile('recon','matlab');
addpath(matlabDir,fullfile(matlabDir,'denoising'));

[summary,metrics] = benchmark_TSE2D_denoisers(inputDir,outputDir, ...
    'Methods',["nlm","bm3d","tgv2"]);
```

Denoising results should be interpreted as optional post-processing. Preserve the unfiltered reconstruction and report the selected method and parameters when filtered images are used in a study.

See:

<https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising>

## NIfTI spatial geometry

Compressed NIfTI output contains scanner-patient geometry rather than only voxel dimensions. The geometry builder converts retained Siemens slice position/orientation metadata to NIfTI RAS and validates slice centers against the resulting affine before writing.

For image-domain post-processing, the source NIfTI geometry can be reused so denoising changes voxel values without changing spatial geometry.

## Result fields

Representative fields include:

```text
result.meta
result.prewhitening
result.phaseCorrection
result.echoMagnitudeCorrection
result.grappa
result.reconstructionMethod
result.sense
result.cs
result.sensitivityMaps
result.samplingMasks
result.images.zeroFilled
result.images.reconstructed
result.images.reconstructedNoPhaseCorrection
result.kspace
```

Optional fields depend on configuration.

## Scope and assumptions

- Cartesian conventional 2D TSE only.
- Siemens Twix is the currently implemented raw-data input.
- MDH `LIN` is phase encoding and `SEG` is echo number.
- Integrated contiguous ACS is expected for the maintained PI calibration path.
- Repeated acquisitions at one LIN are averaged.
- RSS, diagnostic GRAPPA, ESPIRiT-SENSE, and Cartesian TV/Haar CS are available.
- Echo-magnitude equalization is optional.
- Image-domain denoising is optional and separate from reconstruction.
- Partial Fourier, simultaneous multi-slice, gSlider decoding, non-Cartesian sampling, and multiple ESPIRiT map sets are outside the current workflow.
