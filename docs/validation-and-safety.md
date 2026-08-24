# Validation and safety

This repository includes development-time validation helpers, but it is **not** a scanner safety certification system.

::: danger Research use only
A sequence that passes MATLAB/Pulseq checks is not automatically safe or suitable for volunteer or patient scanning. Scanner-side RF/SAR, gradient, PNS, protocol, interpreter and watchdog checks remain mandatory, together with local institutional approval.
:::

## 1. What the sequence scripts currently check

The maintained sequence entry points call:

```matlab
check_Timing(seq)
check_Label(seq)
check_PNS(seq, Actual)
```

and generate sequence/k-space plots for visual inspection.

The optional Pulseq `seq.testReport` path is present but commented out in the maintained entry scripts and can be enabled for additional development diagnostics.

## 2. Timing validation

`check_Timing` calls Pulseq `seq.checkTiming` and prints the detailed error report when validation fails.

Timing validation is necessary for exported sequence consistency, but it does not establish:

- acceptable RF power or SAR;
- acceptable PNS on the actual scanner;
- correct interpreter behavior;
- correct patient orientation;
- acceptable image quality;
- absence of problematic eddy-current effects.

A timing failure must be fixed before scanner use. A timing pass is only one layer of validation.

## 3. Label validation

The sequence uses acquisition labels for phase encoding, slice order, echoes, reference data and scanner/interpreter coordination.

Inspect label behavior after changes to:

- PE ordering;
- acceleration factor;
- ACS/reference layout;
- multi-slice acquisition mode;
- phase-correction navigator acquisition; or
- sequence-loop structure.

For PI, also verify that the scanner protocol and interpreter agree with exported LIN/ACS metadata.

## 4. PNS prediction

`check_PNS` uses Pulseq `calcPNS` with the scanner-specific Siemens `.asc` model chosen by `ScannerType`.

Current scanner mappings are documented in [Installation](installation.md).

A software PNS pass is useful development evidence, but it is not a substitute for scanner-side gradient-watchdog behavior or site-specific validation.

### PNS is not validated by documentation CI

The GitHub Pages workflow in this repository builds **documentation only**. It does not run MATLAB, Pulseq sequence generation or `calcPNS`, and it does not provide the Siemens `.asc` hardware models.

Therefore a green documentation workflow must never be interpreted as evidence that a sequence passes PNS.

## 5. RF peak amplitude and SAR

RF safety remains a known area requiring scanner validation, especially for 7 T TSE and gSlider-TSE.

Sequence-side timing correctness does not guarantee acceptable:

- peak B1;
- RF amplifier demand;
- time-averaged RF power;
- local/global SAR;
- slice-profile behavior after VERSE or other RF modifications.

The gSlider sequence uses a gSlider excitation with a relatively high time-bandwidth product and can use variable refocusing flip-angle schedules. Review these pulses explicitly.

Do not bypass scanner RF/SAR limits because the sequence was generated successfully in MATLAB.

## 6. Gradient raster and waveform validation

The custom gradient design utilities solve accepted waveforms on the integer gradient raster and validate:

- target area;
- duration;
- initial/final amplitudes;
- gradient-amplitude limit;
- slew-rate limit.

This addresses discrete-raster correctness but does not model every scanner-specific gradient-system effect.

Equal gradient area does not imply equal eddy-current behavior. Amplitude, slew, polarity, waveform duration and continuity with neighboring gradients can all matter on the real system.

## 7. Slice order and orientation

The maintained sequence path is non-oblique. Logical axes are mapped to physical x/y/z axes, with additional gradient sign corrections.

`MultiSliceMode`, `MultiSliceDir`, `SliceLabel` and `SlicePositions` also influence how acquisition order is interpreted by the Siemens interpreter.

Before in-vivo use:

1. scan a phantom or asymmetric test object;
2. verify physical slice order;
3. verify displayed orientation;
4. verify RO/PE polarity;
5. verify NIfTI orientation if offline reconstruction is used.

Do not infer anatomical direction only from variable names.

## 8. PI and ICE validation

For accelerated PI, confirm that sequence and scanner settings agree on:

- PE acceleration factor;
- full encoded PE matrix;
- center LIN;
- first imaging line;
- ACS location and total ACS width;
- Siemens iPAT acceleration and reference-line settings.

The sequence exports metadata, but the Siemens iPAT card must still be configured consistently.

Online TSE phase correction additionally requires a compatible interpreter to consume `TurboFactor` and `PhaseCorrection` and configure the corresponding ICE behavior.

## 9. Offline reconstruction validation

The MATLAB reconstruction is deliberately transparent and includes internal numerical safeguards, including:

- noise-prewhitening diagnostics;
- navigator SNR and fitted phase metrics;
- GRAPPA calibration NMSE/conditioning diagnostics;
- SENSE/CS forward-adjoint inner-product tests;
- solver convergence/residual histories;
- ESPIRiT calibration and support checks;
- NIfTI geometry consistency checks.

These checks validate the implemented reconstruction model, not equivalence with proprietary Siemens ICE.

## 10. Recommended staged scanner validation

A conservative validation sequence is:

1. review exported sequence parameters and RF/gradient waveforms;
2. run timing, label and appropriate PNS development checks;
3. use a low-duty-cycle phantom protocol;
4. verify slice order and orientation;
5. establish an `R=1` baseline;
6. test accelerated PI with matched ACS/iPAT settings;
7. test phase correction off versus on;
8. compare offline and online reconstructions with matched acquisition settings;
9. inspect ghosting, blur, geometric shifts and echo-train modulation;
10. inspect scanner RF/SAR/PNS/watchdog logs before any in-vivo use.

## 11. Known limitations relevant to safety/validation

Current important limitations include:

- non-oblique sequence orientation only;
- offline gSlider reconstruction is absent;
- partial Fourier, SMS and non-Cartesian offline reconstruction are absent;
- online ICE behavior depends on an external Siemens Pulseq interpreter;
- RF/SAR safety is not established by MATLAB timing checks;
- GitHub Actions do not validate PNS;
- scanner-specific eddy-current and image-quality behavior still requires phantom testing.

When adding a new scanner, RF pulse, sequence mode or reconstruction path, treat it as a new validation target rather than assuming previous scanner evidence transfers automatically.
