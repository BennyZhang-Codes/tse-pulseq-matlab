# Phase encoding and Siemens ICE metadata

This page documents the repository's phase-encoding conventions and the boundary between Pulseq sequence metadata, Siemens interpreter behavior, online ICE reconstruction and the offline MATLAB reconstruction.

## 1. Logical PE coordinates versus Siemens LIN

The sequence first constructs a signed logical phase-encoding order `PE3DOrder`. For 2D imaging this represents physical `ky` steps around zero.

For parallel imaging (`R > 1` and `AccelerationMode='PI'`), the sequence then maps the logical coordinate to the zero-based Siemens Cartesian LIN convention.

For an even encoded matrix:

```text
centerLIN = nPE / 2
```

For example, with `nPE = 300`:

```text
ky =    0 -> LIN 150
ky = +150 -> LIN   0
ky = -149 -> LIN   1
```

The implementation checks that:

- physical `ky = 0` maps to the expected center LIN;
- regular PI imaging LINs satisfy the acceleration lattice;
- LIN values remain within `[0, nPE-1]`; and
- duplicate PI LIN labels are not generated.

## 2. PI and CS intentionally use different label behavior

Do **not** assume that every acquisition mode uses the same LIN mapping.

The Siemens Cartesian zero-based mapping described above is applied only to accelerated PI acquisitions. Fully sampled (`R = 1`) and CS acquisitions retain their separate existing mappings.

This is intentional because the CS order may contain null/sentinel entries and is not designed to drive online Siemens GRAPPA.

In practical terms:

| Acquisition | Intended reconstruction | LIN convention |
| --- | --- | --- |
| `R=1` | RSS / offline reference | legacy fully sampled mapping |
| PI, `R>1` | Siemens-compatible PI metadata; offline GRAPPA/SENSE also possible | zero-based Siemens Cartesian LIN |
| CS, `R>1` | offline iterative reconstruction | separate CS mapping; do not apply PI assumptions |

## 3. mapVBVD uses one-based indices in MATLAB

A frequent source of confusion is that the exported sequence metadata and Twix objects are not expressed in the same indexing convention.

The sequence definition uses Siemens-style zero-based LIN metadata. After `mapVBVD` reads the Twix file, the reconstruction uses MATLAB/mapVBVD one-based indices for fields such as `Lin`, `Sli` and `Seg`.

Therefore:

```text
Siemens center LIN = mapVBVD center LIN - 1
```

Do not compare raw numerical LIN values across these two contexts without accounting for the index shift.

## 4. PE ordering and effective TE

The sequence supports:

```text
CentricFull
CentricHalf
Linear
```

A prescribed center-echo index is estimated from:

```text
k0prescr = round(TEeff / TE1)
```

with a minimum of echo 1. The PE order is then circularly shifted so that physical `ky = 0` is associated with the requested effective echo as closely as the discrete train allows.

This mapping is important because TSE contrast and point-spread behavior depend on which echo samples which portion of k-space.

## 5. PI ACS region

For PI, the sequence tracks three types of phase-encoding lines:

- regular accelerated imaging lines;
- ACS/reference-only lines;
- ACS lines that are also imaging lines.

The exported ACS width counts the union of the latter two ACS categories.

The sequence writes:

```text
kSpacePhaseEncodingLines
kSpaceCenterLine
AccelerationFactorPE
FirstFourierLine
FirstRefLine
nRefLine
```

`nRefLine` is the total ACS width used for bookkeeping and interpreter/reconstruction coordination.

!!! warning "Siemens protocol must match"
    Exporting `nRefLine` does **not** automatically configure the Siemens iPAT card. The scanner protocol must still be set manually to the same ACS/reference-line width expected by the acquisition and interpreter.

A mismatch can cause failed online GRAPPA, inconsistent calibration, unexpected reference streams or reconstruction artifacts.

## 6. Full encoded matrix size matters

An accelerated acquisition may never sample the numerically last LIN. The sequence therefore explicitly exports the full encoded PE matrix size as `kSpacePhaseEncodingLines` rather than asking the interpreter/reconstruction to infer matrix size from acquired lines alone.

This avoids ambiguous matrix reconstruction for regular undersampling.

## 7. TSE online phase-correction metadata

When phase correction is enabled, the sequence exports:

```text
TurboFactor = nEcho
PhaseCorrection = 'on'
```

and acquires one phase-correction navigator for each TSE echo during the corresponding prescan.

The corrected `TurboFactor` name is important because the target interpreter needs the echo-train length to advertise/configure the correct number of phase-correction scans.

However, writing the sequence definitions alone does **not** enable a complete ICE phase-correction chain.

The compatible Siemens interpreter must consume the metadata and configure the appropriate online TSE phase-correction behavior. Scanner protocol settings must also be compatible.

The offline MATLAB reconstruction implements a transparent constant-plus-readout-linear navigator phase model. It is not a byte-for-byte clone of proprietary ICE phase-correction internals.

## 8. Slice metadata

The sequence exports:

```text
SliceThickness
SliceGap
SlicePositions
SliceLabel
MultiSliceMode
MultiSliceDir
nSlice
```

Pulseq `SLC` labels intentionally remain acquisition ordinals. Physical/anatomical positions are carried separately through `SliceLabel` and `SlicePositions` so that the target interpreter can remap acquisition order to physical slice order.

An interpreter that ignores this remapping may display or reconstruct slices in acquisition order rather than the intended anatomical order.

## 9. Axis mapping and orientation

The current maintained sequence workflow is non-oblique. Logical RO/PE/3D axes are mapped to physical x/y/z axes by `AxisRO`, `AxisPE` and `Axis3D`, while `SignCorr` changes gradient polarity.

The exported rotation matrix is identity. Consequently, sequence settings, interpreter assumptions and reconstruction orientation must agree.

Always validate slice order and image orientation with a phantom or unmistakably asymmetric geometry before relying on anatomical labels.

## 10. Offline reconstruction scope

The offline MATLAB reconstruction reads the Twix header and MDH metadata rather than blindly assuming the sequence-side values.

It supports:

- conventional Cartesian 2D TSE;
- RSS;
- diagnostic 1D PE-GRAPPA;
- ordinary ESPIRiT-SENSE;
- SENSE-based Cartesian CS with TV and Haar-L1 penalties.

It does **not** currently implement:

- gSlider decoding;
- partial Fourier reconstruction;
- SMS;
- non-Cartesian reconstruction;
- proprietary Siemens ICE coil combination or filters.

## 11. Recommended scanner checks for accelerated PI

Before relying on online PI reconstruction, confirm all of the following together:

1. `R` in the Pulseq sequence;
2. `AccelerationFactorPE` seen by the interpreter;
3. full encoded `nPE`;
4. center LIN;
5. regular imaging lattice;
6. ACS start and width;
7. Siemens iPAT protocol acceleration and reference-line settings;
8. phase-correction navigator count when enabled; and
9. reconstructed orientation and slice order.

Treat these fields as one acquisition/reconstruction contract rather than independent metadata values.
