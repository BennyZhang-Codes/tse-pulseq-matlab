# Siemens 7 T encoding and ICE integration

This page is the **platform-specific reference for the repository's currently validated Siemens 7 T path**. It documents how the vendor-neutral logical Pulseq acquisition is mapped into Siemens LIN/ACS metadata, interpreter behavior, online ICE reconstruction, and the current MATLAB Twix reconstruction.

For the general boundary between the reusable sequence core and scanner-specific integration, start with [Platform Integration](platform-integration.md).

## 1. Logical PE coordinates versus Siemens LIN

The sequence first constructs a signed logical phase-encoding order `PE3DOrder`. For 2D imaging this represents physical `ky` steps around zero and belongs to the vendor-independent acquisition description.

For parallel imaging (`R > 1` and `AccelerationMode='PI'`), the current Siemens implementation then maps the logical coordinate to the zero-based Siemens Cartesian LIN convention.

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

The implementation checks that physical `ky = 0` maps to the expected center LIN, regular PI imaging LINs satisfy the acceleration lattice, LIN values remain within `[0,nPE-1]`, and duplicate PI LIN labels are not generated.

## 2. PI and CS intentionally use different metadata behavior

Do **not** assume that every acquisition mode or scanner vendor uses the same line-index mapping.

The Siemens Cartesian zero-based mapping described above is applied only to accelerated PI acquisitions in the current Siemens path. Fully sampled (`R = 1`) and CS acquisitions retain their separate mappings.

This is intentional because the CS order may contain null/sentinel entries and is not designed to drive online Siemens GRAPPA.

| Acquisition | Intended reconstruction | Current metadata behavior |
| --- | --- | --- |
| `R=1` | RSS / offline reference | fully sampled mapping |
| PI, `R>1` | online Siemens PI or offline GRAPPA/SENSE | zero-based Siemens Cartesian LIN in the current implementation |
| CS, `R>1` | offline CS | separate CS mapping; do not apply PI LIN assumptions |

A future non-Siemens adapter should define its own mapping from logical Pulseq encoding coordinates to platform-specific metadata rather than inheriting Siemens LIN semantics by default.

## 3. mapVBVD uses one-based indices in MATLAB

The sequence definition uses Siemens-style zero-based LIN metadata. After `mapVBVD` reads Twix, the reconstruction uses MATLAB/mapVBVD one-based indices for fields such as `Lin`, `Sli`, and `Seg`.

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

A prescribed center-echo index is estimated from

```text
k0prescr = round(TEeff / TE1)
```

with a minimum of echo 1. The PE order is then circularly shifted so that physical `ky = 0` is associated with the requested effective echo as closely as the discrete train allows.

This mapping is part of the sequence design and is independent of Siemens LIN numbering.

## 5. PI ACS region

For PI, the sequence tracks regular accelerated imaging lines, ACS/reference-only lines, and ACS lines that are also imaging lines. The exported ACS width counts the union of the latter two ACS categories.

For the current Siemens interpreter path, the sequence writes:

```text
kSpacePhaseEncodingLines
kSpaceCenterLine
AccelerationFactorPE
FirstFourierLine
FirstRefLine
nRefLine
```

`nRefLine` is the total ACS width used for bookkeeping and interpreter/reconstruction coordination.

::: warning Siemens protocol must match
Exporting `nRefLine` does **not** automatically configure the Siemens iPAT card. The scanner protocol must still be set manually to the same ACS/reference-line width expected by the acquisition and interpreter.
:::

A mismatch can cause failed online GRAPPA, inconsistent calibration, unexpected reference streams, or reconstruction artifacts.

## 6. Full encoded matrix size matters

An accelerated acquisition may never sample the numerically last encoding index. The current Siemens path therefore explicitly exports the full encoded PE matrix size as `kSpacePhaseEncodingLines` rather than asking the interpreter/reconstruction to infer matrix size from acquired lines alone.

The same principle applies to other platforms: the interpreter and reconstruction need an unambiguous description of the full encoded matrix, even if metadata field names differ.

## 7. TSE online phase-correction metadata

When phase correction is enabled in the current Siemens workflow, the sequence exports:

```text
TurboFactor = nEcho
PhaseCorrection = 'on'
```

and acquires one phase-correction navigator for each TSE echo during the corresponding prescan.

The compatible Siemens interpreter must consume the metadata and configure the intended online phase-correction behavior. The offline MATLAB reconstruction instead implements a constant-plus-readout-linear navigator phase model and is not intended to reproduce proprietary ICE internals byte-for-byte.

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

Pulseq `SLC` labels remain acquisition ordinals. Physical/anatomical positions are carried separately through `SliceLabel` and `SlicePositions` so that the target interpreter can remap acquisition order to physical slice order.

## 9. Axis mapping and orientation

The current maintained sequence workflow is non-oblique. Logical RO/PE/3D axes are mapped to physical x/y/z axes by `AxisRO`, `AxisPE`, and `Axis3D`, while `SignCorr` changes gradient polarity.

The exported rotation matrix is identity. Sequence settings, interpreter assumptions, and reconstruction orientation must therefore agree and should be verified with phantom/asymmetric geometry.

## 10. Offline reconstruction scope

The bundled offline MATLAB reconstruction is currently Siemens-specific because it reads Twix headers and MDH metadata through `mapVBVD`.

It supports:

- conventional Cartesian 2D TSE;
- RSS;
- GRAPPA;
- SENSE;
- CS;
- ESPIRiT sensitivity estimation for the default SENSE/CS path.

The current **GRAPPA** implementation uses Cartesian undersampling with acceleration along PE, integer acceleration, and integrated contiguous ACS. It preserves acquired rows and synthesizes only missing rows. Partial-Fourier GRAPPA, SMS/slice-GRAPPA, non-Cartesian GRAPPA, irregular variable-density masks, and Siemens ICE-specific kernel/scaling/filtering behavior are not implemented. See [Reconstruction](/reconstruction) for details.

The overall offline reconstruction also does **not** currently implement:

- gSlider decoding;
- partial Fourier reconstruction;
- SMS;
- non-Cartesian reconstruction;
- raw-data readers for other MRI vendors;
- multiple ESPIRiT map sets; or
- proprietary Siemens ICE coil combination or image filters.

## 11. Recommended checks for the current Siemens PI path

Before relying on online Siemens PI reconstruction, confirm all of the following together:

1. `R` in the Pulseq sequence;
2. `AccelerationFactorPE` seen by the interpreter;
3. full encoded `nPE`;
4. center LIN;
5. regular imaging lattice;
6. ACS start and width;
7. Siemens iPAT protocol acceleration and reference-line settings;
8. phase-correction navigator count when enabled; and
9. reconstructed orientation and slice order.

Treat these fields as one acquisition/reconstruction contract rather than independent metadata values. For another vendor, define and validate the equivalent contract for that platform instead of assuming Siemens field names or index conventions transfer directly.
