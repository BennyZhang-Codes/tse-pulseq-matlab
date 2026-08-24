# TSE Pulseq for MATLAB

[![MATLAB CI](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml) [![Documentation](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/docs.yml/badge.svg?branch=main)](https://bennyzhang-codes.github.io/tse-pulseq-matlab/) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22076863.svg)](https://doi.org/10.5281/zenodo.22076863)

Siemens-targeted MATLAB tools for Cartesian 2D turbo spin echo (TSE) Pulseq sequence generation and controlled offline reconstruction of conventional 2D TSE Twix data.

> **Research software.** MATLAB/Pulseq timing checks, PNS estimates, CI results, and offline reconstruction do not replace scanner-side RF/SAR, gradient/PNS, protocol, interpreter, watchdog, or local institutional validation before volunteer or patient scanning.

## Highlights

- Conventional 2D TSE and gSlider-TSE sequence generation, with optional TRAPS refocusing-flip schedules.
- Configurable phase-encoding order, PI/ACS metadata, and CS acquisition paths.
- Offline conventional 2D TSE RSS, GRAPPA, ESPIRiT-SENSE, and Cartesian CS reconstruction.
- Raster-constrained gradient design and regression tests for Siemens LIN and reconstruction-critical conventions.

## Quick start

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Open MATLAB in the repository root, then generate a conventional sequence:

```matlab
run('TSE_2D.m')
```

Run the deterministic MATLAB regression suite:

```bash
matlab -batch "run(fullfile(pwd,'tests','run_ci_tests.m'))"
```

Generated `.seq` and resolved `Setup`/`Actual` files are written under `seq/`. Keep them with the repository commit and submodule SHAs used to generate them.

## Start here

| Task | Entry point |
| --- | --- |
| Generate conventional 2D TSE | [`TSE_2D.m`](TSE_2D.m) |
| Generate gSlider-TSE | [`TSE_2D_gSlider.m`](TSE_2D_gSlider.m) |
| Reconstruct conventional 2D TSE Twix data | [`run_recon_TSE2D.m`](recon/matlab/examples/run_recon_TSE2D.m) |
| Validate a 7 T phantom experiment | [Staged phantom validation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/staged-phantom-validation) |

The offline reconstruction does **not** implement gSlider decoding.

## Tested compatibility

| Component | Status |
| --- | --- |
| MATLAB CI | R2024b on GitHub-hosted Ubuntu |
| Pulseq | v1.5.1 submodule |
| VERSE | Public MIT-licensed submodule with third-party attribution |
| Scanner configuration | `Terra-XJ` and `Terra-XR` PNS-model mappings |
| Scanner execution / online ICE | Compatible external Siemens Pulseq interpreter and matched scanner protocol required |

## Current limitations

Offline gSlider decoding, partial Fourier, simultaneous multi-slice, non-Cartesian reconstruction, and oblique sequence orientation are not implemented. PI and CS use separate sampling and label conventions; do not use CS definitions for online ICE GRAPPA.

## Requirements

- MATLAB with plotting support.
- Git submodules: `pulseq/` and `VERSE/`. If necessary, run `git submodule update --init --recursive`.
- A compatible Siemens `.asc` PNS model when running `check_PNS`.
- [`mapVBVD`](https://github.com/pehses/mapVBVD) on the MATLAB path for Twix reconstruction.

## Documentation

- [Installation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/installation)
- [Sequence generation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/sequence-generation)
- [Parameter reference](https://bennyzhang-codes.github.io/tse-pulseq-matlab/parameter-reference)
- [Phase encoding and Siemens ICE metadata](https://bennyzhang-codes.github.io/tse-pulseq-matlab/phase-encoding-and-ice)
- [Offline reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction)
- [Validation and safety](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation-and-safety)
- [Reproducibility and citation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reproducibility)

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and test expectations, and [SECURITY.md](SECURITY.md) for software-security and scanner-safety reporting boundaries.

## Citation

Use the repository DOI: [10.5281/zenodo.22076863](https://doi.org/10.5281/zenodo.22076863). Citation metadata is available in [CITATION.cff](CITATION.cff).

If you use `TSE_2D_gSlider.m`, also cite:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Program #3256. [Abstract](http://echo.ismrm.org/p/ISMRM2024/3256)

## License

This repository is released under the [MIT License](LICENSE). Pulseq and VERSE are git submodules with their own licenses and attribution notices.