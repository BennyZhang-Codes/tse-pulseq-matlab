# Sequence generation

The maintained sequence entry points are `TSE_2D.m` and `TSE_2D_gSlider.m`. Both use the same modular preparation pipeline and differ mainly in excitation/refocusing behavior and the gSlider-specific sequence loop.

## Configuration structures

The entry scripts expose three user-facing structures:

- `Setup` — scanner, geometry, timing, acceleration, slice ordering and sequence behavior;
- `SetupRF` — excitation/refocusing/inversion RF type, duration, TBP and phase;
- `SetupSpoiling` — crusher/spoiler dephasing cycles, reference length and selected waveform constraints.

`Setup` is copied to `Actual` before preparation. Derived scanner, timing, slice, PE, RF and export metadata are then added to `Actual`. For reproducibility, save and report the resolved `Actual` structure associated with the generated `.seq` file.

## Preparation pipeline

The current sequence flow is:

```text
Setup / SetupRF / SetupSpoiling
          |
          v
        Actual
          |
          +--> prep_System
          +--> prep_SlicePositions
          +--> prep_PE3DOrder
          +--> prep_Excitation / prep_Refocusing / prep_Inversion
          +--> prep_SpoilingArea
          +--> prep_Gradient_GR / prep_Gradient_Block
          +--> prep_Label
          +--> prep_Delay
          +--> prep_NoiseScan
          |
          v
   prep_Seqloop* / prep_Seqloop_IR*
          |
          v
 check_Timing / check_Label / check_PNS
          |
          v
     prep_Definition
          |
          v
 .seq + saved Setup/Actual + plots
```

## Scanner configuration

`Setup.ScannerType` currently supports:

```matlab
'Terra-XJ'
'Terra-XR'
```

`prep_System` selects absolute scanner limits and the expected Siemens `.asc` PNS model. User-configurable soft limits such as:

```matlab
Setup.MaxGrad_soft = 40;
Setup.MaxSlew_soft = 150;
```

are used during waveform design and can be kept below the hardware maximum to provide margin.

## Geometry

Typical geometry fields are:

```matlab
Setup.fovRO
Setup.fovPE
Setup.nRO
Setup.nPE
Setup.nSlice
Setup.SliceThickness
Setup.SliceGap
```

The nominal in-plane voxel dimensions are `fovRO/nRO` and `fovPE/nPE`. The sequence exports FOV, matrix size, slice thickness, gap and slice-position metadata for interpreter/reconstruction use.

## TSE timing

Core timing controls include:

```matlab
Setup.nEcho
Setup.TE1
Setup.TEeff
Setup.TR
Setup.roDuration
```

The scripts rasterize RF/ADC/gradient-related timing before building the echo train. `TEeff` is used to align the selected echo with the k-space center through PE ordering.

Changing RF durations, readout duration, echo spacing, turbo factor, inversion timing, crusher strength or spoiler duration can make the requested TE/TR infeasible. Re-run timing validation after every material protocol change.

## PE ordering

Supported `PEMode` values include:

```text
CentricFull
CentricHalf
Linear
```

The echo associated with physical `ky = 0` is shifted so that the requested effective TE is aligned with k-space center when possible.

PE ordering changes more than acquisition order: in TSE it changes how the echo envelope is mapped across k-space and can therefore affect contrast modulation, PSF, ringing, motion sensitivity and phase sensitivity.

See [Phase encoding and Siemens ICE metadata](phase-encoding-and-ice.md) for acceleration-specific label conventions.

## Parallel imaging and compressed sensing

Acceleration is selected with:

```matlab
Setup.AccelerationMode = 'PI';  % or 'CS'
Setup.R = 2;
```

PI and CS are intentionally treated as different acquisition modes:

- PI uses a regular accelerated imaging lattice plus an ACS region and Siemens-compatible zero-based LIN metadata;
- CS uses its own sampling/order representation and is intended for offline iterative reconstruction, not online ICE GRAPPA.

Do not apply PI LIN assumptions to CS acquisitions.

## Multi-slice ordering

Two independent concepts are configured:

```matlab
Setup.MultiSliceMode = 'Interleaved'; % or 'Sequential'
Setup.MultiSliceDir  = 'Descending';  % or 'Ascending'
```

`MultiSliceMode` controls acquisition order. `MultiSliceDir` controls the physical direction assigned to slice positions.

Pulseq `SLC` labels remain acquisition ordinals. Physical slice labels/positions are exported separately for interpreter-side remapping. The anatomical interpretation must be confirmed on the target scanner because it also depends on patient position, axis mapping and gradient polarity.

## Axis mapping and orientation

The current maintained examples are non-oblique:

```matlab
Setup.AxisRO = 'x';
Setup.AxisPE = 'y';
Setup.Axis3D = 'z';
```

Physical gradient polarity is controlled through:

```matlab
Setup.SignCorr.x
Setup.SignCorr.y
Setup.SignCorr.z
```

The exported rotation matrix is currently identity, so the interpreter and reconstruction must agree with the configured logical-to-physical axis mapping and signs.

## RF configuration

`SetupRF` selects pulse type, duration, time-bandwidth product and phase. For example, conventional TSE currently uses a sinc excitation and SLR refocusing pulse, while gSlider uses a gSlider excitation with a larger excitation TBP.

The sequence generator can validate timing and waveform constraints, but it cannot establish scanner RF safety. Review peak B1, pulse fidelity and SAR separately.

## gSlider and TRAPS

`TSE_2D_gSlider.m` supports:

```matlab
Setup.TRAPS = 'on';
SetupRF.typeEx = 'gSlider';
```

When TRAPS is enabled, a variable refocusing flip-angle schedule is generated relative to the echo aligned with k-space center.

The repository currently supports gSlider sequence generation but not offline gSlider decoding.

## Crushers and spoilers

Crusher/spoiler strength is specified as dephasing cycles divided by a physical reference length, rather than as hard-coded gradient area. Supported references include:

```text
Slice
RO
PE
3D
Slab
```

For example:

```matlab
SetupSpoiling.RefocusingCrusher.Cycles = 4;
SetupSpoiling.RefocusingCrusher.Reference = 'Slice';
```

The resulting area is:

```text
area = Cycles / referenceLength
```

This makes spoiler strength scale naturally when resolution or slice/slab thickness changes.

The custom gradient solvers treat continuous analytical solutions as seeds only; accepted waveforms are solved and validated on the integer gradient raster against area, duration, endpoints, gradient amplitude and slew limits.

## Exported outputs

After validation, `prep_Definition` writes sequence definitions and constructs a descriptive sequence name. The script saves:

```text
seq/<sequence-name>.seq
seq/<sequence-name>.mat
```

The MAT file contains both `Setup` and `Actual`.

Keep these files together for reproducibility. The `.seq` file alone does not preserve all context about the software revision, submodule SHAs, scanner protocol or reconstruction settings.
