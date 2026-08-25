# Sequence API

The maintained sequence entry scripts are configuration-driven MATLAB scripts. They build `Setup`, `SetupRF`, and `SetupSpoiling`, copy the requested state into `Actual`, then call a sequence of preparation functions that resolve timing, geometry, encoding, RF/gradient events, labels, and export metadata.

For the scientific interpretation of these stages, see [Architecture](/concepts-overview), [TSE echo-train model](/theory/tse-echo-train), and [Sequence generation](/sequence-generation).

## `TSE_2D.m`

**Purpose.** Generate a conventional Cartesian 2D TSE Pulseq sequence.

**Configuration.** The main user-facing controls are held in

```matlab
Setup
SetupRF
SetupSpoiling
```

Typical configuration includes scanner profile, FOV/matrix, slice geometry, `TE1`, `TEeff`, TR, echo-train length, acceleration, PE ordering, RF pulse types, readout duration, and crusher/spoiler settings.

**Outputs.** The script creates a Pulseq `seq`, runs development checks, writes sequence definitions, exports the `.seq` file, and saves the requested/resolved MATLAB configuration.

**Source.** [TSE_2D.m](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D.m)

## `TSE_2D_gSlider.m`

**Purpose.** Generate the gSlider-TSE variant.

**Key differences.** The entry point uses gSlider excitation and can enable a TRAPS refocusing schedule. Offline gSlider decoding is not currently implemented by `recon_TSE2D`.

**Source.** [TSE_2D_gSlider.m](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D_gSlider.m)

## Preparation pipeline

The calls below are the maintained sequence-building path. The function signatures are shown in the same direction as the current entry script calls.

### `prep_System`

```matlab
[sys, sys_soft, seq, Actual] = prep_System(Actual)
```

Resolves the selected scanner profile and Pulseq system limits, creates the `mr.Sequence` object, and records resolved values in `Actual`.

The current hardware presets are Siemens 7 T integration presets; they are not a universal scanner abstraction.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_System.m)

### `prep_SlicePositions`

```matlab
[SliceLabel, SliceOrder, SlicePositions] = prep_SlicePositions(Actual)
```

Resolves slice ordering, label indices, and physical slice positions from the requested multi-slice geometry.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_SlicePositions.m)

### `prep_PE3DOrder`

```matlab
[PE3D, Actual] = prep_PE3DOrder(Actual)
```

Constructs the logical PE ordering and the currently implemented PI/CS metadata mapping. This stage is where echo index, physical $k_y$, acceleration, reference lines, and platform metadata meet.

See [Phase encoding & effective TE](/theory/phase-encoding) before changing this stage.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_PE3DOrder.m)

### `prep_Excitation`

```matlab
[RF, Grad] = prep_Excitation(RF, Grad, Actual, sys_soft)
```

Builds the configured excitation RF pulse and associated slice-select gradient events.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Excitation.m)

### `prep_Refocusing`

```matlab
[RF, Grad] = prep_Refocusing(RF, Grad, Actual, sys_soft)
```

Builds refocusing RF pulses and slice-select events, including the requested fixed or variable flip-angle schedule.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Refocusing.m)

### `prep_Inversion`

```matlab
[RF, Grad] = prep_Inversion(RF, Grad, Actual, sys_soft)
```

Builds inversion events when `Actual.IR == 'on'`.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Inversion.m)

### `prep_SpoilingArea`

```matlab
Grad = prep_SpoilingArea(Grad, Actual)
```

Resolves crusher/spoiler areas from the configured cycle/reference definitions.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_SpoilingArea.m)

### `prep_Gradient_GR`

```matlab
[ADC, Grad] = prep_Gradient_GR(Grad, ADC, Actual, sys_soft)
```

Builds the frequency-encoding readout/ADC events under the resolved raster and soft gradient constraints.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Gradient_GR.m)

### `prep_Gradient_Block`

```matlab
[Grad, RF, Delay] = prep_Gradient_Block(Grad, RF, ADC, Delay, Actual, sys_soft)
```

Splits and combines gradient/RF timing into the blocks used by the sequence loop.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Gradient_Block.m)

### `prep_Label`

```matlab
[seq, Label] = prep_Label(seq, Actual, Label)
```

Initializes Pulseq labels used for PE, slice, echo/reference, and current interpreter integration.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Label.m)

### `prep_Delay`

```matlab
Delay = prep_Delay(Actual, Delay)
```

Builds the resolved delay events used by the echo train and sequence repetition structure.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Delay.m)

### `prep_NoiseScan`

```matlab
[seq, Label] = prep_NoiseScan(seq, Actual, PE3D, ADC, Label, sys)
```

Adds the optional receive-noise acquisition used by the offline prewhitening path.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_NoiseScan.m)

### `prep_Seqloop` / `prep_Seqloop_IR`

```matlab
seq = prep_Seqloop(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft)
seq = prep_Seqloop_IR(seq, Actual, RF, Grad, ADC, Delay, Label, sys_soft)
```

Assemble the final acquisition loop for non-IR and IR modes, respectively.

[Source: `prep_Seqloop.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Seqloop.m) · [Source: `prep_Seqloop_IR.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Seqloop_IR.m)

## Validation helpers

### `check_Timing`

```matlab
seq = check_Timing(seq)
```

Runs the Pulseq timing checker and reports errors. A pass is necessary for sequence consistency but is not scanner safety certification.

### `check_Label`

```matlab
check_Label(seq)
```

Checks the acquisition-label sequence used by the current encoding/interpreter integration.

### `check_PNS`

```matlab
check_PNS(seq, Actual)
```

Runs the development PNS calculation using the currently configured scanner hardware model. See [Validation & safety](/validation-and-safety) for the scope and limitations.

## Definitions and export

`prep_Definition.m` writes interpreter-facing Pulseq definitions derived from `Actual`. Several definitions are part of the currently validated Siemens integration and should therefore be treated as the platform layer rather than as universal TSE physics.

[Source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/prep/prep_Definition.m)

## Configuration reference

Use [Parameter Reference](/parameter-reference) for user-facing fields and [Platform Integration](/platform-integration) for the boundary between portable acquisition concepts and Siemens-specific definitions.
