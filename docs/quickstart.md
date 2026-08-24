# Quick start

This page gives the shortest path from a fresh clone to a generated sequence and a first offline reconstruction.

## 1. Clone the repository

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

See [Installation](installation.md) for MATLAB, mapVBVD, Siemens `.asc` and interpreter requirements.

## 2. Generate a conventional 2D TSE sequence

Open MATLAB with the repository root as the current folder.

Edit the configuration block near the top of `TSE_2D.m`. A minimal starting configuration is already provided in the script. The main fields to review first are:

```matlab
Setup.ScannerType      = 'Terra-XJ';
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

Then run:

```matlab
run('TSE_2D.m')
```

The maintained script performs sequence preparation, timing/label/PNS checks, exports sequence definitions, saves the resolved configuration and writes the `.seq` file.

Generated outputs are written under `seq/` and include:

- `<sequence-name>.seq`;
- a MAT file containing the original `Setup` and resolved `Actual` structures.

Always inspect the console output and plots before using the exported sequence.

## 3. Generate a gSlider-TSE sequence

Use `TSE_2D_gSlider.m`:

```matlab
run('TSE_2D_gSlider.m')
```

The gSlider entry point shares the same main preparation path but uses gSlider excitation and can enable a TRAPS refocusing-flip schedule:

```matlab
Setup.TRAPS = 'on';
SetupRF.typeEx = 'gSlider';
```

The default gSlider example uses a higher excitation time-bandwidth product than the conventional TSE example. RF peak amplitude, B1, slice profile and SAR therefore require explicit review.

!!! note "Offline gSlider reconstruction"
    The repository currently generates gSlider-TSE acquisitions, but the MATLAB offline reconstruction does **not** implement gSlider decoding.

## 4. First offline reconstruction

Install `mapVBVD`, then edit:

```text
recon/matlab/examples/run_recon_TSE2D.m
```

Set at least:

```matlab
twixFile = "path-to-meas.dat";
outputDir = "path-to-output";
mapVBVDPath = "path-to-mapVBVD";
```

The routine-use example currently enables:

```matlab
applyPrewhitening = true;
applyPhaseCorrection = true;
applyEchoMagnitudeCorrection = true;
echoMagnitudeMethod = "wiener";
echoMagnitudeAlpha = 0;
echoMagnitudeLambda = "auto";
echoMagnitudeMaxGain = 2;
runGrappa = true;
```

Run:

```matlab
run(fullfile('recon','matlab','examples','run_recon_TSE2D.m'))
```

For a quick diagnostic reconstruction of one slice, set:

```matlab
slices = 3;
comparePhaseCorrection = false;
```

## 5. Choose a reconstruction method explicitly

The programmatic API supports:

```text
auto
rss
grappa
sense
cs
```

Example ordinary ESPIRiT-SENSE:

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

These regularization values are starting points validated on the repository's matched phantom experiments, not universal optimum values. Retune them when contrast, resolution, coil configuration, ACS width or sampling changes materially.

## 6. Before scanning

A `.seq` file that passes software checks is not automatically ready for human scanning. At minimum, confirm:

- scanner model and hardware limits;
- RF peak amplitude, B1 and SAR;
- PNS on the appropriate scanner model;
- slice order and orientation;
- PI acceleration and ACS settings in the Siemens protocol;
- online phase-correction behavior if used; and
- phantom image quality before volunteer/patient use.

See [Validation and safety](validation-and-safety.md) before scanner deployment.
