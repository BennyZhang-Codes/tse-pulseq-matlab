# Validation and safety

This repository includes development-time validation helpers, but it is **not a scanner safety certification system**.

The sequence design aims to be portable through Pulseq. Validation evidence, hardware limits, RF/SAR supervision, PNS models, interpreter behavior, and scanner-side watchdogs are necessarily target-platform responsibilities.

::: danger Research use only
A sequence that passes MATLAB/Pulseq checks is not automatically safe or suitable for volunteer or patient scanning. Scanner-side RF/SAR, gradient/PNS, protocol, interpreter, watchdog, and local institutional requirements remain mandatory.
:::

## 1. Sequence checks

The maintained sequence entry points currently call

```matlab
check_Timing(seq)
check_Label(seq)
check_PNS(seq, Actual)
```

and generate sequence/k-space plots for visual inspection.

The optional Pulseq `seq.testReport` path can be enabled for additional development checks.

## 2. Timing

`check_Timing` calls Pulseq `seq.checkTiming` and prints the detailed error report when validation fails.

Timing validation is necessary for exported sequence consistency, but it does not establish

- acceptable RF power or SAR;
- acceptable PNS on the actual scanner;
- correct interpreter behavior;
- correct orientation;
- correct reconstruction metadata; or
- acceptable image quality.

## 3. Labels, PE order, and metadata

Inspect label and encoding behavior after changes to

- PE ordering;
- acceleration;
- ACS/reference layout;
- slice ordering;
- phase-correction navigator acquisition; or
- sequence-loop structure.

Logical $k_y$ and echo-to-$k_y$ ordering are acquisition concepts. Target-platform line counters and online-reconstruction metadata should be validated as adapter behavior rather than treated as universal sequence definitions.

## 4. PNS prediction

PNS prediction is a **platform-dependent development feature**.

The current `check_PNS` path calls Pulseq `Sequence.calcPNS`. In the tracked Pulseq implementation, this uses external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) to evaluate the SAFE model [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007."). The software repository asks users to consider citing Szczepankiewicz et al. [[27]](/references#ref-27 "Szczepankiewicz F, Westin C-F, Nilsson M. Gradient waveform design for tensor-valued encoding in diffusion MRI. J Neurosci Methods. 2021;348:109007.").

A hardware model compatible with the target gradient system is also required by that calculation. Scanner-vendor hardware-model files are external platform inputs and are not distributed by this repository.

::: warning Current implementation status
PNS prediction should be optional for sequence generation, but the current entry scripts still call `check_PNS` directly. Refactoring this into a clean opt-in dependency is tracked in [TO DO & implementation checklist](/todo).
:::

A software PNS prediction remains development evidence and does not replace scanner-side PNS/gradient supervision.

## 5. RF peak amplitude and SAR

RF safety remains a target-scanner validation responsibility, especially for TSE and gSlider-TSE because refocusing trains can create substantial RF duty cycle.

Sequence-side timing correctness does not guarantee acceptable

- peak B1;
- RF amplifier demand;
- time-averaged RF power;
- local/global SAR; or
- slice-profile behavior after RF modifications such as VERSE.

## 6. Gradient raster and waveform validation

The custom gradient utilities validate the discrete rasterized waveform for target area, duration, endpoint amplitudes, gradient limit, and slew-rate limit.

This addresses software-level waveform correctness but does not model every scanner-specific gradient-system effect. Equal gradient area does not imply identical eddy-current or system-response behavior.

## 7. Slice order and orientation

The maintained sequence path is currently non-oblique. Logical axes are mapped to physical axes through the current configuration.

Before in-vivo use, verify physical slice order, displayed orientation, RO/PE polarity, and offline reconstructed orientation using an asymmetric phantom or equivalent geometry.

General oblique-orientation support remains a planned improvement; see [TO DO](/todo).

## 8. Accelerated imaging

For accelerated imaging, confirm that acquisition, target interpreter, and reconstruction agree on

- full encoded PE matrix;
- physical k-space center;
- acceleration factor;
- acquired imaging lattice;
- ACS/reference region; and
- phase-correction navigator behavior when used.

GRAPPA/SENSE/CS should be validated against a matched reference before relying on accelerated reconstruction for scientific conclusions.

## 9. Offline reconstruction validation

The bundled MATLAB reconstruction includes internal checks for

- prewhitening;
- navigator fitting;
- GRAPPA calibration;
- SENSE/CS forward-adjoint consistency;
- solver histories;
- ESPIRiT calibration;
- coil compression; and
- NIfTI geometry.

These validate aspects of the implemented numerical workflow. They do not establish equivalence to a proprietary vendor reconstruction or portability of the raw-data reader to unsupported formats.

## 10. Recommended staged validation

For any target platform, a conservative sequence-validation progression is

1. review RF/gradient waveforms and resolved protocol parameters;
2. run timing, label, and any available platform-appropriate development checks;
3. use a low-duty-cycle phantom protocol;
4. verify orientation and slice order;
5. establish an `R=1` baseline;
6. test accelerated imaging with matched sampling/calibration settings;
7. test phase correction and other optional processing separately;
8. compare offline/online reconstructions when both are available;
9. inspect ghosting, blur, geometric shifts, and echo-train modulation; and
10. review scanner RF/SAR/PNS/watchdog results before in-vivo use.

This guidance is intentionally platform neutral. Site- or scanner-specific operating procedures should remain local/platform documentation rather than being presented as part of the reusable sequence package.

## 11. Current limitations relevant to validation

- scanner testing to date reflects the current development environment rather than all Pulseq-capable platforms;
- hardware profiles and metadata handling are not yet fully separated from the reusable sequence core;
- PNS prediction is not yet a clean optional dependency;
- non-oblique sequence orientation only;
- offline gSlider reconstruction is absent;
- partial Fourier, SMS, and non-Cartesian reconstruction are absent;
- the maintained raw-data reader is currently Twix-specific; and
- RF/SAR safety is not established by MATLAB timing/PNS checks.

See [TO DO & implementation checklist](/todo) for the planned engineering work behind these limitations.
