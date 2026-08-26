# Installation

## Core requirements

Sequence generation requires:

- MATLAB;
- the tracked `pulseq/` and `VERSE/` Git submodules.

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If needed:

```bash
git submodule update --init --recursive
```

The maintained sequence scripts add the repository folders they need to the MATLAB path.

## Optional and feature-specific dependencies

| Dependency | Required for |
| --- | --- |
| [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) + target-system hardware model | current PNS prediction path |
| [`mapVBVD`](https://github.com/pehses/mapVBVD) | current Siemens Twix raw-data reader |
| SigPy | regenerating the bundled SLR/gSlider RF pulse banks |
| MATLAB GPU support | optional GPU execution of SENSE/CS |
| BM3D / CAT12 | optional BM3D/SANLM denoising |

The bundled SLR/gSlider `.mat` pulse banks can be used without Python or SigPy at normal MATLAB runtime.

## PNS prediction

`check_PNS` calls Pulseq `Sequence.calcPNS`. In the Pulseq revision tracked here, that path uses external `safe_pns_prediction` and a hardware model compatible with the target gradient system.

Target-system hardware-model files are not distributed with this repository. The current sequence scripts still call `check_PNS` directly; making PNS prediction cleanly optional is tracked in [TO DO](/todo).

See [Validation & Safety](/validation-and-safety) and [Dependencies & Method Provenance](/reference/provenance) for the role and source of this calculation.

## Reconstruction setup

For the maintained Twix reconstruction path, make `mapVBVD` available to MATLAB or provide its location directly:

```matlab
result = recon_TSE2D(twixFile, ...
    'MapVBVDPath', 'E:\\Tools\\mapVBVD');
```

Supported reconstruction methods are RSS, GRAPPA, SENSE, and CS. ESPIRiT is used for the default SENSE/CS sensitivity estimation.

## Verify the installation

From the repository root:

```matlab
which mr.Sequence
run('TSE_2D.m')
```

If using the current PNS prediction path, also check:

```matlab
which safe_gwf_to_pns
```

Scanner execution additionally requires a compatible Pulseq interpreter and target-system validation. Continue with [Quick Start](/quickstart).
