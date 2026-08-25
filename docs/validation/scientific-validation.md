# Scientific validation strategy

This page defines how evidence from this repository should be interpreted. The goal is to separate **implementation agreement**, **numerical-model validation**, and **scanner evidence** rather than treating every successful comparison as equivalent proof.

::: info Evidence hierarchy
Two implementations can agree very closely while sharing the same sign, unit, centering, metadata, or modeling error. For that reason, implementation agreement is useful but is not automatically an independent validation of the physical acquisition model.
:::

## Validation levels

The documentation uses four evidence levels.

| Level | Question answered | TSE Pulseq examples | What it does **not** prove |
| --- | --- | --- | --- |
| **1. Implementation consistency** | Do two code paths that should implement the same numerical operation agree? | Forward/adjoint identity for the Cartesian SENSE operator; correction on/off regression tests; repeated packing of the same LIN layout | Correct physical model, correct scanner metadata, or vendor portability |
| **2. Approximation / algorithm accuracy** | How far does an accelerated or regularized numerical method depart from a defined reference? | GRAPPA vs acquired/reference rows; SENSE/CS reconstruction vs a frozen fully sampled reference; echo equalization vs uncorrected data under a matched protocol | Independent verification of phase sign, geometry, units, or scanner behavior |
| **3. Independent numerical validation** | Does an independently assembled reference reproduce the target model? | Direct Cartesian DFT or independently assembled encoding matrix; independent metadata-to-$k_y$ mapping; independent geometry calculation | Hardware fidelity, RF/SAR safety, or image quality on the scanner |
| **4. Physical validation** | Does the acquisition behave as intended on a real system or a trusted physical simulator? | Siemens 7 T phantom measurements, measured navigator behavior, scanner-side orientation checks, RF/SAR/PNS/watchdog acceptance | Automatic transfer of validity to another scanner, interpreter, coil, or protocol |

The levels are cumulative rather than interchangeable. A Level-1 test is still valuable after Level-4 scanner work because it can catch a new software regression; a physical experiment does not replace operator-level numerical checks.

## 1. Implementation consistency

### Forward/adjoint identity

For the Cartesian multicoil operator

$$
A=PFS,
$$

the implementation checks the numerical inner-product identity

$$
\langle Ax,y\rangle \approx \langle x,A^Hy\rangle.
$$

A useful dimensionless diagnostic is

$$
\epsilon_{\mathrm{adj}}
=
\frac{\left|\langle Ax,y\rangle-\langle x,A^Hy\rangle\right|}
{\max\!\left(\left|\langle Ax,y\rangle\right|,\left|\langle x,A^Hy\rangle\right|,\varepsilon\right)}.
$$

The current iterative reconstruction stops when the relative mismatch exceeds `5e-5`. This is an implementation safeguard, not evidence that the acquisition model itself is complete.

### Data-layout consistency

The current Siemens raw-data path should also be checked for deterministic agreement of

- MDH `LIN`, `SLC`, and `SEG` interpretation;
- zero-based sequence-side LIN versus one-based mapVBVD indexing;
- acquired and reference-line packing;
- readout-oversampling removal; and
- application of the same prewhitening/correction transforms to compatible streams.

These tests are particularly important because an indexing error can produce a visually plausible image while still changing the intended echo-to-$k_y$ mapping.

## 2. Approximation and reconstruction accuracy

Any algorithm comparison must define the reference before reporting an error.

For a reconstructed complex image $x$ and a frozen reference $x_{\mathrm{ref}}$, the primary complex error can be reported as

$$
\mathrm{NRMSE}_{\mathbb C}
=
\frac{\lVert x-x_{\mathrm{ref}}\rVert_2}
{\lVert x_{\mathrm{ref}}\rVert_2}.
$$

Do **not** apply a post-hoc global phase or intensity alignment before the primary operator/reconstruction comparison unless that alignment is itself part of the predefined protocol. Magnitude NRMSE, SSIM, edge sharpness, or contrast metrics can be added as secondary image-domain measures.

For TSE-specific echo correction, report the gain model and its noise consequence together with any apparent sharpening. A method that removes line-to-line envelope modulation by strongly amplifying weak echoes is operating at a different noise point from the uncorrected reconstruction.

## 3. Independent numerical validation

The strongest software-only validation should use a reference that is assembled independently from the production implementation.

For Cartesian SENSE, one suitable reference for a small matrix is a direct encoding matrix

$$
E_{(j,c),v}
=
P_j\,C_c(\mathbf r_v)
\exp\!\left[-i2\pi\mathbf k_j\cdot\mathbf r_v\right]\Delta V,
$$

followed by explicit matrix multiplication. Such a test can independently expose

- Fourier sign mistakes;
- centering offsets;
- voxel-coordinate errors;
- sampling-mask mistakes;
- coil-dimension transposition; and
- normalization differences.

Likewise, an independent echo-to-$k_y$ table constructed from the intended PE schedule is a stronger validation of `prep_PE3DOrder`/LIN metadata than comparing two functions that reuse the same intermediate structure.

::: warning Current documentation status
The repository contains several implementation-level diagnostics, but a single frozen, exhaustive independent-reference validation suite is not yet documented as a release-level artifact. Until such a suite is frozen, claims should distinguish implemented checks from independent validation.
:::

## 4. Physical validation

The current scanner-validation boundary is **Siemens 7 T**. Physical evidence from that environment is valuable for the tested sequence/interpreter/reconstruction combination, but it should not be generalized automatically to another vendor or hardware platform.

A physical validation campaign should establish, at minimum:

1. orientation and slice order with an asymmetric phantom;
2. $R=1$ image and k-space baseline;
3. echo-to-$k_y$ ordering and effective-TE behavior;
4. phase-correction navigator behavior;
5. accelerated acquisition with matched ACS/interpreter settings;
6. offline reconstruction with a frozen protocol;
7. RF/SAR/PNS/watchdog acceptance on the scanner; and
8. matched comparisons before moving to in-vivo imaging.

The detailed scanner procedure remains in [Validation & safety](/validation-and-safety) and [Siemens 7 T phantom SOP](/staged-phantom-validation).

## Recommended metric set

For a methods-style report, prefer a small set of metrics whose role is explicit.

| Metric | Role |
| --- | --- |
| Forward relative error | Production forward model vs independent reference |
| Adjoint relative error | Production adjoint vs independent reference |
| Adjoint identity error | Internal operator consistency |
| Normal-operator relative error | $A^HA$ or weighted normal-operator consistency |
| Complex NRMSE | Primary reconstruction fidelity |
| Magnitude NRMSE / SSIM | Secondary image-domain interpretation |
| Navigator residual phase | TSE phase-correction quality |
| Echo-envelope residual | Magnitude-equalization behavior |
| Geometry error | Slice-center/orientation consistency in scanner coordinates |

## Evidence-status table for this repository

| Claim | Current status | Appropriate wording |
| --- | --- | --- |
| VitePress documentation builds | CI verified | “Documentation build passes.” |
| Cartesian SENSE forward/adjoint implementation | Numerical self-check implemented | “The implementation checks the forward/adjoint identity before iterative reconstruction.” |
| Offline Twix reconstruction | Implemented for conventional Cartesian 2D TSE | “Bundled Siemens Twix reconstruction is available for the documented scope.” |
| gSlider offline decoding | Not implemented | Do not imply offline gSlider reconstruction support |
| Vendor-neutral acquisition goal | Architectural goal | “Pulseq acquisition design is intended to be portable; current integrations remain platform specific.” |
| Scanner validation | Siemens 7 T boundary | Do not claim general vendor/scanner validation |
| Human-scan safety | Not established by repository checks | Scanner/site safety processes remain mandatory |

## Reporting principle

The preferred order is:

```text
implementation consistency
→ approximation / reconstruction accuracy
→ independent numerical validation
→ physical validation
→ performance
```

This ordering keeps the scientific claim attached to the level of evidence that actually supports it. Continue with [Reconstruction protocol](/validation/reconstruction-protocol) before comparing algorithms, then use [Performance & benchmarking](/validation/performance-benchmarking) only after the comparison conditions are frozen.
