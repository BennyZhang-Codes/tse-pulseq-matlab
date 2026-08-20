# TSE Pulseq for MATLAB

MATLAB implementations for designing two-dimensional turbo spin echo (TSE) Pulseq sequences. The repository includes conventional and gSlider excitation workflows, configurable phase encoding, optional inversion recovery, and basic timing, label, and peripheral nerve stimulation (PNS) checks.

## Included workflows

| Entry point | Description |
| --- | --- |
| `TSE.m` | Conventional 2D multi-slice TSE sequence generator. |
| `TSE_gSlider.m` | 2D TSE generator using gSlider excitation; supports TRAPS refocusing-flip schedules. |
| `IRTSE.m` | Earlier standalone IR-TSE implementation retained for reference. |
| `IR_TSE_Interleaved.m` | Earlier standalone interleaved IR-TSE implementation retained for reference. |

The actively maintained generators use the shared modules in `prep/` and are configured through `Setup` and `Actual` structures.

## Repository layout

```text
prep/       Sequence preparation: system limits, RF, gradients, PE ordering, and loops
check/      Timing, label, and PNS validation helpers
plot/       k-space, phase-encoding, and gradient plotting helpers
utils/      Gradient-composition and RF flip-angle utilities
VERSE/      VERSE and minimum-SAR RF utilities
pulseq/     Bundled Pulseq MATLAB implementation
```

## Requirements

- MATLAB with plotting support.
- The bundled `pulseq/` directory; no separate Pulseq installation is needed when running the supplied entry points from the repository root.
- A Siemens gradient hardware model (`.asc`) on the MATLAB path for PNS calculation. `prep/prep_System.m` currently supports:
  - `Terra-XJ` — `MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc`
  - `Terra-XR` — `MP_GPA_K2298_2250V_793A_SC72CD_EGA.asc`

## Quick start

1. Open MATLAB and set the current folder to this repository.
2. Edit the `Setup` section near the top of `TSE.m` or `TSE_gSlider.m`.
3. Run one of the scripts:

   ```matlab
   run('TSE.m')
   % or
   run('TSE_gSlider.m')
   ```

4. Review the timing, label, and PNS output in the MATLAB Command Window.
5. Find the generated Pulseq file in `seq/`. Generated sequence files are not tracked by Git.

To skip PNS validation when a compatible `.asc` file is unavailable, comment out the `check_PNS(seq, Actual)` line in the selected entry-point script.

## Configuration

The sequence scripts start with a `Setup` structure and copy it to `Actual` before generating the sequence. `prep_System` adds scanner-specific settings, including the PNS hardware-model filename, to `Actual`.

| Setting | Purpose |
| --- | --- |
| `ScannerType` | Selects the hardware limits and PNS model (`Terra-XJ` or `Terra-XR`). |
| `MaxGrad_soft`, `MaxSlew_soft` | Soft gradient and slew-rate limits used while designing the sequence. |
| `IR`, `IRMode`, `TI` | Enable inversion recovery and choose its timing mode. |
| `PEMode` | Select `CentricFull`, `CentricHalf`, or `Linear` phase-encoding order. |
| `AccelerationMode`, `R` | Select parallel imaging (`PI`) or compressed sensing (`CS`) and the acceleration factor. |
| `MultiSliceMode` | Select `Interleaved` or `Sequential` slice order. |
| `AxisRO`, `AxisPE`, `Axis3D` | Map logical readout, phase-encode, and slice-select axes to physical `x`, `y`, and `z` axes. |
| `SignCorr` | Defines the sign for each physical gradient axis. |
| `paramsRF` | Controls RF pulse types, durations, time-bandwidth products, and phases. |

`TSE_gSlider.m` additionally exposes `TRAPS` and uses `fliptraps` to construct the refocusing flip-angle schedule.

## Generated sequence metadata

`prep/prep_Definition.m` writes sequence definitions needed for reconstruction and export, including FOV, matrix size, TR/TE, slice positions, acceleration settings, reference-line information, echo-train length, and phase-correction status.

## Validation and visualization

Each maintained entry point runs:

- `check_Timing` to call Pulseq's timing validation;
- `check_Label` to inspect acquisition labels;
- `check_PNS` with the scanner-specific hardware model; and
- Pulseq sequence and k-space plotting helpers for visual inspection.

These checks help with development but do not replace scanner-side safety review, protocol validation, or institutional approval before scanning.

## Notes

- Axis mapping is non-oblique. Ensure it matches the mapping expected by the target Siemens interpreter and reconstruction workflow.
- Parameters are expressed in SI units unless otherwise noted (for example, FOV in metres and timing in seconds).
- The legacy standalone IR scripts are kept for comparison; prefer the shared preparation workflow in `TSE.m` and `TSE_gSlider.m` for new development.
