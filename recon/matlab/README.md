# MATLAB reconstruction: Cartesian 2D TSE Twix reconstruction

This folder contains a transparent MATLAB reconstruction path for the
Siemens/Pulseq Cartesian **2D TSE** sequence in this repository. It does not
implement gSlider encoding.

The workflow is intended for sequence debugging and quantitative A/B tests.
It does not claim pixel-for-pixel equivalence with Siemens ICE, which may use
proprietary raw-data scaling, coil compression, adaptive coil combination,
GRAPPA kernels, filtering, and intensity normalization.

## Quick start

Edit the configuration block in `run_recon_TSE2D.m`, then run the script.

The programmatic entry point is:

```matlab
addpath(fullfile('recon', 'matlab'));

result = recon_TSE2D(twixFile, ...
    'MapVBVDPath','E:\Tools\mapVBVD', ...
    'Prewhiten',true, ...
    'PhaseCorrection',true, ...
    'EchoMagnitudeCorrection',true, ...
    'EchoMagnitudeMethod','wiener', ...
    'EchoMagnitudeAlpha',0, ...
    'EchoMagnitudeLambda','auto', ...
    'EchoMagnitudeMaxGain',2, ...
    'GRAPPA',true, ...
    'OutputDir',outputDir, ...
    'SaveNifti',true);

imageTSE = result.images.reconstructed;
```

For a phase-correction A/B reconstruction, add:

```matlab
'ComparePhaseCorrection',true
```

For a faster single-slice diagnostic reconstruction:

```matlab
'Slices',3, 'ComparePhaseCorrection',false
```

## Processing modules

| File | Purpose |
|---|---|
| `read_TSE2D_twix.m` | Reads image, phasecor, refscan, refscanPC, and noise streams with mapVBVD; copies the required MDH counters. |
| `estimate_noise_whitener.m` | Estimates the complex receive-noise covariance and regularized inverse square root. |
| `apply_coil_matrix.m` | Applies the whitening matrix to image, reference, and navigator data in memory-bounded chunks. |
| `estimate_TSE_phasecor.m` | Fits per-slice, per-echo, per-coil constant and readout-linear phase relative to a reference echo. |
| `apply_TSE_phasecor.m` | Applies the fitted phase model to image and PAT reference acquisitions using SLC/SEG. |
| `apply_TSE_echomagcor.m` | Applies legacy power-law or noise-stable Wiener echo-magnitude equalization to image and PAT reference streams. |
| `pack_TSE2D_kspace.m` | Packs unsorted acquisitions by one-based mapVBVD LIN and avoids double-weighting shared image/reference lines. |
| `recon_TSE2D_GRAPPA.m` | Calibrates and applies diagnostic 1D PE-GRAPPA for integer acceleration factors R >= 2. |
| `recon_TSE2D_SENSE.m` | Solves the ordinary ESPIRiT-SENSE least-squares problem by CG on the normal equations, with optional L2 stabilization. |
| `recon_TSE2D_CS.m` | Solves the same SENSE encoding problem with isotropic TV and orthonormal Haar-L1 regularization. |
| `utils/prepare_TSE2D_sense_model.m` | Builds the shared PCA-compressed k-space, sampling mask, and ESPIRiT/RSS sensitivity model. |
| `utils/sense_TSE2D_forward.m`, `utils/sense_TSE2D_adjoint.m` | Apply the common masked Cartesian PFS operator and its tested adjoint. |
| `utils/estimate_TSE2D_espirit.m` | Estimates a single set of ESPIRiT maps from the ACS calibration matrix. |
| `recon_TSE2D_RSS.m` | Performs centered 2D IFFT and RSS coil combination. |
| `build_TSE2D_nifti_geometry.m` | Builds and validates a scanner-patient RAS sform from Siemens MDH slice centers and quaternions. |
| `save_TSE2D_results.m` | Saves MAT, PNG, CSV, and text diagnostics. |
| `recon_TSE2D.m` | Orchestrates the complete workflow. |
| `write_TSE2D_nifti.m` | Writes compressed single-precision volumes with complete Twix-derived RAS geometry. |
| `batch_recon_TSE2D.m` | Reconstructs every Twix `.dat` in an input directory to one `.nii.gz` per file. |

## Prewhitening

Noise is loaded without readout-oversampling removal, because image-domain
cropping correlates adjacent noise samples. For a sample-by-coil noise matrix
`N`, the covariance is estimated as

```text
C = N' * N / (numberOfSamples - 1)
```

after channel-wise mean removal. It is regularized by shrinking toward its
diagonal:

```text
Creg = (1-shrinkage) * C + shrinkage * diag(diag(C))
```

The Hermitian inverse square root `W = Creg^(-1/2)` is applied to all raw
streams before phase correction and GRAPPA. Consequently, GRAPPA calibration,
image data, reference data, and final RSS combination share the same coil
basis. The default shrinkage is `0.02`.

If no usable noise scan is present, the code issues a warning and uses an
identity matrix. The fallback is never silent.

## TSE phase correction

For each SLC, SEG, and receive channel, the phase of

```text
navigatorEcho .* conj(referenceNavigatorEcho)
```

is fitted as a weighted linear function of normalized readout k-space. The
constant term corrects echo-to-echo phase offsets; the slope corrects linear
readout phase. Echo 1 is the default reference.

The same coefficients are applied to the image and PAT reference streams.
When Pulseq marks the same navigator as PHASCOR and reference phase correction,
mapVBVD exposes it in both `phasecor` and `refscanPC`; the code reads the
physical navigator from `phasecor` only and does not duplicate it.

## Echo-magnitude correction

When `EchoMagnitudeCorrection=true`, the normalized navigator magnitude
`A_e` is converted to an echo-specific gain. Image and PAT reference data
receive the same gain after navigator phase correction and before packing and
GRAPPA.

The legacy `power` method uses

```text
g_e = A_e^(EchoMagnitudeAlpha - 1)
```

`EchoMagnitudeMethod='wiener'` instead uses the normalized regularized inverse

```text
g_e = (1 + lambda) * A_e^(EchoMagnitudeAlpha + 1) / (A_e^2 + lambda)
```

At `lambda=0`, the Wiener formula equals the power method; at the reference
echo (`A_e=1`) its gain is always one. `EchoMagnitudeLambda='auto'` chooses a
separate lambda for each slice from the larger of:

- the noise-to-signal ratio of the prewhitened reference navigator; and
- the minimum regularization required to satisfy `EchoMagnitudeMaxGain`.

The maximum-gain target changes the smooth Wiener curve and is not a hard
clip. A numeric non-negative `EchoMagnitudeLambda` bypasses automatic
selection. `EchoMagnitudeAlpha=0` targets full equalization before
regularization; intermediate alpha values add a second sharpness/noise
trade-off. The default runner uses Wiener auto-lambda with maximum gain 2,
limiting the predicted per-line noise-variance gain to at most four.

## NIfTI spatial geometry

Compressed NIfTI output contains a complete scanner-patient sform, not
only voxel dimensions. read_TSE2D_twix retains each slice's MDH
SliceData.slicePos: [Sag Cor Tra quaternion(w x y z)]. The geometry
builder converts Siemens SCT/LPH coordinates to NIfTI RAS and maps the
stored MATLAB dimensions [readout, phase, slice] to their physical
directions.

For multislice data, pixdim(3) is measured from adjacent MDH slice
centers; slice thickness remains separate metadata. The affine origin is
the center of voxel [0,0,0]. Before writing, every image-slice center is
mapped through the affine and compared with its MDH position. After
writing, the sform and voxel dimensions are read back and checked.

This allows scans with different matrices or in-plane resolutions to share
the same scanner RAS physical space when their Siemens geometry agrees.

## GRAPPA

The GRAPPA implementation operates along phase encoding and supports the
regular Cartesian lattice for integer `R >= 2`:

1. Determine the actually acquired image lattice from MDH LIN.
2. Identify every missing PE residue class.
3. Select the nearest acquired PE source lines for each target.
4. Calibrate separate boundary/residue kernels from the contiguous ACS data.
5. Preserve all acquired image and ACS samples and synthesize only missing LINs.

The default kernel uses four PE source lines and no readout neighbors
(`GrappaKxKernel = 0`). This is fast and relatively well-conditioned with 39
ACS lines and 32 channels. A wider kernel such as `[-1 0 1]` is supported but
needs more ACS equations, memory, and computation.

Calibration NMSE and condition estimates are saved in `result.grappa` and the
text summary. They assess self-consistency inside ACS, not equivalence to ICE.

## Iterative SENSE and compressed sensing

`ReconstructionMethod` accepts `auto`, `rss`, `grappa`, `sense`, or `cs`.
`auto` preserves the original behavior: GRAPPA for accelerated data when
enabled, otherwise direct RSS. The two iterative methods share one encoding
model:

```text
E x = P F (S x)
```

where `P` is the measured LIN mask, `F` is a centered unitary 2-D FFT, and
`S` contains ACS-derived complex sensitivity maps. Coil compression and map
estimation are performed once per slice after prewhitening.

- `sense` solves `0.5*||E*x-y||_2^2 + 0.5*lambda*||x||_2^2` with CG.
- `cs` solves `0.5*||E*x-y||_2^2 + lambdaTV*TV(x) + lambdaW*||W*x||_1`
  with a Chambolle-Pock primal-dual iteration.

The image scale is normalized from the adjoint reconstruction before solving,
so the default regularization values are much less dependent on raw Twix
amplitude. Both solvers run an explicit numerical forward/adjoint test and
store convergence and residual histories in `result.sense` or `result.cs`.

The supplied R=5 CS-TSE example has 60 sampled ky lines and 30 central ACS
lines, but no phase-correction navigator. For that file use
`PhaseCorrection=false` and `EchoMagnitudeCorrection=false`. The sampling is
random only along ky, so its incoherence and regularization behavior are not
equivalent to a 2-D Poisson-disc mask.

`utils/estimate_TSE2D_espirit.m` currently returns one ESPIRiT map set. This is
appropriate when the object is contained in the calibration FOV; multi-map
ESPIRiT remains an extension point for calibration-region aliasing or small-FOV
cases.

See `run_recon_TSE2D_iterative.m` for matched SENSE and CS NIfTI
reconstructions. The design follows the shared-operator structure used by
[MRIReco.jl](https://github.com/MagneticResonanceImaging/MRIReco.jl),
[SigPy](https://github.com/mikgroup/sigpy), and
[BART PICS](https://github.com/mrirecon/bart).

## Result fields

```text
result.meta
result.prewhitening
result.phaseCorrection
result.echoMagnitudeCorrection
result.grappa
result.reconstructionMethod
result.sense                                  (ordinary SENSE diagnostics)
result.cs                                     (CS diagnostics)
result.sensitivityMaps                        (optional)
result.images.zeroFilled
result.images.reconstructed
result.images.reconstructedNoPhaseCorrection   (optional)
result.kspace                                  (optional)
```

When `OutputDir` is nonempty, the workflow writes:

- `<prefix>.nii.gz` when `SaveNifti=true`; the header stores Twix-derived
  scanner-patient RAS geometry and voxel dimensions
- `<prefix>_recon.mat`
- `<prefix>_final.png`
- `<prefix>_phasecor.csv` and `<prefix>_phasecor_metrics.png`
- `<prefix>_phasecor_comparison.png` when requested
- `<prefix>_summary.txt`

## Scope and assumptions

- Cartesian 2D TSE only.
- MDH `LIN` is phase encoding and `SEG` is echo number.
- Full encoded PE matrix size is supplied by the Twix header.
- Integrated contiguous ACS is expected for GRAPPA.
- Repeated acquisitions at one LIN are averaged.
- RSS is used after optional prewhitening; no sensitivity-map coil combine is
  included.
- Partial Fourier, simultaneous multi-slice, gSlider, non-Cartesian sampling,
  and compressed-sensing reconstruction are outside this workflow.
