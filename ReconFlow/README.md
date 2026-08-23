# ReconFlow: Cartesian 2D TSE Twix reconstruction

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
addpath('E:\Pulseq_seqs\tse-pulseq-matlab\ReconFlow');

result = recon_TSE2D(twixFile, ...
    'MapVBVDPath','E:\Tools\mapVBVD', ...
    'Prewhiten',true, ...
    'PhaseCorrection',true, ...
    'GRAPPA',true, ...
    'OutputDir',outputDir);

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
| `pack_TSE2D_kspace.m` | Packs unsorted acquisitions by one-based mapVBVD LIN and avoids double-weighting shared image/reference lines. |
| `recon_TSE2D_GRAPPA.m` | Calibrates and applies diagnostic 1D PE-GRAPPA for integer acceleration factors R >= 2. |
| `recon_TSE2D_RSS.m` | Performs centered 2D IFFT and RSS coil combination. |
| `save_TSE2D_results.m` | Saves MAT, PNG, CSV, and text diagnostics. |
| `recon_TSE2D.m` | Orchestrates the complete workflow. |

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

## Result fields

```text
result.meta
result.prewhitening
result.phaseCorrection
result.grappa
result.images.zeroFilled
result.images.reconstructed
result.images.reconstructedNoPhaseCorrection   (optional)
result.kspace                                  (optional)
```

When `OutputDir` is nonempty, the workflow writes:

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

