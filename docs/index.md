---
layout: home

title: TSE Pulseq for MATLAB
titleTemplate: false

description: Research documentation for Cartesian 2D TSE and gSlider-TSE sequence development with Pulseq, explicit platform integration, and transparent MATLAB reconstruction.

hero:
  name: TSE Pulseq
  text: Research documentation for 2D TSE with Pulseq
  tagline: Physics-first documentation for Cartesian TSE and gSlider-TSE sequence design, echo-to-k-space encoding, scanner integration, offline MATLAB reconstruction, and scientific validation. The acquisition architecture is intended to be portable; the current scanner validation and bundled raw-data reconstruction are Siemens 7 T / Twix specific.
  actions:
    - theme: brand
      text: Quick Start
      link: /quickstart
    - theme: alt
      text: Signal Model
      link: /theory/tse-echo-train
    - theme: alt
      text: Validation Strategy
      link: /validation/scientific-validation

features:
  - title: Physics before implementation
    details: Start from the continuous TSE signal, echo-dependent encoding, discrete formulation, and matrix model before reading MATLAB implementation details.
    link: /theory/tse-echo-train
  - title: Explicit numerical model
    details: Separate the physical echo-train model from the corrected Cartesian PFS operator used by the current SENSE and CS reconstruction paths.
    link: /reconstruction
  - title: Layered validation
    details: Distinguish implementation consistency, approximation accuracy, independent numerical validation, and physical scanner evidence.
    link: /validation/scientific-validation
  - title: Reproducible reference
    details: Keep parameter conventions, frozen reconstruction protocol, API/source links, citations, and platform boundaries inspectable.
    link: /reference/
---

::: warning Research software
This repository is intended for research sequence development. Passing Pulseq timing, labels, development PNS checks, or documentation CI does **not** establish human-scan safety. Scanner-side RF/SAR, gradient/PNS, interpreter, watchdog, protocol, and local institutional checks remain mandatory.
:::

## Documentation philosophy

The site is organized as a **Methods companion** rather than a software landing page. The preferred scientific reading order is

```text
physical signal model
→ discrete echo / sample / coil formulation
→ matrix encoding
→ explicit sequence implementation
→ reconstruction model
→ scientific validation
→ performance
→ API / troubleshooting
```

The sequence-specific implementation layer is kept visible because this repository develops an acquisition, not only a reconstruction library. At the same time, Theory, workflow, validation evidence, performance, and API lookup are kept as separate documentation responsibilities.

## One acquisition, several implementation layers

For receive channel $c$, echo $e$, and ADC sample $j$, a discrete TSE model can be written as

$$
y_{e,j,c}
\approx
\sum_v
m_v C_{v,c} E_{e,v}
\exp\!\left[-i2\pi(k_{x,e,j}x_v+k_{y,e}y_v)\right]\Delta V
+\varepsilon_{e,j,c}.
$$

The sequence generator controls the mapping $e\mapsto k_{y,e}$ together with RF/gradient timing. The offline reconstruction then estimates measured echo corrections and currently solves a corrected Cartesian model

$$
A=PFS
$$

for SENSE/CS. These are related layers, but they are not the same mathematical object. See [TSE signal and echo-train model](/theory/tse-echo-train).

## Reading paths

<div class="reading-paths">
  <a class="reading-path" href="./theory/tse-echo-train">
    <strong>Understand the method</strong>
    <span>Architecture → Symbols → Signal model → Phase encoding → gSlider/TRAPS</span>
  </a>
  <a class="reading-path" href="./reconstruction">
    <strong>Run a reconstruction</strong>
    <span>Quick Start → Reconstruction workflow → Echo corrections → Reconstruction API</span>
  </a>
  <a class="reading-path" href="./validation/scientific-validation">
    <strong>Validate or report results</strong>
    <span>Scientific validation → Reconstruction protocol → Scanner safety → Performance</span>
  </a>
  <a class="reading-path" href="./reference/">
    <strong>Look up an interface</strong>
    <span>Parameter reference → Sequence API → Reconstruction API → Literature</span>
  </a>
</div>

## Scope and portability boundary

| Layer | Portable scientific concept | Current implementation boundary |
| --- | --- | --- |
| TSE acquisition | RF echo train, Cartesian encoding, echo-to-$k_y$ mapping | Current scanner presets and metadata include Siemens 7 T specifics |
| Pulseq sequence | Vendor-independent `.seq` description | Requires a compatible target-platform interpreter and validation |
| Online integration | Platform/interpreter dependent | Current documented LIN/ICE integration is Siemens oriented |
| Offline reconstruction | Cartesian multicoil reconstruction concepts are general | Bundled reader currently consumes Siemens Twix via mapVBVD |
| gSlider | Acquisition is implemented | Offline gSlider decoding is not implemented |
| Validation | Evidence should be layered and reproducible | Current scanner-validation boundary is Siemens 7 T |

The project therefore uses **vendor-neutral as a design goal**, not as a claim that every current source file and raw-data path is already vendor independent.

## Documentation map

| Section | Primary question |
| --- | --- |
| **Getting Started** | How do I install, generate a sequence, reconstruct first data, or build the docs? |
| **Theory** | What physical and mathematical model is being implemented? |
| **Sequence Design** | How are timing, RF, gradients, PE ordering, labels, and platform definitions assembled? |
| **Reconstruction** | How are Twix data preprocessed, corrected, calibrated, and reconstructed? |
| **Validation & Performance** | What evidence supports correctness, what conditions must be frozen, and how should benchmarks be reported? |
| **Reference** | What are the parameters/functions and where is their source? |
| **Support** | What fails in practice and how should it be diagnosed? |

## Start here

- New to the repository: **[Quick Start](/quickstart)**.
- Reviewing the method: **[TSE signal and echo-train model](/theory/tse-echo-train)**.
- Modifying the sequence: **[Sequence generation](/sequence-generation)** and **[Sequence API](/reference/sequence-api)**.
- Reconstructing data: **[Reconstruction](/reconstruction)** and **[Reconstruction API](/reference/reconstruction-api)**.
- Preparing a methods comparison: **[Reconstruction protocol](/validation/reconstruction-protocol)**.
- Interpreting evidence: **[Scientific validation strategy](/validation/scientific-validation)** before **[Performance & benchmarking](/validation/performance-benchmarking)**.
