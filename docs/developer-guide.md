# Developer guide

This page describes the repository architecture and the recommended workflow for extending the project.

## 1. Repository layout

```text
TSE_2D.m               conventional 2D TSE entry point
TSE_2D_gSlider.m       gSlider-TSE entry point
prep/                   sequence preparation modules
check/                  timing, label and PNS development checks
plot/                   sequence and k-space visualization
utils/                  rasterized gradient solvers and general utilities
pulseq/                 Pulseq git submodule
VERSE/                  VERSE/minimum-SAR RF git submodule
recon/matlab/           conventional 2D TSE MATLAB reconstruction
recon/julia/            Julia-side reconstruction code retained by the project
seq/                     generated sequence/configuration outputs; not tracked
docs/                    static MkDocs documentation
.github/workflows/       CI/deployment workflows
```

## 2. Sequence architecture

The maintained entry scripts should remain configuration-focused. Sequence implementation belongs in shared preparation functions where practical.

The current architecture is:

```text
configuration
   -> Actual
   -> system/slice/PE/RF/gradient/label/delay preparation
   -> sequence loop
   -> validation
   -> exported definitions
   -> .seq + configuration archive
```

When adding a feature, prefer extending a shared `prep_*` module over duplicating logic in both `TSE_2D.m` and `TSE_2D_gSlider.m`.

## 3. Preserve `Setup` versus `Actual`

`Setup` should represent user intent. `Actual` is the resolved configuration after preparation.

New derived values should normally be written to `Actual` rather than mutating the meaning of the original user-facing `Setup` field.

This distinction is important for reproducibility and debugging.

## 4. Gradient design rules

The custom gradient utilities deliberately treat the continuous analytical solution as a seed, not as the final scanner waveform.

A returned waveform must be valid on the integer gradient raster and satisfy:

- requested area;
- exact rasterized duration;
- endpoint amplitudes;
- gradient-amplitude limit;
- slew-rate limit.

Do not replace the current raster-aware search with a simple continuous solution followed by naive rounding.

For minimum-time problems with nonzero endpoints, do not assume fixed-duration feasibility is monotonic; an ordinary binary search is not a proof of the discrete minimum.

## 5. Crusher/spoiler conventions

Crusher and spoiler strength is defined as dephasing cycles per physical reference length.

When adding a new spoiler type, use the centralized `SetupSpoiling`/`prep_SpoilingArea` convention rather than embedding raw gradient areas inside the sequence loop.

This keeps behavior interpretable as voxel size, FOV or slice/slab thickness changes.

## 6. PE/ICE metadata rules

PI and CS are separate acquisition modes.

For PI:

- preserve the zero-based Siemens LIN convention;
- preserve the regular accelerated lattice checks;
- export the full encoded matrix size;
- keep ACS bookkeeping consistent with `FirstRefLine`/`nRefLine`;
- remember that Siemens iPAT protocol settings remain an external dependency.

For CS:

- do not silently reuse PI LIN assumptions;
- preserve compatibility with the offline iterative reconstruction path.

Changes to PE labels should be tested with odd/even matrix sizes, multiple acceleration factors and central-line placement.

## 7. Reconstruction architecture

`recon_TSE2D.m` orchestrates the offline pipeline. Keep individual operations modular:

```text
read raw data
prewhiten
estimate/apply navigator corrections
pack Cartesian k-space
reconstruct
save diagnostics
```

SENSE and CS intentionally share one multicoil encoding model and sensitivity/calibration preparation path. New iterative algorithms should reuse the same tested forward/adjoint operators when the encoding model is unchanged.

## 8. Numerical safeguards

Do not remove validation checks merely to make a dataset run.

Important current safeguards include:

- explicit warnings/fallback for missing noise data;
- navigator-data requirements for echo-magnitude correction;
- GRAPPA calibration diagnostics;
- ESPIRiT contiguous-calibration checks;
- SENSE/CS forward-adjoint inner-product tests;
- CS primal-dual step-size checks;
- NIfTI geometry consistency checks.

If a safeguard is too strict for a legitimate new acquisition, update the model and tests rather than disabling the check globally.

## 9. Static documentation first

The first documentation stage is intentionally **static MkDocs**. Documentation should explain stable workflows, conventions, limitations and reproducibility before introducing automatically generated API references.

For now:

- edit the Markdown files in `docs/`;
- keep `mkdocs.yml` navigation explicit;
- ensure code snippets match maintained entry points;
- update docs in the same PR as user-visible behavior changes.

Automatic MATLAB API extraction can be considered later, once public function boundaries and docstring conventions are stable.

## 10. Build documentation locally

Install the pinned documentation theme used by CI:

```bash
python -m pip install mkdocs-material==9.7.7
```

Build strictly:

```bash
mkdocs build --strict
```

Preview locally:

```bash
mkdocs serve
```

The development server normally prints a local URL such as `http://127.0.0.1:8000/`.

## 11. GitHub Pages deployment

`.github/workflows/docs.yml` builds the static MkDocs site and deploys the generated `site/` directory using GitHub Pages Actions.

The workflow is triggered on pushes to `main` that affect documentation/configuration and can also be run manually.

Repository Settings must use **GitHub Actions** as the Pages publishing source before the first deployment succeeds.

The expected project Pages URL is:

```text
https://bennyzhang-codes.github.io/tse-pulseq-matlab/
```

## 12. Pull-request expectations

A PR that changes sequence/reconstruction behavior should describe:

- motivation;
- user-visible changes;
- mathematical/algorithmic changes when relevant;
- compatibility implications;
- validation performed;
- known limitations;
- scanner-side validation still required.

Update the corresponding documentation page when a PR changes a public workflow, configuration field, output convention or known limitation.

## 13. Release discipline

Before a citation-oriented release:

1. run the maintained sequence examples and reconstruction smoke tests available to you;
2. verify submodule revisions;
3. update documentation;
4. update `CITATION.cff` with release metadata;
5. tag/release a fixed revision;
6. archive through Zenodo if a DOI is desired;
7. add the real DOI only after Zenodo assigns it.

See [Reproducibility and citation](reproducibility.md).
