---
layout: home

hero:
  name: TSE Pulseq
  text: 2D TSE development toward vendor-neutral deployment
  tagline: MATLAB development of Cartesian TSE and gSlider-TSE with Pulseq. The current implementation and scanner validation are on Siemens 7 T; bundled raw-data reconstruction currently targets Siemens Twix.
  actions:
    - theme: brand
      text: Quick Start
      link: /quickstart
    - theme: alt
      text: Sequence Design
      link: /sequence-generation

features:
  - title: Sequence design
    details: Pulseq-based 2D TSE and gSlider-TSE with configurable RF, timing, echo train, slice ordering, PI/CS sampling, and TRAPS schedules.
    link: /sequence-generation
  - title: Platform integration
    details: Separate reusable acquisition concepts from scanner-specific hardware limits, interpreter metadata, safety models, and validation as the project expands beyond Siemens 7 T.
    link: /platform-integration
  - title: Reconstruction
    details: Transparent RSS, diagnostic PE-GRAPPA, ESPIRiT-SENSE, and Cartesian CS for the current conventional 2D TSE Siemens Twix workflow.
    link: /reconstruction
  - title: Validation
    details: Timing and label checks, current Siemens PNS development checks, staged phantom validation, and explicit scanner-side safety boundaries.
    link: /validation-and-safety
---

<section class="home-section home-workflow">
  <div class="section-kicker">HOW TO USE</div>
  <h2>A clear path from sequence design to scanner data</h2>
  <p class="section-lead">The documentation separates reusable acquisition concepts from scanner-specific implementation. Start with the sequence, then integrate and validate the target platform before relying on scanner or raw-data behavior.</p>

  <div class="flow-grid">
    <a class="flow-card" href="./quickstart">
      <span class="flow-step">01</span>
      <strong>Run a known example</strong>
      <span>Install the project and generate a conventional 2D TSE `.seq` file with the current tested setup.</span>
    </a>
    <a class="flow-card" href="./sequence-generation">
      <span class="flow-step">02</span>
      <strong>Design the acquisition</strong>
      <span>Configure RF, timing, echo train, geometry, ordering, PI, CS, and gSlider options.</span>
    </a>
    <a class="flow-card" href="./platform-integration">
      <span class="flow-step">03</span>
      <strong>Integrate the scanner</strong>
      <span>Adapt system limits, interpreter metadata, orientation, safety models, and reconstruction contracts.</span>
    </a>
    <a class="flow-card" href="./validation-and-safety">
      <span class="flow-step">04</span>
      <strong>Validate, then acquire</strong>
      <span>Complete software checks, staged phantom validation, and scanner-side RF/SAR/PNS review before in-vivo use.</span>
    </a>
  </div>
</section>

<section class="home-section">
  <div class="section-kicker">PLATFORM STATUS</div>
  <h2>Vendor-neutral goal, currently Siemens-coupled implementation</h2>

  <div class="scope-strip">
    <div class="scope-item">
      <span class="scope-label">Design goal</span>
      <strong>Vendor-neutral Pulseq TSE</strong>
      <span>The acquisition concepts are intended to remain portable at the Pulseq level as support expands to additional scanner platforms.</span>
    </div>
    <div class="scope-item">
      <span class="scope-label">Current implementation</span>
      <strong>Siemens 7 T path</strong>
      <span>Shared prep code currently includes Terra hardware presets, Siemens PI/LIN mapping, interpreter definitions, and `.asc` PNS models.</span>
    </div>
    <div class="scope-item">
      <span class="scope-label">Raw-data reconstruction</span>
      <strong>Siemens Twix</strong>
      <span>The bundled MATLAB reader and reconstruction currently target conventional Cartesian 2D TSE Twix data through `mapVBVD`.</span>
    </div>
  </div>
</section>

::: info Porting to another vendor
The project is intended to support vendor-neutral sequence development, but the current code path still contains Siemens-specific integration. See [Platform Integration](platform-integration.md) for the exact coupling points and the work required to add another scanner platform.
:::

::: warning Research use only
Pulseq timing checks, PNS prediction, and software-side validation do **not** replace scanner-side safety checks, RF/SAR review, protocol validation, gradient-watchdog checks, local approvals, or staged phantom testing before volunteer or patient imaging.
:::

<section class="home-section home-links">
  <div class="section-kicker">REFERENCE</div>
  <h2>Detailed references when you need them</h2>
  <div class="reference-grid">
    <a href="./parameter-reference"><strong>Parameter Reference</strong><span>Sequence controls, timing, geometry, acceleration, RF, and spoiling parameters.</span></a>
    <a href="./platform-integration"><strong>Platform Integration</strong><span>Current Siemens coupling, target architecture, and a practical checklist for adding another scanner platform.</span></a>
    <a href="./phase-encoding-and-ice"><strong>Siemens 7 T Encoding & ICE</strong><span>Current LIN, ACS, phase-correction, interpreter, and ICE metadata contract.</span></a>
    <a href="./reproducibility"><strong>Reproducibility & Citation</strong><span>Pin software, submodules, platform details, protocol settings, and reconstruction options for published work.</span></a>
  </div>
</section>
