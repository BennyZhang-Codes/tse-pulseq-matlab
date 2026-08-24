# TSE Pulseq for MATLAB

**TSE Pulseq for MATLAB** is a research-oriented MATLAB toolkit for Siemens-targeted Cartesian 2D turbo spin echo (TSE) sequence generation with Pulseq, together with a transparent offline reconstruction workflow for conventional 2D TSE Siemens Twix data.

The repository includes:

- conventional multi-slice 2D TSE sequence generation;
- gSlider-TSE sequence generation with optional TRAPS refocusing schedules;
- configurable phase-encoding order, PI and Cartesian CS sampling;
- inversion recovery and multi-slice ordering controls;
- raster-constrained gradient, crusher and spoiler design;
- Siemens-oriented sequence definitions for PE, ACS and TSE phase-correction metadata;
- timing, label and PNS development checks; and
- offline RSS, diagnostic PE-GRAPPA, ESPIRiT-SENSE and TV/Haar-regularized CS reconstruction for conventional 2D TSE.

!!! warning "Research use only"
    This repository is research code. Pulseq timing checks, PNS prediction and software-side validation do **not** replace scanner-side safety checks, RF/SAR review, protocol validation, gradient-watchdog checks, local approvals, or staged phantom testing before volunteer or patient imaging.

## Start here

If you are new to the repository, follow this order:

1. [Installation](installation.md) — clone the repository with submodules and configure MATLAB dependencies.
2. [Quick start](quickstart.md) — generate a conventional TSE or gSlider sequence and run a first offline reconstruction.
3. [Sequence generation](sequence-generation.md) — understand `Setup`, `SetupRF`, `SetupSpoiling`, timing and exported files.
4. [Phase encoding and Siemens ICE metadata](phase-encoding-and-ice.md) — understand PI/CS boundaries, LIN conventions, ACS metadata and online phase-correction requirements.
5. [Reconstruction](reconstruction.md) — understand the Twix-to-image pipeline and the supported reconstruction methods.
6. [Validation and safety](validation-and-safety.md) — review what the software checks and what must still be verified on the scanner.
7. [Reproducibility and citation](reproducibility.md) — record releases, commit/submodule SHAs, sequence parameters and citation metadata.
8. [Developer guide](developer-guide.md) — repository architecture, contribution rules and documentation workflow.

## Main entry points

| Entry point | Purpose |
| --- | --- |
| `TSE_2D.m` | Conventional Cartesian 2D multi-slice TSE sequence generator. |
| `TSE_2D_gSlider.m` | gSlider-TSE sequence generator with optional TRAPS refocusing-flip schedules. |
| `recon/matlab/examples/run_recon_TSE2D.m` | Editable routine-use reconstruction example. |
| `recon/matlab/examples/run_recon_TSE2D_iterative.m` | Matched iterative SENSE/CS reconstruction example. |
| `recon/matlab/recon_TSE2D.m` | Programmatic offline reconstruction API. |

## Current scope

The maintained sequence generators target **non-oblique Cartesian 2D TSE**. The offline MATLAB reconstruction supports **conventional Cartesian 2D TSE only**. In particular, offline gSlider decoding is not yet implemented.

The reconstruction path is intended for transparent research reconstruction, sequence debugging, phantom validation and controlled A/B comparisons. It does not claim pixel-for-pixel equivalence with Siemens ICE, whose raw-data scaling, coil compression/combination, GRAPPA implementation, filtering and intensity normalization may differ.

## Documentation site

This site is built with MkDocs and deployed through GitHub Pages. Once GitHub Pages is enabled with **GitHub Actions** as the publishing source, pushes to `main` that modify the documentation will automatically rebuild and deploy the public site.

Default GitHub Pages URL after enablement:

`https://bennyzhang-codes.github.io/tse-pulseq-matlab/`

## License and citation

The software is distributed under the MIT License. See [Reproducibility and citation](reproducibility.md) for software citation, release pinning, Zenodo guidance and the gSlider-TSE reference.
