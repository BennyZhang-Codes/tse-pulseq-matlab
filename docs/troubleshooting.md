# Troubleshooting

This page groups common failures by layer. Diagnose the **acquisition, platform integration, reconstruction, and post-processing** stages separately rather than changing several parts of the pipeline at once.

## Pulseq or VERSE functions are missing

Check that the repository was cloned with submodules:

```bash
git submodule status
git submodule update --init --recursive
```

From MATLAB, confirm that Pulseq resolves:

```matlab
which mr.Sequence
```

The maintained sequence scripts add the repository modules to the MATLAB path themselves when run from the repository root.

## `check_Timing` fails

A timing failure usually means the requested TE/TR is incompatible with the rasterized RF, readout, crusher, spoiler, or delay requirements.

Check recent changes to:

- RF duration or TBP;
- `TE1`, `TEeff`, or `TR`;
- readout duration;
- crusher/spoiler cycles or fixed spoiler duration;
- inversion-recovery timing;
- gradient amplitude/slew limits.

Do not bypass `check_Timing`. Resolve the actual event duration or requested protocol instead.

## Gradient design reports infeasibility

The custom gradient utilities validate exact area, rasterized duration, endpoints, gradient amplitude, and slew rate. A continuous-time solution can become infeasible after rasterization.

If a waveform fails:

1. verify units and target area;
2. inspect endpoint amplitudes inherited from neighboring blocks;
3. allow a longer duration or lower target area;
4. confirm that `MaxGrad_soft` and `MaxSlew_soft` are appropriate for the target system;
5. avoid replacing the raster-aware solver with simple analytical rounding.

## PNS model is missing or `check_PNS` cannot run

The current development PNS path expects the Siemens `.asc` model associated with the selected Terra scanner profile. Ensure the required model is available on the MATLAB path.

For another scanner model or vendor, do **not** reuse a Terra model as a placeholder. Add the appropriate platform-specific PNS/safety strategy and repeat scanner validation.

## RF peak or SAR concerns

A successful Pulseq timing check does not establish RF safety. High-TBP gSlider excitation and long/refocused TSE trains can be demanding at 7 T.

Review peak B1, RF duration, refocusing schedule, predicted/ scanner-reported SAR, and the target scanner's RF supervision. If the scanner rejects the sequence, do not defeat the safety limit in software.

## Wrong phase-encoding center or accelerated reconstruction failure

For accelerated PI, verify the complete contract rather than only `R`:

- logical $k_y$ center and echo assignment;
- full encoded `nPE`;
- regular accelerated imaging lattice;
- ACS start and width;
- exported Siemens LIN mapping for the current 7 T path;
- Siemens iPAT acceleration and reference-line settings;
- mapVBVD one-based versus exported zero-based line indices.

See [Phase encoding & effective TE](/theory/phase-encoding) and [Siemens 7 T LIN & ICE](/phase-encoding-and-ice).

## Phase correction appears ineffective

Confirm that phase-correction navigators are actually present and that `SEG`, `SLC`, and related counters identify echoes and slices as expected.

The offline phase model estimates a constant and readout-linear term. Artifacts outside that model may remain. Also remember that enabling `PhaseCorrection` in sequence metadata is not by itself sufficient for Siemens online ICE correction; the compatible interpreter and scanner protocol must consume the relevant metadata.

## Echo-magnitude correction makes the image noisy

Inverse equalization necessarily amplifies noise when late echoes have weak magnitude. Inspect the estimated $A_e$, selected regularization, and gain curve.

Prefer the regularized Wiener-style mode for routine experiments when full inverse-envelope weighting is unstable, and evaluate corrected images against uncorrected data with matched windowing. See [Echo Corrections](/guide/echo-corrections).

## No usable noise stream is available

The reconstruction warns and uses an identity coil transform when receive-noise data cannot be used. This means prewhitening did not occur.

Do not suppress the warning if quantitative comparisons depend on a consistent noise basis. Check whether the raw acquisition contains the expected noise data and whether the reader identifies that stream correctly.

## ESPIRiT/SENSE/CS stops before reconstruction

Common causes are:

- insufficient contiguous ACS data;
- an invalid calibration region;
- inconsistent k-space/sensitivity dimensions;
- failed forward/adjoint inner-product test;
- an unsupported or empty sampling mask.

The forward/adjoint mismatch threshold is a safeguard. Do not disable it to make a dataset run; first determine whether the operator definitions or data geometry are inconsistent.

## CS looks over-smoothed or unstable

The example TV and Haar weights are starting values, not universal parameters. Retune them when resolution, contrast, acceleration, coil configuration, sampling mask, or calibration changes.

Keep the encoding model fixed while sweeping regularization. Compare data residual, image structure, and a reference acquisition when available.

## gSlider raw data do not reconstruct correctly

The bundled MATLAB reconstruction does **not** currently implement gSlider decoding. `recon_TSE2D` is for conventional Cartesian 2D TSE.

Use [gSlider-TSE & TRAPS](/guide/gslider-traps) for the current sequence scope and do not interpret a conventional reconstruction as a decoded gSlider volume.

## Slice order or image orientation is wrong

The maintained sequence is non-oblique and relies on logical axis mapping, `SignCorr`, slice acquisition order, exported physical slice metadata, interpreter behavior, and reconstruction geometry.

Use an asymmetric phantom and verify:

- RO/PE polarity;
- physical slice direction;
- acquisition order versus anatomical order;
- interpreter remapping of `SLC` ordinals;
- NIfTI affine orientation for offline output.

Do not infer anatomy from variable names alone.

## Documentation build fails

Install the pinned documentation dependencies from the repository root:

```bash
npm install
npm run docs:build
```

The site uses VitePress, MathJax, and Mermaid. If a formula or diagram fails, first isolate the affected Markdown page and check its math delimiters or Mermaid syntax rather than disabling the global renderer.

## Still unsure which layer is failing?

Start from the smallest validated baseline:

1. generate a fully sampled conventional `R=1` TSE sequence;
2. confirm timing, labels, and appropriate development hardware checks;
3. validate geometry/orientation on a phantom;
4. reconstruct without optional echo-magnitude correction or denoising;
5. add PI, phase correction, iterative reconstruction, gSlider, or post-processing one feature at a time.

This keeps acquisition, metadata, reconstruction, and post-processing failures distinguishable.
