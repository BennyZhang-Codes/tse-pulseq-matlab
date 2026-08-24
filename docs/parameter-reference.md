# Parameter reference

This page is a development reference for the maintained Cartesian 2D TSE entry points. Values are nominal; after generation, use the saved `Actual` structure as the record of the resolved protocol.

The acquisition parameters describe the Pulseq sequence itself. Scanner hardware limits, interpreter metadata, Siemens LIN/ICE behavior, and raw-data reconstruction belong to the **platform integration layer** and should not be assumed to transfer unchanged to another vendor. See [Platform Integration](platform-integration.md).

## Geometry and readout

| Field | Unit | Primary effect | Check when changing |
| --- | --- | --- | --- |
| `fovRO`, `fovPE` | m | Field of view and aliasing margin | Voxel size, gradient area |
| `nRO`, `nPE` | samples | In-plane resolution and scan time | ADC, PE coverage, reconstruction matrix |
| `roDuration` | s | Readout bandwidth and distortion/noise trade-off | ADC dwell, TE feasibility |
| `SliceThickness`, `SliceGap` | m | Through-plane resolution and cross-talk | Slice selection, spoiler reference |
| `nSlice` | count | Coverage and TR duty cycle | Slice order, RF/SAR duty cycle |

Nominal in-plane resolution is `fovRO/nRO` by `fovPE/nPE`.

## TSE timing and contrast

| Field | Unit | Primary effect | Important coupling |
| --- | --- | --- | --- |
| `nEcho` | count | Turbo factor / echo-train length | Echo modulation, blurring, SAR |
| `TE1` | s | First echo time | RF duration, readout, crusher timing |
| `TEeff` | s | Echo intended for physical `ky=0` | PE ordering and contrast |
| `TR` | s | Recovery and scan time | Slice count, IR, SAR duty cycle |
| `rflip` / TRAPS | degree | Refocusing pathway and SAR | Echo envelope, image contrast |

For TSE, `TEeff` does not independently set contrast: PE ordering determines which echo samples central k-space. Verify the resulting order after changing `PEMode`, `nEcho`, `TE1`, or `TEeff`.

## Acceleration and platform metadata

| Field | Meaning | Required validation |
| --- | --- | --- |
| `AccelerationMode='PI'` | Regular undersampling plus ACS | Validate the target interpreter's acceleration/calibration mapping; on the current Siemens path, match iPAT R and reference lines |
| `R` | PI/CS acceleration factor | Test sampling lattice and ACS width; on Siemens, also verify LIN mapping |
| `RefLinesRatio` | Fraction of PE lines reserved for PI reference | Confirm ACS intent, exported metadata and image coverage |
| `AccelerationMode='CS'` | Offline irregular sampling | Do not apply PI/ICE LIN assumptions |
| `PEMode` | `CentricFull`, `CentricHalf`, or `Linear` | Inspect echo-to-`ky` mapping and PSF |

The logical `ky` order is part of the acquisition design. The currently validated Siemens 7 T PI path additionally maps that order to zero-based Siemens LIN with `ky=0 → LIN=floor(nPE/2)`; for even `nPE=300`, that is LIN 150. Another interpreter may require a different metadata mapping. See [Siemens 7 T encoding and ICE integration](phase-encoding-and-ice.md).

## RF, VERSE, and spoilers

| Field | Meaning | Required validation |
| --- | --- | --- |
| `SetupRF.tEx/tRef/tInv` | RF durations | TE/TR feasibility and peak B1 |
| `SetupRF.tbpEx/tbpRef/tbpInv` | Time-bandwidth products | Slice profile and peak B1 |
| `VERSE` | Variable-rate RF/gradient path | RF profile, B1, SAR, gradient fidelity |
| Spoiler `Cycles` | Dephasing cycles | Residual coherence versus TE/TR burden |
| Spoiler `Reference` | `Slice`, `RO`, `PE`, `3D`, `Slab` | Area scaling after geometry changes |

Spoiler area is `Cycles/referenceLength`. The selected waveform must still satisfy gradient amplitude and slew limits on the discrete raster.

## Minimum change checklist

After changing any protocol parameter:

1. regenerate the sequence and retain `Setup`, `Actual`, `.seq`, and the Git commit/submodule SHAs;
2. inspect `check_Timing`, labels, and the gradient/trajectory plots;
3. inspect `seq.testReport` during development, especially maximum gradient and slew;
4. repeat staged phantom validation for changes affecting RF, gradients, PE ordering, acceleration, interpreter integration, or reconstruction;
5. obtain target-scanner RF/SAR/PNS and interpreter checks before in-vivo use.
