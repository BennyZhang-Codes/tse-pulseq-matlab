# Parameter reference

This page is a development reference for the maintained Cartesian 2D TSE entry points. Values are nominal; after generation, use the saved `Actual` structure as the record of the resolved protocol.

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

## PI, CS, and Siemens metadata

| Field | Meaning | Required validation |
| --- | --- | --- |
| `AccelerationMode='PI'` | Regular undersampling plus ACS | Match Siemens iPAT R and reference lines |
| `R` | PI/CS acceleration factor | For PI, test LIN lattice and ACS width |
| `RefLinesRatio` | Fraction of PE lines reserved for PI reference | Confirm exported ACS metadata and image coverage |
| `AccelerationMode='CS'` | Offline irregular sampling | Do not use PI/ICE LIN assumptions |
| `PEMode` | `CentricFull`, `CentricHalf`, or `Linear` | Inspect echo-to-ky mapping and PSF |

For PI, the maintained convention is zero-based Siemens LIN with `ky=0 → LIN=floor(nPE/2)`. For even `nPE=300`, that is LIN 150. See [Phase encoding and Siemens ICE](phase-encoding-and-ice.md).

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
4. repeat staged phantom validation for changes affecting RF, gradients, PE ordering, acceleration, or reconstruction;
5. obtain scanner-side RF/SAR/PNS and interpreter checks before in-vivo use.