# Quick start

This page gives the shortest engineering path from a fresh clone to a generated Pulseq sequence and, for the currently implemented Siemens path, a first offline reconstruction.

::: info Platform status
The acquisition is expressed with Pulseq [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552."), but the maintained scanner presets, LIN/ICE metadata and current raw-data reader reflect the Siemens 7 T systems used for validation. See [Platform Integration](/platform-integration).
:::

## 1. Clone with submodules

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

The tracked submodules are Pulseq and VERSE.

## 2. Install the PNS prediction dependency

The maintained sequence scripts call `check_PNS`, which calls Pulseq `Sequence.calcPNS`. The tracked Pulseq implementation requires the external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) MATLAB package.

Add that package to the MATLAB path before sequence generation:

```matlab
addpath(genpath('path-to-safe_pns_prediction'));
which safe_gwf_to_pns
```

The current Siemens PNS check also requires the correct scanner-specific `MP_GPA*.asc` SAFE hardware model. The SAFE calculation is based on the model of Hebrank and Gebhardt [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007."). See [Installation](/installation#safe-pns-prediction-dependency) and [Validation & Safety](/validation-and-safety#pns-prediction).

## 3. Generate conventional 2D TSE

Open MATLAB in the repository root. Review the main configuration block in `TSE_2D.m`, for example:

```matlab
Setup.NoiseScan        = 'on';
Setup.PhaseCorrection  = 'on';
Setup.IR               = 'off';
Setup.PEMode           = 'CentricFull';
Setup.AccelerationMode = 'PI';

Setup.fovRO            = 120e-3;
Setup.fovPE            = 120e-3;
Setup.nRO              = 120;
Setup.nPE              = 120;
Setup.nEcho            = 10;
Setup.nSlice           = 5;
Setup.SliceThickness   = 2e-3;
Setup.TE1              = 14e-3;
Setup.TEeff            = 14e-3;
Setup.TR               = 5000e-3;
Setup.R                = 2;
```

The maintained example also selects a currently implemented scanner profile:

```matlab
Setup.ScannerType = 'Terra-XJ';
```

`Terra-XJ` is a Siemens 7 T integration preset, not a requirement of RARE/TSE [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.") or Pulseq itself.

Generate the sequence:

```matlab
run('TSE_2D.m')
```

The script resolves `Setup` into `Actual`, prepares RF/gradient/ADC/PE objects, assembles the sequence loop, performs timing/label/PNS development checks, and writes the `.seq` plus a MAT archive of the configuration.

See [Sequence Implementation](/sequence-generation) for the source-level pipeline.

## 4. Choose PI or CS acquisition deliberately

Parallel imaging and compressed sensing use different PE patterns:

```matlab
Setup.AccelerationMode = 'PI';
% or
Setup.AccelerationMode = 'CS';
```

The current CS sampling implementation uses Michael Lustig-derived SparseMRI utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195."). It generates a one-dimensional polynomial variable-density PE mask with Monte-Carlo interference minimization; Poisson-disc sampling is not implemented.

Before changing `R`, `p`, `r`, `nEcho`, `TEeff` or PE mode, read [Phase Encoding & Acceleration](/theory/phase-encoding).

## 5. Generate gSlider-TSE

Run:

```matlab
run('TSE_2D_gSlider.m')
```

The gSlider entry point can enable

```matlab
Setup.TRAPS = 'on';
SetupRF.typeEx = 'gSlider';
```

The bundled gSlider/SLR RF banks were generated offline with SigPy RF. gSlider method provenance is documented with [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.") and TRAPS with [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535."). See [gSlider-TSE & TRAPS](/guide/gslider-traps).

::: info Offline gSlider reconstruction
The repository generates gSlider-TSE acquisitions, but the bundled MATLAB reconstruction does **not** implement gSlider decoding.
:::

## 6. First offline reconstruction

The current reconstruction consumes Siemens Twix through external [mapVBVD](https://github.com/pehses/mapVBVD). Edit:

```text
recon/matlab/examples/run_recon_TSE2D.m
```

Set at least:

```matlab
twixFile = "path-to-meas.dat";
outputDir = "path-to-output";
mapVBVDPath = "path-to-mapVBVD";
```

The maintained example keeps optional echo magnitude correction disabled:

```matlab
applyPrewhitening = true;
applyPhaseCorrection = true;
applyEchoMagnitudeCorrection = false;
runGrappa = true;
```

Then run:

```matlab
run(fullfile('recon','matlab','examples','run_recon_TSE2D.m'))
```

For a quick one-slice reconstruction:

```matlab
slices = 3;
comparePhaseCorrection = false;
```

## 7. Choose a reconstruction method

The programmatic entry point supports

```text
auto
rss
grappa
sense
cs
```

The method names are standard MRI terms. Package-specific restrictions are documented separately:

- **GRAPPA** — current implementation uses Cartesian PE acceleration with integer `R` and contiguous integrated ACS; partial Fourier, SMS/slice-GRAPPA, non-Cartesian GRAPPA, and irregular variable-density masks are not implemented.
- **SENSE** — current implementation uses the package's Cartesian `PFS` operator; ESPIRiT is the default sensitivity estimation method.
- **CS** — current implementation uses the same Cartesian multicoil data-consistency model with TV and Haar-L1 regularization.

Example SENSE:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'ReconstructionMethod', 'sense', ...
    'SENSEIterations', 50, ...
    'SENSETikhonov', 1e-4, ...
    'IterativeUseGPU', 'auto');
```

Example CS:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'ReconstructionMethod', 'cs', ...
    'CSIterations', 250, ...
    'CSTVWeight', 0.006, ...
    'CSWaveletWeight', 0.0005, ...
    'IterativeUseGPU', 'auto');
```

See [Reconstruction](/reconstruction) for equations, defaults, implementation details, and support limits.

## 8. Optional processing stays optional

### Echo magnitude correction

Enable `EchoMagnitudeCorrection` only when deliberately evaluating navigator-derived echo-envelope equalization. The feature is disabled by default and its RARE/FSE literature basis, gain equations, and limits are documented in [Optional Echo Correction](/guide/echo-corrections).

### Image-domain denoising

NLM, BM3D, SANLM and TGV2 live in a separate post-reconstruction module. `recon_TSE2D` does not run them automatically. See [Optional Denoising](/guide/denoising).

## 9. Before scanner use

A generated `.seq` file is not automatically ready for human scanning. Confirm at minimum:

- target scanner model and hardware limits;
- RF peak B1 and scanner-side SAR supervision;
- `safe_pns_prediction` plus the correct hardware model for the development PNS calculation;
- scanner-side gradient/PNS supervision;
- slice order/orientation;
- interpreter compatibility;
- PI/ACS settings when used;
- relevant platform-specific labels/metadata; and
- phantom behavior before volunteer/patient use.

See [Scanner Validation & Safety](/validation-and-safety) and the [Siemens 7 T Phantom SOP](/staged-phantom-validation) for the currently documented validation path.
