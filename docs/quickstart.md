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

The tracked submodules are Pulseq and VERSE. See [Dependencies & method provenance](/reference/provenance) before redistributing or modifying inherited/adapted components.

## 2. Generate conventional 2D TSE

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

The script resolves `Setup` into `Actual`, prepares RF/gradient/ADC/PE objects, assembles the sequence loop, performs the available timing/label/PNS development checks and writes the `.seq` plus a MAT archive of the configuration.

See [Sequence Implementation](/sequence-generation) for the source-level pipeline.

## 3. Choose PI or CS acquisition deliberately

Parallel-imaging and compressed-sensing acquisition use different PE patterns:

```matlab
Setup.AccelerationMode = 'PI';
% or
Setup.AccelerationMode = 'CS';
```

The CS path uses Michael Lustig-derived SparseMRI sampling utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.") to generate **1D polynomial variable-density PE sampling with Monte-Carlo interference minimization**. It is not Poisson-disc sampling.

Before changing `R`, `p`, `r`, `nEcho`, `TEeff` or PE mode, read [Phase Encoding & Acceleration](/theory/phase-encoding).

## 4. Generate gSlider-TSE

Run:

```matlab
run('TSE_2D_gSlider.m')
```

The gSlider entry point can enable

```matlab
Setup.TRAPS = 'on';
SetupRF.typeEx = 'gSlider';
```

The bundled gSlider/SLR RF banks were generated offline with SigPy RF. gSlider method provenance is documented with [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.") and the TRAPS-style refocusing schedule with [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535."). See [gSlider-TSE & TRAPS](/guide/gslider-traps).

::: info Offline gSlider reconstruction
The repository generates gSlider-TSE acquisitions, but the bundled MATLAB reconstruction does **not** implement gSlider decoding.
:::

## 5. First offline reconstruction

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

The maintained example keeps optional echo-envelope equalization disabled:

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

## 6. Choose a reconstruction method

The programmatic entry point supports

```text
auto
rss
grappa
sense
cs
```

The `grappa` path is regular Cartesian **1D PE-GRAPPA** calibrated from contiguous ACS. Its current support boundary is documented explicitly in [Reconstruction](/reconstruction): no partial-Fourier GRAPPA, SMS/slice-GRAPPA, non-Cartesian GRAPPA, or irregular variable-density mask reconstruction.

Example ESPIRiT-SENSE:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'ReconstructionMethod', 'sense', ...
    'SENSEIterations', 50, ...
    'SENSETikhonov', 1e-4, ...
    'IterativeUseGPU', 'auto');
```

Example Cartesian CS:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', mapVBVDPath, ...
    'ReconstructionMethod', 'cs', ...
    'CSIterations', 250, ...
    'CSTVWeight', 0.006, ...
    'CSWaveletWeight', 0.0005, ...
    'IterativeUseGPU', 'auto');
```

The [Reconstruction](/reconstruction) chapter contains the calling interface, equations, defaults, calibration choices and source functions in one place. The numeric defaults above are starting values, not universal optimum parameters.

## 7. Optional processing stays optional

### Echo magnitude correction

Enable `EchoMagnitudeCorrection` only when deliberately evaluating navigator-derived echo-envelope equalization. The feature is disabled by default and its RARE/FSE literature basis, gain equations and limits are documented in [Optional Echo Correction](/guide/echo-corrections).

### Image-domain denoising

NLM, BM3D, SANLM and TGV2 live in a separate post-reconstruction module. `recon_TSE2D` does not run them automatically. See [Optional Denoising](/guide/denoising).

## 8. Before scanner use

A generated `.seq` file is not automatically ready for human scanning. Confirm at minimum:

- target scanner model and hardware limits;
- RF peak B1 and scanner-side SAR supervision;
- gradient/PNS behavior with the correct target-system safety path;
- slice order/orientation;
- interpreter compatibility;
- PI/ACS settings when used;
- relevant platform-specific labels/metadata; and
- phantom behavior before volunteer/patient use.

See [Scanner Validation & Safety](/validation-and-safety) and the [Siemens 7 T Phantom SOP](/staged-phantom-validation) for the currently documented validation path.
