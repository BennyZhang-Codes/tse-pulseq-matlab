# Repository architecture

`tse-pulseq-matlab` is organized around an acquisition lifecycle rather than around a reconstruction-library API.

```mermaid
flowchart LR
    A[User configuration] --> B[Sequence preparation]
    B --> C[Pulseq SEQ]
    C --> D[Platform integration]
    D --> E[Acquisition]
    E --> F[Raw data]
    F --> G[MATLAB reconstruction]
    G --> H[Optional post-processing]
```

Pulseq is the sequence-description portability layer [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552."). Platform integration and validation remain responsibilities of each target scanner.

## 1. User configuration

The sequence entry points are

```text
TSE_2D.m
TSE_2D_gSlider.m
```

User intent is expressed through `Setup`, `SetupRF`, and `SetupSpoiling`. The code copies the requested state into `Actual` and progressively adds resolved timing, RF, gradient, PE, slice, and current platform information.

- `Setup` = requested protocol;
- `Actual` = resolved implementation after rasterization and preparation.

## 2. Sequence preparation

The `prep/` directory converts the requested protocol into Pulseq objects. Major responsibilities include

- system constraints;
- slice positions/order;
- phase encoding and acceleration;
- RF preparation;
- readout, crushers and spoilers;
- labels and delays;
- optional noise scan;
- TSE/gSlider loops; and
- exported definitions.

The sequence is a RARE/TSE-family acquisition [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.").

See [Sequence Implementation](/sequence-generation).

## 3. External methods and tools

Established methods/tools used by the repository include

- Pulseq [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq. Magn Reson Med. 2017;77:1544-1552.");
- SparseMRI-derived CS sampling [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.");
- SLR [[20]](/references#ref-20 "Pauly JM, Le Roux P, Nishimura DG, Macovski A. Parameter relations for the Shinnar-Le Roux selective excitation pulse design algorithm. IEEE Trans Med Imaging. 1991;10:53-65.");
- gSlider [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.");
- TRAPS [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535.");
- VERSE [[23]](/references#ref-23 "Lee D, Lustig M, Grissom WA, Pauly JM. Time-optimal design for multidimensional and parallel transmit variable-rate selective excitation. Magn Reson Med. 2009;61:1471-1479."); and
- SAFE-model PNS prediction [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007.") through external `safe_pns_prediction` when used.

See [Dependencies & Method Provenance](/reference/provenance).

## 4. Platform integration

The intended architecture keeps scanner-specific behavior outside the reusable acquisition definition.

Platform integration may provide

- hardware limits and raster/dead-time constraints;
- PNS/safety-model inputs;
- interpreter capabilities;
- line/index metadata;
- orientation conventions;
- online-reconstruction metadata; and
- raw-data format adapters.

The current code is not yet fully separated this way. Some scanner-profile, metadata, PNS, and raw-data assumptions still reflect the environment used during development/testing. The planned refactoring is tracked in [TO DO & implementation checklist](/todo).

See [Platform Integration](/platform-integration).

## 5. Validation

Sequence-side checks currently cover timing, labels, and the configured PNS development path.

```mermaid
flowchart LR
    A[Software checks] --> B[Phantom validation]
    B --> C[Platform safety checks]
    C --> D[Approved study use]
```

These checks do not certify human-scan safety. See [Validation Strategy](/validation/scientific-validation) and [Validation & Safety](/validation-and-safety).

## 6. Raw-data reconstruction

The companion reconstruction provides

- prewhitening;
- phase correction;
- optional echo magnitude correction;
- Cartesian k-space packing;
- RSS;
- GRAPPA;
- SENSE;
- CS;
- ESPIRiT sensitivity estimation;
- numerical checks; and
- geometry/output handling.

The maintained raw-data reader currently uses Siemens Twix through `mapVBVD`; that reader dependency is a current implementation detail rather than the intended reconstruction abstraction.

Package-specific restrictions are documented under [Reconstruction](/reconstruction).

## 7. Optional processing

Two optional categories are kept separate from the core sequence/reconstruction definition:

- **echo magnitude correction** — optional k-space preprocessing;
- **NLM / BM3D / SANLM / TGV2** — optional image-domain post-processing.

See [Optional Echo Correction](/guide/echo-corrections) and [Optional Denoising](/guide/denoising).

## 8. Current implementation boundary

| Layer | Current status |
| --- | --- |
| Acquisition | Pulseq Cartesian 2D TSE / gSlider-TSE |
| Sequence code | MATLAB + Pulseq |
| PI/CS | PI + variable-density CS PE sampling |
| RF assets | sinc + SigPy-generated SLR/gSlider pulse banks; optional VERSE |
| PNS prediction | SAFE-based development path; should become explicitly optional |
| Platform integration | not yet fully separated from the development environment |
| Raw-data reader | Siemens Twix via mapVBVD |
| Reconstruction | RSS, GRAPPA, SENSE, CS; ESPIRiT sensitivity estimation |
| gSlider decoding | not implemented |
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
recon/matlab/                  conventional TSE reconstruction
recon/julia/                   retained Julia reconstruction work
seq/                           generated outputs
docs/                          VitePress source
```

Continue with [Sequence Implementation](/sequence-generation), [Reconstruction](/reconstruction), or [TO DO](/todo).
