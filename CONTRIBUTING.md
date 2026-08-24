# Contributing

Thank you for improving TSE Pulseq for MATLAB. This repository is research software for MRI sequence development; contributions must not imply scanner, clinical, or regulatory validation.

## Before opening a pull request

1. Create a focused branch from `main`.
2. Clone submodules with `git clone --recurse-submodules` or run `git submodule update --init --recursive`.
3. Run the MATLAB regression suite:

```powershell
matlab -batch "run(fullfile(pwd,'tests','run_ci_tests.m'))"
```

4. Update the relevant documentation if a public parameter, label convention, reconstruction option, sequence behavior, or known limitation changes.

## Code expectations

- Preserve Pulseq raster constraints and explicitly validate timing after sequence changes.
- Treat Siemens labels, LIN conventions, and PE ordering as compatibility interfaces; add a regression test when changing them.
- Keep third-party code in its own submodule or directory with its original license and attribution.
- Do not commit `.seq`, `.dat`, raw scanner data, patient data, secrets, or local scanner configuration files.
- Keep new tests deterministic and independent of scanner hardware and proprietary Twix data.

## Pull requests

Describe the motivation, implementation, validation command/results, and any scanner-side validation still required. For RF, gradient, SAR, PNS, ICE, or reconstruction changes, explicitly state the tested scope and limitations.