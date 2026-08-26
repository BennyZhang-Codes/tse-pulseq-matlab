# Sequence API

The maintained sequence scripts build `Setup`, `SetupRF`, and `SetupSpoiling`, copy the requested configuration into `Actual`, and call preparation functions that resolve timing, geometry, RF, gradients, phase encoding, labels, checks, and export metadata.

For normal use, start with [Quick Start](/quickstart) and [Parameter Reference](/parameter-reference). This page is the source-oriented function map.

## Entry points

### `TSE_2D.m`

Generates the conventional Cartesian 2D TSE Pulseq sequence.

**Source:** [TSE_2D.m](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D.m)

### `TSE_2D_gSlider.m`

Generates the gSlider-TSE acquisition. Offline gSlider decoding is not currently implemented by `recon_TSE2D`.

An optional TRAPS-style variable-refocusing branch exists only as an experimental/test path and is not a core gSlider-TSE feature.

**Source:** [TSE_2D_gSlider.m](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D_gSlider.m)

## Preparation functions

| Function | Purpose |
| --- | --- |
| `prep_System` | resolve system/scanner profile and Pulseq limits |
| `prep_SlicePositions` | slice order and physical positions |
| `prep_PE3DOrder` | logical PE ordering and PI/CS path |
| `prep_Excitation` | excitation RF + slice-select events |
| `prep_Refocusing` | refocusing RF + slice-select events |
| `prep_Inversion` | inversion events when enabled |
| `prep_SpoilingArea` | crusher/spoiler areas |
| `prep_Gradient_GR` | readout gradient + ADC |
| `prep_Gradient_Block` | reusable RF/gradient blocks |
| `prep_Label` | Pulseq acquisition labels |
| `prep_Delay` | TSE/repetition delays |
| `prep_NoiseScan` | optional receive-noise acquisition |
| `prep_Seqloop` / `prep_Seqloop_IR` | conventional TSE acquisition loops |
| `prep_Seqloop_gSlider` / `prep_Seqloop_IR_gSlider` | gSlider-TSE acquisition loops |
| `prep_Definition` | exported Pulseq definitions |

See [Sequence Implementation](/sequence-generation) for how these stages connect.

## Phase-encoding implementation

```matlab
[PE3D, Actual] = prep_PE3DOrder(Actual)
```

The PI and CS paths are described in [Phase Encoding & Acceleration](/theory/phase-encoding). The current CS sampling utilities include Michael Lustig-derived `genPDF.m` / `genSampling.m` code and the repository's `genSampling_TSE.m` adaptation; see [Dependencies & Method Provenance](/reference/provenance).

## RF provenance

`prep_Excitation`, `prep_Refocusing`, and `prep_Inversion` use Pulseq-generated or bundled RF assets depending on the selected configuration. The SLR and gSlider pulse banks were generated offline with SigPy RF. See [Dependencies & Method Provenance](/reference/provenance).

## Checks

### `check_Timing`

Runs the Pulseq timing checker.

### `check_Label`

Checks the acquisition labels used by the sequence.

### `check_PNS`

Runs the current PNS prediction path through Pulseq `Sequence.calcPNS`. In the tracked Pulseq revision, this requires external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) and a compatible target-system hardware model.

The current sequence scripts still call this path directly; making it cleanly optional is tracked in [TO DO](/todo). See [Installation](/installation) and [Validation & Safety](/validation-and-safety).

## Outputs

The entry scripts export the `.seq` file and save the requested/resolved MATLAB configuration. Use the saved `Actual` values when checking what was actually generated after rasterization and preparation.
