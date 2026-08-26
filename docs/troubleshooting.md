# Troubleshooting

## Pulseq or VERSE functions are missing

Make sure the repository was cloned with submodules:

```bash
git submodule update --init --recursive
```

Then confirm Pulseq is visible in MATLAB:

```matlab
which mr.Sequence
```

Run the maintained sequence scripts from the repository root.

## `check_Timing` fails

The requested TE/TR may be incompatible with the rasterized RF, readout, crusher/spoiler, or gradient limits.

Check recent changes to:

- `TE1`, `TEeff`, or `TR`;
- RF duration / TBP;
- readout duration;
- crusher/spoiler settings;
- inversion timing; and
- gradient amplitude/slew limits.

Resolve the event timing rather than bypassing `check_Timing`.

## `check_PNS` cannot run

The current PNS path requires external `safe_pns_prediction` and a hardware model compatible with the target gradient system. The hardware model is not distributed with this repository.

See [Installation](/installation) and [Validation & Safety](/validation-and-safety).

## PI / GRAPPA reconstruction fails

Check that acquisition and reconstruction agree on:

- acceleration factor `R`;
- full `nPE`;
- regular accelerated PE lattice;
- contiguous ACS/reference lines; and
- logical PE indices / raw-data line mapping.

The current GRAPPA implementation does not handle irregular CS masks. See [Phase Encoding & Acceleration](/theory/phase-encoding) and [Reconstruction](/reconstruction).

## Phase correction appears ineffective

Confirm that phase-correction navigators are present in the raw data and identified with the expected slice/echo counters.

The current offline model fits constant and readout-linear phase terms. Artifacts outside that model may remain. See [Reconstruction](/reconstruction).

## Echo magnitude correction amplifies noise

Echo-envelope equalization can increase noise when later echoes have low signal. Inspect the estimated echo envelope and gain curve, and compare the corrected result with the uncorrected reconstruction.

The correction is optional and disabled by default. See [Optional Echo Correction](/guide/echo-corrections).

## No usable noise scan is available

If no usable receive-noise stream is found, the reconstruction warns and falls back to an identity coil transform, so prewhitening is not applied.

Check that the acquisition contains the expected noise stream and that the reader identifies it correctly.

## ESPIRiT / SENSE / CS stops before reconstruction

Common causes include:

- insufficient ACS data;
- invalid calibration region;
- inconsistent k-space/sensitivity dimensions;
- failed forward/adjoint consistency check; or
- an empty/unsupported sampling mask.

See the method-specific options and limits in [Reconstruction](/reconstruction).

## CS looks over-smoothed or unstable

The example TV/Haar regularization values are starting points, not universal settings. Adjust them for the acquisition, sampling pattern, and desired image characteristics while keeping the underlying data and encoding model fixed during comparisons.

## gSlider raw data do not decode

The bundled MATLAB reconstruction does **not** currently implement gSlider decoding. `recon_TSE2D` is for conventional Cartesian 2D TSE.

See [gSlider-TSE](/guide/gslider-tse).

## Slice order or orientation is wrong

Check:

- `AxisRO`, `AxisPE`, and `Axis3D`;
- `SignCorr`;
- physical slice positions/order;
- interpreter mapping; and
- NIfTI geometry for offline output.

The maintained sequence path is currently non-oblique.

## Documentation build fails

From the repository root:

```bash
npm install
npm run docs:build
```

If one formula or Mermaid diagram fails, check the affected Markdown page and diagram/math syntax first.
