# Echo phase and magnitude correction

The offline MATLAB workflow uses TSE phase-correction navigators to estimate echo-dependent phase and, optionally, echo-magnitude modulation. These operations are performed **after receive-noise prewhitening and before Cartesian k-space packing** so that imaging data and calibration/reference data remain in a consistent coil basis.

::: info Optional reconstruction choice
Navigator phase correction and echo-magnitude equalization are separate operations. Echo-magnitude equalization is **optional and disabled by default** in both the core API and the maintained reconstruction example. The package provides the method and diagnostics; users should decide whether to enable it for a particular acquisition, comparison, or scientific question and should report the selected settings when it is used.
:::

## Processing order

```mermaid
flowchart LR
    A[Twix data] --> B[Prewhitening]
    B --> C[Navigator phase]
    C --> D[Phase correction]
    D --> E[Echo envelope]
    E --> F[Optional gain]
    F --> G[K-space packing]
    G --> H[Reconstruction]
```

The same fitted phase and magnitude corrections are applied to compatible imaging and PAT-reference acquisitions according to their slice and echo counters. This avoids reconstructing imaging data in one correction basis while calibrating GRAPPA or sensitivity estimation from another.

## Scientific basis for echo-envelope correction

Echo-dependent signal modulation across the TSE/RARE echo train maps into the phase-encoding direction through echo-to-$k_y$ ordering. The resulting k-space modulation can broaden the phase-encoding point-spread function or produce structured ringing when the modulation is discontinuous. Correction of this effect has a long history in RARE/FSE reconstruction.

The current implementation is most closely related to four published lines of work:

| Reference | Relevant idea | Relation to this implementation |
| --- | --- | --- |
| [[16]](/references#ref-16 "Oshio and Singh, IEEE TMI 1992") | Correction of T2-dependent distortion in multi-excitation RARE, including human studies | Establishes RARE/TSE echo-modulation correction as a reconstruction problem; the present code uses a different measured-envelope formulation |
| [[17]](/references#ref-17 "Zhou et al., JMRI 1993") | Demodulation of FSE phase-encoding weighting using a set of non-phase-encoded echoes acquired after an extra excitation | Closest acquisition precedent for the present unencoded navigator echo train; the present code estimates a normalized measured envelope directly rather than fitting multiple tissue-specific T2 values |
| [[18]](/references#ref-18 "Chen et al., IEEE TMI 1994") | Global T2 amplitude restoration in k-space using Wiener filtering while accounting for additive noise | Direct precedent for regularized global k-space amplitude restoration; the present implementation does not reproduce the paper's additional local linear-prediction stage |
| [[19]](/references#ref-19 "Busse et al., MRM 2000") | Wiener demodulation of FSE k-space before reconstruction to reduce T2-decay blur while constraining inverse-filter noise | Direct precedent for using Wiener regularization instead of unstable inverse-envelope weighting |

These references support the **general strategy** of estimating or modeling echo-train modulation and compensating it before image reconstruction. They do not imply that the exact gain function or automatic regularization used here is identical to any one published implementation.

The classical Wiener theory in [[15]](/references#ref-15 "Wiener, 1949") provides the general inverse-filtering background; references [[16]](/references#ref-16 "Oshio and Singh, IEEE TMI 1992")–[[19]](/references#ref-19 "Busse et al., MRM 2000") are the MRI-specific methodological basis.

## How the current implementation differs from a tissue T2 model

The current estimator derives one normalized scalar envelope value for each slice and echo,

$$
A_{s,e}>0,
\qquad
A_{s,e_{\mathrm{ref}}}=1,
$$

from the measured non-phase-encoded navigator data after prewhitening and noise-floor correction.

It therefore represents a **measured effective echo-train envelope**, not a voxelwise estimate of tissue $T_2$. In general, the true TSE modulation can depend on

$$
E_e(\mathbf r)
=
E_e\!\left(
T_1(\mathbf r),
T_2(\mathbf r),
B_1^+(\mathbf r),
\text{slice profile},
\{\alpha_n\},
\ldots
\right),
$$

so a single $A_{s,e}$ cannot invert spatially varying tissue, $B_1^+$, stimulated-echo, or slice-profile behavior. This is why the feature is described as **navigator-derived global echo-envelope equalization**, rather than as a quantitative T2 correction.

## Noise prewhitening first

Let the mean-removed noise matrix be

$$
\mathbf N\in\mathbb C^{M\times C},
$$

where $M$ is the number of noise samples and $C$ is the number of receive channels. The sample covariance is regularized toward its diagonal and an inverse Hermitian square root is used to construct a prewhitening transform $\mathbf W_N$.

For row-wise coil data $\mathbf D$,

$$
\widetilde{\mathbf D}=\mathbf D\mathbf W_N.
$$

The transform is applied consistently to image, phase-correction, and reference data. If no usable noise stream exists, the reconstruction warns and falls back to an identity transform rather than silently claiming that prewhitening was performed.

## Navigator phase model

For slice $s$, echo $e$, receive channel $c$, and normalized readout coordinate $\kappa$, define the relative navigator with respect to a reference echo $e_{\mathrm{ref}}$ as

$$
z_{s,e,c}(\kappa)
=
n_{s,e,c}(\kappa)
n^*_{s,e_{\mathrm{ref}},c}(\kappa).
$$

The unwrapped relative phase is fitted with a magnitude-weighted linear model,

$$
\arg z_{s,e,c}(\kappa)
\approx
\beta_{1,s,e,c}\kappa
+
\beta_{0,s,e,c}.
$$

The two terms capture

- $\beta_0$: echo-to-echo constant phase offset;
- $\beta_1$: readout-linear phase variation.

The correction is

$$
p_{s,e,c}(\kappa)
=
\exp\!\left[-i\left(
\beta_{1,s,e,c}\kappa+
\beta_{0,s,e,c}
\right)\right].
$$

This is a transparent offline model of the constant and readout-linear components visible in the TSE navigator. It is **not** a reproduction of proprietary Siemens ICE filtering or adaptive reconstruction internals.

## Echo-magnitude estimate

Repeated navigators are complex averaged before estimating their power. The implementation uses the prewhitened noise estimate to remove the expected navigator noise floor before normalizing each echo to a reference echo.

Denote the resulting normalized magnitude by

$$
A_{s,e}>0,
\qquad
A_{s,e_{\mathrm{ref}}}=1.
$$

This measured navigator envelope is used only when echo-magnitude correction is enabled.

## Power-law equalization

The backward-compatible power-law gain is

$$
g^{\mathrm{power}}_{s,e}
=
A_{s,e}^{\alpha-1},
\qquad 0\leq\alpha\leq1.
$$

Interpretation:

- $\alpha=0$: target full inverse-envelope equalization;
- $\alpha=1$: preserve the measured envelope;
- intermediate $\alpha$: partial equalization.

Direct inversion can amplify late-echo noise strongly when $A_{s,e}$ is small.

## Wiener-style regularized equalization

The alternative normalized Wiener-style gain is

$$
g^{\mathrm{W}}_{s,e}
=
(1+\lambda_s)
\frac{A_{s,e}^{\alpha+1}}
{A_{s,e}^2+\lambda_s}.
$$

This normalization gives

$$
g^{\mathrm{W}}(A=1)=1
$$

for any non-negative $\lambda_s$, and approaches the power-law form as $\lambda_s\rightarrow0$.

With `EchoMagnitudeLambda='auto'`, the code chooses a separate $\lambda_s$ for each slice from the larger of

- a navigator noise-to-signal regularization term; and
- the regularization needed to respect the configured smooth maximum-gain target.

`EchoMagnitudeMaxGain` therefore changes the **regularized gain curve**. It is not implemented as a hard post-hoc clipping operation.

The factor $(1+\lambda_s)$ and the automatic $\lambda_s$ rule are implementation choices used to retain unity gain at the reference envelope and to provide a practical noise/gain safeguard. They should be described as a **Wiener-style regularized equalizer**, not as a uniquely optimal Wiener estimator.

## Defaults and explicit opt-in

The core API uses

```matlab
'EchoMagnitudeCorrection', false
'EchoMagnitudeMethod', 'power'
'EchoMagnitudeAlpha', 1
```

The maintained example also keeps the operation disabled:

```matlab
applyEchoMagnitudeCorrection = false;
```

When a user deliberately enables the feature, a practical regularized configuration is available through

```matlab
'EchoMagnitudeCorrection', true
'EchoMagnitudeMethod', 'wiener'
'EchoMagnitudeAlpha', 0
'EchoMagnitudeLambda', 'auto'
'EchoMagnitudeMaxGain', 2
```

These settings are **available options, not a recommendation that all TSE data should be equalized**. The appropriate choice depends on echo ordering, echo envelope, tissue contrast, noise, acceleration, field strength, and the purpose of the reconstruction.

## What the correction can and cannot do

Echo-magnitude equalization can reduce a measured global navigator envelope imposed across phase-encoding lines and may reduce TSE blur or ringing when that envelope is an important source of k-space modulation. However,

- upweighting a weak echo also upweights its noise;
- one slice-wise envelope does not represent all tissues or all spatial locations;
- stimulated echoes, $B_1^+$, slice profile, relaxation, motion, and other effects are not explicitly inverted;
- the method does not recover information that was never encoded;
- changing the echo envelope can change image contrast as well as apparent sharpness;
- the uncorrected reconstruction should be retained for comparison when the method is evaluated.

For quantitative T2 estimation or claims of tissue-specific signal restoration, a tissue- and sequence-aware model such as EPG/Bloch simulation would be required in addition to, or instead of, this global measured-envelope correction.

## Reporting the option

If echo-magnitude equalization is used in a study, report at least

- whether it was enabled;
- navigator/reference echo definition;
- `EchoMagnitudeMethod`;
- `EchoMagnitudeAlpha`;
- manual or automatic $\lambda$ selection;
- `EchoMagnitudeMaxGain` when automatic regularization is used;
- measured echo envelope and gain range when relevant; and
- whether corrected and uncorrected reconstructions were compared.

This allows another user to reproduce the reconstruction without implying that the optional correction is part of the sequence definition itself.

For the acquisition-side interpretation, see [TSE signal and echo-train model](/theory/tse-echo-train). For the full processing chain, see [Reconstruction workflow](/reconstruction).
