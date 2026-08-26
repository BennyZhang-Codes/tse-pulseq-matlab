# Reference

This section is for users who need exact source locations, external dependencies, method provenance, or citation information.

## Main entry points

| Entry point | Purpose | Documentation |
| --- | --- | --- |
| `TSE_2D.m` | conventional Cartesian 2D TSE | [Sequence Implementation](/sequence-generation) |
| `TSE_2D_gSlider.m` | gSlider-TSE | [gSlider-TSE](/guide/gslider-traps) |
| `recon_TSE2D(filename, ...)` | conventional 2D TSE reconstruction | [Reconstruction](/reconstruction) |

## Sequence source reference

[Sequence API](/reference/sequence-api) maps the main preparation/check/export functions used by the sequence scripts. [Parameter Reference](/parameter-reference) documents the user-facing sequence configuration.

## Method and code provenance

[Dependencies & Method Provenance](/reference/provenance) records, where applicable:

```text
scientific method
+ upstream software/code source
+ repository implementation/adaptation
```

This includes Pulseq, SparseMRI-derived CS sampling, SigPy-generated RF pulse banks, VERSE, PNS tooling, reconstruction methods, coil compression, and optional denoising tools. Experimental/test-only code paths are identified as such rather than presented as main package features.

## Literature references

[References](/references) uses numbered MRM-style citations. In-text citations are clickable and show the full citation on hover; DOI identifiers in the bibliography are hyperlinks.

Example:

```md
[[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.")
```

## Reproducibility

[Reproducibility & Citation](/reproducibility) summarizes what should be saved with an acquisition/reconstruction and how to cite the repository and methods used.
