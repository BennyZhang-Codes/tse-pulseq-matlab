# Installation

This page describes the minimum environment required for sequence generation and offline reconstruction.

## 1. Clone with submodules

Pulseq and VERSE are tracked as git submodules. Clone the repository with:

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If the repository was cloned without submodules, initialize them afterwards:

```bash
git submodule update --init --recursive
```

The repository currently tracks:

- `pulseq/` → `pulseq/pulseq`;
- `VERSE/` → `BennyZhang-Codes/VERSE-RF-Pulse`.

For reproducible work, record the parent-repository commit **and** the resolved submodule SHAs rather than assuming the current upstream state.

## 2. MATLAB

A recent MATLAB installation with standard numerical and plotting functionality is required.

Open MATLAB from the repository root. The sequence entry scripts add the repository modules to the MATLAB path automatically, including:

```text
pulseq/
prep/
check/
plot/
utils/
VERSE/
```

No repository-wide `addpath(genpath(...))` is required before running the maintained sequence entry points.

## 3. Pulseq

Pulseq is bundled as a submodule and is required for:

- `mr.Sequence`;
- RF, gradient, ADC and label objects;
- timing validation;
- sequence export;
- k-space calculation; and
- PNS calculation when a compatible Siemens `.asc` model is available.

The top-level README currently documents the bundled Pulseq submodule as v1.5.1. For a reproducible experiment, record the submodule commit SHA because the exact checked-out commit is more precise than a moving version description.

## 4. VERSE

The `VERSE/` submodule contains VERSE and minimum-SAR RF utilities used by supported RF-design paths.

`Setup.VERSE` controls whether the configured sequence path enables VERSE-related behavior where implemented. Enabling VERSE does not remove the need to inspect RF peak amplitude, B1, pulse fidelity, SAR and scanner compatibility.

## 5. mapVBVD for Siemens Twix reconstruction

Offline MATLAB reconstruction requires [`mapVBVD`](https://github.com/pehses/mapVBVD).

You can either add `mapVBVD.m` to the MATLAB path yourself or provide its folder to the reconstruction call:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', 'E:\\Tools\\mapVBVD');
```

The offline reconstruction reads conventional Cartesian 2D TSE Twix data and does not currently decode gSlider acquisitions.

## 6. Siemens gradient hardware model for PNS prediction

`check_PNS` calls the Pulseq PNS calculator using a scanner-specific Siemens `.asc` hardware model selected by `ScannerType`.

Current mappings are:

| `ScannerType` | Hard gradient limit | Hard slew limit | `.asc` model expected on MATLAB path |
| --- | ---: | ---: | --- |
| `Terra-XJ` | 70 mT/m | 200 T/m/s | `MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc` |
| `Terra-XR` | 80 mT/m | 200 T/m/s | `MP_GPA_K2298_2250V_793A_SC72CD_EGA.asc` |

The example sequence design uses configurable *soft* limits, commonly 40 mT/m and 150 T/m/s, which are separate from the absolute hardware limits used to initialize the Pulseq system object.

If the appropriate `.asc` file is unavailable, PNS checking may be disabled during software development, but PNS must still be assessed before scanner use.

## 7. Siemens Pulseq interpreter

Scanner execution requires a compatible Siemens Pulseq interpreter. Online ICE behavior additionally depends on the interpreter and matching scanner protocol settings.

In particular, exported definitions such as `TurboFactor`, `PhaseCorrection`, PE matrix size, center LIN, ACS width and slice metadata only become effective when the target interpreter consumes them consistently.

## 8. Optional GPU support

Iterative SENSE and CS reconstruction can use a MATLAB-supported GPU:

```matlab
'IterativeUseGPU', 'auto'
```

`'auto'` uses a GPU when MATLAB reports one as available and otherwise falls back to CPU. GPU support is optional; ordinary RSS and diagnostic GRAPPA do not require it.

## 9. Verify the installation

From the repository root, first confirm that the sequence entry point can resolve Pulseq:

```matlab
which mr.Sequence
```

Then run a maintained sequence script after reviewing its configuration:

```matlab
run('TSE_2D.m')
```

A successful development run should include timing, label and PNS output plus sequence/k-space plots. These checks do not by themselves establish scanner safety; see [Validation and safety](validation-and-safety.md).
