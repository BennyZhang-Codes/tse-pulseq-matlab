# TSE signal and echo-train model

This page presents the acquisition model in the order used by a Methods section: **continuous signal → discrete echo-train formulation → matrix form → current numerical realization → reconstruction approximations**. Code variables and array layouts are discussed only after the physical model is defined.

## 1. Continuous signal model

For receive channel $c$, the complex MR signal can be written as

$$
s_c(t)
=
\int_{\Omega}
m(\mathbf r)\,C_c(\mathbf r)\,E(\mathbf r,t)
\exp\!\left[-i2\pi\mathbf k(t)\cdot\mathbf r\right]
\,d\mathbf r
+\varepsilon_c(t),
$$

where

- $m(\mathbf r)$ is the underlying transverse object representation;
- $C_c(\mathbf r)$ is the complex receive sensitivity;
- $E(\mathbf r,t)$ contains echo-train-dependent amplitude and phase;
- $\mathbf k(t)$ is the logical Cartesian encoding trajectory; and
- $\varepsilon_c(t)$ is receive noise.

For a TSE acquisition, the critical feature is that $E(\mathbf r,t)$ changes across the echo train while different echoes are assigned to different phase-encoding locations. This couples **echo evolution** to **k-space ordering**.

The original RARE/TSE concept is described by Hennig et al. [[1]](/references#ref-1 "Hennig et al. RARE, MRM 1986"). The repository expresses the acquisition using Pulseq, which provides a hardware-independent sequence description layer [[2]](/references#ref-2 "Layton et al. Pulseq, MRM 2017").

## 2. Discrete echo-train formulation

Let

- $e=1,\ldots,N_E$ denote echo index;
- $j$ denote the ADC sample within one readout;
- $v$ denote voxel index;
- $c$ denote receive channel; and
- $k_{y,e}$ denote the logical phase-encoding location assigned to echo $e$.

A discrete Cartesian model is

$$
y_{e,j,c}
\approx
\sum_{v=1}^{N_v}
m_v\,C_{v,c}\,E_{e,v}
\exp\!\left[-i2\pi
\left(k_{x,e,j}x_v+k_{y,e}y_v\right)
\right]\Delta V
+\varepsilon_{e,j,c}.
$$

The echo-dependent factor may be written

$$
E_{e,v}=A_{e,v}\exp(i\phi_{e,v}),
$$

but this factor should **not** be interpreted as a single-exponential $T_2$ model in general. Real TSE signal evolution can include

- refocusing-flip-angle history;
- stimulated-echo pathways;
- B1+ variation;
- excitation/refocusing slice profiles;
- relaxation; and
- other sequence-specific phase terms.

A simple exponential envelope is useful intuition, but predictive modeling of a variable-flip-angle TSE train generally requires Bloch- or EPG-style modeling.

## 3. Echo-to-$k_y$ mapping and PSF

If the PE schedule assigns echo $e(k_y)$ to logical phase-encoding coordinate $k_y$, then the echo train produces a PE modulation

$$
w(k_y,\mathbf r)=E_{e(k_y)}(\mathbf r).
$$

Ignoring spatial dependence momentarily, the corresponding phase-encoding point-spread behavior is approximately

$$
\mathrm{PSF}_{\mathrm{PE}}(y)
\propto
\mathcal F^{-1}_{k_y}\!\left\{w(k_y)\right\}.
$$

This explains why echo ordering, effective TE, turbo factor, refocusing schedule, tissue properties, and reconstruction should be considered together rather than as unrelated controls.

## 4. Matrix formulation

For one echo, define a diagonal echo-modulation operator

$$
D_e=\operatorname{diag}(E_{e,1},\ldots,E_{e,N_v}),
$$

coil-sensitivity operator $S$, centered Cartesian Fourier operator $F$, and a sampling operator $P_e$ that selects the samples assigned to echo $e$.

The physical acquisition model can then be expressed compactly as

$$
y_e=P_eFSD_e x+\varepsilon_e.
$$

Stacking all echoes gives

$$
\mathbf y
=
\begin{bmatrix}
P_1FSD_1\\
P_2FSD_2\\
\vdots\\
P_{N_E}FSD_{N_E}
\end{bmatrix}x
+\boldsymbol\varepsilon
\equiv
E_{\mathrm{TSE}}x+\boldsymbol\varepsilon.
$$

This matrix level is the bridge between acquisition physics and the reconstruction implementation. It also makes explicit that changing the PE schedule changes the stacked operator even if the underlying RF echo train is unchanged.

## 5. Current explicit implementation

The sequence generator resolves the acquisition in two stages:

```text
requested Setup
→ resolved echo timing / PE ordering / labels
→ Pulseq RF, gradient, ADC and definition blocks
```

The current MATLAB implementation uses `prep_PE3DOrder` to determine the logical PE order and current platform metadata, then assembles the pulse sequence through the preparation/sequence-loop functions documented in [Sequence API](/reference/sequence-api).

For the currently validated Siemens path, logical $k_y$ must be distinguished from Siemens LIN metadata and from one-based mapVBVD indices. See [Symbols & notation](/theory/symbols) and [Siemens 7 T LIN & ICE](/phase-encoding-and-ice).

## 6. Reconstruction model after correction

The bundled iterative reconstruction does **not** explicitly invert the full spatially varying $D_e$ model. Instead, it first applies measured navigator-based corrections to reduce dominant echo-dependent phase and optional magnitude modulation in the acquired data.

After preprocessing, SENSE and CS use the simplified Cartesian multicoil model

$$
A=PFS,
$$

which can be interpreted as assuming that the retained echo-dependent modulation is sufficiently small or is treated as part of the effective image contrast rather than explicitly modeled in the encoding operator.

This distinction is important:

> **The acquisition model is TSE echo dependent; the current iterative reconstruction model is a corrected Cartesian $PFS$ model.**

The navigator correction therefore changes the data presented to the reconstruction, not the fundamental RF echo-train physics.

## 7. Effective TE

The maintained sequence exposes

```matlab
Setup.TE1
Setup.TEeff
Setup.nEcho
```

The current center-echo prescription is

$$
e_0
=
\max\!\left(
\operatorname{round}\!\left(\frac{T_{E,\mathrm{eff}}}{T_{E,1}}\right),
1
\right).
$$

The PE order is shifted so that physical $k_y=0$ is associated with echo $e_0$ when the discrete train allows it.

::: info Effective TE is a mapping, not a complete contrast model
`TEeff` specifies the desired relationship between the echo train and central k-space. Final image contrast still depends on the full echo envelope, PE ordering, refocusing schedule, tissue properties, B1+, and reconstruction.
:::

## 8. Linear and centric ordering

The maintained sequence supports `Linear`, `CentricFull`, and `CentricHalf` PE modes.

- **Linear** ordering distributes consecutive echoes progressively through $k_y$ and generally produces a smoother echo-envelope modulation across PE.
- **Centric** ordering prioritizes central k-space around the requested center echo and redistributes later-echo attenuation toward outer spatial frequencies.

Neither is universally superior. Comparisons should hold geometry, echo spacing, turbo factor, RF schedule, acceleration, and reconstruction protocol fixed.

See [Phase encoding & effective TE](/theory/phase-encoding) for the exact logical-order interpretation.

## 9. Refocusing schedules and gSlider

Conventional TSE can use a fixed `Setup.rflip`. The gSlider entry point can enable a TRAPS schedule:

```matlab
Setup.TRAPS = 'on';
```

Variable refocusing angles alter stimulated-echo pathways and echo amplitudes. gSlider excitation additionally changes the slab/subslice encoding problem. These effects belong to the physical acquisition model and should not be reduced to a scalar post-reconstruction intensity correction.

See [gSlider & TRAPS](/guide/gslider-traps).

## 10. Echo correction as a measured data model

The navigator model estimates a relative echo phase and amplitude envelope from acquired phase-correction data. The current correction layer includes

1. per-slice/per-echo/per-coil phase correction; and
2. optional power or Wiener-style echo-magnitude equalization.

The magnitude correction can reduce line-to-line envelope modulation but increases noise when weak echoes are upweighted. It is therefore a controlled preprocessing trade-off, not a replacement for sequence design or a full inversion of $D_e$.

See [Echo phase & magnitude correction](/guide/echo-corrections).

## 11. Relation to previous methods

The repository combines established MRI components rather than presenting every component as new.

| Component | Established basis | Current implementation |
| --- | --- | --- |
| TSE / RARE echo train | Multi-echo spin-echo acquisition [[1]](/references#ref-1 "Hennig et al. RARE, MRM 1986") | Pulseq implementation with explicit echo-to-$k_y$ ordering |
| Portable sequence description | Pulseq [[2]](/references#ref-2 "Layton et al. Pulseq, MRM 2017") | MATLAB sequence-generation and scanner-integration layers |
| Parallel imaging | SENSE / GRAPPA [[5]](/references#ref-5 "Griswold et al. GRAPPA, MRM 2002") [[6]](/references#ref-6 "Pruessmann et al. SENSE, MRM 1999") | Diagnostic PE-GRAPPA and ESPIRiT-SENSE paths |
| Sensitivity estimation | ESPIRiT [[7]](/references#ref-7 "Uecker et al. ESPIRiT, MRM 2014") | Native MATLAB single-map estimator |
| Compressed sensing | Sparse MRI [[8]](/references#ref-8 "Lustig et al. Sparse MRI, MRM 2007") | Cartesian TV + Haar regularized solver |
| Echo correction | Navigator-based measured correction concept | TSE-specific phase fit plus optional regularized magnitude equalization |

The useful software contribution is the explicit integration of sequence generation, scanner metadata, correction, reconstruction, and validation in one inspectable research workflow. Claims should remain attached to the actually validated platform and experiments.

## 12. Implementation conventions

When translating equations to code, preserve these distinctions:

- logical signed $k_y$ is not Siemens LIN;
- sequence-side LIN metadata are zero based;
- mapVBVD indices are one based;
- prewhitening matrix and Haar-wavelet transform are different operators;
- measured echo corrections are data preprocessing, not the same object as $D_e$ in the physical model;
- the current iterative forward operator is Cartesian $PFS$ after correction.

The common notation is centralized in [Symbols & notation](/theory/symbols).

## Design checklist

When modifying a TSE protocol, inspect together

- `TE1`, `TEeff`, and `nEcho`;
- PE mode and the echo assigned to physical $k_y=0$;
- fixed or variable refocusing angles;
- RF duration/slice profile and crusher timing;
- PI/CS sampling and ACS placement;
- navigator phase and amplitude behavior;
- PE blur/ringing under a matched reconstruction protocol; and
- scanner RF/SAR/PNS consequences.

Continue with [Phase encoding & effective TE](/theory/phase-encoding), then [Reconstruction](/reconstruction) and [Scientific validation strategy](/validation/scientific-validation).
