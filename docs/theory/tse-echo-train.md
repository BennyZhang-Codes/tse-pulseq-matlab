# TSE signal & echo-train implementation

This page explains the signal model only to the level needed to understand the sequence implementation: **why echo ordering matters, what the code is assigning to $k_y$, and why the reconstruction cannot treat every acquired row as physically identical before correction**.

The acquisition is a Pulseq implementation [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552.") of a RARE/TSE-family echo train [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.").

## Echo-dependent acquisition model

For receive channel $c$,

$$
s_c(t)
=
\int_\Omega
m(\mathbf r)C_c(\mathbf r)E(\mathbf r,t)
\exp[-i2\pi\mathbf k(t)\cdot\mathbf r]
\,d\mathbf r
+\varepsilon_c(t).
$$

The implementation-relevant term is $E(\mathbf r,t)$: the TSE echo train changes while different echoes are assigned to different PE rows.

For echo $e$, readout sample $j$, voxel $v$ and coil $c$,

$$
y_{e,j,c}
\approx
\sum_v
m_v C_{v,c} E_{e,v}
\exp[-i2\pi(k_{x,e,j}x_v+k_{y,e}y_v)]\Delta V
+\varepsilon_{e,j,c}.
$$

The echo factor $E_{e,v}$ can include relaxation, refocusing history, stimulated echoes, B1 and slice-profile effects. It should not generally be reduced to a single global exponential.

## Why PE ordering matters

If `prep_PE3DOrder` assigns echo $e(k_y)$ to a logical PE coordinate, the sequence places the echo modulation across k-space as

$$
w(k_y,\mathbf r)=E_{e(k_y)}(\mathbf r).
$$

Ignoring spatial dependence for intuition,

$$
\mathrm{PSF}_{\mathrm{PE}}(y)
\propto
\mathcal F^{-1}_{k_y}\{w(k_y)\}.
$$

Therefore `PEMode`, ETL, `TEeff`, refocusing angles and optional echo correction affect the same acquisition/reconstruction chain.

```mermaid
flowchart LR
    A[RF echo train] --> B[Echo amplitudes / phases]
    B --> C[Echo-to-ky assignment]
    C --> D[PE k-space modulation]
    D --> E[Image contrast + PSF]
```

## Physical operator versus implemented reconstruction

For one echo, a convenient physical model is

$$
y_e=P_eFSD_ex+\varepsilon_e,
$$

where

- $D_e$ contains echo-dependent voxel modulation;
- $S$ contains receive sensitivities;
- $F$ is Cartesian Fourier encoding; and
- $P_e$ selects the samples assigned to echo $e$.

Stacking all echoes yields an echo-dependent TSE encoding operator.

The current iterative reconstruction does **not** solve this full spatially varying model. After measured navigator preprocessing, SENSE/CS use

$$
A=PFS.
$$

This is an explicit implementation choice:

> The sequence is physically echo dependent; the current iterative reconstructor uses a corrected Cartesian $PFS$ model.

See [Reconstruction](/reconstruction) for the implemented operator, solver and options.

## Effective TE in the code

The sequence exposes

```matlab
Setup.TE1
Setup.TEeff
Setup.nEcho
```

and uses the approximate center-echo prescription

$$
e_0
=
\max\!\left[
\operatorname{round}\!\left(\frac{T_{E,\mathrm{eff}}}{T_{E,1}}\right),1
\right].
$$

The PE order is shifted so that physical $k_y=0$ is acquired near echo $e_0$ when the discrete matrix/ETL/acceleration pattern permits it.

`TEeff` is therefore primarily a **center-k-space placement parameter** in the implementation. Final tissue contrast still depends on the entire echo train.

## Linear and centric modes

The maintained modes are

```text
Linear
CentricFull
CentricHalf
```

- **Linear** distributes echo evolution progressively through $k_y$.
- **Centric** prioritizes central k-space around the selected effective echo and moves other echoes toward higher spatial frequencies.

Neither ordering is universally preferable. The sequence code makes the mapping explicit so it can be inspected and validated rather than hidden inside scanner reconstruction assumptions.

See [Phase encoding & acceleration](/theory/phase-encoding) for the exact logical sampling/ordering path.

## Variable refocusing and gSlider

The conventional entry point can use fixed refocusing angles. `TSE_2D_gSlider.m` can additionally use a TRAPS-style schedule based on Hennig et al. [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535."). Variable refocusing changes stimulated-echo pathways and therefore changes $E_{e,v}$.

The gSlider excitation itself follows gSlider RF encoding [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151."), while the repository's TSE-specific implementation is associated with [[14]](/references#ref-14 "Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. Proc Intl Soc Magn Reson Med. 2024; Program #3256.").

See [gSlider-TSE & TRAPS](/guide/gslider-traps) for code-level behavior.

## Echo-envelope correction in this model

The navigator path estimates measured phase and a global slice-level echo envelope. Optional magnitude equalization can reduce the measured line-to-line modulation before the simplified $PFS$ reconstruction, drawing on prior RARE/FSE correction literature [[16]](/references#ref-16 "Oshio K, Singh M. Correction of T2 distortion in multi-excitation RARE sequence. IEEE Trans Med Imaging. 1992;11:123-128.")–[[19]](/references#ref-19 "Busse RF, Riederer SJ, Fletcher JG, Bharucha AE, Brandt KR. Interactive fast spin-echo imaging. Magn Reson Med. 2000;44:339-348.").

The measured slice-level envelope is not equivalent to $D_e$ because $D_e$ can vary spatially and by tissue. See [Echo phase & magnitude correction](/guide/echo-corrections).

## Established components used by the package

| Component | Method basis | Repository implementation |
| --- | --- | --- |
| RARE/TSE echo train | [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.") | Pulseq TSE loops and explicit PE ordering |
| Pulseq sequence description | [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq. Magn Reson Med. 2017;77:1544-1552.") | `pulseq/` submodule and MATLAB `mr.*` events |
| PI reconstruction | GRAPPA [[5]](/references#ref-5 "Griswold MA, Jakob PM, Heidemann RM, et al. GRAPPA. Magn Reson Med. 2002;47:1202-1210."); SENSE [[6]](/references#ref-6 "Pruessmann KP, Weiger M, Scheidegger MB, Boesiger P. SENSE. Magn Reson Med. 1999;42:952-962.") | PE-GRAPPA and ESPIRiT-SENSE |
| Sensitivity estimation | ESPIRiT [[7]](/references#ref-7 "Uecker M, Lai P, Murphy MJ, et al. ESPIRiT. Magn Reson Med. 2014;71:990-1001.") | repository single-map MATLAB estimator |
| CS | Sparse MRI [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI. Magn Reson Med. 2007;58:1182-1195.") | Lustig-derived PE sampling + TV/Haar-L1 reconstruction |

For the full source/citation lineage, see [Dependencies & method provenance](/reference/provenance).

## Implementation checklist

When changing the sequence, inspect together

- `TE1`, `TEeff`, ETL and PE mode;
- which echo acquires physical $k_y=0$;
- PI/CS sampling and ACS placement;
- fixed or variable refocusing angles;
- RF duration/profile and crusher timing;
- navigator phase/envelope behavior; and
- matched reconstruction blur/ringing and contrast.
