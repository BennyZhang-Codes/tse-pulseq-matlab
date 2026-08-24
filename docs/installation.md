# Installation

This page separates the **Pulseq sequence-development environment** from the **current Siemens 7 T implementation, scanner-validation, and reconstruction dependencies**. Vendor-neutral deployment is the project direction rather than a claim that the present code is already scanner-independent; see [Platform Integration](platform-integration.md).

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

Pulseq is bundled as a submodule and provides the portable sequence-description layer used for:

- `mr.Sequence`;
- RF, gradient, ADC and label objects;
- timing validation;
- sequence export;
- k-space calculation; and
- PNS calculation when a compatible hardware model is available.

The sequence design is intended to remain independent of a single MRI vendor. Executing the exported `.seq` file on a real platform still requires a compatible Pulseq interpreter and platform-specific validation.

For a reproducible experiment, record the Pulseq submodule commit SHA because the exact checked-out commit is more precise than a moving version description.

## 4. VERSE

The `VERSE/` submodule contains VERSE and minimum-SAR RF utilities used by supported RF-design paths.

`Setup.VERSE` controls whether the configured sequence path enables VERSE-related behavior where implemented. Enabling VERSE does not remove the need to inspect RF peak amplitude, B1, pulse fidelity, SAR and scanner compatibility.

## 5. Current Siemens Twix reconstruction path

The bundled offline MATLAB reconstruction currently targets Siemens Twix raw data and requires [`mapVBVD`](https://github.com/pehses/mapVBVD).

You can either add `mapVBVD.m` to the MATLAB path yourself or provide its folder to the reconstruction call:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', 'E:\\Tools\\mapVBVD');
```

The offline reconstruction reads conventional Cartesian 2D TSE Twix data and does not currently decode gSlider acquisitions.

This Twix dependency belongs to the present reconstruction implementation; it does **not** make the Pulseq sequence design Siemens-specific.

## 6. Current Siemens 7 T PNS models

`check_PNS` currently calls the Pulseq PNS calculator using scanner-specific Siemens `.asc` hardware models selected by `ScannerType`.

Current mappings are:

| `ScannerType` | Hard gradient limit | Hard slew limit | `.asc` model expected on MATLAB path |
| --- | ---: | ---: | --- |
| `Terra-XJ` | 70 mT/m | 200 T/m/s | `MP_GPA_K2259_2000V_650A_SC72CD_EGA.asc` |
| `Terra-XR` | 80 mT/m | 200 T/m/s | `MP_GPA_K2298_2250V_793A_SC72CD_EGA.asc` |

The example sequence design uses configurable *soft* limits, commonly 40 mT/m and 150 T/m/s, which are separate from the absolute hardware limits used to initialize the Pulseq system object.

These presets reflect the currently validated Siemens 7 T environment. Porting the sequence to another scanner requires appropriate hardware limits and a corresponding PNS/safety-validation strategy rather than reusing a Terra model.

## 7. Scanner interpreter

Scanner execution requires a Pulseq interpreter compatible with the target MR platform.

The repository's current scanner validation has been performed on Siemens 7 T systems. Consequently, several exported definitions and documentation pages also cover the Siemens interpreter/ICE contract, including `TurboFactor`, `PhaseCorrection`, PE matrix size, center LIN, ACS width and slice metadata.

For another vendor, the Pulseq event sequence remains the portable layer, while interpreter-facing metadata and online reconstruction integration may need adaptation. Use [Platform Integration](platform-integration.md) as the porting checklist.

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

A successful development run should include timing, label and available PNS output plus sequence/k-space plots. These checks do not by themselves establish scanner safety or portability to an unvalidated platform; see [Validation and safety](validation-and-safety.md).
