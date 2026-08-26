# Installation

This page separates the **core sequence-development environment** from optional platform-specific tools and reconstruction dependencies.

## 1. Clone with submodules

Pulseq and VERSE are tracked as Git submodules:

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If needed:

```bash
git submodule update --init --recursive
```

The repository currently tracks:

- `pulseq/` → `pulseq/pulseq`;
- `VERSE/` → `BennyZhang-Codes/VERSE-RF-Pulse`.

For reproducible work, record the parent-repository commit and resolved submodule SHAs.

## 2. MATLAB

A recent MATLAB installation with standard numerical and plotting functionality is required.

The maintained sequence entry scripts add the repository modules they need, including

```text
pulseq/
prep/
check/
plot/
utils/
VERSE/
```

No repository-wide `addpath(genpath(...))` is required before running the maintained entry points.

## 3. Pulseq

Pulseq provides the sequence-description layer used for

- `mr.Sequence`;
- RF, gradient, ADC and label objects;
- timing validation;
- sequence export;
- k-space calculation; and
- PNS-calculation interfaces when the corresponding optional dependencies/platform inputs are available.

Executing an exported `.seq` file on a scanner still requires a compatible Pulseq interpreter and target-platform validation.

## 4. Optional PNS prediction

The current `check_PNS` path calls Pulseq `Sequence.calcPNS`. In the tracked Pulseq revision, that implementation uses the external MATLAB package [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction).

If PNS prediction is used, the calculation also needs a hardware model compatible with the target gradient system. Scanner-vendor hardware-model files are **external platform inputs and are not distributed by this repository**.

The SAFE-model basis is documented in [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007.") and the software repository asks users to consider citing Szczepankiewicz et al. [[27]](/references#ref-27 "Szczepankiewicz F, Westin C-F, Nilsson M. Gradient waveform design for tensor-valued encoding in diffusion MRI. J Neurosci Methods. 2021;348:109007.").

::: warning Current implementation status
PNS prediction is conceptually an **optional platform-dependent development feature**, but the current sequence scripts still call `check_PNS` directly. Refactoring this into a clean opt-in dependency is tracked in [TO DO & implementation checklist](/todo).
:::

The software prediction does not replace scanner-side gradient/PNS supervision or site-specific safety validation.

## 5. VERSE and generated RF pulse banks

The `VERSE/` submodule provides the optional VERSE RF path.

The bundled SLR and gSlider `.mat` RF pulse banks were generated offline through `prep/pulse/RF_pulse.ipynb` using SigPy RF. Python/SigPy is not required for ordinary MATLAB sequence generation unless those pulse banks are regenerated.

See [Dependencies & Method Provenance](/reference/provenance).

## 6. Offline reconstruction dependencies

The maintained raw-data reader currently targets Siemens Twix and uses external [`mapVBVD`](https://github.com/pehses/mapVBVD).

You can add `mapVBVD.m` to the MATLAB path or provide its folder directly:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', 'E:\\Tools\\mapVBVD');
```

Available reconstruction methods are

```text
RSS
GRAPPA
SENSE
CS
```

ESPIRiT is used for the default SENSE/CS sensitivity estimation. See [Reconstruction](/reconstruction) for implementation limits.

## 7. Optional GPU support

SENSE and CS can use a MATLAB-supported GPU:

```matlab
'IterativeUseGPU', 'auto'
```

`'auto'` uses a GPU when available and otherwise falls back to CPU. RSS and GRAPPA do not require GPU support.

## 8. Target scanner / interpreter

Scanner execution requires a Pulseq interpreter compatible with the target MR platform plus correct target-system hardware limits and validation.

The repository currently contains some scanner-profile and metadata assumptions from the development environment. These are documented as current implementation constraints and are being separated from the reusable acquisition core; see [Platform Integration](/platform-integration) and [TO DO](/todo).

## 9. Verify the installation

Confirm Pulseq can be resolved:

```matlab
which mr.Sequence
```

If using the current PNS prediction path, also confirm:

```matlab
which safe_gwf_to_pns
```

Then review the target configuration and run:

```matlab
run('TSE_2D.m')
```

A successful software run does not establish scanner safety; see [Validation & Safety](/validation-and-safety).
