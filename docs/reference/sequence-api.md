# Sequence API

The maintained sequence entry scripts are configuration-driven MATLAB scripts. They build `Setup`, `SetupRF`, and `SetupSpoiling`, copy the requested state into `Actual`, then call preparation functions that resolve timing, geometry, encoding, RF/gradient events, labels, validation checks, and export metadata.

For the engineering interpretation of these stages, see [Architecture](/concepts-overview) and [Sequence implementation](/sequence-generation).

## `TSE_2D.m`

**Purpose.** Generate a conventional Cartesian 2D TSE Pulseq sequence.

**Configuration.** Main user-facing controls are held in `Setup`, `SetupRF`, and `SetupSpoiling`.

**Outputs.** The script creates a Pulseq `seq`, runs development checks, writes sequence definitions, exports the `.seq` file, and saves the requested/resolved MATLAB configuration.

**Source.** [TSE_2D.m](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D.m)

## `TSE_2D_gSlider.m`

**Purpose.** Generate the gSlider-TSE variant.

**Key differences.** The entry point uses gSlider excitation and can enable a TRAPS refocusing schedule. Offline gSlider decoding is not currently implemented by `recon_TSE2D`.

**Source.** [TSE_2D_gSlider.m](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D_gSlider.m)

## Preparation pipeline

### `prep_System`

```matlab
[sys, sys_soft, seq, Actual] = prep_System(Actual)
```

Resolves the selected scanner profile and Pulseq system limits, creates the `mr.Sequence` object, and records resolved values in `Actual`.

### `prep_SlicePositions`

```matlab
[SliceLabel, SliceOrder, SlicePositions] = prep_SlicePositions(Actual)
```

Resolves slice ordering, label indices, and physical slice positions.

### `prep_PE3DOrder`

```matlab
[PE3D, Actual] = prep_PE3DOrder(Actual)
```

Constructs logical PE ordering and the current PI/CS metadata mapping. See [Phase encoding & acceleration](/theory/phase-encoding).

### `prep_Excitation`

```matlab
[RF, Grad] = prep_Excitation(RF, Grad, Actual, sys_soft)
```

Builds excitation RF and slice-select events.

### `prep_Refocusing`

```matlab
[RF, Grad] = prep_Refocusing(RF, Grad, Actual, sys_soft)
```

Builds refocusing RF and slice-select events.

### `prep_Inversion`

```matlab
[RF, Grad] = prep_Inversion(RF, Grad, Actual, sys_soft)
```

Builds inversion events when enabled.

### `prep_SpoilingArea`

```matlab
Grad = prep_SpoilingArea(Grad, Actual)
```

Resolves crusher/spoiler areas from configured cycle/reference definitions.

### `prep_Gradient_GR`

```matlab
[ADC, Grad] = prep_Gradient_GR(Grad, ADC, Actual, sys_soft)
```

Builds the readout gradient and ADC events.

### `prep_Gradient_Block`

```matlab
[Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, Actual, sys_soft)
```

Builds the gradient/RF blocks used by the sequence loop.

### `prep_Label`

```matlab
[seq, Label] = prep_Label(seq, Actual, Label)
```

Initializes Pulseq labels used for PE, slice, echo/reference, and current interpreter integration.

### `prep_Delay`

```matlab
Delay = prep_Delay(Actual, Delay)
```

Builds delay events used by the echo train and repetition structure.

### `prep_NoiseScan`

```matlab
[seq, Label] = prep_NoiseScan(seq, Actual, PE3D, ADC, Label, sys)
```

Adds the optional receive-noise acquisition used by prewhitening.

### `prep_Seqloop` / `prep_Seqloop_IR`

```matlab
seq = prep_Seqloop(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft)
seq = prep_Seqloop_IR(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft)
```

Assemble the final acquisition loop for non-IR and IR modes.

## Validation helpers

### `check_Timing`

```matlab
seq = check_Timing(seq)
```

Runs the Pulseq timing checker. A pass is necessary for sequence consistency but is not scanner safety certification.

### `check_Label`

```matlab
check_Label(seq)
```

Checks acquisition labels used by the current encoding/interpreter integration.

### `check_PNS`

```matlab
check_PNS(seq, Actual)
```

Runs PNS prediction through Pulseq `Sequence.calcPNS`. In the Pulseq revision tracked by this repository, `calcPNS` requires the external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) MATLAB package on the path and uses the SAFE model [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007."). The current Siemens path also requires the appropriate `MP_GPA*.asc` hardware model.

If either dependency is missing, the repository `check_PNS` now raises an explicit error rather than failing later inside Pulseq.

See [Installation](/installation#safe-pns-prediction-dependency), [Validation & safety](/validation-and-safety#pns-prediction), and [Dependencies & method provenance](/reference/provenance).

## Definitions and export

`prep_Definition.m` writes interpreter-facing Pulseq definitions derived from `Actual`. Several definitions belong to the currently validated Siemens integration and should be treated as platform-specific implementation details.

## Configuration reference

Use [Parameter Reference](/parameter-reference) for user-facing fields and [Platform Integration](/platform-integration) for the boundary between portable acquisition concepts and Siemens-specific definitions.
