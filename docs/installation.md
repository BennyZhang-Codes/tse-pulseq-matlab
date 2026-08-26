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

Pulseq is bundled as a submodule and provides the portable sequence-description layer used for `mr.Sequence`, RF/gradient/ADC/label objects, timing validation, sequence export, k-space calculation, and PNS-calculation interfaces.

The sequence design is intended to remain independent of a single MRI vendor. Executing the exported `.seq` file on a real platform still requires a compatible Pulseq interpreter and platform-specific validation.

## 4. PNS prediction dependency

`check/check_PNS.m` calls Pulseq `Sequence.calcPNS`. In the Pulseq revision tracked by this repository, `calcPNS` depends on the external MATLAB package [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction).

Install the package separately and add it to the MATLAB path when PNS prediction is required, for example:

```matlab
addpath(genpath('path-to-safe_pns_prediction'));
```

The calculation uses the SAFE model [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007.") and the software repository asks users to consider citing Szczepankiewicz et al. [[27]](/references#ref-27 "Szczepankiewicz F, Westin C-F, Nilsson M. Gradient waveform design for tensor-valued encoding in diffusion MRI. J Neurosci Methods. 2021;348:109007.").

A scanner-specific hardware model compatible with the target gradient system is also required by the PNS calculation. Those scanner hardware parameters are **not part of this open-source sequence repository and are not distributed here**.

::: warning Development check only
The SAFE-model calculation is useful for sequence development but does not replace scanner-side gradient/PNS supervision or local safety validation.
:::

## 5. VERSE and generated RF pulse banks

The `VERSE/` submodule contains VERSE and minimum-SAR RF utilities used by supported RF-design paths. `Setup.VERSE` controls whether the configured sequence path enables VERSE-related behavior where implemented.

The bundled SLR and gSlider `.mat` RF pulse banks were generated offline through `prep/pulse/RF_pulse.ipynb` using SigPy RF. Python/SigPy is therefore not required for normal MATLAB sequence generation unless those pulse banks are regenerated. See [Dependencies & method provenance](/reference/provenance).

## 6. Current Siemens Twix reconstruction path

The bundled offline MATLAB reconstruction currently targets Siemens Twix raw data and requires [`mapVBVD`](https://github.com/pehses/mapVBVD).

You can either add `mapVBVD.m` to the MATLAB path yourself or provide its folder to the reconstruction call:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', 'E:\\Tools\\mapVBVD');
```

Available reconstruction methods are:

```text
RSS
GRAPPA
SENSE
CS
```

ESPIRiT is used for the default SENSE/CS sensitivity-map estimation. The current GRAPPA implementation uses Cartesian undersampling with acceleration along PE, integer acceleration, and contiguous integrated ACS. Partial-Fourier GRAPPA, SMS/slice-GRAPPA, non-Cartesian GRAPPA, and irregular variable-density mask reconstruction are not implemented. See [Reconstruction](/reconstruction) for the complete support boundary.

The offline reconstruction does not currently decode gSlider acquisitions.

## 7. Current scanner profiles

The current sequence implementation includes Siemens 7 T scanner profiles used in the validated development environment. These profiles define the hardware limits and current platform integration expected by the sequence code.

PNS prediction additionally requires the external `safe_pns_prediction` package and a compatible scanner-specific hardware model supplied for the target system. The repository does not distribute scanner-vendor hardware-model files.

The example sequence design uses configurable soft limits, commonly 40 mT/m and 150 T/m/s, which are separate from the absolute hardware limits used to initialize the Pulseq system object.

Porting the sequence to another scanner requires appropriate hardware limits, interpreter integration, and a corresponding PNS/safety-validation strategy rather than reusing an unrelated scanner model.

## 8. Scanner interpreter

Scanner execution requires a Pulseq interpreter compatible with the target MR platform.

The repository's current scanner validation has been performed on Siemens 7 T systems. Consequently, several exported definitions and documentation pages cover the Siemens interpreter/ICE contract, including `TurboFactor`, `PhaseCorrection`, PE matrix size, center LIN, ACS width and slice metadata.

For another vendor, the Pulseq event sequence remains the portable layer, while interpreter-facing metadata and online reconstruction integration may need adaptation. Use [Platform Integration](platform-integration.md) as the porting checklist.

## 9. Optional GPU support

SENSE and CS reconstruction can use a MATLAB-supported GPU:

```matlab
'IterativeUseGPU', 'auto'
```

`'auto'` uses a GPU when MATLAB reports one as available and otherwise falls back to CPU. GPU support is optional; RSS and GRAPPA use the standard MATLAB path and do not require it.

## 10. Verify the installation

From the repository root, confirm Pulseq can be resolved:

```matlab
which mr.Sequence
```

When PNS prediction is required, also confirm the SAFE implementation is available:

```matlab
which safe_gwf_to_pns
```

Then run a maintained sequence script after reviewing its configuration:

```matlab
run('TSE_2D.m')
```

A successful development run should include timing, label and available PNS output plus sequence/k-space plots. These checks do not by themselves establish scanner safety or portability to an unvalidated platform; see [Validation and safety](validation-and-safety.md).
