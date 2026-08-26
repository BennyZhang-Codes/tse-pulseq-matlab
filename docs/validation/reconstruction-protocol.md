# Reconstruction protocol

A reconstruction comparison is only interpretable when the acquisition model, preprocessing, calibration, solver, and evaluation rules are frozen in advance. This page defines a reproducible protocol for comparing RSS, GRAPPA, SENSE, CS, and optional echo-correction variants in this repository.

::: info Why this page exists
The protocol is deliberately separate from [Reconstruction](/reconstruction). The reconstruction chapter explains how the pipeline works; this page specifies what must remain fixed when methods are compared or results are reported.
:::

## 1. Freeze the data definition

Record the exact raw-data and sequence state:

- Twix file identifier and acquisition date;
- `.seq` file and repository commit;
- Pulseq and VERSE submodule SHAs;
- scanner/interpreter version when available;
- matrix, FOV, slice thickness/gap, orientation, and slice order;
- `TE1`, `TEeff`, `nEcho`, TR, refocusing schedule, and PE mode;
- acceleration factor and ACS/reference layout;
- whether noise, phase-correction, and PAT-reference scans were acquired.

Do not compare two reconstruction methods on silently different raw-data subsets.

## 2. Freeze coordinate and indexing conventions

The following conventions must be identical across methods:

| Item | Protocol requirement |
| --- | --- |
| Logical PE coordinate | Same physical $k_y$ definition and center convention |
| Siemens LIN | Same zero-based sequence-side metadata interpretation |
| MATLAB indexing | Same one-based mapVBVD conversion |
| Readout centering | Same FFT shift convention |
| Image orientation | Same scanner-to-RAS geometry and slice ordering |
| Cropping / ROI | Predefined before metric calculation and applied identically |

A predefined FOV crop or ROI is acceptable when it represents the intended analysis region. **Post-hoc cropping chosen to improve a method's metric is not.**

## 3. Freeze raw-data preprocessing

Recommended default comparison state:

```matlab
'RemoveOversampling', true
'Prewhiten', true
'NoiseShrinkage', 0.02
'PhaseCorrection', true
'EchoMagnitudeCorrection', false
```

If echo magnitude correction is the variable under study, keep every other preprocessing choice fixed and report its method, `EchoMagnitudeAlpha`, regularization mode/value, maximum-gain target, and resulting noise amplification.

## 4. Freeze k-space packing and sampling

All methods must use the same acquired Cartesian samples after preprocessing.

Record:

- acquired LIN set;
- repeated-line averaging rule;
- ACS/reference lines;
- whether imaging and refscan views overlap physically;
- final binary sampling mask $P$; and
- any excluded corrupt acquisitions and the rule used to identify them.

Do not let one algorithm receive additional central lines, a different ACS width, or a different slice subset unless that difference is the explicit experimental variable.

## 5. Freeze coil processing

For SENSE and CS, record the sensitivity and compression state.

Typical starting configuration:

```matlab
'SensitivityMethod', 'espirit'
'ESPIRiTKernelSize', [6 6]
'ESPIRiTSubspaceThreshold', 0.02
'ESPIRiTEigenvalueCrop', 0.95
'CoilCompressionEnergy', 0.99
'MaximumVirtualCoils', 12
```

If coil compression is enabled, use the same compressed coil basis for all methods intended to share that basis.

GRAPPA currently operates on the packed multichannel k-space supplied to `recon_TSE2D_GRAPPA` and is not routed through the SENSE/CS PCA/ESPIRiT preparation step. Therefore a GRAPPA versus SENSE/CS comparison must report that difference explicitly.

## 6. Freeze the forward model

For SENSE and CS, the common Cartesian encoding model is

$$
A=PFS,
$$

with the same sampling mask $P$, centered unitary Fourier operator $F$, and sensitivity multiplication $S$.

Before iterative reconstruction, the forward/adjoint identity check must pass under the same numerical tolerance.

GRAPPA is a k-space interpolation method and does not use the SENSE/CS `PFS` iterative operator.

## 7. Freeze reconstruction settings

### SENSE

```matlab
'SENSEIterations', 50
'SENSETolerance', 1e-5
'SENSETikhonov', 1e-4
```

### CS

```matlab
'CSIterations', 250
'CSTVWeight', 0.006
'CSWaveletWeight', 0.0005
'CSWaveletLevels', 2
```

If regularization is tuned separately for each dataset, specify the tuning rule.

### GRAPPA

```matlab
'GrappaKySourceCount', 4
'GrappaKxKernel', 0
'GrappaRegularization', 1e-4
```

Also record:

- acceleration factor $R$;
- exact acquired imaging lattice;
- ACS location and width;
- source-line/readout offsets when changed from defaults;
- calibration NMSE and conditioning returned by the implementation; and
- confirmation that acquired image/ACS rows are preserved.

Current GRAPPA implementation limits:

- acceleration along phase encoding only;
- integer `R >= 2`;
- regular Cartesian acceleration lattice;
- integrated contiguous ACS;
- no partial-Fourier GRAPPA;
- no SMS/slice-GRAPPA;
- no non-Cartesian GRAPPA;
- no irregular variable-density/CS mask reconstruction; and
- no Siemens ICE-specific kernel/scaling/filtering replication.

The method name is simply **GRAPPA**; these are package-specific implementation limits.

## 8. Freeze precision and hardware

Record MATLAB release, CPU, GPU/driver information when used, `IterativeUseGPU`, numerical precision, material thread/environment settings, and first-run/warm-up policy.

## 9. Freeze stopping and failure rules

Examples:

- adjoint mismatch above the configured threshold → SENSE/CS invalid;
- insufficient ACS for ESPIRiT → SENSE/CS not run;
- insufficient or underdetermined GRAPPA calibration → GRAPPA not run;
- non-finite output → invalid;
- maximum iteration reached → report as such rather than silently extending one method;
- failed geometry validation → do not report NIfTI as spatially valid.

## 10. Freeze evaluation metrics

Primary operator/reconstruction comparisons should use raw complex values where available.

$$
\mathrm{NRMSE}_{\mathbb C}
=
\frac{\lVert x-x_{\mathrm{ref}}\rVert_2}
{\lVert x_{\mathrm{ref}}\rVert_2}.
$$

Magnitude NRMSE and SSIM can be secondary image-domain measures. For GRAPPA, calibration NMSE is a useful calibration-quality measure but is **not** a substitute for reconstruction fidelity against a frozen reference.

## 11. Reproducible reporting template

| Category | Fields to report |
| --- | --- |
| Acquisition | FOV, matrix, slices, TE1, TEeff, ETL, TR, PE mode, acceleration, ACS |
| Sequence | repository SHA, Pulseq SHA, scanner profile, interpreter/platform |
| Preprocessing | oversampling removal, whitening, phase correction, echo magnitude correction |
| Coil model | sensitivity method, ESPIRiT settings, coil compression; state GRAPPA coil-basis handling |
| Reconstruction | method and method-specific settings |
| Numerics | precision, CPU/GPU, MATLAB release |
| Evaluation | reference definition, ROI/crop rule, metrics |
| Runtime | warm-up rule, repetitions, timing scope |

## 12. Recommended comparison order

```text
R=1 / acquired-line baseline
→ validate packing and geometry
→ validate phase correction
→ validate PI sampling + ACS
→ run GRAPPA and/or validate sensitivity maps
→ run SENSE
→ run CS when required
→ freeze metrics
→ benchmark runtime and memory
```

See [Scientific validation strategy](/validation/scientific-validation) and [Performance & benchmarking](/validation/performance-benchmarking).
