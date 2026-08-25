# gSlider-TSE and TRAPS

`TSE_2D_gSlider.m` extends the conventional Cartesian 2D TSE workflow with gSlider excitation and an optional variable refocusing-angle schedule. The sequence shares the main preparation architecture with `TSE_2D.m`, but its RF design and repetition structure require separate interpretation and validation.

## Maintained entry point

Run the gSlider sequence from the repository root:

```matlab
run('TSE_2D_gSlider.m')
```

The maintained example uses

```matlab
Setup.TRAPS       = 'on';
SetupRF.typeEx    = 'gSlider';
SetupRF.tEx       = 5.12e-3;
SetupRF.tbpEx     = 12;
SetupRF.typeRef   = 'slr';
SetupRF.tbpRef    = 6;
```

The larger excitation time-bandwidth product is one reason the gSlider RF path should be reviewed separately for peak B1, slice profile, RF energy, and scanner SAR behavior.

## TRAPS refocusing schedule

When TRAPS is enabled, the current entry point identifies the echo intended for central k-space as

$$
e_0
=
\max\!\left(
\operatorname{round}\!\left(\frac{T_{E,\mathrm{eff}}}{T_{E,1}}\right),
1
\right),
$$

and uses that location when constructing the refocusing schedule.

In code, the current implementation is generated with `fliptraps(...)` and stored in `Setup.faRef`. The schedule modifies echo amplitudes and stimulated-echo pathways relative to a fixed 180° train. Treat it as part of the TSE signal model rather than only as an RF-power setting.

## Sequence-loop differences

The gSlider path uses dedicated sequence-loop functions:

```text
prep_Seqloop_gSlider
prep_Seqloop_IR_gSlider
```

while retaining the shared preparation stages for system limits, slice positions, phase encoding, RF/refocusing preparation, gradient blocks, labels, delays, noise scans, timing checks, and sequence definitions.

This keeps conventional TSE and gSlider behavior aligned where the acquisition concepts are shared while preserving gSlider-specific repetition/excitation behavior in its own sequence loop.

## Repetitions and encoding

The maintained gSlider example uses multiple repetitions (`Setup.nRep`) associated with its excitation encoding. Keep the gSlider encoding dimension conceptually separate from the conventional receive-coil and phase-encoding dimensions.

The current repository generates gSlider acquisitions but **does not implement the corresponding offline gSlider decoding** in `recon/matlab`. The bundled MATLAB reconstruction therefore remains a conventional Cartesian 2D TSE path.

::: warning Reconstruction scope
Do not pass a gSlider acquisition through the conventional `recon_TSE2D` workflow and interpret the result as a decoded gSlider volume. A dedicated reconstruction must account for the gSlider encoding model and its calibration/conditioning.
:::

## RF and slice-profile validation

For gSlider or other high-TBP excitation designs, inspect at least:

- excitation and refocusing peak B1;
- RF duration and rasterized timing;
- nominal and measured slice/slab profile;
- B1 sensitivity at the target field strength;
- interaction between variable refocusing angles and the echo envelope;
- SAR and scanner-side RF supervision;
- crusher/spoiler behavior around the modified RF pulses.

A successful Pulseq timing check does not establish these properties.

## Relationship to effective TE

The same logical PE model is used: `TEeff` determines the desired echo for physical $k_y=0$. With TRAPS, however, the signal at that echo depends on the full refocusing history. This makes it especially important to distinguish **k-space placement of the center echo** from **a predictive tissue-contrast model**.

For echo-train interpretation, see [TSE echo-train model](/theory/tse-echo-train). For implementation details shared with conventional TSE, see [Sequence Generation](/sequence-generation).

## Citation

If the gSlider-TSE sequence is used in research, cite the associated ISMRM work listed in [Literature references](/references#ref-gslider).
