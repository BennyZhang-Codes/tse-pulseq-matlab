# TSE echo-train model

Turbo spin echo acquires multiple phase-encoding lines after one excitation. The key design question is therefore not only *when* an echo is formed, but also **which echo samples which part of k-space**.

## Echo-dependent modulation

Let $e=1,\ldots,N_E$ denote the echo index and let $E_e(\mathbf r)$ denote the complex signal modulation at that echo. If the phase-encoding schedule assigns echo $e(k_y)$ to logical phase-encoding coordinate $k_y$, then the acquired k-space is modulated by

$$
w(k_y,\mathbf r)=E_{e(k_y)}(\mathbf r).
$$

Ignoring spatial dependence for a moment, the phase-encoding point-spread behavior is approximately related to

$$
\mathrm{PSF}_{\mathrm{PE}}(y)
\propto
\mathcal F_{k_y}^{-1}\!\left\{w(k_y)\right\}.
$$

A smooth decay across $k_y$ broadens the PSF; abrupt changes can introduce ringing or other structured modulation. This is why echo ordering, turbo factor, refocusing-angle schedule, effective TE, and tissue-dependent relaxation should be considered together rather than as independent controls.

## First echo and effective TE

The maintained sequence exposes

```matlab
Setup.TE1
Setup.TEeff
Setup.nEcho
```

`TE1` sets the first-echo timing. `TEeff` expresses which echo should sample physical $k_y=0$ as closely as the discrete echo train permits.

The current center-echo prescription is

$$
e_0
=
\max\!\left(
\operatorname{round}\!\left(\frac{T_{E,\mathrm{eff}}}{T_{E,1}}\right),
1
\right).
$$

The phase-encoding order is then shifted so that physical $k_y=0$ is associated with echo $e_0$ when possible.

::: info Effective TE is an acquisition mapping
`TEeff` does not by itself determine image contrast. It specifies the desired relationship between the echo train and central k-space. The final contrast and PSF also depend on the complete echo envelope, PE ordering, refocusing schedule, tissue properties, and reconstruction.
:::

## Linear and centric ordering

The maintained sequence supports `Linear`, `CentricFull`, and `CentricHalf` PE modes.

- **Linear** ordering distributes consecutive echoes progressively across $k_y$. Echo-envelope variation therefore appears as a comparatively smooth modulation along the phase-encoding direction.
- **Centric** ordering acquires central k-space early or around the prescribed center echo and moves outward. It can emphasize the contrast associated with the central echo but changes how late-echo attenuation is distributed over high spatial frequencies.

Neither ordering is universally superior. Compare them with fixed geometry, echo spacing, turbo factor, and refocusing schedule when studying blur, ringing, or contrast changes.

## Refocusing flip-angle schedules

Conventional TSE can use a fixed refocusing angle through `Setup.rflip`. The gSlider entry point can additionally enable a TRAPS schedule:

```matlab
Setup.TRAPS = 'on';
```

Variable refocusing angles change the echo amplitudes and stimulated-echo pathways. They can reduce RF power or reshape the echo train, but they also change the relationship between nominal `TEeff` and the actual tissue-dependent signal envelope.

The sequence generator creates the requested schedule; it does **not** claim that a simple exponential decay fully predicts the resulting TSE contrast. For predictive tissue-specific modeling, use a Bloch/EPG-style simulation appropriate to the RF pulses, slice profiles, B1 distribution, and relaxation parameters.

## Echo-magnitude correction is not a replacement for acquisition design

The offline MATLAB workflow can estimate a navigator-derived echo amplitude $A_e$ and apply an optional equalization gain. This can reduce measured line-to-line envelope modulation, but it has an unavoidable noise trade-off: inverse weighting of a weak late echo amplifies its noise.

The regularized Wiener-style method therefore limits inversion through a smooth regularization parameter rather than blindly forcing every echo to the same magnitude. See [Echo phase & magnitude correction](/guide/echo-corrections).

Even successful equalization does not recover information that was never acquired. It also does not explicitly invert the complete tissue-dependent TSE point-spread function or stimulated-echo physics.

## Design checklist

When modifying a TSE protocol, inspect the following together:

- `TE1`, `TEeff`, and `nEcho`;
- `PEMode` and the echo assigned to physical $k_y=0$;
- fixed or variable refocusing angles;
- excitation/refocusing durations and crusher timing;
- PI/CS sampling and ACS placement;
- measured navigator phase/magnitude behavior;
- phase-encoding blur/ringing in matched phantom data;
- RF/SAR and scanner-side safety consequences.

Continue with [Phase encoding & effective TE](/theory/phase-encoding) for the logical sampling model and [Sequence Generation](/sequence-generation) for the MATLAB implementation.
