# Validation and safety

This repository includes development-time validation helpers, but it is **not** a scanner safety certification system.

Vendor-neutral deployment is the project goal, while validation evidence is necessarily platform-specific. The current implementation and validation path is Siemens 7 T, and parts of the shared prep code still contain Siemens-specific system/metadata logic. See [Platform Integration](platform-integration.md) for the current implementation boundary and porting requirements.

::: danger Research use only
A sequence that passes MATLAB/Pulseq checks is not automatically safe or suitable for volunteer or patient scanning. Scanner-side RF/SAR, gradient, PNS, protocol, interpreter and watchdog checks remain mandatory, together with local institutional approval.
:::

## 1. Sequence checks

The maintained sequence entry points call:

```matlab
check_Timing(seq)
check_Label(seq)
check_PNS(seq, Actual)
```

and generate sequence/k-space plots for visual inspection.

The optional Pulseq `seq.testReport` path is present but commented out in the maintained entry scripts and can be enabled for additional development checks.

## 2. Timing

`check_Timing` calls Pulseq `seq.checkTiming` and prints the detailed error report when validation fails.

Timing validation is necessary for exported sequence consistency, but it does not establish acceptable RF power/SAR, PNS on the actual scanner, correct interpreter behavior, correct patient orientation, or image quality.

## 3. Labels and metadata

Inspect label behavior after changes to PE ordering, acceleration, ACS/reference layout, multi-slice acquisition mode, phase-correction navigator acquisition, or sequence-loop structure.

For the current Siemens PI implementation, also verify that scanner protocol and interpreter settings agree with exported LIN/ACS metadata.

## 4. PNS prediction

The repository uses **PNS prediction** as a development check. `check_PNS` calls Pulseq `Sequence.calcPNS`, and the tracked Pulseq implementation uses the external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) MATLAB package to evaluate the SAFE model [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007."). The software repository asks users to consider citing Szczepankiewicz et al. [[27]](/references#ref-27 "Szczepankiewicz F, Westin C-F, Nilsson M. Gradient waveform design for tensor-valued encoding in diffusion MRI. J Neurosci Methods. 2021;348:109007.").

The dependency chain is:

```text
check_PNS
→ Pulseq Sequence.calcPNS
→ safe_pns_prediction
→ scanner-specific MP_GPA*.asc SAFE parameters
```

Therefore two external pieces are required for the current Siemens PNS check:

1. `safe_pns_prediction` on the MATLAB path;
2. the appropriate Siemens `MP_GPA*.asc` hardware model for the target gradient system.

The hardware files are not distributed by `safe_pns_prediction` or this repository.

Current documented mappings are:

| `ScannerType` | `.asc` hardware model |
| --- | --- |
| `Terra-XJ` | `MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc` |
| `Terra-XR` | `MP_GPA_K2298_2250V_793A_SC72CD_EGA.asc` |

The SAFE model is a model-based prediction. The upstream package itself cautions that predictions can be inaccurate and should be interpreted carefully. A software PNS pass therefore remains development evidence rather than a substitute for scanner-side gradient/PNS supervision. citeturn652792search1

### PNS is not validated by documentation CI

The GitHub Pages workflow builds documentation only. It does not run MATLAB, install `safe_pns_prediction`, provide scanner hardware models, generate sequences, or execute `calcPNS`.

A green documentation workflow must therefore never be interpreted as evidence that a sequence passes PNS.

## 5. RF peak amplitude and SAR

RF safety remains a scanner-validation responsibility, especially for 7 T TSE and gSlider-TSE.

Sequence-side timing correctness does not guarantee acceptable peak B1, RF amplifier demand, time-averaged RF power, local/global SAR, or slice-profile behavior after VERSE or other RF modifications.

Do not bypass scanner RF/SAR limits because the sequence was generated successfully in MATLAB.

## 6. Gradient raster and waveform validation

The custom gradient design utilities validate the discrete rasterized waveform for target area, duration, initial/final amplitudes, gradient-amplitude limit, and slew-rate limit.

This addresses software-level waveform correctness but does not model every scanner-specific gradient-system effect. Equal gradient area does not imply equal eddy-current behavior.

## 7. Slice order and orientation

The maintained sequence path is non-oblique. Logical axes are mapped to physical x/y/z axes, with additional gradient sign corrections.

Before in-vivo use, verify physical slice order, displayed orientation, RO/PE polarity, and offline reconstructed orientation using an asymmetric phantom or equivalent geometry.

## 8. Accelerated imaging and current Siemens integration

For accelerated imaging, confirm that the Pulseq sequence, target interpreter and reconstruction agree on sampling pattern, encoded matrix, calibration data, and phase-encoding labels.

For the currently validated Siemens PI path, additionally confirm PE acceleration, full encoded PE matrix, center LIN, first imaging line, ACS location/width, and Siemens iPAT settings.

Online TSE phase correction additionally requires a compatible Siemens interpreter to consume `TurboFactor` and `PhaseCorrection` and configure the corresponding ICE behavior.

## 9. Offline reconstruction validation

The bundled MATLAB reconstruction currently targets Siemens Twix data. It includes internal checks for prewhitening, navigator fitting, GRAPPA calibration, SENSE/CS forward-adjoint consistency, solver histories, ESPIRiT calibration, coil compression, and NIfTI geometry.

These validate aspects of the implemented numerical workflow; they do not establish equivalence to Siemens ICE or portability to another vendor.

## 10. Recommended staged scanner validation

A conservative validation sequence for any target platform is:

1. review exported sequence parameters and RF/gradient waveforms;
2. run timing, label and appropriate PNS development checks;
3. use a low-duty-cycle phantom protocol;
4. verify slice order and orientation;
5. establish an `R=1` baseline;
6. test accelerated imaging with matched calibration/interpreter settings;
7. test phase correction off versus on when supported;
8. compare offline and online reconstructions where both are available;
9. inspect ghosting, blur, geometric shifts and echo-train modulation;
10. inspect scanner RF/SAR/PNS/watchdog results before any in-vivo use.

For a new scanner vendor or model, repeat the platform-specific validation rather than inheriting the Siemens 7 T status.

## 11. Known limitations relevant to safety/validation

Current important limitations include:

- scanner validation has currently been performed only on Siemens 7 T systems;
- current hardware/PNS presets cover the documented Terra configurations;
- `safe_pns_prediction` and scanner-specific `MP_GPA*.asc` data are external dependencies of `check_PNS`;
- non-oblique sequence orientation only;
- offline gSlider reconstruction is absent;
- partial Fourier, SMS and non-Cartesian offline reconstruction are absent;
- the bundled offline raw-data reconstruction is Siemens Twix-specific;
- online ICE behavior depends on an external Siemens Pulseq interpreter in the current validated path;
- RF/SAR safety is not established by MATLAB timing/PNS checks; and
- scanner-specific eddy-current and image-quality behavior still requires physical testing.
