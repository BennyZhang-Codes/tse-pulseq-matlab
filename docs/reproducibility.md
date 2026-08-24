# Reproducibility and citation

This page describes how to make a sequence-generation or reconstruction result reproducible across software revisions.

## 1. Prefer a fixed release for published work

For papers, abstracts, shared datasets or long-lived protocols, prefer a tagged GitHub Release over an unpinned `main` checkout.

A reproducible record should include:

- repository release/tag;
- repository commit SHA;
- Pulseq submodule SHA;
- VERSE submodule SHA when relevant;
- MATLAB version;
- scanner model and interpreter version/configuration;
- saved `Setup` and resolved `Actual` structures;
- exported `.seq` file;
- scanner protocol settings that are not encoded in the `.seq` file;
- reconstruction code revision and reconstruction options.

If no formal release exists for the exact experiment, record the full commit SHA instead of referring only to `main`.

## 2. Record submodule revisions

The repository tracks Pulseq and VERSE as git submodules. A parent-repository commit points to exact submodule commits, so keep the repository clone intact when archiving an experiment.

Useful commands are:

```bash
git rev-parse HEAD
git submodule status
```

For a clean reproducible checkout:

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
git checkout <release-or-commit>
git submodule update --init --recursive
```

## 3. Archive `Setup`, `Actual` and `.seq` together

The sequence scripts save the original `Setup` and resolved `Actual` structures alongside the exported `.seq` file.

These serve different purposes:

- `Setup` records the user-requested configuration;
- `Actual` contains derived scanner, timing, PE, slice and export information after preparation;
- `.seq` is the scanner-facing Pulseq sequence description.

For reproducible studies, archive all three rather than only the `.seq` file.

## 4. Record scanner-side settings that are not fully encoded

Some scanner/interpreter behavior is not guaranteed by the `.seq` file alone. Record at least:

- Siemens Pulseq interpreter build/revision;
- patient position and intended orientation;
- iPAT acceleration and ACS/reference-line settings;
- online TSE phase-correction configuration;
- any scanner-side RF/SAR or reconstruction settings that materially affect the result.

This is particularly important because exported `nRefLine` does not by itself set the Siemens iPAT card.

## 5. Record offline reconstruction options

The offline reconstruction exposes explicit options for:

- prewhitening;
- noise covariance regularization;
- phase correction;
- echo-magnitude correction;
- GRAPPA;
- SENSE/CS;
- ESPIRiT;
- coil compression;
- GPU use;
- output format.

Save the runner script or a MAT/text record of the options used for every dataset that will be compared quantitatively.

Do not describe a result simply as "CS reconstruction" without reporting the regularization and calibration configuration.

## 6. Current software citation metadata

The repository contains `CITATION.cff` with the current software citation metadata:

```text
Title: TSE Pulseq for MATLAB
Author: Jinyuan Zhang
Type: software
License: MIT
Repository: https://github.com/BennyZhang-Codes/tse-pulseq-matlab
```

At the time this documentation was created, `CITATION.cff` does **not** yet contain a software version or DOI field. Do not invent a DOI when citing the current repository state.

GitHub's **Cite this repository** interface can use `CITATION.cff` to format the available citation metadata.

## 7. Zenodo DOI workflow

For archival citation, a recommended future workflow is:

1. connect the GitHub repository to Zenodo;
2. create a GitHub Release with a stable semantic version/tag;
3. allow Zenodo to archive that release;
4. add the resulting version-specific DOI and/or concept DOI to the release notes and `CITATION.cff`;
5. use the version-specific DOI when citing the exact software used for a publication.

Until a Zenodo record has actually been created, documentation should say that the DOI is **not yet assigned** rather than using a placeholder DOI that could be mistaken for a real identifier.

## 8. gSlider-TSE citation

If you use `TSE_2D_gSlider.m`, cite the associated work:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. In: *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Singapore. Program #3256.

When appropriate, also cite Pulseq and the reconstruction methods actually used (for example GRAPPA, ESPIRiT or compressed sensing).

## 9. Recommended release checklist

Before creating a release intended for citation:

- verify the maintained sequence examples run as expected;
- record the Pulseq and VERSE submodule SHAs;
- update `CITATION.cff` with `version` and `date-released`;
- update documentation for known limitations and compatibility;
- confirm example reconstruction defaults;
- create a release tag;
- archive the release with Zenodo if DOI-backed citation is desired;
- add the DOI to `CITATION.cff` only after it exists;
- keep release notes focused on user-visible behavior and compatibility.

## 10. Minimum methods reporting template

For a reproducible methods section, report at least:

```text
Software: TSE Pulseq for MATLAB, release/tag or commit SHA
Pulseq submodule: commit SHA
Scanner/interpreter: model + interpreter revision
Acquisition: matrix, FOV, slices, TR, TE1, TEeff, turbo factor, PE order, R, ACS
RF: excitation/refocusing type and relevant flip-angle schedule
Validation: timing/PNS/scanner-side checks performed
Reconstruction: method + phase/magnitude correction + calibration + regularization
```

The exact level of detail can be shortened in a manuscript when the software release and archived configuration files are publicly available, but the release/commit identity should remain explicit.
