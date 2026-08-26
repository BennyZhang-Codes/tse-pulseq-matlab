# Symbols and notation

This page is the common notation source for the Theory, Reconstruction, Validation, and Reference sections. The purpose is not only convenience: a centralized symbol table helps expose inconsistencies in phase sign, indexing, units, and array layout before they become implementation bugs.

## Indices

| Symbol | Meaning |
| --- | --- |
| $e$ | Echo index within the TSE echo train |
| $j$ | ADC sample index within one readout |
| $v$ | Voxel index |
| $c$ | Receive-channel index |
| $p$ | Logical phase-encoding-line index when a line-oriented index is useful |
| $s$ | Slice index |

## Dimensions

| Symbol | Meaning |
| --- | --- |
| $N_E$ | Echo-train length / turbo factor (`nEcho`) |
| $N_x$ | Reconstructed/readout matrix size |
| $N_y$ | Reconstructed/phase-encoding matrix size |
| $N_v=N_xN_y$ | Number of in-plane voxels for a 2D slice |
| $N_c$ | Number of receive channels |
| $N_s$ | Number of slices |
| $R$ | Parallel-imaging / sampling acceleration factor |

## Physical quantities

| Symbol | Meaning | Typical units |
| --- | --- | --- |
| $\mathbf r=(x,y)$ | In-plane spatial coordinate | m |
| $\Delta V$ | Voxel area/volume factor in a discrete integral | m² or m³ |
| $t$ | Continuous sequence/readout time | s |
| $T_{E,1}$ | First-echo time (`TE1`) | s |
| $T_{E,\mathrm{eff}}$ | Requested effective echo time (`TEeff`) | s |
| $\mathbf k=(k_x,k_y)$ | Logical Cartesian spatial-frequency coordinate | cycles/m |
| $k_{y,e}$ | Logical PE coordinate assigned to echo $e$ | cycles/m |
| $m(\mathbf r)$ | Underlying complex transverse object representation | arbitrary MR signal units |
| $C_c(\mathbf r)$ | Complex receive sensitivity | relative / arbitrary |
| $E_e(\mathbf r)$ | Echo-dependent complex TSE modulation | dimensionless relative factor |
| $A_e$ | Navigator-derived normalized echo magnitude | relative |
| $\phi_e$ | Echo-dependent phase | rad |

The common continuous signal model is

$$
s_c(t)
=
\int_\Omega m(\mathbf r)C_c(\mathbf r)E(\mathbf r,t)
\exp\!\left[-i2\pi\mathbf k(t)\cdot\mathbf r\right]d\mathbf r
+\varepsilon_c(t).
$$

See [TSE signal and echo-train model](/theory/tse-echo-train) for the discrete and matrix formulations.

## Encoding and reconstruction operators

| Symbol | Meaning |
| --- | --- |
| $D_e$ | Diagonal voxel-domain echo-modulation operator for echo $e$ |
| $S$ | Coil-sensitivity multiplication operator |
| $F$ | Centered unitary 2D Cartesian Fourier transform |
| $P_e$ | Sampling operator for samples assigned to echo $e$ |
| $P$ | Final acquired-line sampling operator after k-space packing |
| $E_{\mathrm{TSE}}$ | Stacked physical TSE encoding model across echoes |
| $A=PFS$ | Current corrected Cartesian multicoil forward operator used by SENSE/CS |
| $A^H$ | Adjoint of the current Cartesian forward operator |
| $y$ | Measured/preprocessed multicoil k-space vector |
| $x$ | Reconstructed complex image |

For one echo,

$$
y_e=P_eFSD_ex+\varepsilon_e,
$$

whereas the current iterative reconstruction after navigator preprocessing uses

$$
Ax=PFSx.
$$

The distinction between $E_{\mathrm{TSE}}$ and $A$ is intentional: the former describes echo-dependent acquisition physics, while the latter is the implemented corrected Cartesian reconstruction model.

## Noise and weighting operators

| Symbol | Meaning |
| --- | --- |
| $\Psi$ | Receive-noise covariance matrix |
| $W_N$ | Receive-noise prewhitening matrix derived from $\Psi$ |
| $W_H$ | Orthonormal Haar transform used by the CS regularizer |
| $D$ | 2D finite-difference operator used by the TV regularizer |
| $\lambda_2$ | SENSE Tikhonov regularization weight |
| $\lambda_{\mathrm{TV}}$ | CS isotropic-TV weight |
| $\lambda_W$ | CS Haar-wavelet $\ell_1$ weight |

Do not reuse the same symbol $W$ for both noise whitening and wavelet regularization. They are unrelated operators with different domains and physical interpretations.

## Navigator-correction quantities

| Symbol | Meaning |
| --- | --- |
| $n_{e,c}(\kappa)$ | Navigator readout for echo $e$, channel $c$, readout coordinate $\kappa$ |
| $z_{e,c}(\kappa)$ | Relative navigator with respect to the reference echo |
| $\beta_{0,e,c}$ | Fitted constant phase offset |
| $\beta_{1,e,c}$ | Fitted readout-linear phase slope |
| $g_e$ | Echo-magnitude correction gain |
| $\lambda_e$ | Wiener-style magnitude-correction regularization when applicable |

Exact equations are documented in [Echo phase & magnitude correction](/guide/echo-corrections).

## Acquisition terms

| Term | Meaning |
| --- | --- |
| `PEMode` | Logical PE ordering mode (`Linear`, `CentricFull`, `CentricHalf`) |
| ACS | Autocalibration/reference region for parallel imaging |
| `SEG` | Current Siemens/Twix echo/segment counter used by the reconstruction path |
| `LIN` | Current Siemens phase-encoding-line metadata counter |
| `SLC` | Current Siemens/mapVBVD slice counter |

## Indexing conventions

Three coordinate/index systems must not be conflated.

1. **Logical $k_y$** — signed physical phase-encoding coordinate used to describe the acquisition independently of vendor metadata.
2. **Siemens LIN** — current platform-specific zero-based line metadata exported by the sequence integration path.
3. **MATLAB/mapVBVD indexing** — one-based indexing after Twix data are exposed to MATLAB.

A shift between LIN and MATLAB array index is therefore an indexing convention, not a change in the physical $k_y$ location. See [Siemens 7 T LIN & ICE](/phase-encoding-and-ice).

## Requested vs resolved configuration

The sequence code distinguishes requested settings from resolved settings:

- `Setup`, `SetupRF`, `SetupSpoiling` describe user intent;
- `Actual` starts from `Setup` and receives derived timing, hardware, PE, RF, slice, label, and export information during preparation.

For reproducibility, retain both requested and resolved configuration together with the exported `.seq` file and source revision.

## MATLAB array-layout conventions

The mathematics is written with explicit voxel/sample/coil indices, while MATLAB stores multidimensional arrays. The exact dimensions depend on the routine, but documentation should always state which array dimension represents

- readout sample;
- acquisition/line;
- channel;
- slice; and
- echo/segment.

Do not infer physical orientation from MATLAB dimension order alone. Scanner orientation and NIfTI geometry are resolved separately.

## Phase and Fourier convention

The documentation uses the encoding phase

$$
\exp\!\left[-i2\pi\mathbf k\cdot\mathbf r\right]
$$

for the forward Cartesian transform convention. Any independent reference implementation should state its sign, centering, and normalization explicitly before comparison.
