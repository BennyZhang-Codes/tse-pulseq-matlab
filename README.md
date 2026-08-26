# TSE Pulseq for MATLAB

[![CI](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml) [![Documentation](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/docs.yml/badge.svg?branch=main)](https://bennyzhang-codes.github.io/tse-pulseq-matlab/) [![Coverage](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab/graph/badge.svg?token=JNHD7UK0A3)](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22076863.svg)](https://doi.org/10.5281/zenodo.22076863)

MATLAB/Pulseq research software for **Cartesian 2D turbo spin echo (TSE)** sequence development, including conventional multi-slice TSE and gSlider-TSE, together with a transparent offline MATLAB reconstruction workflow for conventional 2D TSE data.

The documentation is organized around the needs of an **open-source sequence implementation**: configuration and sequence construction → RF/phase-encoding/acceleration implementation → scanner integration → raw-data reconstruction → optional corrections/post-processing → validation/safety → source and method provenance.

> **Platform status.** Vendor-neutral deployment is a project goal, but the current implementation remains coupled to the Siemens 7 T development path in scanner presets, PI/LIN mapping, interpreter definitions, and PNS models. Scanner validation has so far been performed on Siemens 7 T systems, and the bundled offline raw-data reconstruction currently targets Siemens Twix. Other vendors are not yet implemented or validated.

> **Research software.** MATLAB/Pulseq timing checks, PNS estimates, CI results, and offline reconstruction do not replace scanner-side RF/SAR, gradient/PNS, protocol, interpreter, watchdog, or local institutional validation before volunteer or patient scanning.

## Scope

| Layer | Current scope |
| --- | --- |
| Design goal | Portable Pulseq development for Cartesian 2D TSE and gSlider-TSE with configurable RF, timing, PE order, PI/CS sampling, slice ordering, and TRAPS-style schedules. |
| Current sequence implementation | Pulseq-based, with Siemens-specific Terra profiles, PI/LIN mapping, interpreter definitions, and development PNS models still present in shared code. |
| Validated scanner path | Siemens 7 T systems only at present. |
| Offline reconstruction | Conventional Cartesian 2D TSE from Siemens Twix: RSS, 1D PE-GRAPPA, ESPIRiT-SENSE, and Cartesian CS, with optional navigator echo-magnitude correction and optional image-domain denoising. |
| Not currently implemented | Validated non-Siemens scanner paths, offline gSlider decoding, partial Fourier, SMS, non-Cartesian reconstruction, and oblique sequence orientation. |

The bundled GRAPPA implementation is a **regular Cartesian 1D PE-GRAPPA** path. It supports integer PE acceleration, calibration from a contiguous ACS region, regularized kernel fitting, optional readout-neighbor offsets, and preservation of acquired image/ACS rows. It does **not** implement partial-Fourier GRAPPA, SMS/slice-GRAPPA, non-Cartesian GRAPPA, irregular variable-density masks, or proprietary Siemens ICE kernel/scaling/filtering behavior.

Adding another scanner platform requires a compatible Pulseq interpreter, correct hardware/safety models, platform metadata integration, and a new staged validation campaign. See [Platform Integration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/platform-integration).

## Quick start

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Open MATLAB in the repository root and generate a conventional sequence:

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
| [`TSE_2D_gSlider.m`](TSE_2D_gSlider.m) | gSlider excitation with optional TRAPS-style refocusing schedule. |
| [`recon/matlab/examples/run_recon_TSE2D.m`](recon/matlab/examples/run_recon_TSE2D.m) | Editable offline reconstruction example for conventional 2D TSE Siemens Twix data. |
| [`recon/matlab/recon_TSE2D.m`](recon/matlab/recon_TSE2D.m) | Programmatic reconstruction entry point for the current Twix workflow. |

The offline reconstruction does **not** implement gSlider decoding.

## External methods, tools, and provenance

The repository intentionally records both the scientific method and the concrete code/tool source where relevant. Important examples include:

- **Pulseq** — tracked as the `pulseq/` Git submodule; sequence construction uses the Pulseq MATLAB API.
- **CS phase-encoding sampling** — `prep/CS/genPDF.m` and `genSampling.m` retain `(c) Michael Lustig 2007`; `genSampling_TSE.m` is the TSE-oriented adaptation. The implemented pattern is one-dimensional polynomial variable-density PE sampling with Monte-Carlo interference minimization, not Poisson-disc sampling.
- **SLR and gSlider RF banks** — generated offline by `prep/pulse/RF_pulse.ipynb` using `sigpy.mri.rf` and stored as `.mat` pulse banks for MATLAB use.
- **VERSE** — provided through the `VERSE/` Git submodule, whose repository documents its upstream code lineage.
- **Twix reading** — current offline reconstruction uses external [`mapVBVD`](https://github.com/pehses/mapVBVD).
- **BM3D / CAT12 SANLM** — optional third-party denoisers and intentionally not vendored.

The full file-by-file mapping between feature, implementation source, upstream software and scientific citation is in **[Dependencies & Method Provenance](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/provenance)**. The numbered bibliography is in **[Literature References](https://bennyzhang-codes.github.io/tse-pulseq-matlab/references)**.

## Requirements

### Sequence development

- MATLAB with standard numerical and plotting functionality.
- Git submodules: `pulseq/` and `VERSE/`.
- A compatible Pulseq interpreter and scanner-side validation path for the target MR system.

If necessary:

```bash
git submodule update --init --recursive
```

The bundled SLR/gSlider `.mat` RF pulse banks can be used without Python/SigPy at MATLAB runtime. SigPy is required only when regenerating those pulse banks through `prep/pulse/RF_pulse.ipynb`.

### Current Siemens 7 T implementation and reconstruction path

- `ScannerType='Terra-XJ'` or `'Terra-XR'` in the currently implemented system profiles.
- A compatible Siemens Pulseq interpreter for scanner execution in the validated environment.
- A compatible Siemens `.asc` PNS model when running `check_PNS`.
- [`mapVBVD`](https://github.com/pehses/mapVBVD) on the MATLAB path for Siemens Twix reconstruction.

## Documentation

Full site: **https://bennyzhang-codes.github.io/tse-pulseq-matlab/**

Recommended paths:

- **Generate or modify the acquisition** → [Quick Start](https://bennyzhang-codes.github.io/tse-pulseq-matlab/quickstart) → [Sequence Implementation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/sequence-generation) → [Phase Encoding & Acceleration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/theory/phase-encoding) → [Parameter Reference](https://bennyzhang-codes.github.io/tse-pulseq-matlab/parameter-reference).
- **Work on gSlider / variable refocusing** → [gSlider-TSE & TRAPS](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/gslider-traps).
- **Run or understand reconstruction** → [Reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction) → [Optional Echo Correction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections) → [Optional Denoising](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising).
- **Check method/code origin** → [Dependencies & Method Provenance](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/provenance) → [Literature References](https://bennyzhang-codes.github.io/tse-pulseq-matlab/references).
- **Validate or report results** → [Validation Strategy](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation/scientific-validation) → [Reconstruction Protocol](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation/reconstruction-protocol) → [Validation & Safety](https://bennyzhang-codes.github.io/tse-pulseq-matlab/validation-and-safety).

## Optional reconstruction processing

`EchoMagnitudeCorrection` is available but disabled by default. It is a navigator-derived global echo-envelope equalization option with its MRI literature basis documented on the [Echo Correction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/echo-corrections) page.

NLM, BM3D, SANLM and TGV2 are separate optional image-domain post-processing tools. `recon_TSE2D` does not invoke them automatically. See [Optional Denoising](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/denoising).

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

Also cite the scientific methods actually used in the reported acquisition/reconstruction (for example Pulseq, SLR/gSlider, GRAPPA/SENSE/ESPIRiT/CS, optional echo equalization, or denoising) as listed in the documentation.

## License

This repository is released under the [MIT License](LICENSE). Pulseq and VERSE are Git submodules with their own licenses and attribution notices; optional third-party denoisers remain under their upstream licenses.
