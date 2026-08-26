# Parameter reference

This page summarizes the main user-facing parameters for the maintained Cartesian 2D TSE entry points. After generation, use the saved `Actual` structure as the record of the resolved protocol.

## Geometry and readout

| Field | Unit | Primary effect |
| --- | --- | --- |
| `fovRO`, `fovPE` | m | field of view |
| `nRO`, `nPE` | samples | in-plane matrix / resolution |
| `roDuration` | s | readout duration and bandwidth |
| `SliceThickness`, `SliceGap` | m | through-plane geometry |
| `nSlice` | count | slice coverage |

Nominal in-plane resolution is `fovRO/nRO` by `fovPE/nPE`.

## TSE timing

| Field | Unit | Primary effect |
| --- | --- | --- |
| `nEcho` | count | echo-train length / turbo factor |
| `TE1` | s | first echo time |
| `TEeff` | s | echo intended for physical `ky=0` |
| `TR` | s | repetition time |
| `rflip` | degree | refocusing flip angle |

For TSE, `TEeff` is coupled to the PE ordering because the echo assigned to central k-space determines the effective contrast weighting. See [TSE Echo Train](/theory/tse-echo-train).

## Phase encoding and acceleration

| Field | Meaning |
| --- | --- |
| `PEMode` | `CentricFull`, `CentricHalf`, or `Linear` |
| `AccelerationMode='PI'` | regular PE undersampling with ACS/reference lines |
| `AccelerationMode='CS'` | variable-density PE sampling for offline CS reconstruction |
| `R` | acceleration factor |
| `RefLinesRatio` | PI reference/ACS fraction |
| `p`, `r` | current CS variable-density sampling parameters |

See [Phase Encoding & Acceleration](/theory/phase-encoding) for the implemented PE patterns.

## RF

| Field | Meaning |
| --- | --- |
| `SetupRF.typeEx` | excitation family, including sinc / gSlider paths |
| `SetupRF.typeRef` | refocusing RF family |
| `SetupRF.typeInv` | inversion RF family |
| `SetupRF.tEx/tRef/tInv` | RF durations |
| `SetupRF.tbpEx/tbpRef/tbpInv` | time-bandwidth products |
| `VERSE` | optional VERSE RF/gradient path |

The bundled SLR and gSlider RF pulse banks are generated offline with SigPy and stored as `.mat` files. See [Dependencies & Method Provenance](/reference/provenance).

## gSlider-TSE

`TSE_2D_gSlider.m` uses the gSlider RF encoding path and dedicated gSlider sequence loops. See [gSlider-TSE](/guide/gslider-traps).

`Setup.TRAPS` exists only for an **experimental/test variable-refocusing path** based on `utils/fliptraps.m`; it should not be interpreted as a core gSlider-TSE feature.

## Spoilers

| Field | Meaning |
| --- | --- |
| spoiler `Cycles` | desired dephasing cycles |
| spoiler `Reference` | reference dimension such as `Slice`, `RO`, `PE`, `3D`, or `Slab` |

Spoiler area scales as `Cycles/referenceLength`, after which the waveform must satisfy the configured gradient amplitude and slew limits.

## Platform-dependent settings

The current source still contains scanner/profile and metadata settings from the Siemens 7 T development environment. These are implementation details rather than universal TSE parameters. See [Platform Integration](/platform-integration) and [TO DO](/todo).

## After changing parameters

Regenerate the sequence, inspect the resolved `Actual` values and sequence/k-space plots, and confirm timing/labels. Scanner-side RF/SAR, gradient/PNS, interpreter, and phantom checks remain required before in-vivo use.
