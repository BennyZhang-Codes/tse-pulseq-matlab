# API reference

The reference section answers **how to call the current MATLAB implementation**. Scientific rationale and derivations remain in [Theory](/theory/tse-echo-train), while end-to-end processing remains in [Reconstruction](/reconstruction).

::: info Scope
The repository is primarily a research sequence-development codebase rather than a packaged MATLAB toolbox with a formally versioned public API. The pages below document the maintained entry points and the core functions that define the current production workflow.
:::

## Main entry points

| Entry point | Purpose | Documentation | Source |
| --- | --- | --- | --- |
| `TSE_2D.m` | Generate conventional Cartesian 2D TSE | [Quick Start](/quickstart) | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D.m) |
| `TSE_2D_gSlider.m` | Generate gSlider-TSE with optional TRAPS schedule | [gSlider & TRAPS](/guide/gslider-traps) | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D_gSlider.m) |
| `recon_TSE2D(filename, ...)` | Offline conventional 2D TSE Siemens-Twix reconstruction | [Reconstruction](/reconstruction) | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/recon_TSE2D.m) |

## Reference groups

### Sequence generation

[Sequence API](/reference/sequence-api) lists the maintained preparation stages used by the two sequence entry scripts:

```text
system / geometry
→ PE ordering
→ RF
→ gradients
→ labels / delays
→ noise scan
→ sequence loop
→ checks / definitions / export
```

Use the [Parameter Reference](/parameter-reference) for user-facing `Setup`, `SetupRF`, and `SetupSpoiling` fields.

### Reconstruction

[Reconstruction API](/reference/reconstruction-api) documents `recon_TSE2D`, its option groups, correction helpers, k-space packing, sensitivity/calibration utilities, and output behavior.

### Validation and checks

The maintained sequence scripts call

```matlab
check_Timing(seq)
check_Label(seq)
check_PNS(seq, Actual)
```

These are development checks and do not constitute scanner safety certification. Their interpretation is documented in [Validation & safety](/validation-and-safety).

### Denoising

Optional post-reconstruction filtering is documented in [Image-domain denoising](/guide/denoising). The denoising routines are intentionally separated from the core reconstruction API because filtering occurs after image reconstruction and changes the output statistics.

## API documentation convention

Each core API page follows the same order:

```text
Name / signature
Short description
Arguments / options
Returns
Example / notes
Source
```

Long derivations are not duplicated here. For example, navigator correction equations live in [Echo phase & magnitude correction](/guide/echo-corrections), and the SENSE/CS signal model lives in [Reconstruction](/reconstruction) and [TSE echo-train model](/theory/tse-echo-train).

## Source-of-truth policy

When documentation and code disagree, the checked-out source revision is the implementation source of truth. For a reproducible scan or reconstruction, record the repository commit together with the `.seq`/Twix data and relevant submodule revisions.
