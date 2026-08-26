# Scientific validation strategy

This page defines how evidence from this repository should be interpreted. The goal is to separate **implementation consistency**, **algorithm accuracy**, **independent numerical validation**, and **physical scanner validation** rather than treating every successful comparison as equivalent proof.

::: info Evidence hierarchy
Two implementations can agree closely while sharing the same sign, unit, centering, metadata, or modeling error. Implementation agreement is therefore useful but is not automatically independent validation of the physical acquisition model.
:::

## Validation levels

| Level | Question answered | Examples | What it does **not** prove |
| --- | --- | --- | --- |
| **1. Implementation consistency** | Do code paths that should implement the same numerical operation agree? | forward/adjoint identity; deterministic PE packing; correction on/off regression tests | correct physical model or scanner behavior |
| **2. Algorithm accuracy** | How far does an accelerated/regularized method depart from a defined reference? | GRAPPA/SENSE/CS vs frozen fully sampled reference; echo correction vs uncorrected data | independent verification of coordinates, units, or scanner metadata |
| **3. Independent numerical validation** | Does an independently assembled reference reproduce the intended numerical model? | direct Cartesian DFT/encoding matrix; independent echo-to-$k_y$ table; independent geometry calculation | hardware fidelity or human-scan safety |
| **4. Physical validation** | Does the acquisition behave as intended on a real target system? | phantom measurements, measured navigator behavior, orientation checks, scanner-side RF/SAR/PNS/watchdog acceptance | automatic transfer to another scanner/interpreter/protocol |

These levels are cumulative rather than interchangeable.

## 1. Implementation consistency

### Forward/adjoint identity

For the Cartesian multicoil operator

$$
A=PFS,
$$

the implementation checks

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

The maintained raw-data path should be checked for deterministic agreement of

- reader metadata → PE/slice/echo mapping;
- acquired/reference-line packing;
- readout-oversampling handling; and
- application of the same prewhitening/correction transforms to compatible streams.

Reader-specific counters and indexing conventions belong to the raw-data adapter rather than to the generic TSE method.

## 2. Algorithm and reconstruction accuracy

For a reconstructed complex image $x$ and frozen reference $x_{\mathrm{ref}}$,

$$
\mathrm{NRMSE}_{\mathbb C}
=
\frac{\lVert x-x_{\mathrm{ref}}\rVert_2}
{\lVert x_{\mathrm{ref}}\rVert_2}.
$$

Do not apply post-hoc global phase/intensity alignment before a primary comparison unless that alignment is predefined as part of the protocol. Magnitude NRMSE, SSIM, edge sharpness, or contrast metrics can be secondary measures.

For optional echo magnitude correction, report the gain model and its noise consequence together with any apparent sharpening.

## 3. Independent numerical validation

For Cartesian SENSE, one suitable small-matrix reference is an explicitly assembled encoding matrix

$$
E_{(j,c),v}
=
P_j\,C_c(\mathbf r_v)
\exp\!\left[-i2\pi\mathbf k_j\cdot\mathbf r_v\right]\Delta V.
$$

Such a reference can independently expose Fourier sign mistakes, centering offsets, voxel-coordinate errors, sampling-mask mistakes, coil-dimension transposition, and normalization differences.

Likewise, an independent echo-to-$k_y$ table is stronger validation of the sequence PE order than comparing two functions that reuse the same intermediate structure.

::: warning Current status
The repository contains implementation-level diagnostics, but a single frozen exhaustive independent-reference validation suite is not yet documented as a release artifact. Expanding that validation is tracked in [TO DO](/todo).
:::

## 4. Physical validation

Physical validation is **target-platform specific**. Scanner testing performed on one system should not be generalized automatically to another scanner, interpreter, coil, or protocol.

A physical validation campaign should establish, at minimum:

1. orientation and slice order with an asymmetric phantom;
2. $R=1$ image and k-space baseline;
3. echo-to-$k_y$ ordering and effective-TE behavior;
4. phase-correction navigator behavior;
5. accelerated acquisition with matched ACS/interpreter settings;
6. offline reconstruction with a frozen protocol when used;
7. RF/SAR/PNS/watchdog acceptance on the target scanner; and
8. matched comparisons before moving to in-vivo imaging.

Reusable guidance is kept in [Validation & Safety](/validation-and-safety). Scanner- or site-specific SOPs should remain local/platform documentation rather than part of the core sequence package.

## Recommended metric set

| Metric | Role |
| --- | --- |
| Forward relative error | production forward model vs independent reference |
| Adjoint relative error | production adjoint vs independent reference |
| Adjoint identity error | internal operator consistency |
| Complex NRMSE | primary reconstruction fidelity |
| Magnitude NRMSE / SSIM | secondary image-domain interpretation |
| Navigator residual phase | phase-correction quality |
| Echo-envelope residual / gain | optional magnitude-correction behavior |
| Geometry error | slice-center/orientation consistency |

## Evidence-status table

| Claim | Current status | Appropriate wording |
| --- | --- | --- |
| Documentation build | CI verified when workflow passes | “Documentation build passes.” |
| SENSE/CS forward-adjoint implementation | numerical self-check implemented | “The implementation checks the forward/adjoint identity.” |
| Offline reconstruction | implemented for conventional Cartesian 2D TSE within the current reader scope | state the supported raw-data format separately |
| gSlider offline decoding | not implemented | do not imply decoding support |
| Platform portability | architectural goal with remaining adapter work | do not claim all Pulseq scanners are already supported |
| Scanner testing | limited to the development environment to date | do not claim general scanner validation |
| Human-scan safety | not established by repository checks | scanner/site safety processes remain mandatory |

## Reporting principle

```text
implementation consistency
→ algorithm / reconstruction accuracy
→ independent numerical validation
→ physical validation
→ performance
```

Continue with [Reconstruction Protocol](/validation/reconstruction-protocol) before comparing algorithms and [Performance & Benchmarking](/validation/performance-benchmarking) only after the comparison conditions are frozen.
