# Quick start

This page gives the shortest engineering path from a fresh clone to a generated Pulseq sequence and, when supported by the current raw-data reader, a first offline reconstruction.

::: info Current testing boundary
Scanner development/testing to date has used Siemens 7 T systems. The sequence design itself is implemented with Pulseq and the documentation treats scanner-specific assumptions as platform-integration details rather than as the sequence definition.
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

The maintained example currently selects a scanner profile from the development environment. This is a **current implementation detail**, not a requirement of RARE/TSE [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.") or Pulseq [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552.").

Generate the sequence:

```matlab
run('TSE_2D.m')
```

The script resolves `Setup` into `Actual`, prepares RF/gradient/ADC/PE objects, assembles the echo train, runs the currently configured development checks, and writes the `.seq` plus a MAT archive of the configuration.

::: warning Current PNS-check behavior
The current sequence path calls `check_PNS`. That check uses Pulseq `Sequence.calcPNS`, which depends on external `safe_pns_prediction` plus a target-system hardware model. Making PNS prediction a truly **optional platform-dependent dependency** is tracked in [TO DO & implementation checklist](/todo).
:::

See [Sequence Implementation](/sequence-generation) for the source-level pipeline.

## 3. Choose PI or CS acquisition deliberately

Parallel imaging and compressed sensing use different PE patterns:

```matlab
Setup.AccelerationMode = 'PI';
% or
Setup.AccelerationMode = 'CS';
```

The current CS sampling implementation uses Michael Lustig-derived SparseMRI utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195."). It generates a one-dimensional polynomial variable-density PE mask with Monte-Carlo interference minimization; Poisson-disc sampling is not implemented.

Before changing `R`, `p`, `r`, `nEcho`, `TEeff`, or PE mode, read [Phase Encoding & Acceleration](/theory/phase-encoding).

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

The bundled gSlider/SLR RF banks were generated offline with SigPy RF. gSlider method provenance is documented with [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.") and TRAPS with [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535.").

::: info Offline gSlider reconstruction
The repository generates gSlider-TSE acquisitions, but the bundled MATLAB reconstruction does **not** implement gSlider decoding. This is tracked in [TO DO](/todo).
:::

## 5. First offline reconstruction

The maintained raw-data reader currently consumes Siemens Twix through external [mapVBVD](https://github.com/pehses/mapVBVD). Edit:

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

## 6. Choose a reconstruction method

The programmatic entry point supports

```text
auto
rss
grappa
sense
cs
```

Method names use standard MRI terminology. Package-specific support limits are documented in [Reconstruction](/reconstruction).

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

## 7. Optional processing stays optional

### Echo magnitude correction

Enable `EchoMagnitudeCorrection` only when deliberately evaluating navigator-derived echo-envelope equalization. The feature is disabled by default. See [Optional Echo Correction](/guide/echo-corrections).

### Image-domain denoising

NLM, BM3D, SANLM, and TGV2 live in a separate post-reconstruction module. `recon_TSE2D` does not run them automatically. See [Optional Denoising](/guide/denoising).

## 8. Before scanner use

A generated `.seq` file is not automatically ready for human scanning. Confirm the target platform's

- hardware limits;
- RF peak B1 and scanner-side SAR supervision;
- gradient/PNS supervision;
- orientation and slice order;
- interpreter compatibility;
- PI/ACS metadata when used; and
- phantom behavior before volunteer/patient use.

PNS prediction through SAFE tooling is a development aid, not a replacement for scanner-side safety supervision. See [Validation & Safety](/validation-and-safety) and [Platform Integration](/platform-integration).
