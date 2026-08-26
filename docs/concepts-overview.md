# Repository architecture

`tse-pulseq-matlab` is organized around an acquisition lifecycle. The code starts from a protocol configuration, produces a Pulseq sequence, couples that sequence to a scanner integration layer, and provides raw-data reconstruction for the currently validated Siemens workflow.

```mermaid
flowchart LR
    A[User configuration] --> B[Sequence preparation]
    B --> C[Pulseq SEQ]
    C --> D[Scanner integration]
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

- `Setup` = requested protocol;
- `Actual` = resolved implementation after rasterization and platform preparation.

## 2. Sequence preparation

The `prep/` directory converts the requested protocol into Pulseq objects. Major responsibilities include system limits, slice positions/order, phase encoding and acceleration, RF preparation, readout/crushers/spoilers, labels/delays, optional noise scan, TSE/gSlider loops, and exported definitions.

The sequence is a RARE/TSE-family acquisition [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.").

See [Sequence Implementation](/sequence-generation).

## 3. External methods and tools

Established methods/tools used by the sequence implementation include:

- Pulseq [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq. Magn Reson Med. 2017;77:1544-1552.");
- CS sampling derived from SparseMRI utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.");
- SLR [[20]](/references#ref-20 "Pauly JM, Le Roux P, Nishimura DG, Macovski A. Parameter relations for the Shinnar-Le Roux selective excitation pulse design algorithm. IEEE Trans Med Imaging. 1991;10:53-65.");
- gSlider [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.");
- TRAPS [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535.");
- VERSE [[23]](/references#ref-23 "Lee D, Lustig M, Grissom WA, Pauly JM. Time-optimal design for multidimensional and parallel transmit variable-rate selective excitation. Magn Reson Med. 2009;61:1471-1479."); and
- SAFE-model PNS prediction [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007.") through the external `safe_pns_prediction` package.

See [Dependencies & Method Provenance](/reference/provenance) for software/code origin and repository-specific adaptations.

## 4. Scanner integration

A `.seq` file still needs a target-system execution layer. Current Siemens-specific integration includes:

- `Terra-XJ` / `Terra-XR` system profiles;
- zero-based PI LIN mapping;
- interpreter/ICE definitions;
- Siemens `MP_GPA*.asc` hardware models; and
- external `safe_pns_prediction` for the PNS calculation called through Pulseq `calcPNS`.

These are current implementation details, not definitions of TSE itself.

See [Platform Integration](/platform-integration), [Installation](/installation), and [Siemens 7 T LIN & ICE](/phase-encoding-and-ice).

## 5. Validation

Sequence-side checks under `check/` provide timing, label and PNS development checks. The current PNS dependency chain is

```text
check_PNS
→ Pulseq calcPNS
→ safe_pns_prediction
→ scanner-specific MP_GPA*.asc parameters
```

These checks do not certify human-scan safety.

```mermaid
flowchart LR
    A[Software checks] --> B[Phantom validation]
    B --> C[Platform safety checks]
    C --> D[Approved study use]
```

See [Validation Strategy](/validation/scientific-validation) and [Scanner Validation & Safety](/validation-and-safety).

## 6. Raw-data reconstruction

The current reconstruction targets conventional Cartesian 2D TSE Siemens Twix data and uses mapVBVD for file reading. It provides:

- prewhitening;
- phase correction;
- optional echo magnitude correction;
- k-space packing;
- RSS;
- GRAPPA;
- SENSE;
- CS;
- ESPIRiT sensitivity estimation for the default SENSE/CS path;
- numerical checks; and
- NIfTI geometry/output.

Package-specific restrictions are documented under [Reconstruction](/reconstruction) rather than encoded in the method names.

## 7. Optional processing

Two optional categories are kept separate from the core sequence/reconstruction definition:

- **echo magnitude correction** — optional k-space preprocessing;
- **NLM / BM3D / SANLM / TGV2** — optional image-domain post-processing.

See [Optional Echo Correction](/guide/echo-corrections) and [Optional Denoising](/guide/denoising).

## 8. Current implementation boundary

| Layer | Current status |
| --- | --- |
| Acquisition format | Pulseq Cartesian 2D TSE / gSlider-TSE |
| Sequence code | MATLAB + Pulseq |
| Scanner presets | Siemens 7 T Terra variants |
| PI/CS | PI + variable-density CS PE sampling |
| RF assets | sinc + SigPy-generated SLR/gSlider pulse banks; optional VERSE |
| PNS calculation | Pulseq `calcPNS` + external `safe_pns_prediction` + scanner `MP_GPA*.asc` model |
| Scanner validation | Siemens 7 T |
| Raw-data reader | Siemens Twix via mapVBVD |
| Reconstruction | RSS, GRAPPA, SENSE, CS; ESPIRiT sensitivity estimation |
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
docs/                          VitePress source
```

Continue with [Sequence Implementation](/sequence-generation), [Reconstruction](/reconstruction), or [Dependencies & Method Provenance](/reference/provenance).
