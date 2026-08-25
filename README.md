# TSE Pulseq for MATLAB

[![CI](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml) [![Documentation](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/docs.yml/badge.svg?branch=main)](https://bennyzhang-codes.github.io/tse-pulseq-matlab/) [![Coverage](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab/graph/badge.svg?token=JNHD7UK0A3)](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22076863.svg)](https://doi.org/10.5281/zenodo.22076863)

MATLAB/Pulseq research software for Cartesian 2D turbo spin echo (TSE) sequence development, including conventional multi-slice TSE and gSlider-TSE, together with a transparent offline reconstruction workflow for conventional 2D TSE data.

The documentation is organized as an MRI Methods companion: **signal model → encoding → sequence implementation → reconstruction → scientific validation → performance → API/reference**.

> **Platform status.** Vendor-neutral deployment is the project goal, but the current implementation remains coupled to the Siemens 7 T development path in scanner presets, PI/LIN mapping, interpreter definitions, and PNS models. Scanner validation has so far been performed on Siemens 7 T systems, and the bundled offline raw-data reconstruction currently targets Siemens Twix. Other vendors are not yet implemented or validated.

> **Research software.** MATLAB/Pulseq timing checks, PNS estimates, CI results, and offline reconstruction do not replace scanner-side RF/SAR, gradient/PNS, protocol, interpreter, watchdog, or local institutional validation before volunteer or patient scanning.

## Scope

| Layer | Current scope |
| --- | --- |
| Design goal | Portable Pulseq development for Cartesian 2D TSE and gSlider-TSE with configurable RF, timing, PE order, PI/CS sampling, slice ordering, and TRAPS schedules. |
| Current sequence implementation | Pulseq-based, with Siemens-specific Terra profiles, PI/LIN mapping, interpreter definitions, and development PNS models still present in shared code. |
| Validated scanner path | Siemens 7 T systems only at present. |
| Offline reconstruction | Conventional Cartesian 2D TSE from Siemens Twix: RSS, diagnostic GRAPPA, ESPIRiT-SENSE, and Cartesian CS, with optional navigator phase/magnitude correction and post-reconstruction denoising. |
| Not currently implemented | Validated non-Siemens scanner paths, offline gSlider decoding, partial Fourier, SMS, non-Cartesian reconstruction, and oblique sequence orientation. |

Adding another scanner platform requires a compatible Pulseq interpreter, correct hardware/safety models, platform metadata integration, and a new staged validation campaign. See the [platform-integration documentation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/platform-integration).

## Quick start

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Open MATLAB in the repository root and generate a conventional sequence using the currently implemented scanner profile:

```matlab
run('TSE_2D.m')
```

Or generate the gSlider variant:

```matlab
run('TSE_2D_gSlider.m')
```

Run the deterministic MATLAB regression suite:

```bash
matlab -batch "run(fullfile(pwd,'tests','run_ci_tests.m'))"
```

Generated `.seq` and resolved `Setup`/`Actual` files are written under `seq/`. Keep them with the repository commit and submodule SHAs used to generate them.

## Main entry points

| Entry point | Purpose |
| --- | --- |
| [`TSE_2D.m`](TSE_2D.m) | Conventional 2D multi-slice TSE generator. |
| [`TSE_2D_gSlider.m`](TSE_2D_gSlider.m) | gSlider excitation with optional TRAPS refocusing-flip schedule. |
| [`recon/matlab/examples/run_recon_TSE2D.m`](recon/matlab/examples/run_recon_TSE2D.m) | Editable offline reconstruction example for conventional 2D TSE Siemens Twix data. |
| [`recon/matlab/recon_TSE2D.m`](recon/matlab/recon_TSE2D.m) | Programmatic reconstruction entry point for the current Twix workflow. |

The offline reconstruction does **not** implement gSlider decoding.

## Requirements

### Sequence development

- MATLAB with standard numerical and plotting functionality.
- Git submodules: `pulseq/` and `VERSE/`.
- A compatible Pulseq interpreter and scanner-side validation path for the target MR system.

If necessary:

```bash
git submodule update --init --recursive
```

### Current Siemens 7 T implementation and reconstruction path

- `ScannerType='Terra-XJ'` or `'Terra-XR'` in the currently implemented system profiles.
- A compatible Siemens Pulseq interpreter for scanner execution in the validated environment.
- A compatible Siemens `.asc` PNS model when running `check_PNS`.
- [`mapVBVD`](https://github.com/pehses/mapVBVD) on the MATLAB path for Siemens Twix reconstruction.

## Documentation

Full site: **https://bennyzhang-codes.github.io/tse-pulseq-matlab/**

Recommended paths:

- **Understand the method** → [Architecture](https://bennyzhang-codes.github.io/tse-pulseq-matlab/concepts-overview) → [Symbols & notation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/theory/symbols) → [TSE signal and echo-train model](https://bennyzhang-codes.github.io/tse-pulseq-matlab/theory/tse-echo-train) → [Phase encoding & effective TE](https://bennyzhang-codes.github.io/tse-pulseq-matlab/theory/phase-encoding).
- **Generate a sequence** → [Quick start](https://bennyzhang-codes.github.io/tse-pulseq-matlab/quickstart) → [Sequence generation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/sequence-generation) → [Parameter reference](https://bennyzhang-codes.github.io/tse-pulseq-matlab/parameter-reference).
- **Run reconstruction** → [Reconstruction workflow](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction) → [Echo corrections](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections) → [Reconstruction API](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/reconstruction-api).
- **Validate/report results** → [Scientific validation strategy](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation/scientific-validation) → [Reconstruction protocol](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation/reconstruction-protocol) → [Validation & safety](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation-and-safety) → [Performance & benchmarking](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation/performance-benchmarking).
- **Look up code interfaces** → [API overview](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/) → [Sequence API](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/sequence-api) → [Reconstruction API](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/reconstruction-api).

## Documentation development

From the repository root:

```bash
npm install
npm run docs:dev
npm run docs:build
```

The source lives under `docs/`. GitHub Actions builds and deploys the VitePress site; generated Pages output should not be edited manually.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and test expectations, and [SECURITY.md](SECURITY.md) for software-security and scanner-safety reporting boundaries.

## Citation

Use the repository DOI: [10.5281/zenodo.22076863](https://doi.org/10.5281/zenodo.22076863). Citation metadata is available in [CITATION.cff](CITATION.cff).

If you use `TSE_2D_gSlider.m`, also cite:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Program #3256. [Abstract](http://echo.ismrm.org/p/ISMRM2024/3256)

## License

This repository is released under the [MIT License](LICENSE). Pulseq and VERSE are git submodules with their own licenses and attribution notices.
