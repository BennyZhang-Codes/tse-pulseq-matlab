---
layout: home

title: TSE Pulseq for MATLAB
titleTemplate: false

description: Vendor-neutral Pulseq development of Cartesian 2D TSE and gSlider-TSE, with explicit platform integration and transparent MATLAB reconstruction.

hero:
  name: TSE Pulseq
  text: Vendor-neutral 2D TSE sequence development
  tagline: A MATLAB/Pulseq framework for Cartesian TSE and gSlider-TSE sequence design, explicit scanner-platform integration, and transparent offline reconstruction. The reusable acquisition model is vendor-neutral in intent; the current scanner validation and bundled raw-data path are Siemens 7 T and Twix specific.
  actions:
    - theme: brand
      text: Get Started
      link: /quickstart
    - theme: alt
      text: Explore Theory
      link: /theory/tse-echo-train
    - theme: alt
      text: Reconstruction
      link: /reconstruction

features:
  - title: Echo-train-aware design
    details: Treat echo ordering, effective TE, refocusing schedules, crushers, and k-space placement as one TSE acquisition model.
    link: /theory/tse-echo-train
  - title: Pulseq sequence generation
    details: Generate conventional 2D TSE and gSlider-TSE from modular MATLAB preparation stages with raster-aware RF, gradients, ADC, labels, and timing.
    link: /sequence-generation
  - title: Transparent reconstruction
    details: Reconstruct Siemens Twix data with prewhitening, navigator phase and magnitude correction, RSS, PE-GRAPPA, ESPIRiT-SENSE, and Cartesian CS.
    link: /reconstruction
  - title: Explicit validation boundary
    details: Separate vendor-neutral acquisition concepts from hardware limits, interpreter metadata, scanner safety checks, and platform-specific validation.
    link: /validation-and-safety
---

::: warning Research software
This repository is intended for research sequence development. A Pulseq sequence that passes software timing, label, or development PNS checks is not automatically safe for human scanning. Scanner-side RF/SAR, gradient/PNS, interpreter, watchdog, protocol, and local institutional checks remain mandatory.
:::

## One acquisition model, explicit implementation layers

The documentation follows the same separation of concerns as the code: first define the TSE acquisition and its echo-to-k-space mapping, then resolve it against a scanner platform, then reconstruct and validate the resulting data.

<div class="home-capabilities">
  <div class="home-capability"><strong>Acquisition model</strong><span>RF · echo train · gradients · ADC · logical $k_y$ order · slice ordering</span></div>
  <div class="home-capability"><strong>Platform integration</strong><span>Hardware limits · interpreter metadata · orientation · scanner safety model</span></div>
  <div class="home-capability"><strong>Reconstruction</strong><span>Noise whitening · echo corrections · Cartesian PI/CS · image export</span></div>
  <div class="home-capability"><strong>Validation</strong><span>Numerical checks · phantom studies · scanner-side acceptance and safety</span></div>
</div>

For a receive channel $c$ and an echo $e$ assigned to phase-encoding location $k_y$, a useful abstraction of the acquired TSE signal is

$$
y_{e,c}(k_x,k_y)
=
\int_{\Omega}
m(\mathbf r)\,C_c(\mathbf r)\,E_e(\mathbf r)
\exp\!\left[-i2\pi\left(k_xx+k_yy\right)\right]
\,d\mathbf r,
$$

where $m(\mathbf r)$ is the underlying object, $C_c(\mathbf r)$ is the receive sensitivity, and $E_e(\mathbf r)$ represents echo-dependent amplitude and phase. The phase-encoding schedule determines the mapping $e\mapsto k_y$, so echo-train modulation and k-space ordering jointly determine contrast and the phase-encoding point-spread function.

The repository does **not** treat every layer as vendor-neutral. The Pulseq acquisition concepts are intended to be portable, whereas the currently implemented hardware presets, Siemens LIN/ICE metadata, scanner validation, and Twix reader are explicit platform-specific components. See [Architecture](/concepts-overview) for the complete boundary.

## Suggested reading order

Start with **[Quick Start](/quickstart)** for a minimal conventional 2D TSE run. Continue with the **[architecture overview](/concepts-overview)** and **[TSE echo-train model](/theory/tse-echo-train)** before changing phase encoding, effective TE, or refocusing schedules. Use **[Sequence Generation](/sequence-generation)** and the **[Parameter Reference](/parameter-reference)** for implementation details. For raw data, follow the **[reconstruction workflow](/reconstruction)** and the dedicated **[echo-correction](/guide/echo-corrections)** page. Interpret all scanner results through **[Platform Integration](/platform-integration)** and **[Validation & Safety](/validation-and-safety)**.
