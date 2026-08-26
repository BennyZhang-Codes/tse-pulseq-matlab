# Parameter reference

This page is a development reference for the maintained Cartesian 2D TSE entry points. Values are nominal; after generation, use the saved `Actual` structure as the record of the resolved protocol.

Acquisition parameters describe the Pulseq sequence itself. Target-system hardware limits, interpreter metadata, line counters, safety/PNS inputs, and raw-data formats belong to the **platform integration layer** and should not be assumed to transfer unchanged between scanners. See [Platform Integration](/platform-integration).

## Geometry and readout

| Field | Unit | Primary effect | Check when changing |
| --- | --- | --- | --- |
| `fovRO`, `fovPE` | m | Field of view and aliasing margin | voxel size, gradient area |
| `nRO`, `nPE` | samples | in-plane resolution and scan time | ADC, PE coverage, reconstruction matrix |
| `roDuration` | s | readout bandwidth and distortion/noise trade-off | ADC dwell, TE feasibility |
| `SliceThickness`, `SliceGap` | m | through-plane resolution and cross-talk | slice selection, spoiler reference |
| `nSlice` | count | coverage and TR duty cycle | slice order, RF/SAR duty cycle |

Nominal in-plane resolution is `fovRO/nRO` by `fovPE/nPE`.

## TSE timing and contrast

| Field | Unit | Primary effect | Important coupling |
| --- | --- | --- | --- |
| `nEcho` | count | turbo factor / echo-train length | echo modulation, blurring, SAR |
| `TE1` | s | first echo time | RF duration, readout, crusher timing |
| `TEeff` | s | echo intended for physical `ky=0` | PE ordering and contrast |
| `TR` | s | recovery and scan time | slice count, IR, SAR duty cycle |
| `rflip` / TRAPS | degree | refocusing pathway and SAR | echo envelope, image contrast |

For TSE, `TEeff` does not independently set contrast: PE ordering determines which echo samples central k-space. Verify the resulting order after changing `PEMode`, `nEcho`, `TE1`, or `TEeff`.

## Acceleration

| Field | Meaning | Required validation |
| --- | --- | --- |
| `AccelerationMode='PI'` | regular undersampling plus ACS | verify sampling lattice, ACS layout and target-platform metadata |
| `R` | PI/CS acceleration factor | verify effective acquired-line count and reconstruction compatibility |
| `RefLinesRatio` | fraction of PE lines reserved for PI reference | confirm ACS intent and image coverage |
| `AccelerationMode='CS'` | variable-density offline sampling | verify mask, acquired-line count and offline reconstruction path |
| `PEMode` | `CentricFull`, `CentricHalf`, or `Linear` | inspect echo-to-`ky` mapping and PSF |

The logical `ky` order is part of the acquisition design. Any scanner/interpreter line-index convention should be treated as a platform translation layer rather than as the definition of physical phase encoding.

See [Phase Encoding & Acceleration](/theory/phase-encoding) for the implemented PI/CS patterns.

## RF, VERSE, and spoilers

| Field | Meaning | Required validation |
| --- | --- | --- |
| `SetupRF.tEx/tRef/tInv` | RF durations | TE/TR feasibility and peak B1 |
| `SetupRF.tbpEx/tbpRef/tbpInv` | time-bandwidth products | slice profile and peak B1 |
| `VERSE` | variable-rate RF/gradient path | RF profile, B1, SAR, gradient fidelity |
| spoiler `Cycles` | dephasing cycles | residual coherence versus TE/TR burden |
| spoiler `Reference` | `Slice`, `RO`, `PE`, `3D`, `Slab` | area scaling after geometry changes |

Spoiler area is `Cycles/referenceLength`. The selected waveform must still satisfy gradient amplitude and slew limits on the discrete raster.

## Platform-dependent settings

The current source tree contains scanner/profile fields used by the development environment. Those fields should be understood as current adapter inputs rather than universal TSE parameters.

Planned refactoring includes

- moving hardware profiles out of the reusable sequence core;
- making PNS prediction optional;
- separating logical PE from target-platform line metadata; and
- generalizing orientation support.

See [TO DO & implementation checklist](/todo).

## Minimum change checklist

After changing any protocol parameter:

1. regenerate the sequence and retain `Setup`, `Actual`, `.seq`, and the Git/submodule revisions;
2. inspect timing, labels, PE/echo order, and gradient/trajectory plots;
3. inspect `seq.testReport` when used during development;
4. repeat an appropriate phantom comparison for changes affecting RF, gradients, PE ordering, acceleration, orientation, or reconstruction; and
5. obtain target-scanner RF/SAR/PNS and interpreter checks before in-vivo use.
