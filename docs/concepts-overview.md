# Repository architecture

The repository has two main user-facing parts: **sequence generation** and **companion reconstruction**.

```mermaid
flowchart LR
    A[Setup] --> B[Sequence preparation]
    B --> C[Pulseq SEQ]
    C --> D[Scanner execution]
    D --> E[Raw data]
    E --> F[MATLAB reconstruction]
```

## Sequence generation

The maintained entry points are:

```text
TSE_2D.m
TSE_2D_gSlider.m
```

User parameters are defined in `Setup`, `SetupRF`, and `SetupSpoiling`. Sequence preparation functions under `prep/` resolve RF, gradients, timing, slice positions, phase encoding, acceleration, labels, and delays before writing the Pulseq `.seq` file.

`Actual` stores the resolved configuration produced from the requested setup.

See [Sequence Implementation](/sequence-generation) and [Parameter Reference](/parameter-reference).

## Reconstruction

`recon/matlab/` contains the companion reconstruction for conventional Cartesian 2D TSE. The main entry point is:

```matlab
result = recon_TSE2D(filename, ...)
```

It provides prewhitening, navigator phase correction, RSS, GRAPPA, SENSE, CS, ESPIRiT sensitivity estimation, and optional processing. The maintained raw-data reader currently uses Siemens Twix through `mapVBVD`.

See [Reconstruction](/reconstruction).

## Main directories

```text
TSE_2D.m / TSE_2D_gSlider.m   sequence entry points
prep/                          sequence preparation and RF/sampling assets
check/                         timing, label and PNS development checks
plot/                          sequence / k-space visualization
utils/                         shared sequence utilities
pulseq/                        Pulseq submodule
VERSE/                         VERSE submodule
recon/matlab/                  MATLAB reconstruction
seq/                           generated sequence outputs
docs/                          documentation source
```

For external algorithms and software used by these components, see [Dependencies & Method Provenance](/reference/provenance).
