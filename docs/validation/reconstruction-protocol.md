# Reconstruction protocol

A reconstruction comparison is only interpretable when the acquisition model, preprocessing, calibration, solver, and evaluation rules are frozen in advance. This page defines a reproducible protocol for comparing RSS, regular Cartesian 1D PE-GRAPPA, ESPIRiT-SENSE, Cartesian CS, and optional echo-correction variants in this repository.

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

If echo-magnitude correction is the variable under study, keep every other preprocessing choice fixed and report

- method (`power` or `wiener`);
- `EchoMagnitudeAlpha`;
- regularization mode/value;
- maximum-gain target; and
- resulting maximum noise-standard-deviation gain.

Prewhitening should be applied before navigator estimation so that all compared correction models operate in the same receive-noise basis.

## 4. Freeze k-space packing and sampling

All methods must use the same acquired Cartesian samples after preprocessing.

The protocol should record:

- acquired LIN set;
- repeated-line averaging rule;
- ACS/reference lines;
- whether imaging and refscan views overlap physically;
- final binary sampling mask $P$;
- any excluded corrupt acquisitions and the rule used to identify them.

Do not let one algorithm receive additional central lines, a different ACS width, or a different slice subset unless that difference is the explicit experimental variable.

## 5. Freeze coil processing

For iterative reconstruction, record the sensitivity and compression state.

Typical starting configuration:

```matlab
'SensitivityMethod', 'espirit'
'ESPIRiTKernelSize', [6 6]
'ESPIRiTSubspaceThreshold', 0.02
'ESPIRiTEigenvalueCrop', 0.95
'CoilCompressionEnergy', 0.99
'MaximumVirtualCoils', 12
```

If coil compression is enabled, use the same compressed coil basis for all iterative methods intended to share that basis. If RSS is retained as an uncompressed baseline, state that explicitly rather than calling the methods identical except for the solver.

GRAPPA currently operates on the packed multichannel k-space supplied to `recon_TSE2D_GRAPPA` and is not routed through the SENSE/CS PCA/ESPIRiT preparation step. Therefore a comparison between GRAPPA and compressed SENSE/CS must report that difference explicitly rather than implying identical coil preprocessing.

## 6. Freeze the forward model

For SENSE and CS, the common Cartesian encoding model is

$$
A=PFS,
$$

with the same sampling mask $P$, centered unitary Fourier operator $F$, and sensitivity multiplication $S$.

Before iterative reconstruction, the forward/adjoint identity check must pass under the same numerical tolerance. A failed adjoint check invalidates the benchmark; it should not be bypassed to obtain runtime numbers.

GRAPPA is a k-space interpolation method and therefore does not use this $PFS$ iterative operator. Its comparison conditions are frozen separately below.

## 7. Freeze solver and reconstruction settings

### SENSE

Record at least:

```matlab
'SENSEIterations', 50
'SENSETolerance', 1e-5
'SENSETikhonov', 1e-4
```

### Cartesian CS

Record at least:

```matlab
'CSIterations', 250
'CSTVWeight', 0.006
'CSWaveletWeight', 0.0005
'CSWaveletLevels', 2
```

If regularization is tuned separately for each dataset, specify the tuning rule. Do not describe a parameter as “fixed” if it was selected after inspecting the target result.

### Regular Cartesian 1D PE-GRAPPA

Record at least:

```matlab
'GrappaKySourceCount', 4
'GrappaKxKernel', 0
'GrappaRegularization', 1e-4
```

Also record:

- PE acceleration factor $R$;
- exact acquired imaging lattice;
- contiguous ACS location and width;
- source-line offsets used by each fitted kernel when relevant;
- calibration NMSE and conditioning returned by the implementation; and
- confirmation that acquired image/ACS rows are preserved and only missing rows are synthesized.

The current implementation supports regular integer Cartesian acceleration along PE. It does not implement partial-Fourier GRAPPA, SMS/slice-GRAPPA, non-Cartesian GRAPPA, irregular variable-density/CS masks, or proprietary Siemens ICE kernel/scaling/filtering behavior. See [Reconstruction](/reconstruction#current-grappa-limitations).

These are support boundaries of the implemented method, not reasons to treat it as a separate “diagnostic” form of GRAPPA.

## 8. Freeze precision and hardware

Record:

- MATLAB release;
- CPU model;
- GPU model and driver/runtime information when used;
- `IterativeUseGPU` setting;
- numerical precision of data/operators;
- thread/environment settings that materially affect timing;
- first-run/warm-up policy.

If GPU and CPU results are compared numerically, report the tolerance used for acceptable floating-point differences.

## 9. Freeze stopping and failure rules

A fair comparison requires a predefined failure policy.

Examples:

- adjoint mismatch above the configured threshold → iterative reconstruction invalid;
- insufficient ACS for ESPIRiT → SENSE/CS not run;
- insufficient or underdetermined ACS calibration for GRAPPA → GRAPPA not run;
- non-finite output → invalid;
- maximum iteration reached → report as such rather than silently extending one method;
- failed geometry validation → do not export/report NIfTI as spatially valid.

## 10. Freeze evaluation metrics

Primary operator/reconstruction comparisons should use raw complex values where available.

Recommended metrics:

$$
\mathrm{NRMSE}_{\mathbb C}
=
\frac{\lVert x-x_{\mathrm{ref}}\rVert_2}
{\lVert x_{\mathrm{ref}}\rVert_2},
$$

plus magnitude NRMSE and SSIM as secondary image-domain measures.

For echo correction, additionally report navigator residual phase, normalized echo envelope, maximum gain, and a noise-amplification measure. For geometry-sensitive experiments, report slice-center/orientation consistency separately from image intensity metrics.

For GRAPPA, kernel calibration NMSE is a useful calibration-quality measure but is **not** a substitute for image-domain fidelity against a frozen reference.

## 11. Reproducible reporting template

A compact methods table should include:

| Category | Fields to report |
| --- | --- |
| Acquisition | FOV, matrix, slices, TE1, TEeff, ETL, TR, PE mode, acceleration, ACS |
| Sequence | repository SHA, Pulseq SHA, scanner profile, interpreter/platform |
| Preprocessing | oversampling removal, whitening, phase correction, echo magnitude correction |
| Coil model | sensitivity method, ESPIRiT settings, coil compression; state if GRAPPA uses the original coil basis |
| Reconstruction | method, GRAPPA kernel settings or iterative solver settings, regularization |
| Numerics | precision, CPU/GPU, MATLAB release |
| Evaluation | reference definition, ROI/crop rule, metrics |
| Runtime | warm-up rule, number of repetitions, timing scope |

## 12. Recommended comparison order

For a new dataset, use the following progression:

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

This avoids optimizing a reconstruction around a pipeline whose data layout or physical interpretation has not yet been validated.

See [Scientific validation strategy](/validation/scientific-validation) for the evidence hierarchy and [Performance & benchmarking](/validation/performance-benchmarking) for runtime/memory reporting.
