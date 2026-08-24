# Sequence generation

The maintained entry points are `TSE_2D.m` and `TSE_2D_gSlider.m`. Both build a Cartesian 2D TSE acquisition through the same modular preparation pipeline and differ mainly in excitation/refocusing behavior and the gSlider-specific sequence loop.

This page focuses on the **sequence core**: geometry, timing, RF, phase encoding, acceleration and slice ordering. Scanner presets, hardware limits and interpreter metadata are integration details and are kept near the end of the page; see [Platform Integration](platform-integration.md) for the full portability boundary.

## Configuration structures

The entry scripts expose three user-facing structures:

- `Setup` — system profile selection, geometry, timing, acceleration, slice ordering and sequence behavior;
- `SetupRF` — excitation/refocusing/inversion RF type, duration, TBP and phase;
- `SetupSpoiling` — crusher/spoiler dephasing cycles, reference length and selected waveform constraints.

`Setup` is copied to `Actual` before preparation. Derived system, timing, slice, PE, RF and export metadata are then added to `Actual`. For reproducibility, save the resolved `Actual` structure together with the generated `.seq` file.

## Preparation pipeline

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
 check_Timing / check_Label / available check_PNS
          |
          v
     prep_Definition
          |
          v
 .seq + saved Setup/Actual + plots
```

The preparation functions resolve user intent into raster-compatible RF, gradient, ADC, timing and metadata objects before the final sequence loop is assembled.

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

The nominal in-plane voxel dimensions are `fovRO/nRO` and `fovPE/nPE`. Geometry also affects readout/phase-encoding gradient areas, slice selection and spoiler reference lengths.

## TSE timing

Core timing controls include:

```matlab
Setup.nEcho
Setup.TE1
Setup.TEeff
Setup.TR
Setup.roDuration
```

The scripts rasterize RF-, ADC- and gradient-related timing before building the echo train. `TEeff` is used together with PE ordering to align the selected echo with physical `ky = 0`.

Changing RF duration, readout duration, echo spacing, turbo factor, inversion timing, crusher strength or spoiler duration can make the requested TE/TR infeasible. Re-run timing validation after every material protocol change.

## Phase-encoding order

Supported `PEMode` values include:

```text
CentricFull
CentricHalf
Linear
```

The echo associated with physical `ky = 0` is shifted so that the requested effective TE is aligned with k-space center when possible.

PE ordering changes more than acquisition order: in TSE it controls how the echo envelope is mapped across k-space and therefore affects contrast modulation, PSF, ringing, motion sensitivity and phase sensitivity.

The **logical `ky` order is part of the vendor-neutral acquisition design**. Platform-specific line numbering such as Siemens LIN is applied later by the current integration layer; see [Siemens 7 T encoding and ICE integration](phase-encoding-and-ice.md).

## Parallel imaging and compressed sensing

Acceleration is selected with:

```matlab
Setup.AccelerationMode = 'PI';  % or 'CS'
Setup.R = 2;
```

PI and CS are intentionally treated as different acquisition modes:

- **PI** uses a regular accelerated imaging lattice plus an ACS region;
- **CS** uses its own sampling/order representation and is intended for offline iterative reconstruction.

The sampling pattern and ACS intent belong to the sequence design. A scanner adapter may additionally need to translate them into platform-specific line indices or online-reconstruction metadata.

For the current Siemens 7 T path, accelerated PI is mapped to Siemens-compatible zero-based LIN metadata. Do not apply that mapping to CS acquisitions or to another scanner platform unless its interpreter explicitly requires the same convention.

## Multi-slice ordering

Two independent concepts are configured:

```matlab
Setup.MultiSliceMode = 'Interleaved'; % or 'Sequential'
Setup.MultiSliceDir  = 'Descending';  % or 'Ascending'
```

`MultiSliceMode` controls acquisition order. `MultiSliceDir` controls the physical direction assigned to slice positions.

Pulseq `SLC` labels remain acquisition ordinals. Physical slice labels/positions are exported separately for interpreter-side remapping. Anatomical interpretation must be confirmed on the target scanner because it also depends on patient position, axis mapping, gradient polarity and interpreter behavior.

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

The exported rotation matrix is currently identity. The logical sequence description can remain portable, but every scanner integration must verify how these axes and signs map into the platform's physical/display coordinate conventions.

## RF configuration

`SetupRF` selects pulse type, duration, time-bandwidth product and phase. Conventional TSE currently uses a sinc excitation and SLR refocusing pulse, while gSlider uses a gSlider excitation with a larger excitation TBP.

The sequence generator can validate timing and waveform constraints, but it cannot establish scanner RF safety. Review peak B1, pulse fidelity and SAR separately on the target platform.

## gSlider and TRAPS

`TSE_2D_gSlider.m` supports:

```matlab
Setup.TRAPS = 'on';
SetupRF.typeEx = 'gSlider';
```

When TRAPS is enabled, a variable refocusing flip-angle schedule is generated relative to the echo aligned with k-space center.

The repository currently supports gSlider sequence generation but not offline gSlider decoding.

## Crushers and spoilers

Crusher/spoiler strength is specified as dephasing cycles divided by a physical reference length rather than as a hard-coded gradient area. Supported references include:

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

## Target-system profile

The sequence must ultimately be resolved against the hardware limits of a real scanner. The shipped `Setup.ScannerType` presets currently include:

```matlab
'Terra-XJ'
'Terra-XR'
```

These are **currently implemented Siemens 7 T profiles**, not the vendor scope of the sequence design. `prep_System` uses the selected profile to provide absolute gradient/slew limits and the available PNS development model.

User-configurable soft limits such as:

```matlab
Setup.MaxGrad_soft = 40;
Setup.MaxSlew_soft = 150;
```

can be kept below the scanner maximum to provide design margin.

A new scanner platform requires its own correct system limits, safety/PNS strategy and interpreter integration. Do not reuse a Terra profile as a generic placeholder. See [Platform Integration](platform-integration.md).

## Exported outputs

After validation, `prep_Definition` writes sequence definitions and constructs a descriptive sequence name. The script saves:

```text
seq/<sequence-name>.seq
seq/<sequence-name>.mat
```

The MAT file contains both `Setup` and `Actual`.

Keep these files together for reproducibility. The `.seq` file alone does not preserve all context about the software revision, submodule SHAs, target scanner, interpreter, protocol or reconstruction settings.
