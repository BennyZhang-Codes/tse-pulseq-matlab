# TSE Pulseq for MATLAB

[![CI](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml) [![Documentation](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/docs.yml/badge.svg?branch=main)](https://bennyzhang-codes.github.io/tse-pulseq-matlab/) [![Coverage](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab/graph/badge.svg?token=JNHD7UK0A3)](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22076863.svg)](https://doi.org/10.5281/zenodo.22076863)

MATLAB/Pulseq tools for developing Cartesian 2D turbo spin echo (TSE) sequences toward **vendor-neutral deployment**, including conventional multi-slice TSE and gSlider-TSE, together with a transparent offline reconstruction workflow for conventional 2D TSE data.

> **Platform status.** Vendor-neutral deployment is the project goal, but the current implementation is still coupled to the Siemens 7 T development path in several places: scanner presets, PI/LIN mapping, interpreter definitions and PNS models. Scanner validation has so far been performed on Siemens 7 T systems, and the bundled offline raw-data reconstruction currently targets Siemens Twix. Other vendors are not yet implemented or validated.

> **Research software.** MATLAB/Pulseq timing checks, PNS estimates, CI results, and offline reconstruction do not replace scanner-side RF/SAR, gradient/PNS, protocol, interpreter, watchdog, or local institutional validation before volunteer or patient scanning.

## Scope

| Layer | Current scope |
| --- | --- |
| Design goal | Vendor-neutral Pulseq development for Cartesian 2D TSE and gSlider-TSE, with configurable RF, timing, PE order, PI/CS sampling, slice ordering and TRAPS schedules. |
| Current sequence implementation | Pulseq-based, but shared prep code currently contains Siemens-specific Terra profiles, PI/LIN mapping and interpreter definitions. |
| Validated scanner path | Siemens 7 T systems only at present. |
| Offline reconstruction | Conventional Cartesian 2D TSE from Siemens Twix data: RSS, diagnostic GRAPPA, ESPIRiT-SENSE, and Cartesian CS. |
| Not currently implemented | Validated non-Siemens scanner paths, offline gSlider decoding, partial Fourier, SMS, non-Cartesian reconstruction and oblique sequence orientation. |

Adding another scanner platform requires code changes for the system/metadata integration layer, a compatible Pulseq interpreter, correct hardware limits and safety models, and a new staged validation campaign. See [Platform Integration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/platform-integration).

## Quick start

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Open MATLAB in the repository root and generate a conventional sequence using the current tested scanner preset:

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
- Git submodules: `pulseq/` and `VERSE/`. If necessary, run `git submodule update --init --recursive`.
- A compatible Pulseq interpreter and scanner-side validation path for the target MR system.

### Current Siemens 7 T implementation and reconstruction path

- `ScannerType='Terra-XJ'` or `'Terra-XR'` in the currently implemented system profiles.
- A compatible Siemens Pulseq interpreter for scanner execution in the validated environment.
- A compatible Siemens `.asc` PNS model when running `check_PNS`.
- [`mapVBVD`](https://github.com/pehses/mapVBVD) on the MATLAB path for Siemens Twix reconstruction.

## Documentation

- [Installation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/installation)
- [Quick start](https://bennyzhang-codes.github.io/tse-pulseq-matlab/quickstart)
- [Sequence generation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/sequence-generation)
- [Parameter reference](https://bennyzhang-codes.github.io/tse-pulseq-matlab/parameter-reference)
- [Platform integration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/platform-integration)
- [Siemens 7 T encoding and ICE integration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/phase-encoding-and-ice)
- [Siemens Twix reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction)
- [Validation and safety](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation-and-safety)
- [Siemens 7 T staged phantom validation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/staged-phantom-validation)
- [Reproducibility and citation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reproducibility)

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and test expectations, and [SECURITY.md](SECURITY.md) for software-security and scanner-safety reporting boundaries.

## Citation

Use the repository DOI: [10.5281/zenodo.22076863](https://doi.org/10.5281/zenodo.22076863). Citation metadata is available in [CITATION.cff](CITATION.cff).

If you use `TSE_2D_gSlider.m`, also cite:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Program #3256. [Abstract](http://echo.ismrm.org/p/ISMRM2024/3256)

## License

This repository is released under the [MIT License](LICENSE). Pulseq and VERSE are git submodules with their own licenses and attribution notices.
