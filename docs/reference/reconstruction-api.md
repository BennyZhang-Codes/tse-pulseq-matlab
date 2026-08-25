# Reconstruction API

## `recon_TSE2D`

```matlab
result = recon_TSE2D(filename, Name, Value, ...)
```

Offline diagnostic reconstruction for **conventional Cartesian 2D TSE Siemens Twix data**.

The maintained processing order is

```text
Twix read
→ noise prewhitening
→ navigator phase correction
→ optional echo-magnitude correction
→ LIN-based Cartesian packing
→ RSS / GRAPPA / ESPIRiT-SENSE / CS
→ optional outputs
```

The function does not currently decode gSlider acquisitions and does not reproduce proprietary Siemens ICE filtering/coil-combination behavior.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/recon_TSE2D.m)

## Required argument

### `filename`

Path to the Siemens Twix `.dat` file.

```matlab
result = recon_TSE2D("meas_MID00123.dat", ...)
```

## Raw-data and preprocessing options

| Option | Default | Purpose |
| --- | --- | --- |
| `MapVBVDPath` | `''` | Folder containing `mapVBVD.m` |
| `RemoveOversampling` | `true` | Remove readout oversampling from compatible image/reference streams |
| `Prewhiten` | `true` | Apply receive-noise prewhitening |
| `NoiseShrinkage` | `0.02` | Diagonal covariance shrinkage factor |
| `NoiseEigenvalueFloor` | `1e-6` | Eigenvalue floor for the covariance regularization |
| `Slices` | `[]` | One-based mapVBVD SLC indices; empty means all slices |

Noise data are intentionally handled differently from image cropping because image-domain cropping can correlate neighboring noise samples and bias the covariance estimate.

## Navigator correction options

| Option | Default | Purpose |
| --- | --- | --- |
| `PhaseCorrection` | `true` | Apply TSE navigator phase correction |
| `PhaseReferenceEcho` | `1` | Reference echo used by the navigator model |
| `EchoMagnitudeCorrection` | `false` | Enable navigator-derived echo-magnitude equalization |
| `EchoMagnitudeAlpha` | `1` | Target-envelope exponent in `[0,1]` |
| `EchoMagnitudeMethod` | `'power'` | `'power'` or `'wiener'` |
| `EchoMagnitudeLambda` | `'auto'` | Wiener regularization or explicit scalar |
| `EchoMagnitudeMaxGain` | `2` | Smooth gain limit used by the automatic Wiener rule |

See [Echo phase & magnitude correction](/guide/echo-corrections) for the equations and noise trade-off.

## Reconstruction selection

`ReconstructionMethod` accepts

```text
auto
rss
grappa
sense
cs
```

The `auto` path uses the configured data/calibration state and `GRAPPA` option to select the maintained diagnostic behavior. For reproducible comparisons, prefer an explicit method name.

## GRAPPA options

| Option | Default |
| --- | ---: |
| `GRAPPA` | `true` |
| `GrappaKySourceCount` | `4` |
| `GrappaKxKernel` | `0` |
| `GrappaRegularization` | `1e-4` |

The repository implements a transparent PE-GRAPPA baseline. Acquired imaging/ACS samples are preserved and only missing PE rows are synthesized.

## SENSE options

| Option | Default |
| --- | ---: |
| `SENSEIterations` | `50` |
| `SENSETolerance` | `1e-5` |
| `SENSETikhonov` | `1e-4` |

The common iterative forward model is

$$
A=PFS.
$$

A numerical forward/adjoint identity check is performed before the iterative solver. A mismatch above the implemented threshold stops reconstruction.

## CS options

| Option | Default |
| --- | ---: |
| `CSIterations` | `250` |
| `CSTVWeight` | `0.006` |
| `CSWaveletWeight` | `0.0005` |
| `CSWaveletLevels` | `2` |

The CS path uses the same Cartesian multicoil encoding model as SENSE plus isotropic TV and orthonormal Haar-wavelet regularization.

## Sensitivity and coil-compression options

| Option | Default |
| --- | --- |
| `SensitivityMethod` | `'espirit'` |
| `SensitivityReadoutWidth` | `30` |
| `ESPIRiTKernelSize` | `[6 6]` |
| `ESPIRiTSubspaceThreshold` | `0.02` |
| `ESPIRiTEigenvalueCrop` | `0.95` |
| `CoilCompressionEnergy` | `0.99` |
| `MaximumVirtualCoils` | `12` |
| `KeepSensitivityMaps` | `false` |

The default iterative path uses a native MATLAB single-map ESPIRiT estimator and optional ACS-derived global PCA coil compression.

## GPU option

```matlab
'IterativeUseGPU', 'auto'
```

Accepted values are `true`, `false`, or `'auto'`. GPU execution applies to the iterative SENSE/CS path; RSS and diagnostic GRAPPA do not require GPU support.

## Output options

| Option | Default | Purpose |
| --- | --- | --- |
| `KeepKspace` | `false` | Keep final per-slice k-space in `result` |
| `ComparePhaseCorrection` | `false` | Also reconstruct the uncorrected comparison branch |
| `OutputDir` | `''` | Output directory; empty disables filesystem output |
| `OutputPrefix` | `''` | Prefix for saved files |
| `SaveMat` | `true` | Save MATLAB result data when output is enabled |
| `SaveFigures` | `true` | Save diagnostic figures when output is enabled |
| `SaveNifti` | `false` | Save reconstructed magnitude NIfTI |
| `NiftiVoxelSizeMm` | `[]` | Optional explicit voxel size override |
| `OverwriteOutputs` | `false` | Allow overwriting existing outputs |
| `Verbose` | `true` | Console diagnostics |

## Example: SENSE

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'Prewhiten', true, ...
    'PhaseCorrection', true, ...
    'ReconstructionMethod', 'sense', ...
    'SENSEIterations', 50, ...
    'SENSETolerance', 1e-5, ...
    'SENSETikhonov', 1e-4, ...
    'IterativeUseGPU', 'auto');
```

## Example: Wiener echo equalization + SENSE

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'Prewhiten', true, ...
    'PhaseCorrection', true, ...
    'EchoMagnitudeCorrection', true, ...
    'EchoMagnitudeMethod', 'wiener', ...
    'EchoMagnitudeAlpha', 0, ...
    'EchoMagnitudeLambda', 'auto', ...
    'EchoMagnitudeMaxGain', 2, ...
    'ReconstructionMethod', 'sense');
```

When comparing the corrected and uncorrected results, keep the sampling, sensitivity estimation, solver, regularization, and evaluation ROI fixed. See [Reconstruction protocol](/validation/reconstruction-protocol).

## Core helper functions

| Function | Role | Source |
| --- | --- | --- |
| `read_TSE2D_twix` | Read image / phasecor / refscan / noise streams and MDH metadata | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/read_TSE2D_twix.m) |
| `estimate_noise_whitener` | Estimate regularized receive-noise prewhitening matrix | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/estimate_noise_whitener.m) |
| `apply_coil_matrix` | Apply a coil-space transform to multichannel data | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/apply_coil_matrix.m) |
| `estimate_TSE_phasecor` | Estimate per-slice/per-echo navigator phase and amplitude model | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/estimate_TSE_phasecor.m) |
| `apply_TSE_phasecor` | Apply the fitted navigator phase correction | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/apply_TSE_phasecor.m) |
| `apply_TSE_echomagcor` | Apply power or Wiener-style echo-magnitude correction | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/apply_TSE_echomagcor.m) |
| `pack_TSE2D_kspace` | Pack corrected acquisitions by MDH LIN into Cartesian k-space | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/pack_TSE2D_kspace.m) |
| `build_TSE2D_nifti_geometry` | Build/validate scanner-patient geometry for NIfTI export | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/build_TSE2D_nifti_geometry.m) |

Additional calibration/iterative helper functions live in `recon/matlab/`. Treat their checked-out source revision as authoritative for low-level implementation details.

## Return value

`result` is a structure containing the reconstructed output together with metadata and diagnostics produced by the selected path. Optional fields depend on configuration, for example retained k-space, sensitivity maps, phase-correction comparison outputs, and filesystem-export information.

For methods reporting, do not rely only on the final magnitude image. Retain the numerical diagnostics and exact option set needed to reproduce the result.
