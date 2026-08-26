# Echo phase & magnitude correction

The MATLAB reconstruction uses the TSE phase-correction navigator train to estimate echo-dependent phase and, optionally, a slice-level echo-magnitude envelope. Corrections are applied **after receive-noise prewhitening and before Cartesian k-space packing**.

::: info Optional magnitude correction
Navigator phase correction and echo-magnitude equalization are separate features. `EchoMagnitudeCorrection` is **disabled by default**. The package exposes the method, settings and diagnostics; the user decides whether it is appropriate for a particular dataset or study.
:::

## Implementation order

```mermaid
flowchart LR
    A[Prewhitened navigator] --> B[Relative phase fit]
    B --> C[Phase correction]
    C --> D[Echo envelope estimate]
    D --> E[Optional regularized gain]
    E --> F[Cartesian packing]
```

The same compatible correction basis is applied to imaging and PAT-reference acquisitions so that calibration and image data are not reconstructed in inconsistent coil/echo bases.

## MRI literature basis

Echo-dependent signal modulation in RARE/TSE maps into $k_y$ through echo ordering and therefore changes the phase-encoding PSF. Correction or demodulation of this effect has been studied in RARE/FSE reconstruction:

| Citation | Published idea | Relation to this package |
| --- | --- | --- |
| [[16]](/references#ref-16 "Oshio K, Singh M. Correction of T2 distortion in multi-excitation RARE sequence. IEEE Trans Med Imaging. 1992;11:123-128.") | correction of T2-dependent distortion in RARE | establishes echo-modulation correction as a reconstruction problem |
| [[17]](/references#ref-17 "Zhou X, Liang ZP, Cofer GP, Beaulieu CF, Suddarth SA, Johnson GA. Reduction of ringing and blurring artifacts in fast spin-echo imaging. J Magn Reson Imaging. 1993;3:803-807.") | demodulation using non-phase-encoded FSE echoes | closest acquisition precedent for the package's unencoded navigator train |
| [[18]](/references#ref-18 "Chen H, Avram H, Kaufman L, Hale J, Kramer D. T2 restoration and noise suppression of hybrid MR images using Wiener and linear prediction techniques. IEEE Trans Med Imaging. 1994;13:667-676.") | global k-space amplitude restoration with Wiener filtering | precedent for regularized inverse-envelope weighting |
| [[19]](/references#ref-19 "Busse RF, Riederer SJ, Fletcher JG, Bharucha AE, Brandt KR. Interactive fast spin-echo imaging. Magn Reson Med. 2000;44:339-348.") | Wiener demodulation of FSE k-space | precedent for controlling inverse-filter noise amplification |

General Wiener inverse-filtering background is reference [[15]](/references#ref-15 "Wiener N. Extrapolation, Interpolation, and Smoothing of Stationary Time Series, with Engineering Applications. MIT Press; 1949."). The exact normalized gain and automatic regularization rule below are repository implementation choices, not a claim of reproducing one of these papers exactly.

## Navigator phase model

For slice $s$, echo $e$, coil $c$ and normalized readout coordinate $\kappa$,

$$
z_{s,e,c}(\kappa)
=
n_{s,e,c}(\kappa)n^*_{s,e_{\mathrm{ref}},c}(\kappa).
$$

The unwrapped relative phase is fitted as

$$
\arg z_{s,e,c}(\kappa)
\approx
\beta_{1,s,e,c}\kappa+\beta_{0,s,e,c},
$$

where $\beta_0$ is the echo-dependent constant phase and $\beta_1$ is a readout-linear term. The applied phase factor is

$$
p_{s,e,c}(\kappa)
=
\exp[-i(\beta_{1,s,e,c}\kappa+\beta_{0,s,e,c})].
$$

This is a transparent offline fit to the measured navigator. It is not a byte-for-byte model of Siemens ICE phase correction.

## Measured echo envelope

Repeated navigators are complex averaged. When a prewhitened noise estimate is available, the expected noise floor is removed from the navigator power before normalization to the reference echo. The result is

$$
A_{s,e}>0,
\qquad
A_{s,e_{\mathrm{ref}}}=1.
$$

`estimate_TSE_phasecor.m` stores this as `phaseCor.amplitudeNorm`.

The quantity $A_{s,e}$ is a **measured effective slice-level echo envelope**. It is not a voxelwise tissue-$T_2$ estimate. In reality, TSE echo behavior can vary with $T_1$, $T_2$, $B_1^+$, slice profile, refocusing history and stimulated echoes.

## Power-law option

`apply_TSE_echomagcor.m` supports

$$
g^{\mathrm{power}}_{s,e}
=
A_{s,e}^{\alpha-1},
\qquad 0\leq\alpha\leq1.
$$

- $\alpha=0$: target full inverse-envelope equalization;
- $\alpha=1$: preserve the measured envelope;
- intermediate $\alpha$: partial equalization.

When $A_{s,e}$ is small, direct inversion can strongly amplify noise.

## Wiener-style regularized option

The package also provides

$$
g^{\mathrm W}_{s,e}
=
(1+\lambda_s)
\frac{A_{s,e}^{\alpha+1}}{A_{s,e}^2+\lambda_s}.
$$

The factor $(1+\lambda_s)$ preserves unity gain at $A=1$. As $\lambda_s\to0$, the formula approaches the power-law form.

With

```matlab
'EchoMagnitudeLambda','auto'
```

$\lambda_s$ is selected separately per slice from the larger of

- a navigator noise-to-signal regularization term; and
- the regularization needed to meet `EchoMagnitudeMaxGain` through the smooth gain curve.

This is therefore documented as a **normalized Wiener-style regularized equalizer**, not as a uniquely optimal LMMSE Wiener estimator.

## Defaults and explicit use

The API defaults are

```matlab
'EchoMagnitudeCorrection', false
'EchoMagnitudeMethod', 'power'
'EchoMagnitudeAlpha', 1
```

A user can explicitly request, for example,

```matlab
'EchoMagnitudeCorrection', true
'EchoMagnitudeMethod', 'wiener'
'EchoMagnitudeAlpha', 0
'EchoMagnitudeLambda', 'auto'
'EchoMagnitudeMaxGain', 2
```

This example demonstrates availability; it is not a package-wide recommendation.

## Limits of the correction

The global navigator envelope can compensate a measured echo-dependent weighting across PE lines, but it cannot generally invert spatially varying TSE physics. In particular:

- weak echoes and their noise are both affected by gain;
- different tissues can have different echo envelopes;
- $B_1^+$, stimulated echoes and slice profile can vary spatially;
- correction can alter contrast as well as apparent sharpness;
- information not encoded in the acquired data cannot be recovered.

For quantitative T2 restoration or tissue-specific modeling, a sequence-aware spatial model such as EPG/Bloch would be required beyond this global envelope correction.

## What to report when used

Record

- `EchoMagnitudeCorrection`;
- reference echo;
- `EchoMagnitudeMethod` and `EchoMagnitudeAlpha`;
- manual/automatic $\lambda$;
- `EchoMagnitudeMaxGain` when relevant;
- measured envelope/gain diagnostics; and
- whether an uncorrected reconstruction was retained for comparison.

## Source map

| Role | Source |
| --- | --- |
| navigator phase/envelope estimate | [`estimate_TSE_phasecor.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/estimate_TSE_phasecor.m) |
| phase application | [`apply_TSE_phasecor.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/apply_TSE_phasecor.m) |
| magnitude gain | [`apply_TSE_echomagcor.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/apply_TSE_echomagcor.m) |
| pipeline integration | [`recon_TSE2D.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/recon_TSE2D.m) |

See [Reconstruction](/reconstruction) for the complete pipeline and [Dependencies & method provenance](/reference/provenance) for package-wide attribution.
