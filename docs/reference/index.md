# Reference & provenance

This section answers two engineering questions:

1. **Where is the implementation?** — sequence entry points, preparation functions and source links.
2. **Where did the method/tool come from?** — scientific citation, upstream software/code source and repository-specific adaptation.

The repository is a research sequence codebase rather than a formally versioned MATLAB toolbox API. The checked-out source revision remains authoritative for exact low-level behavior.

## Main entry points

| Entry point | Purpose | Engineering documentation | Source |
| --- | --- | --- | --- |
| `TSE_2D.m` | conventional Cartesian 2D TSE generation | [Sequence Implementation](/sequence-generation) | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D.m) |
| `TSE_2D_gSlider.m` | gSlider-TSE + optional TRAPS-style schedule | [gSlider-TSE & TRAPS](/guide/gslider-traps) | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/TSE_2D_gSlider.m) |
| `recon_TSE2D(filename, ...)` | conventional 2D TSE Siemens-Twix reconstruction | [Reconstruction](/reconstruction) | [source](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/recon_TSE2D.m) |

## Sequence source reference

[Sequence API](/reference/sequence-api) provides a source-oriented index of the preparation/check/export functions used by the sequence entry scripts. [Parameter Reference](/parameter-reference) documents the user-facing `Setup`, `SetupRF` and `SetupSpoiling` configuration.

The engineering explanation of how these functions compose is in [Sequence Implementation](/sequence-generation), not duplicated as a second theory/API narrative here.

## Reconstruction reference

Function behavior, mathematical model, option defaults and source links are intentionally consolidated in [Reconstruction](/reconstruction). The old `/reference/reconstruction-api` URL is retained as a compatibility redirect page, but reconstruction is no longer split into separate “workflow” and “API” documentation.

## Method/code provenance

[Dependencies & Method Provenance](/reference/provenance) is the canonical mapping for components such as

- Pulseq;
- Lustig-derived SparseMRI CS sampling;
- SigPy-generated SLR/gSlider RF banks;
- TRAPS-style refocusing;
- VERSE upstream lineage;
- mapVBVD;
- GRAPPA/SENSE/ESPIRiT/CS;
- coil compression; and
- optional denoising packages.

For each applicable feature it distinguishes

```text
scientific method
+ upstream software/code source
+ repository adaptation
```

## Literature references

[References](/references) uses MRM-style numbered entries. In-text citations follow the HighOrderMRI interaction pattern, for example:

```md
[[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.")
```

Clicking the number jumps to the reference entry; hovering shows the citation tooltip. DOI identifiers in the bibliography are hyperlinks.

## Reproducibility

[Reproducibility & Citation](/reproducibility) defines what should be archived with a sequence or reconstruction:

- repository revision;
- Pulseq/VERSE submodule revisions;
- generated RF asset provenance when regenerated;
- `Setup`, `Actual` and `.seq`;
- scanner/interpreter information;
- reconstruction configuration; and
- optional correction/post-processing settings.

## Source-of-truth rule

When code and documentation disagree, treat the checked-out code revision as the implementation source of truth and fix the documentation. When a new external method/tool is introduced, update the source, [Provenance](/reference/provenance) and [References](/references) together.
