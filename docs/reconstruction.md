# Reconstruction

The repository provides a transparent MATLAB reconstruction path for **conventional Cartesian 2D TSE Siemens Twix data**.

Main entry points:

```text
recon/matlab/examples/run_recon_TSE2D.m
recon/matlab/examples/run_recon_TSE2D_iterative.m
recon/matlab/recon_TSE2D.m
```

!!! warning "Scope"
    The offline reconstruction does **not** currently decode gSlider acquisitions and does not claim pixel-for-pixel equivalence with Siemens ICE.

## 1. Processing chain

The main reconstruction performs:

```text
Twix read
  |
  v
noise prewhitening
  |
  v
navigator phase estimation/correction
  |
  v
optional echo-magnitude equalization
  |
  v
LIN-based Cartesian k-space packing
  |
  +--> RSS
  +--> PE-GRAPPA
  +--> ESPIRiT-SENSE
  +--> ESPIRiT-SENSE + TV/Haar CS
  |
  v
NIfTI / MAT / PNG / CSV / diagnostics
```

The order matters. Image, navigator and PAT-reference data are kept in a consistent coil basis, and phase/magnitude corrections are applied before k-space packing and calibration-based reconstruction.

## 2. Twix streams and MDH counters

`read_TSE2D_twix.m` reads, when available:

- image data;
- `phasecor` navigators;
- PAT `refscan` data;
- `refscanPC` metadata/view;
- receive-noise data.

The reconstruction retains the counters needed to interpret the acquisition:

- `LIN` — phase-encoding line;
- `SLC` — slice;
- `SEG` — TSE echo index.

Within MATLAB/mapVBVD these indices are one-based.

## 3. Readout oversampling

By default, readout oversampling is removed from image, navigator and reference streams.

Noise is intentionally loaded without readout-oversampling removal. Image-domain cropping can correlate adjacent noise samples and bias the receive-noise covariance.

## 4. Receive-noise prewhitening

Prewhitening is enabled by default:

```matlab
'Prewhiten', true
'NoiseShrinkage', 0.02
```

For a mean-removed sample-by-coil noise matrix `N`, the covariance is estimated and shrunk toward its diagonal before applying a Hermitian inverse square root.

The same coil transform is applied to:

- image data;
- phase-correction data;
- PAT reference data.

If no usable noise stream is available, the code warns and uses an identity transform rather than silently pretending prewhitening succeeded.

## 5. Navigator phase correction

The default reference echo is echo 1.

For each slice, echo and receive channel, the reconstruction compares the current navigator with the reference navigator and fits the phase of:

```text
currentEcho .* conj(referenceEcho)
```

with a weighted linear model over normalized readout k-space:

```text
phase(kx) = linearSlope * normalizedKx + constantPhase
```

The model captures:

- constant echo-to-echo phase offset;
- readout-linear phase.

The same fitted correction is applied to image and PAT-reference acquisitions according to their `SLC` and `SEG` counters.

## 6. Echo-magnitude correction

The core API keeps echo-magnitude correction disabled by default for backward compatibility:

```matlab
'EchoMagnitudeCorrection', false
'EchoMagnitudeMethod', 'power'
'EchoMagnitudeAlpha', 1
```

The routine-use example deliberately opts into a noise-stable Wiener configuration:

```matlab
'EchoMagnitudeCorrection', true
'EchoMagnitudeMethod', 'wiener'
'EchoMagnitudeAlpha', 0
'EchoMagnitudeLambda', 'auto'
'EchoMagnitudeMaxGain', 2
```

These are different by design: API defaults preserve compatibility, while the example demonstrates the current preferred experimental equalization workflow.

The normalized navigator magnitude is denoted `A_e`.

Legacy power-law gain:

```text
g_e = A_e^(alpha - 1)
```

Normalized Wiener-style gain:

```text
g_e = (1 + lambda) * A_e^(alpha + 1) / (A_e^2 + lambda)
```

At `alpha = 0`, the unregularized model targets full envelope equalization. At `alpha = 1`, the unregularized power model preserves the measured envelope.

For Wiener mode, `lambda='auto'` selects a separate value for each slice from the larger of:

- a prewhitened navigator noise-to-signal term; and
- the regularization required to respect the configured smooth maximum-gain target.

The gain target is not implemented as a hard post-hoc clip.

## 7. Cartesian k-space packing

Acquisitions are placed into k-space according to MDH LIN. Repeated acquisitions of the same encoded row are averaged.

When image and reference views identify the same physical line, the workflow avoids intentionally counting the same physical acquisition twice.

## 8. Reconstruction methods

`ReconstructionMethod` accepts:

```text
auto
rss
grappa
sense
cs
```

### `auto`

For accelerated data, `auto` uses diagnostic GRAPPA when enabled. Otherwise it falls back to RSS.

### RSS

Centered 2D inverse FFT is applied coil-by-coil followed by root-sum-of-squares magnitude combination in the current coil basis.

### Diagnostic PE-GRAPPA

The repository implements a transparent one-dimensional PE-GRAPPA baseline for integer acceleration factors `R >= 2`.

Only missing phase-encoding lines are synthesized. Acquired imaging and ACS samples are preserved.

The default diagnostic kernel uses four PE source lines and no readout neighbors, with relative Tikhonov loading `1e-4`.

This implementation is intentionally simpler than Siemens ICE GRAPPA and should not be used to claim reconstruction equivalence with the scanner.

## 9. Iterative SENSE

SENSE and CS share the same Cartesian multicoil encoding model:

```text
A x = P F (S x)
```

where:

- `S` contains complex sensitivity maps;
- `F` is a centered unitary 2D FFT;
- `P` is the acquired-line mask.

Ordinary SENSE solves:

```text
min_x 0.5 ||A x - y||_2^2 + 0.5 lambda ||x||_2^2
```

using conjugate gradients on the normal equations.

Typical starting values:

```matlab
'SENSEIterations', 50
'SENSETolerance', 1e-5
'SENSETikhonov', 1e-4
```

## 10. Cartesian CS

The CS solver minimizes:

```text
0.5 ||A x-y||_2^2
+ lambdaTV * TV(x)
+ lambdaW * ||W x||_1
```

where `W` is an orthonormal Haar transform. Coarsest-scale Haar approximation coefficients are not penalized.

A Chambolle-Pock primal-dual iteration is used.

Reference-validated starting settings in the example are:

```matlab
'CSIterations', 250
'CSTVWeight', 0.006
'CSWaveletWeight', 0.0005
'CSWaveletLevels', 2
```

These are starting values, not universal parameters. Retune them for different resolution, contrast, sampling masks, coil arrays or calibration data.

## 11. Coil compression and ESPIRiT

Iterative reconstruction can use ACS-derived global PCA coil compression before sensitivity estimation.

Typical settings are:

```matlab
'CoilCompressionEnergy', 0.99
'MaximumVirtualCoils', 12
```

The default sensitivity method is native MATLAB single-map ESPIRiT. The calibration workflow:

1. extracts a contiguous ACS region;
2. builds a block-Hankel calibration matrix;
3. retains the singular-vector signal subspace;
4. converts kernels to an image-domain covariance operator;
5. estimates the dominant eigenvector/eigenvalue by power iteration;
6. crops support by eigenvalue threshold; and
7. RSS-normalizes the retained complex map set.

ESPIRiT requires at least eight contiguous ACS lines in the direct estimator. The higher-level iterative pipeline also refuses to proceed without enough central calibration data.

## 12. Forward/adjoint consistency check

Before SENSE or CS iterations, the implementation performs a numerical inner-product test of the forward and adjoint operators.

A relative mismatch greater than `5e-5` stops reconstruction. This protects against silently solving an inconsistent inverse problem after code changes.

## 13. GPU behavior

Use:

```matlab
'IterativeUseGPU', 'auto'
```

`'auto'` attempts to use a supported MATLAB GPU when available and otherwise runs on CPU.

## 14. NIfTI output

The NIfTI writer derives scanner-patient RAS geometry from Siemens MDH slice centers and quaternions when available and validates consistency across slices.

The code checks slice spacing/orientation and verifies reconstructed slice centers against the affine before writing.

This is stricter than writing voxel dimensions alone and is important when comparing data with different matrices or resolutions in scanner physical space.

## 15. Known limitations

The offline MATLAB reconstruction currently excludes:

- gSlider decoding;
- partial Fourier;
- SMS;
- non-Cartesian trajectories;
- multiple ESPIRiT map sets;
- proprietary Siemens raw-data scaling, coil combination and filtering.

Image-domain denoising cannot recover signal or resolution that was not acquired and should not replace acquisition-side echo-envelope optimization.
