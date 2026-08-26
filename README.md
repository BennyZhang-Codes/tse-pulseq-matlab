# TSE Pulseq for MATLAB

[![CI](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/matlab-ci.yml) [![Documentation](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/actions/workflows/docs.yml/badge.svg?branch=main)](https://bennyzhang-codes.github.io/tse-pulseq-matlab/) [![Coverage](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab/graph/badge.svg?token=JNHD7UK0A3)](https://codecov.io/github/BennyZhang-Codes/tse-pulseq-matlab) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22076863.svg)](https://doi.org/10.5281/zenodo.22076863)

Open-source MATLAB/Pulseq implementation of **Cartesian 2D turbo spin echo (TSE)** sequences, including conventional multi-slice TSE and gSlider-TSE, with a companion MATLAB reconstruction pipeline for conventional 2D TSE data.

## Features

### Sequence

- Conventional Cartesian 2D TSE: `TSE_2D.m`
- gSlider-TSE: `TSE_2D_gSlider.m`
- Linear, `CentricFull`, and `CentricHalf` phase-encoding order
- Parallel-imaging (PI) and compressed-sensing (CS) PE sampling
- Sinc and SLR RF pulses, gSlider RF pulse banks, optional VERSE
- Multi-slice and inversion-recovery sequence paths
- Pulseq timing/label checks and sequence/k-space visualization

### Reconstruction

The companion MATLAB pipeline for conventional Cartesian 2D TSE provides:

- noise prewhitening;
- navigator phase correction;
- RSS, GRAPPA, SENSE, and CS;
- ESPIRiT sensitivity estimation and coil compression;
- optional navigator-derived echo magnitude correction;
- optional NLM, BM3D, SANLM, and TGV2 post-processing; and
- NIfTI output.

The maintained raw-data reader currently uses Siemens Twix through external `mapVBVD`. Offline gSlider decoding is not yet implemented.

## Quick start

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

Generate conventional 2D TSE:

```matlab
run('TSE_2D.m')
```

Generate gSlider-TSE:

```matlab
run('TSE_2D_gSlider.m')
```

The sequence scripts write the generated `.seq` file and resolved MATLAB configuration under `seq/`.

For reconstruction, edit and run:

```text
recon/matlab/examples/run_recon_TSE2D.m
```

Full instructions: **[Quick Start](https://bennyzhang-codes.github.io/tse-pulseq-matlab/quickstart)**.

## Requirements

Core sequence generation requires:

- MATLAB;
- the tracked `pulseq/` and `VERSE/` submodules.

Optional/external dependencies are feature-specific:

| Dependency | Needed for |
| --- | --- |
| `safe_pns_prediction` + target-system hardware model | current PNS prediction path |
| `mapVBVD` | current Twix reconstruction reader |
| SigPy | regenerating bundled SLR/gSlider RF pulse banks; not required to use the stored `.mat` banks |
| MATLAB GPU support | optional SENSE/CS GPU execution |
| BM3D / CAT12 | optional BM3D/SANLM denoising |

The current sequence scripts still call `check_PNS` directly. Making PNS prediction a clean optional dependency is a confirmed [TO DO](https://bennyzhang-codes.github.io/tse-pulseq-matlab/todo).

## Documentation

- [Quick Start](https://bennyzhang-codes.github.io/tse-pulseq-matlab/quickstart)
- [Sequence Implementation](https://bennyzhang-codes.github.io/tse-pulseq-matlab/sequence-generation)
- [Parameter Reference](https://bennyzhang-codes.github.io/tse-pulseq-matlab/parameter-reference)
- [Phase Encoding & Acceleration](https://bennyzhang-codes.github.io/tse-pulseq-matlab/theory/phase-encoding)
- [gSlider-TSE](https://bennyzhang-codes.github.io/tse-pulseq-matlab/guide/gslider-traps)
- [Reconstruction](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reconstruction)
- [Dependencies & Method Provenance](https://bennyzhang-codes.github.io/tse-pulseq-matlab/reference/provenance)
- [Literature References](https://bennyzhang-codes.github.io/tse-pulseq-matlab/references)

## Current testing and safety

Scanner development/testing to date has used Siemens 7 T systems. This describes the current testing environment, not the definition of the Pulseq sequence.

> **Research use:** a generated `.seq` file and software checks do not replace target-scanner RF/SAR, gradient/PNS, interpreter/watchdog, phantom, or local safety validation before in-vivo use.

## Citation

Use the repository DOI: [10.5281/zenodo.22076863](https://doi.org/10.5281/zenodo.22076863). Citation metadata is in [CITATION.cff](CITATION.cff).

If `TSE_2D_gSlider.m` is used, also cite:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Program #3256. [Abstract](http://echo.ismrm.org/p/ISMRM2024/3256)

Scientific methods used in an acquisition/reconstruction should be cited as listed in the documentation.

## License

MIT License. Pulseq, VERSE, and other external dependencies remain under their upstream licenses.
