# Reproducibility and citation

This page describes how to make a sequence-generation or reconstruction result reproducible across software revisions and scanner platforms.

Vendor-neutral deployment is the project goal, but the current implementation and validation path is Siemens 7 T. Always record the actual scanner vendor/model and interpreter used; do not treat validation on one platform as evidence for another. See [Platform Integration](platform-integration.md) for the current coupling points.

## 1. Prefer a fixed release for published work

For papers, abstracts, shared datasets or long-lived protocols, prefer a tagged GitHub Release over an unpinned `main` checkout.

A reproducible record should include:

- repository release/tag;
- repository commit SHA;
- Pulseq submodule SHA;
- VERSE submodule SHA when relevant;
- MATLAB version;
- scanner vendor and model;
- Pulseq interpreter version/configuration;
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
- `.seq` is the Pulseq sequence description used by the target interpreter.

For reproducible studies, archive all three rather than only the `.seq` file.

## 4. Record platform-specific scanner settings

Some scanner/interpreter behavior is not guaranteed by the `.seq` file alone. Record the target platform's interpreter revision, patient position/orientation assumptions, accelerated-imaging calibration settings, online phase-correction behavior, and any scanner-side RF/SAR or reconstruction settings that materially affect the result.

For the repository's current Siemens 7 T validation path, record at least:

- Siemens Pulseq interpreter build/revision;
- patient position and intended orientation;
- iPAT acceleration and ACS/reference-line settings;
- online TSE phase-correction configuration;
- any scanner-side RF/SAR or reconstruction settings that materially affect the result.

This is particularly important because exported `nRefLine` does not by itself set the Siemens iPAT card.

For another vendor, record the equivalent interpreter and acquisition/reconstruction contract for that platform rather than assuming Siemens metadata semantics transfer directly.

## 5. Record offline reconstruction options

The bundled offline reconstruction currently targets Siemens Twix data and exposes explicit options for:

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

## 6. Software citation

The repository contains `CITATION.cff` with software citation metadata and the Zenodo DOI:

```text
Title: TSE Pulseq for MATLAB
Author: Jinyuan Zhang
Type: software
License: MIT
DOI: 10.5281/zenodo.22076863
Repository: https://github.com/BennyZhang-Codes/tse-pulseq-matlab
```

Use the repository DOI when citing the software unless a version-specific DOI is provided for the exact release used in your study.

GitHub's **Cite this repository** interface can use `CITATION.cff` to format the available citation metadata.

## 7. Release and Zenodo workflow

For archival releases:

1. create a GitHub Release with a stable semantic version/tag;
2. archive that release with Zenodo;
3. record the version-specific DOI when Zenodo assigns one;
4. update `CITATION.cff` with `version`, `date-released`, and the appropriate DOI when a release is finalized;
5. use the version-specific DOI when citing the exact software release used for a publication, while retaining the concept/repository DOI when appropriate.

## 8. gSlider-TSE citation

If you use `TSE_2D_gSlider.m`, cite the associated work:

> Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. In: *Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition*, Singapore, Singapore. Program #3256.

When appropriate, also cite Pulseq and the reconstruction methods actually used (for example GRAPPA, ESPIRiT or compressed sensing).

## 9. Recommended release checklist

Before creating a release intended for citation:

- verify the maintained sequence examples run as expected;
- record the Pulseq and VERSE submodule SHAs;
- update `CITATION.cff` with `version` and `date-released`;
- update documentation for known limitations and platform compatibility;
- confirm example reconstruction defaults;
- create a release tag;
- archive the release with Zenodo;
- record the version-specific DOI after it exists;
- keep release notes focused on user-visible behavior and compatibility.

## 10. Minimum methods reporting template

For a reproducible methods section, report at least:

```text
Software: TSE Pulseq for MATLAB, release/tag or commit SHA
Pulseq submodule: commit SHA
Scanner: vendor + model + field strength
Pulseq interpreter: implementation + revision
Acquisition: matrix, FOV, slices, TR, TE1, TEeff, turbo factor, PE order, R, ACS
RF: excitation/refocusing type and relevant flip-angle schedule
Validation: timing/PNS/scanner-side checks performed
Reconstruction: raw-data format + method + phase/magnitude correction + calibration + regularization
```

The exact level of detail can be shortened in a manuscript when the software release and archived configuration files are publicly available, but the release/commit identity and scanner platform should remain explicit.
