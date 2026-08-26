# TSE echo train

This page explains the sequence behavior needed to understand `TEeff`, echo ordering, and phase encoding in this package.

The acquisition is a Pulseq implementation [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552.") of a RARE/TSE echo train [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.").

## Why echo ordering matters

A TSE train acquires different phase-encoding lines at different echo times. If echo $e$ is assigned to phase-encoding coordinate $k_y$, the echo-dependent signal amplitude becomes a weighting across k-space:

$$
w(k_y)=E_{e(k_y)}.
$$

Its inverse Fourier transform contributes to the phase-encoding point-spread function, so echo ordering affects image contrast and TSE blurring.

```mermaid
flowchart LR
    A[TSE echo train] --> B[Echo amplitudes]
    B --> C[Echo-to-ky assignment]
    C --> D[k-space weighting]
    D --> E[Contrast + PSF]
```

This is why `nEcho`, `TE1`, `TEeff`, refocusing behavior, and `PEMode` should be considered together.

## Effective TE in the sequence

The main timing parameters are

```matlab
Setup.TE1
Setup.TEeff
Setup.nEcho
Setup.TR
```

The code estimates the desired center echo approximately as

$$
e_0=
\max\!\left[
\operatorname{round}\!\left(\frac{T_{E,\mathrm{eff}}}{T_{E,1}}\right),1
\right].
$$

The PE-order generator then places physical $k_y=0$ near that echo when the matrix, ETL, and acceleration pattern permit it.

So in this implementation, `TEeff` primarily controls **which echo is assigned to central k-space**. The final image still reflects the full echo train rather than one isolated echo.

## PE ordering modes

The maintained modes are:

```text
Linear
CentricFull
CentricHalf
```

- **Linear** distributes echo evolution progressively across $k_y$.
- **CentricFull** and **CentricHalf** prioritize central k-space around the selected effective echo and assign other echoes toward higher spatial frequencies according to the implemented ordering rule.

The exact logical PE/echo mapping is documented in [Phase Encoding & Acceleration](/theory/phase-encoding).

## gSlider-TSE

`TSE_2D_gSlider.m` uses the same basic TSE echo-train concept with gSlider RF encoding. The gSlider method basis is [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151."), and the repository's TSE-specific implementation is associated with [[14]](/references#ref-14 "Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. Proc Intl Soc Magn Reson Med. 2024; Program #3256."). See [gSlider-TSE](/guide/gslider-tse).

An experimental TRAPS-style variable-refocusing test path also exists in the source, but it is not a core gSlider-TSE feature.

## Reconstruction relation

The physical TSE signal is echo dependent, but the current SENSE/CS reconstruction uses the Cartesian multicoil model

$$
A=PFS
$$

after preprocessing. Optional navigator-derived echo magnitude correction can reduce a measured global echo-envelope modulation before reconstruction, but it is not a spatially resolved T2 model.

See [Reconstruction](/reconstruction) and [Optional Echo Correction](/guide/echo-corrections).
