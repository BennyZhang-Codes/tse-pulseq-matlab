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
docs/                    VitePress documentation source
.github/workflows/       CI/deployment workflows
```

## 2. Target architecture

The long-term project structure should preserve a clear boundary between **vendor-neutral acquisition design** and **scanner-specific integration**.

```text
Acquisition design
configuration -> Actual
      -> slice / logical PE / RF / gradient / ADC / labels / timing
      -> sequence loop
      -> Pulseq validation
      -> .seq + configuration archive
                |
                v
Platform integration
hardware limits / PNS model / interpreter metadata / orientation
online reconstruction contract / scanner protocol assumptions
                |
                v
Scanner validation
phantom + scanner-side RF/SAR/PNS/watchdog checks
                |
                v
Optional vendor-specific raw-data reconstruction
```

::: warning Current implementation
This separation is a **target architecture**, not a claim that the current code is already vendor-decoupled. Today, `prep_System` supports only the Terra profiles, `prep_PE3DOrder` contains the Siemens PI/LIN mapping, and `prep_Definition` writes Siemens-oriented interpreter definitions in the shared prep path.
:::

The maintained entry scripts should remain configuration-focused. Shared TSE behavior belongs in reusable preparation functions and sequence-loop code; platform-specific system profiles and metadata translation should progressively become explicit integration logic rather than accumulating inside the common acquisition path.

See [Platform Integration](platform-integration.md) for the current coupling points and porting checklist.

## 3. Preserve `Setup` versus `Actual`

`Setup` should represent user intent. `Actual` is the resolved configuration after preparation.

New derived values should normally be written to `Actual` rather than mutating the meaning of the original user-facing `Setup` field.

This distinction is important for reproducibility and debugging.

Platform-derived values such as resolved hardware limits, interpreter-facing indices, or scanner-specific metadata should be identifiable as derived configuration rather than being confused with the logical acquisition request.

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

Hardware limits must correspond to the selected scanner target. Do not reuse the currently implemented Terra limits or PNS models as generic defaults for a different gradient system.

## 5. Crusher/spoiler conventions

Crusher and spoiler strength is defined as dephasing cycles per physical reference length.

When adding a new spoiler type, use the centralized `SetupSpoiling`/`prep_SpoilingArea` convention rather than embedding raw gradient areas inside the sequence loop.

This keeps behavior interpretable as voxel size, FOV or slice/slab thickness changes.

## 6. Encoding and platform metadata rules

Separate **logical encoding** from **platform-specific line numbering and reconstruction metadata**.

For acquisition design:

- preserve physical `ky` ordering independently of vendor index names;
- keep PI and CS as distinct acquisition modes;
- represent full matrix size, k-space center and ACS/reference intent explicitly;
- test odd/even matrix sizes, multiple acceleration factors and central-line placement.

For the currently validated Siemens 7 T path:

- preserve the zero-based Siemens LIN mapping used by the existing implementation;
- preserve the regular accelerated lattice checks;
- export the full encoded matrix size;
- keep ACS bookkeeping consistent with `FirstRefLine` / `nRefLine`;
- remember that Siemens iPAT protocol settings remain an external dependency.

For another platform, define its metadata mapping deliberately instead of copying Siemens LIN semantics. The same logical `ky` pattern may map to different index bases, labels or reconstruction parameters.

For CS, do not silently reuse PI/ICE assumptions. Preserve compatibility with the intended offline iterative reconstruction path.

See [Siemens 7 T encoding and ICE integration](phase-encoding-and-ice.md) for the current metadata contract.

## 7. Platform integration expectations

A new scanner target should explicitly define:

- field strength and absolute gradient/slew limits;
- raster/dead-time requirements when they differ;
- PNS or equivalent hardware safety strategy;
- supported Pulseq interpreter features and version;
- orientation and logical-to-physical axis mapping;
- acceleration/ACS metadata required by the scanner;
- navigator or phase-correction metadata when used;
- online reconstruction dependencies;
- staged scanner validation evidence.

Do not mark a platform as supported merely because the `.seq` file parses. A platform becomes a supported validation target only after interpreter behavior, safety constraints, geometry/orientation and phantom imaging have been checked.

## 8. Reconstruction architecture

`recon_TSE2D.m` orchestrates the current offline pipeline:

```text
read Siemens Twix
prewhiten
estimate/apply navigator corrections
pack Cartesian k-space
reconstruct
save diagnostics
```

The **reconstruction model** and the **raw-data reader** should remain conceptually separate. If support for another raw-data format is added, map that vendor's data and metadata into the reconstruction model rather than spreading raw-data-format assumptions through the sequence design.

SENSE and CS intentionally share one multicoil encoding model and sensitivity/calibration preparation path. New iterative algorithms should reuse the same tested forward/adjoint operators when the encoding model is unchanged.

## 9. Numerical safeguards

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

## 10. Documentation conventions

The documentation remains intentionally **static Markdown**, rendered with VitePress for clear task-oriented navigation.

Keep the public information architecture aligned with the project architecture:

- **Start here** — installation and runnable examples;
- **Sequence design** — reusable acquisition concepts and current sequence workflow;
- **Platform integration** — current coupling, target architecture and scanner-specific metadata;
- **Reconstruction** — current raw-data/reconstruction implementation;
- **Validation** — scanner-independent principles plus platform-specific validation evidence;
- **Project** — reproducibility and contributor guidance.

When behavior changes, update the page belonging to the affected layer rather than adding platform-specific caveats everywhere.

## 11. Build documentation locally

Install the Node dependency declared by the repository:

```bash
npm install
```

Build the site:

```bash
npm run docs:build
```

Preview while editing:

```bash
npm run docs:dev
```

VitePress prints the local preview URL in the terminal.

## 12. GitHub Pages deployment

`.github/workflows/docs.yml` builds the VitePress site and deploys `docs/.vitepress/dist` through GitHub Pages Actions.

The workflow validates documentation pull requests and deploys documentation changes pushed to `main`.

Repository Settings must use **GitHub Actions** as the Pages publishing source.

The expected project Pages URL is:

```text
https://bennyzhang-codes.github.io/tse-pulseq-matlab/
```

## 13. Pull-request expectations

A PR that changes sequence/reconstruction behavior should describe:

- motivation;
- user-visible changes;
- mathematical/algorithmic changes when relevant;
- acquisition versus platform-integration implications;
- validation performed;
- known limitations;
- scanner-side validation still required.

Update the corresponding documentation page when a PR changes a public workflow, configuration field, output convention or known limitation.

## 14. Release discipline

Before a citation-oriented release:

1. run the maintained sequence examples and reconstruction smoke tests available to you;
2. verify submodule revisions;
3. update documentation and platform-support statements;
4. update `CITATION.cff` with release metadata;
5. tag/release a fixed revision;
6. archive through Zenodo if a DOI is desired;
7. add the real DOI only after Zenodo assigns it.

See [Reproducibility and citation](reproducibility.md).
