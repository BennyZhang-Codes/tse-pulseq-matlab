---
layout: home

title: TSE Pulseq for MATLAB
titleTemplate: false

description: Open-source Cartesian 2D TSE and gSlider-TSE sequence implementation in MATLAB/Pulseq with companion offline reconstruction.

hero:
  name: TSE Pulseq
  text: Open-source 2D TSE sequences with Pulseq
  tagline: Generate conventional Cartesian 2D TSE and gSlider-TSE sequences, configure RF and phase encoding, and reconstruct conventional 2D TSE raw data with the companion MATLAB pipeline.
  actions:
    - theme: brand
      text: Quick Start
      link: /quickstart
    - theme: alt
      text: Sequence
      link: /sequence-generation
    - theme: alt
      text: Reconstruction
      link: /reconstruction

features:
  - title: TSE sequence generation
    details: Conventional multi-slice Cartesian 2D TSE with configurable timing, RF, slice ordering and phase encoding.
    link: /sequence-generation
  - title: gSlider-TSE
    details: gSlider RF-encoded TSE acquisition with bundled RF pulse banks.
    link: /guide/gslider-tse
  - title: PI and CS sampling
    details: Parallel-imaging PE patterns and variable-density compressed-sensing PE sampling.
    link: /theory/phase-encoding
  - title: MATLAB reconstruction
    details: Prewhitening, navigator phase correction, RSS, GRAPPA, SENSE and CS with ESPIRiT sensitivity estimation.
    link: /reconstruction
---

## What is this package?

`tse-pulseq-matlab` is an open-source MATLAB/Pulseq implementation of **Cartesian 2D turbo spin echo (TSE)** acquisition. It provides two sequence entry points:

```text
TSE_2D.m          conventional multi-slice 2D TSE
TSE_2D_gSlider.m  gSlider-TSE
```

The repository also includes a companion MATLAB reconstruction for conventional Cartesian 2D TSE data.

## Supported features

| Area | Available functionality |
| --- | --- |
| Sequence | conventional 2D TSE, gSlider-TSE, inversion recovery, multi-slice acquisition |
| Phase encoding | Linear, CentricFull, CentricHalf; PI and CS sampling |
| RF | sinc, SLR pulse banks, gSlider pulse banks, optional VERSE |
| Sequence checks | Pulseq timing, labels, sequence/k-space plots; PNS prediction path when its external inputs are available |
| Reconstruction | RSS, GRAPPA, SENSE, CS; ESPIRiT sensitivity estimation; coil compression |
| Preprocessing | noise prewhitening and navigator phase correction |
| Optional processing | navigator-derived echo magnitude correction; NLM, BM3D, SANLM and TGV2 denoising |
| Output | reconstructed images and NIfTI export in the maintained MATLAB workflow |

Detailed implementation and scientific/code provenance are documented in [Sequence Implementation](/sequence-generation), [Reconstruction](/reconstruction), and [Dependencies & Method Provenance](/reference/provenance).

## Start using it

Clone the repository with its submodules:

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Generate a conventional sequence:

```matlab
run('TSE_2D.m')
```

Generate gSlider-TSE:

```matlab
run('TSE_2D_gSlider.m')
```

See [Quick Start](/quickstart) for the main configuration and reconstruction example.

## Current notes

- Scanner development/testing to date has used Siemens 7 T systems. The sequence itself is described with Pulseq; scanner execution requires a compatible interpreter and target-system validation.
- The maintained offline raw-data reader currently uses Siemens Twix through `mapVBVD`.
- Offline gSlider decoding is not yet implemented.
- The current PNS-check path requires external `safe_pns_prediction` and a target-system hardware model; making this check cleanly optional is listed in [TO DO](/todo).

::: warning Research use
A generated `.seq` file is not by itself evidence of scanner safety. Use the target scanner's RF/SAR, gradient/PNS, interpreter/watchdog and local safety procedures before in-vivo scanning. See [Validation & Safety](/validation-and-safety).
:::

## Documentation

- **Use the package:** [Quick Start](/quickstart) · [Installation](/installation) · [Parameter Reference](/parameter-reference)
- **Understand the sequence:** [Sequence Implementation](/sequence-generation) · [TSE Echo Train](/theory/tse-echo-train) · [Phase Encoding & Acceleration](/theory/phase-encoding) · [gSlider-TSE](/guide/gslider-tse)
- **Reconstruct data:** [Reconstruction](/reconstruction) · [Optional Echo Correction](/guide/echo-corrections) · [Optional Denoising](/guide/denoising)
- **Source and citations:** [Dependencies & Method Provenance](/reference/provenance) · [References](/references)
