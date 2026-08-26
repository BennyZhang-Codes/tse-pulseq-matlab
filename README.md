# TSE Pulseq for MATLAB

[![CI](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml) [![Documentation](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/docs.yml/badge.svg?branch=main)](https://bennyzhang-codes.github.io/tse-pulseq-matlab/) [![Coverage](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab/graph/badge.svg?token=JNHD7UK0A3)](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22076863.svg)](https://doi.org/10.5281/zenodo.22076863)

MATLAB/Pulseq research software for **Cartesian 2D turbo spin echo (TSE)** sequence development, including conventional multi-slice TSE and gSlider-TSE, together with an offline MATLAB reconstruction workflow for conventional 2D TSE data.

The project is documented as an **open-source sequence implementation**: sequence configuration and construction → RF/phase-encoding/acceleration implementation → platform integration → raw-data reconstruction → optional corrections/post-processing → validation/safety → method/code provenance.

> **Current testing.** Scanner development and testing to date have used Siemens 7 T systems, and the maintained offline raw-data reader currently uses Siemens Twix. These are current implementation/testing boundaries, not the intended public abstraction of the sequence.

> **Research software.** Pulseq timing checks, optional PNS prediction, CI results, and offline reconstruction do not replace scanner-side RF/SAR, gradient/PNS, interpreter/watchdog, protocol, or local institutional validation before volunteer or patient scanning.

## Scope

| Layer | Current scope |
| --- | --- |
| Sequence | Cartesian 2D TSE and gSlider-TSE with configurable RF, timing, PE order, PI/CS sampling, slice ordering, and TRAPS-style schedules. |
| Portability goal | Keep the Pulseq acquisition definition independent of scanner-vendor metadata as far as practical. |
| Reconstruction | Conventional Cartesian 2D TSE: RSS, GRAPPA, SENSE, and CS, with ESPIRiT sensitivity estimation. |
| Optional processing | Navigator echo-magnitude correction and image-domain denoising are available but are not mandatory/default reconstruction definitions. |
| Current missing features | gSlider decoding, partial Fourier, SMS, non-Cartesian reconstruction, multiple ESPIRiT map sets, vendor-independent raw-data input, and fully decoupled platform integration. |

Implementation limits are documented under [Reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction) and the public [TO DO & implementation checklist](https://bennyzhang-codes.github.io/tse-pulseq-matlab/todo).

## Quick start

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Generate a conventional sequence:

```matlab
run('TSE_2D.m')
```

Generate the gSlider variant:

```matlab
run('TSE_2D_gSlider.m')
```

Run the deterministic MATLAB regression suite:

```bash
matlab -batch "run(fullfile(pwd,'tests','run_ci_tests.m'))"
```

Generated `.seq` and resolved `Setup`/`Actual` files are written under `seq/`.

## Main entry points

| Entry point | Purpose |
| --- | --- |
| [`TSE_2D.m`](TSE_2D.m) | Conventional 2D multi-slice TSE generator. |
| [`TSE_2D_gSlider.m`](TSE_2D_gSlider.m) | gSlider excitation with optional TRAPS-style refocusing schedule. |
| [`recon/matlab/examples/run_recon_TSE2D.m`](recon/matlab/examples/run_recon_TSE2D.m) | Editable offline reconstruction example for conventional 2D TSE raw data supported by the current reader. |
| [`recon/matlab/recon_TSE2D.m`](recon/matlab/recon_TSE2D.m) | Programmatic reconstruction entry point. |

The bundled reconstruction does **not** currently implement gSlider decoding.

## External methods, tools, and provenance

The repository records both scientific method references and concrete software/code provenance where relevant. Important examples include:

- **Pulseq** — tracked as the `pulseq/` Git submodule.
- **PNS prediction** — the current `check_PNS` path calls Pulseq `Sequence.calcPNS`, whose tracked implementation uses external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) plus target-system hardware parameters. This is a platform-dependent development feature; making it an optional dependency is tracked in the TO DO list.
- **CS sampling** — Lustig SparseMRI-derived one-dimensional variable-density PE sampling with Monte-Carlo interference minimization.
- **SLR and gSlider RF banks** — generated offline with SigPy RF and stored as `.mat` pulse banks.
- **VERSE** — provided through the `VERSE/` Git submodule with upstream lineage documented there.
- **Twix reading** — the current offline reader uses external [`mapVBVD`](https://github.com/pehses/mapVBVD).
- **BM3D / CAT12 SANLM** — optional third-party denoisers and intentionally not vendored.

See **[Dependencies & Method Provenance](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/provenance)** and **[Literature References](https://bennyzhang-codes.github.io/tse-pulseq-matlab/references)**.

## Requirements

### Sequence development

- MATLAB with standard numerical and plotting functionality.
- Git submodules: `pulseq/` and `VERSE/`.
- A compatible Pulseq interpreter and target-platform validation path for scanner execution.

```bash
git submodule update --init --recursive
```

The bundled SLR/gSlider `.mat` RF pulse banks can be used without Python/SigPy at MATLAB runtime. SigPy is needed only when regenerating them.

### Optional / platform-specific dependencies

- [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) plus a target-system hardware model for the current PNS-prediction path.
- [`mapVBVD`](https://github.com/pehses/mapVBVD) for the maintained Siemens Twix raw-data reader.
- MATLAB GPU support for optional GPU execution of SENSE/CS.
- BM3D/CAT12 only when those optional denoisers are used.

Scanner-specific hardware-model files are not distributed by this repository.

## Documentation

Full site: **https://bennyzhang-codes.github.io/tse-pulseq-matlab/**

Recommended paths:

- **Start / generate sequence** → [Quick Start](https://bennyzhang-codes.github.io/tse-pulseq-matlab/quickstart) → [Sequence Implementation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/sequence-generation).
- **Understand PE/PI/CS** → [Phase Encoding & Acceleration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/theory/phase-encoding).
- **Reconstruct data** → [Reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction).
- **Check open work / missing features** → [TO DO & implementation checklist](https://bennyzhang-codes.github.io/tse-pulseq-matlab/todo).
- **Check origin/citations** → [Dependencies & Method Provenance](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/provenance) → [Literature References](https://bennyzhang-codes.github.io/tse-pulseq-matlab/references).
- **Validation** → [Validation Strategy](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation/scientific-validation) → [Validation & Safety](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation-and-safety).

## Optional reconstruction processing

`EchoMagnitudeCorrection` is available but disabled by default. NLM, BM3D, SANLM, and TGV2 are separate optional image-domain post-processing tools and are not invoked automatically by `recon_TSE2D`.

See [Optional Echo Correction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections) and [Optional Denoising](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising).

## Documentation development

```bash
npm install
npm run docs:dev
npm run docs:build
```

GitHub Actions builds and deploys the VitePress site; generated Pages output should not be edited manually.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## Citation

Use the repository DOI: [10.5281/zenodo.22076863](https://doi.org/10.5281/zenodo.22076863). Citation metadata is available in [CITATION.cff](CITATION.cff).

If you use `TSE_2D_gSlider.m`, also cite:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Program #3256. [Abstract](http://echo.ismrm.org/p/ISMRM2024/3256)

Also cite the scientific methods actually used in the reported acquisition/reconstruction as listed in the documentation.

## License

This repository is released under the [MIT License](LICENSE). Pulseq and VERSE are Git submodules with their own licenses and attribution notices; external dependencies remain under their upstream licenses.
