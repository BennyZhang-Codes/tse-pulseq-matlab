# Quick start

This page gives the shortest path from a fresh clone to a generated Pulseq sequence and, for the currently validated Siemens workflow, a first offline reconstruction.

::: info Platform status
The sequence core is designed around the vendor-neutral Pulseq format. The maintained scanner presets currently reflect the Siemens 7 T systems used for validation. See [Platform Integration](platform-integration.md) before treating those presets or metadata conventions as portable to another scanner.
:::

## 1. Clone the repository

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

See [Installation](installation.md) for the sequence-development requirements and the additional Siemens-specific tools used by the current 7 T validation/reconstruction path.

## 2. Generate a conventional 2D TSE sequence

Open MATLAB with the repository root as the current folder.

Edit the configuration block near the top of `TSE_2D.m`. The main sequence controls to review first are:

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

`Terra-XJ` is a **Siemens 7 T integration preset**, not a requirement of the TSE sequence concept. A different target system needs its own correct hardware limits, safety/PNS strategy and interpreter mapping.

Then run:

```matlab
run('TSE_2D.m')
```

The script performs sequence preparation, timing/label checks, the available PNS development check for the selected profile, exports sequence definitions, saves the resolved configuration and writes the `.seq` file.

Generated outputs under `seq/` include:

- `<sequence-name>.seq`;
- a MAT file containing the original `Setup` and resolved `Actual` structures.

Always inspect the console output and plots before using the exported sequence on a scanner.

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

::: info Offline gSlider reconstruction
The repository currently generates gSlider-TSE acquisitions, but the MATLAB offline reconstruction does **not** implement gSlider decoding.
:::

## 4. First offline reconstruction

The bundled reconstruction currently targets **Siemens Twix raw data**. Install `mapVBVD`, then edit:

```text
recon/matlab/examples/run_recon_TSE2D.m
```

Set at least:

```matlab
twixFile = "path-to-meas.dat";
outputDir = "path-to-output";
mapVBVDPath = "path-to-mapVBVD";
```

The maintained example keeps the optional echo-magnitude equalizer disabled by default:

```matlab
applyPrewhitening = true;
applyPhaseCorrection = true;
applyEchoMagnitudeCorrection = false;

echoMagnitudeMethod = "wiener";
echoMagnitudeAlpha = 0;
echoMagnitudeLambda = "auto";
echoMagnitudeMaxGain = 2;
runGrappa = true;
```

Set `applyEchoMagnitudeCorrection = true` only when you intentionally want navigator-derived echo-envelope equalization. The package exposes this as a reconstruction option rather than a required step; compare corrected and uncorrected results for the target dataset and report the selected settings. See [Echo phase & magnitude correction](/guide/echo-corrections).

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

## 6. Optional post-reconstruction denoising

Image-domain denoising is a separate optional module and is not invoked by `recon_TSE2D` automatically. Available comparison paths include NLM, BM3D, SANLM and TGV2.

BM3D is an external optional dependency rather than a required part of the reconstruction. If denoising is used, preserve the unfiltered reconstruction, report the method and parameters, and evaluate structural change rather than assuming that a smoother image is more accurate. See [Image-domain denoising](/guide/denoising).

## 7. Before scanning

A `.seq` file that passes software checks is not automatically ready for human scanning. At minimum, confirm:

- the target scanner model and hardware limits;
- RF peak amplitude, B1 and SAR;
- PNS using an appropriate platform-specific model or scanner-side safety system;
- slice order and orientation;
- interpreter compatibility and any platform-specific acquisition/reconstruction metadata;
- accelerated-imaging calibration settings when used; and
- phantom image quality before volunteer/patient use.

For the currently validated Siemens 7 T path, this additionally includes matching iPAT/ACS settings and checking the intended ICE phase-correction behavior when enabled.

See [Validation and safety](validation-and-safety.md) before scanner deployment.
