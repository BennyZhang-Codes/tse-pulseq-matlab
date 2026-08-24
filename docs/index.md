---
layout: home

hero:
  name: TSE Pulseq for MATLAB
  text: Cartesian 2D TSE sequence design and transparent offline reconstruction
  tagline: Research-oriented MATLAB tools for Siemens-targeted Pulseq TSE, gSlider-TSE, PI/CS sampling, validation helpers, and conventional 2D TSE reconstruction.
  actions:
    - theme: brand
      text: Get Started
      link: /quickstart
    - theme: alt
      text: Installation
      link: /installation
    - theme: alt
      text: View on GitHub
      link: https://github.com/BennyZhang-Codes/tse-pulseq-matlab

features:
  - icon: 🧲
    title: Pulseq TSE Generation
    details: Generate conventional multi-slice 2D TSE and gSlider-TSE sequences with configurable timing, RF, slice ordering, inversion recovery and TRAPS schedules.
    link: /sequence-generation
  - icon: 🧭
    title: Siemens-aware Encoding Metadata
    details: Explicit PI/CS boundaries, Siemens LIN and ACS conventions, phase-correction definitions, slice metadata and interpreter-facing sequence definitions.
    link: /phase-encoding-and-ice
  - icon: 🧮
    title: Transparent Reconstruction
    details: Offline RSS, diagnostic PE-GRAPPA, ESPIRiT-SENSE and TV/Haar-regularized CS for conventional Cartesian 2D TSE Twix data.
    link: /reconstruction
  - icon: 🛡️
    title: Validation First
    details: Timing, labels, PNS development checks and reproducibility guidance, with explicit separation between software validation and scanner-side safety review.
    link: /validation-and-safety
---

## Overview

**TSE Pulseq for MATLAB** is a research-oriented MATLAB toolkit for Siemens-targeted Cartesian 2D turbo spin echo (TSE) sequence generation with Pulseq, together with a transparent offline reconstruction workflow for conventional 2D TSE Siemens Twix data.

The repository includes conventional and gSlider sequence generators, configurable phase-encoding order and acceleration, raster-constrained gradient design, sequence validation helpers, and modular reconstruction tools intended for research development and controlled validation.

::: warning Research use only
This repository is research code. Pulseq timing checks, PNS prediction and software-side validation do **not** replace scanner-side safety checks, RF/SAR review, protocol validation, gradient-watchdog checks, local approvals, or staged phantom testing before volunteer or patient imaging.
:::

## Main entry points

| Entry point | Purpose |
| --- | --- |
| `TSE_2D.m` | Conventional Cartesian 2D multi-slice TSE sequence generator. |
| `TSE_2D_gSlider.m` | gSlider-TSE sequence generator with optional TRAPS refocusing-flip schedules. |
| `recon/matlab/examples/run_recon_TSE2D.m` | Editable routine-use reconstruction example. |
| `recon/matlab/examples/run_recon_TSE2D_iterative.m` | Matched iterative SENSE/CS reconstruction example. |
| `recon/matlab/recon_TSE2D.m` | Programmatic offline reconstruction API. |

## Current scope

The maintained sequence generators target **non-oblique Cartesian 2D TSE**. The offline MATLAB reconstruction supports **conventional Cartesian 2D TSE only**; offline gSlider decoding is not yet implemented.

The reconstruction path is intended for transparent research reconstruction, sequence debugging, phantom validation and controlled A/B comparisons. It does not claim pixel-for-pixel equivalence with Siemens ICE, whose raw-data scaling, coil compression/combination, GRAPPA implementation, filtering and intensity normalization may differ.

## Citation and reproducibility

For published work, pin a release or exact commit and record the submodule SHAs, sequence configuration and scanner-side protocol settings. See [Reproducibility & Citation](reproducibility.md) for the recommended workflow.
