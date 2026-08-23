# TSE Pulseq for MATLAB

MATLAB tools for designing Siemens-targeted, Cartesian 2D turbo spin echo
(TSE) Pulseq sequences. The repository provides conventional and gSlider
sequence generators, configurable phase-encoding order and acceleration,
optional inversion recovery, raster-constrained gradient design, sequence
validation helpers, and a modular offline reconstruction path for conventional
2D TSE Twix data.

> This is research code. Pulseq timing and PNS checks are development aids and
> do not replace scanner-side safety checks, protocol validation, or local
> approval before scanning volunteers or patients.

## Main workflows

| Entry point | Purpose |
| --- | --- |
| [`TSE_2D.m`](TSE_2D.m) | Conventional 2D multi-slice TSE generator. |
| [`TSE_2D_gSlider.m`](TSE_2D_gSlider.m) | 2D TSE generator with gSlider excitation and optional TRAPS refocusing-flip schedules. |
| [`recon/matlab/run_recon_TSE2D.m`](recon/matlab/run_recon_TSE2D.m) | Editable offline reconstruction script for conventional Cartesian 2D TSE Twix data. |
| [`recon/matlab/recon_TSE2D.m`](recon/matlab/recon_TSE2D.m) | Programmatic offline reconstruction entry point. |

The sequence generators share the preparation modules in `prep/`. The offline
reconstruction currently does **not** implement gSlider decoding.

## Repository layout

```text
prep/       System, RF, gradient, PE-ordering, label, and sequence-loop preparation
check/      Timing, label, and peripheral nerve stimulation (PNS) checks
plot/       Sequence, k-space, phase-encoding, and gradient visualization
utils/      Rasterized gradient solvers and general sequence utilities
VERSE/      VERSE and minimum-SAR RF utilities
recon/matlab/  Modular Siemens Twix reconstruction for conventional 2D TSE
pulseq/     Bundled Pulseq MATLAB submodule (currently v1.5.1)
seq/        Generated .seq and parameter files; not tracked by Git
```

## Requirements

### Sequence generation

- MATLAB with plotting support.
- The bundled `pulseq/` submodule. After a fresh clone, initialize it with:

  ```bash
  git submodule update --init --recursive
  ```

- A Siemens gradient hardware model (`.asc`) on the MATLAB path when running
  `check_PNS`:
  - `Terra-XJ`: `MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc`
  - `Terra-XR`: `MP_GPA_K2298_2250V_793A_SC72CD_EGA.asc`
- A compatible Siemens Pulseq interpreter for scanner execution. Online ICE
  reconstruction additionally requires matching interpreter and scanner
  protocol settings.

### Offline reconstruction

- [`mapVBVD`](https://github.com/pehses/mapVBVD) on the MATLAB path for reading
  Siemens Twix data.
- A noise scan is recommended for receive-coil prewhitening. If no usable noise
  stream is present, the reconstruction warns and uses an identity transform.

## Generate a sequence

1. Open MATLAB and set the current folder to the repository root.
2. Edit the `Setup`, `SetupRF`, and `SetupSpoiling` sections near the top of the
   selected entry-point script.
3. Run one of:

   ```matlab
   run('TSE_2D.m')
   % or
   run('TSE_2D_gSlider.m')
   ```

4. Review the timing, label, PNS, sequence, and k-space output.
5. Find the generated `.seq` file and saved `Setup`/`Actual` structures under
   `seq/`.

If a compatible `.asc` model is unavailable, `check_PNS(seq, Actual)` can be
disabled for development, but PNS must still be assessed before scanner use.

## Main sequence configuration

The entry scripts copy `Setup` into `Actual`; preparation functions then add
derived timing, sampling, scanner, slice, and phase-encoding information.

| Setting | Purpose |
| --- | --- |
| `ScannerType` | Selects `Terra-XJ` or `Terra-XR` hardware limits and PNS model. |
| `MaxGrad_soft`, `MaxSlew_soft` | Soft gradient-amplitude and slew-rate limits used during waveform design. |
| `NoiseScan` | Enables the noise acquisition used by offline prewhitening. |
| `PhaseCorrection` | Enables TSE navigator acquisitions and exports the phase-correction definition. |
| `IR`, `IRMode`, `TI` | Enables inversion recovery and selects interleaved or sequential IR timing. |
| `PEMode` | Selects `CentricFull`, `CentricHalf`, or `Linear` echo-train ordering. |
| `AccelerationMode`, `R` | Selects parallel imaging (`PI`) or compressed sensing (`CS`) and the acceleration factor. |
| `RefLinesRatio` | Requests the PI reference region; its final width is adjusted to fill complete echo trains. |
| `nEcho`, `TE1`, `TEeff`, `TR` | Controls turbo factor and principal echo-train timing. |
| `MultiSliceMode` | Selects `Interleaved` or `Sequential` slice acquisition. |
| `MultiSliceDir` | Selects `Ascending` (F-to-H) or `Descending` (H-to-F) slice positions. |
| `AxisRO`, `AxisPE`, `Axis3D` | Maps logical readout, phase-encode, and slice-select axes to physical `x`, `y`, and `z`. |
| `SignCorr` | Sets the sign of each physical gradient axis for the target interpreter and reconstruction orientation. |
| `SetupRF` | Controls RF type, duration, time-bandwidth product, phase, and flip angles. |

`TSE_2D_gSlider.m` additionally exposes the gSlider encoding parameters and
`TRAPS` refocusing-flip schedule.

## Crusher and spoiler configuration

Crusher and spoiler areas are centralized in `SetupSpoiling` instead of being
embedded as fixed gradient areas. Each event specifies a dephasing cycle count
and a reference length:

```matlab
SetupSpoiling.RefocusingCrusher.Cycles = 4;
SetupSpoiling.RefocusingCrusher.Reference = 'Slice';

SetupSpoiling.ReadoutCrusher.Cycles = 1;
SetupSpoiling.ReadoutCrusher.Reference = 'RO';
```

Supported references are `Slice`, `RO`, `PE`, `3D`, and `Slab`. The physical
area is calculated as `Cycles / referenceLength`. The pre-excitation spoiler
and end spoiler also expose reduced slew limits; the end spoiler has an
explicit duration. This keeps spoiling strength tied to spatial resolution or
slice/slab thickness while allowing duration and eddy-current trade-offs to be
tuned separately.

The custom gradient utilities provide both fixed-duration and minimum-time
waveform design. A continuous analytical solution is used as a fast seed, but
the accepted waveform is solved and validated on the integer gradient raster
against its requested area, endpoint amplitudes, gradient limit, and slew-rate
limit. If the local seeded search fails, an interval-based complete raster
fallback is used.

## Phase encoding and Siemens ICE metadata

For accelerated PI acquisitions (`R > 1`), the phase-encoding labels follow the
zero-based Siemens Cartesian LIN convention. For an even encoded matrix,
physical `ky = 0` maps to `LIN = nPE/2`; for example, `nPE = 300` uses signed
logical ky `[-150, 149]` and center `LIN = 150`. The same convention is used for
`R = 2`, `R = 3`, `R = 4`, and other supported integer PI factors.

The sequence exports the full encoded matrix size, center LIN, first imaging
line, first ACS line, total ACS width, and PE acceleration factor. The ACS width
includes both reference-only and reference-plus-image lines. The Siemens iPAT
protocol must still be set manually to the same total ACS width.

Fully sampled (`R = 1`) and CS sampling retain their separate legacy label
mapping. CS definitions are not intended to drive online ICE GRAPPA, and the
offline MATLAB workflow does not implement CS reconstruction.

When phase correction is enabled, the sequence exports:

- `TurboFactor = nEcho`;
- `PhaseCorrection = 'on'`; and
- one navigator acquisition for each echo during the phase-correction pre-scan.

A compatible Siemens interpreter must use these definitions to advertise the
corresponding number of phase-correction scans and select the desired online
ICE phase-correction algorithm. Writing the definitions alone does not fully
configure ICE.

## Offline conventional 2D TSE reconstruction

Edit the configuration block in `recon/matlab/run_recon_TSE2D.m`, then run:

```matlab
run(fullfile('recon', 'matlab', 'run_recon_TSE2D.m'))
```

Or call the workflow directly:

```matlab
addpath(fullfile('recon', 'matlab'));

result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'Prewhiten', true, ...
    'PhaseCorrection', true, ...
    'GRAPPA', true, ...
    'OutputDir', outputDir);

imageTSE = result.images.reconstructed;
```

The processing order is:

1. Read image, reference, navigator, and noise streams with mapVBVD.
2. Estimate a regularized complex noise covariance and apply its inverse square
   root to every raw-data stream.
3. Estimate per-slice, per-echo, per-coil constant and readout-linear phase from
   the navigators and apply it to image and PAT reference data.
4. Pack acquisitions by MDH `LIN`, averaging repeated acquisitions without
   double-weighting shared image/reference lines.
5. Reconstruct fully sampled data by centered IFFT and RSS, or synthesize
   missing PE lines with diagnostic 1D PE-GRAPPA for integer `R >= 2`.
6. Save MAT, PNG, CSV, and text diagnostics when an output directory is given.

The workflow is intended for sequence debugging and controlled A/B tests. It
does not claim pixel-for-pixel equivalence with Siemens ICE, whose raw-data
scaling, coil compression/combination, GRAPPA kernels, filtering, and intensity
normalization may differ. See [`recon/matlab/README.md`](recon/matlab/README.md) for
options, output fields, algorithm details, and limitations.

## Generated sequence metadata

`prep/prep_Definition.m` writes definitions used by the Siemens interpreter and
reconstruction, including:

- FOV, matrix size, slice thickness/gap, slice positions, and slice direction;
- TR, effective TE, bandwidth, repetition count, and turbo factor;
- PE ordering and acceleration mode;
- full encoded PE matrix, center line, PI lattice, and ACS information; and
- noise/phase-correction-related acquisition metadata.

The exported rotation matrix is the identity. Physical axis polarity is applied
through the configured gradient signs, so `Axis*` and `SignCorr` must agree with
the target interpreter and intended image orientation.

## Validation

Both maintained sequence entry points run:

- `check_Timing`, which invokes Pulseq block-timing validation;
- `check_Label`, which inspects acquisition labels;
- `check_PNS`, using the selected scanner hardware model; and
- sequence/k-space plotting for visual inspection.

The optional `seq.testReport` call remains commented out in the entry scripts
and can be enabled for additional trajectory, gradient, slew-rate, TE, and TR
diagnostics.

## Current scope and limitations

- Sequence orientation is non-oblique.
- Online ICE behavior depends on the installed Pulseq interpreter and matching
  scanner protocol configuration.
- PI and CS use separate phase-label conventions; do not apply PI LIN
  assumptions to CS data.
- The offline reconstruction supports Cartesian conventional 2D TSE only. It
  excludes gSlider decoding, partial Fourier, simultaneous multi-slice,
  non-Cartesian trajectories, CS reconstruction, and sensitivity-map coil
  combination.
- PE ordering changes TSE point-spread function, contrast modulation, ringing,
  and motion/phase sensitivity even when sequence timing is valid; ordering
  should therefore be chosen and validated for the intended contrast and
  anatomy.

## Citation

If you use `TSE_2D_gSlider.m`, please cite:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution
> isotropic T2-weighted imaging with high contrast and high SNR. In:
> *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*,
> Singapore, Singapore. Program #3256.
