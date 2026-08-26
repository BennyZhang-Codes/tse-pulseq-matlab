# Repository architecture

`tse-pulseq-matlab` is organized around an acquisition lifecycle rather than around an abstract reconstruction API. The code starts from a protocol configuration, produces a Pulseq sequence, couples that sequence to a scanner adapter, and provides a transparent raw-data reconstruction for the currently validated Siemens workflow.

```mermaid
flowchart LR
    A[User configuration] --> B[Sequence preparation]
    B --> C[Pulseq SEQ]
    C --> D[Scanner adapter]
    D --> E[Acquisition]
    E --> F[Raw data]
    F --> G[MATLAB reconstruction]
    G --> H[Optional post-processing]
```

Pulseq is the sequence-description portability layer [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552."). Platform integration and validation remain explicit responsibilities of each target scanner.

## 1. User configuration

The sequence entry points are

```text
TSE_2D.m
TSE_2D_gSlider.m
```

User intent is expressed through `Setup`, `SetupRF` and `SetupSpoiling`. The code copies the requested configuration into `Actual` and progressively adds resolved timing, RF, gradient, PE, slice and platform metadata.

This distinction is important:

- `Setup` = requested protocol;
- `Actual` = resolved implementation after rasterization and platform preparation.

## 2. Sequence preparation

The `prep/` directory converts the requested protocol into Pulseq objects. Major responsibilities include

- system limits;
- slice positions and ordering;
- phase-encoding/acceleration pattern;
- RF pulse preparation;
- readout, crushers and spoilers;
- labels and delays;
- optional noise scan;
- conventional/gSlider sequence loops; and
- exported sequence definitions.

The sequence is a RARE/TSE-family acquisition [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.") implemented with explicit echo-to-$k_y$ ordering.

See [Sequence Implementation](/sequence-generation).

## 3. External method components inside sequence generation

Some sequence-generation features rely on established external methods or upstream code and are tracked explicitly rather than hidden behind generic names:

- Pulseq sequence construction [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq. Magn Reson Med. 2017;77:1544-1552.");
- Lustig-derived variable-density CS PE sampling [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.");
- SLR RF pulse design [[20]](/references#ref-20 "Pauly JM, Le Roux P, Nishimura DG, Macovski A. Parameter relations for the Shinnar-Le Roux selective excitation pulse design algorithm. IEEE Trans Med Imaging. 1991;10:53-65.");
- gSlider RF encoding [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.");
- TRAPS-style variable refocusing [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535."); and
- VERSE processing through the tracked external submodule [[23]](/references#ref-23 "Lee D, Lustig M, Grissom WA, Pauly JM. Time-optimal design for multidimensional and parallel transmit variable-rate selective excitation. Magn Reson Med. 2009;61:1471-1479.").

See [Dependencies & Method Provenance](/reference/provenance) for the distinction between paper, software source and repository adaptation.

## 4. Scanner integration

A `.seq` file still needs a target-system execution layer. The current repository contains Siemens-specific integration in places such as

- `Terra-XJ` / `Terra-XR` system profiles;
- zero-based PI LIN mapping;
- interpreter/ICE definitions; and
- Siemens `.asc` PNS development models.

These are **current implementation details**, not definitions of the TSE sequence itself. A new platform should implement its own limits, safety strategy, coordinate/index mapping and interpreter contract rather than copying Siemens semantics.

See [Platform Integration](/platform-integration) and [Siemens 7 T LIN & ICE](/phase-encoding-and-ice).

## 5. Acquisition validation

Sequence-side checks under `check/` verify software-level conditions such as timing and label consistency and provide the currently available PNS development calculation. They do not certify human-scan safety.

The validation hierarchy is:

```mermaid
flowchart LR
    A[Software checks] --> B[Phantom validation]
    B --> C[Platform safety checks]
    C --> D[Approved study use]
```

See [Validation Strategy](/validation/scientific-validation) and [Scanner Validation & Safety](/validation-and-safety).

## 6. Raw-data reconstruction

The current companion reconstruction targets conventional Cartesian 2D TSE Siemens Twix data and uses external mapVBVD for file reading. The pipeline then provides

- receive-noise prewhitening;
- navigator phase correction;
- optional echo-envelope equalization;
- Cartesian LIN-based packing;
- RSS / PE-GRAPPA / ESPIRiT-SENSE / CS;
- numerical consistency diagnostics; and
- NIfTI geometry/output.

The reconstruction is intentionally transparent so acquisition behavior can be inspected from raw data rather than relying only on a proprietary scanner image.

All reconstruction functions, equations and main options are documented together under [Reconstruction](/reconstruction).

## 7. Optional processing

Two kinds of optional processing are intentionally separated from the core sequence/reconstruction definition:

- **echo magnitude correction** — optional preprocessing of measured k-space before packing/reconstruction;
- **NLM/BM3D/SANLM/TGV2** — optional image-domain post-processing after reconstruction.

Neither category is automatically selected as the universal correct output. See [Optional Echo Correction](/guide/echo-corrections) and [Optional Denoising](/guide/denoising).

## 8. Current implementation boundary

| Layer | Current status |
| --- | --- |
| Acquisition format | Pulseq Cartesian 2D TSE / gSlider-TSE |
| Sequence code | MATLAB + Pulseq |
| Scanner presets | Siemens 7 T Terra variants |
| PI/CS | regular PI + Lustig-derived 1D variable-density CS PE sampling |
| RF assets | sinc + SigPy-generated SLR/gSlider pulse banks; optional VERSE path |
| Scanner validation | Siemens 7 T |
| Raw-data reader | Siemens Twix via mapVBVD |
| Reconstruction | RSS, PE-GRAPPA, ESPIRiT-SENSE, Cartesian TV/Haar-L1 CS |
| gSlider decoding | not implemented in bundled reconstruction |
| Post-processing | optional only |

## 9. Repository directories

```text
TSE_2D.m / TSE_2D_gSlider.m   sequence entry points
prep/                          sequence preparation and sampling/RF assets
check/                         timing, label, PNS development checks
plot/                          sequence / k-space visualization
utils/                         shared sequence utilities
pulseq/                        Pulseq Git submodule
VERSE/                         VERSE Git submodule
recon/matlab/                  current conventional TSE reconstruction
recon/julia/                   retained Julia reconstruction work
seq/                           generated outputs
references/                    local research/reference material where applicable
docs/                          VitePress source
```

Continue with [Sequence Implementation](/sequence-generation) for the acquisition code, [Reconstruction](/reconstruction) for raw-data processing, or [Dependencies & Method Provenance](/reference/provenance) when reviewing attribution.
