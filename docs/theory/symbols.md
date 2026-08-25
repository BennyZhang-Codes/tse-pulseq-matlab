# Symbols and notation

This page defines the notation used across the theory and reconstruction documentation. It intentionally separates **logical acquisition coordinates** from platform-specific counters such as Siemens LIN.

## Signal and encoding symbols

| Symbol | Meaning |
| --- | --- |
| $\mathbf r=(x,y)$ | In-plane spatial coordinate |
| $m(\mathbf r)$ | Underlying complex transverse image/object representation |
| $c$ | Receive-coil index |
| $C_c(\mathbf r)$ | Complex receive sensitivity for coil $c$ |
| $e$ | Echo index within the TSE echo train |
| $E_e(\mathbf r)$ | Echo-dependent complex modulation at echo $e$ |
| $A_e$ | Normalized navigator-derived echo magnitude used by the optional equalizer |
| $\phi_e$ | Echo-dependent phase term |
| $\mathbf k=(k_x,k_y)$ | Logical Cartesian k-space coordinate |
| $e(k_y)$ | Echo assigned to a logical phase-encoding location |
| $T_{E,1}$ | First-echo time (`TE1`) |
| $T_{E,\mathrm{eff}}$ | Requested effective echo time (`TEeff`) |
| $N_E$ | Echo-train length / turbo factor (`nEcho`) |
| $R$ | Acceleration factor |
| ACS | Autocalibration-signal/reference region for PI calibration |

A compact signal abstraction is

$$
y_{e,c}(k_x,k_y)
=
\int_{\Omega}
m(\mathbf r)C_c(\mathbf r)E_e(\mathbf r)
\exp\!\left[-i2\pi\mathbf k\cdot\mathbf r\right]d\mathbf r.
$$

For documentation purposes it is often useful to write

$$
E_e(\mathbf r)=A_e(\mathbf r)\exp\!\left[i\phi_e(\mathbf r)\right],
$$

while remembering that the true TSE echo behavior can include relaxation, refocusing-angle errors, stimulated-echo pathways, B1 dependence, slice-profile effects, and other sequence-specific physics. The current sequence generator does not replace those effects with a single analytical envelope model.

## Reconstruction symbols

| Symbol | Meaning |
| --- | --- |
| $x$ | Reconstructed image |
| $S$ | Coil-sensitivity multiplication operator |
| $F$ | Centered unitary 2D Fourier transform |
| $P$ | Acquired-line sampling mask |
| $A=PFS$ | Cartesian multicoil forward operator used by SENSE/CS |
| $y$ | Measured multicoil k-space data |
| $W_N$ | Receive-noise prewhitening transform |
| $\lambda_2$ | SENSE Tikhonov regularization |
| $\lambda_{\mathrm{TV}}$ | CS total-variation weight |
| $\lambda_{\mathrm W}$ | CS Haar-wavelet $\ell_1$ weight |
| $D$ | 2D finite-difference operator |
| $W$ | Orthonormal Haar transform in the CS formulation |

The ordinary SENSE model is

$$
Ax=PFSx,
$$

and the regularized reconstruction solves

$$
\min_x\frac12\lVert Ax-y\rVert_2^2
+\frac{\lambda_2}{2}\lVert x\rVert_2^2.
$$

## Indexing conventions

Three coordinate/index systems must not be conflated:

1. **Logical $k_y$** is the signed phase-encoding coordinate used to describe the acquisition independently of a scanner vendor.
2. **Siemens LIN** is the current platform-specific zero-based line metadata used by the accelerated PI integration path.
3. **MATLAB/mapVBVD indices** are one-based after Twix data are exposed to MATLAB.

For the current Siemens path, conversion between exported zero-based LIN and a one-based mapVBVD line index therefore introduces a shift of one. This is a metadata convention, not a change in the underlying physical $k_y$ location. See [Siemens 7 T LIN & ICE](/phase-encoding-and-ice).

## Configuration notation

The sequence code distinguishes requested from resolved configuration:

- `Setup`, `SetupRF`, `SetupSpoiling` describe user intent;
- `Actual` begins from `Setup` and receives derived timing, hardware, PE, slice, RF, and export information during preparation.

For reproducible experiments, retain both requested and resolved configurations together with the exported `.seq` file and source revisions.
