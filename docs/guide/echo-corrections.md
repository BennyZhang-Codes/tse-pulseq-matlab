# Echo phase and magnitude correction

The offline MATLAB workflow uses TSE phase-correction navigators to estimate echo-dependent phase and, optionally, echo-magnitude modulation. These operations are performed **after receive-noise prewhitening and before Cartesian k-space packing** so that imaging data and calibration/reference data remain in a consistent coil basis.

## Processing order

```mermaid
flowchart LR
    A["Twix image / phasecor / refscan / noise"] --> B["Noise prewhitening"]
    B --> C["Navigator phase estimation"]
    C --> D["Apply phase correction"]
    D --> E["Estimate echo magnitude"]
    E --> F["Optional regularized equalization"]
    F --> G["LIN-based k-space packing"]
    G --> H["RSS / GRAPPA / SENSE / CS"]
```

The same fitted phase and magnitude corrections are applied to compatible imaging and PAT-reference acquisitions according to their slice and echo counters. This avoids reconstructing imaging data in one correction basis while calibrating GRAPPA or sensitivity estimation from another.

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

The two terms capture:

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

## Legacy power-law equalization

The backward-compatible power-law gain is

$$
g^{\mathrm{power}}_{s,e}
=
A_{s,e}^{\alpha-1},
\qquad 0\leq\alpha\leq1.
$$

Interpretation:

- $\alpha=0$: full inverse-envelope equalization;
- $\alpha=1$: preserve the measured envelope;
- intermediate $\alpha$: partial equalization.

Direct inversion can amplify late-echo noise strongly when $A_{s,e}$ is small.

## Wiener-style regularized equalization

The routine-use example therefore opts into a normalized Wiener-style gain,

$$
g^{\mathrm{Wiener}}_{s,e}
=
(1+\lambda_s)
\frac{A_{s,e}^{\alpha+1}}
{A_{s,e}^2+\lambda_s}.
$$

This normalization gives

$$
g^{\mathrm{Wiener}}(A=1)=1
$$

for any non-negative $\lambda_s$, and approaches the power-law form as $\lambda_s\rightarrow0$.

With `EchoMagnitudeLambda='auto'`, the code chooses a separate $\lambda_s$ for each slice from the larger of:

- a navigator noise-to-signal regularization term; and
- the regularization needed to respect the configured smooth maximum-gain target.

`EchoMagnitudeMaxGain` therefore changes the **regularized gain curve**. It is not implemented as a hard post-hoc clipping operation.

## API defaults versus routine-use example

The core API preserves conservative backward-compatible defaults:

```matlab
'EchoMagnitudeCorrection', false
'EchoMagnitudeMethod', 'power'
'EchoMagnitudeAlpha', 1
```

The maintained routine-use example deliberately opts into the current experimental equalization workflow:

```matlab
'EchoMagnitudeCorrection', true
'EchoMagnitudeMethod', 'wiener'
'EchoMagnitudeAlpha', 0
'EchoMagnitudeLambda', 'auto'
'EchoMagnitudeMaxGain', 2
```

This distinction is intentional. A library default should not silently alter older reconstructions, while an example can demonstrate the currently preferred experimental configuration.

## What the correction can and cannot do

Echo-magnitude equalization can reduce the measured navigator envelope imposed across phase-encoding lines and may sharpen a TSE image when late echoes are attenuated. However:

- it amplifies noise whenever a weak echo is upweighted;
- the navigator envelope is not a complete tissue-dependent TSE transfer function;
- stimulated echoes, B1, slice profile, relaxation, motion, and other effects are not explicitly inverted;
- correction cannot recover spatial-frequency information that was never acquired;
- post-reconstruction denoising should be assessed separately from acquisition-side equalization.

For the acquisition-side interpretation, see [TSE echo-train model](/theory/tse-echo-train). For the full reconstruction pipeline, see [Reconstruction Workflow](/reconstruction).
