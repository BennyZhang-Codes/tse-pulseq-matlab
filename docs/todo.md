# TO DO & implementation checklist

This page tracks **known engineering gaps and planned work** in `tse-pulseq-matlab`. It is intentionally public: the repository is an open-source sequence implementation, so users should be able to distinguish implemented functionality from planned portability, reconstruction, and validation work.

The checklist describes the current repository state rather than a release promise. Items may be reordered as the sequence evolves.

## High priority — sequence portability

- [ ] **Make PNS prediction an optional dependency.** Sequence generation should not fail only because `safe_pns_prediction` or a target-system hardware model is unavailable. The intended behavior is: run PNS prediction when explicitly enabled and all required platform inputs are available; otherwise skip it with a clear status message.
- [ ] **Separate PNS hardware models from the reusable sequence core.** Target-scanner PNS/SAFE parameters should be supplied by the platform integration layer rather than embedded as sequence-package assets. Scanner-vendor hardware-model files are not distributed by this repository.
- [ ] **Refactor scanner profiles into an explicit platform layer.** `prep_System` currently contains profiles from the development environment. The portable sequence core should instead consume a generic system description containing field strength, gradient/slew limits, raster times, RF/ADC dead times, and other required hardware constraints.
- [ ] **Separate logical phase encoding from vendor metadata.** Logical $k_y$, acceleration, ACS intent, and echo ordering should remain vendor independent. Platform-specific line counters, interpreter definitions, and online-reconstruction metadata should be translated outside the common PE-order implementation.
- [ ] **Generalize orientation support.** The maintained sequence path is currently non-oblique. Add a tested orientation/rotation interface without changing the logical sequence design.
- [ ] **Validate additional Pulseq platforms.** Current scanner testing reflects the development environment only. New scanner/vendor support should be treated as a separate implementation and validation target.

## Sequence features

- [ ] Add a cleaner platform-independent configuration interface for hardware limits and interpreter capabilities.
- [ ] Expand automated tests for PE ordering, echo-to-$k_y$ assignment, ACS layout, slice ordering, and exported definitions across more parameter combinations.
- [ ] Add reproducible RF-regeneration metadata/version capture for SigPy-generated SLR/gSlider pulse banks.
- [ ] Add more automated checks for VERSE/TRAPS RF and gradient constraints where practical.
- [ ] Review whether all sequence definitions currently written by `prep_Definition` are generic acquisition metadata or should move to platform-specific adapters.

## Reconstruction

The bundled reconstruction is a companion to the sequence rather than a separate general-purpose reconstruction framework. Current missing capabilities are tracked explicitly:

- [ ] **gSlider decoding/reconstruction.** Acquisition is implemented; offline gSlider decoding is not yet included in the MATLAB reconstruction.
- [ ] **Partial Fourier reconstruction.** Not currently implemented.
- [ ] **SMS reconstruction.** Not currently implemented.
- [ ] **Non-Cartesian reconstruction.** Not currently implemented.
- [ ] **Multiple ESPIRiT map sets.** The current implementation uses a single ESPIRiT map set.
- [ ] **Vendor-independent raw-data input interface.** The maintained raw-data reader currently consumes Siemens Twix through `mapVBVD`. A future reader abstraction should map vendor-native data/metadata into a common internal representation without introducing vendor assumptions into the sequence core.
- [ ] Add broader regression tests for GRAPPA, SENSE, CS, coil compression, NIfTI geometry, and navigator correction across representative datasets.

## Optional processing and validation

- [ ] Freeze a reproducible validation dataset/protocol for optional echo magnitude correction, including uncorrected comparison, image sharpness, noise amplification, and tissue-contrast checks.
- [ ] Keep image-domain denoising (NLM/BM3D/SANLM/TGV2) explicitly optional and add quantitative comparison examples without defining one universal default.
- [ ] Expand independent numerical validation for the common Cartesian encoding operator beyond self-consistency/adjoint checks.
- [ ] Add platform-neutral phantom validation guidance only where it is reusable across scanners; scanner-specific SOPs should remain site/platform documentation rather than part of the core public package documentation.

## Documentation and provenance

- [ ] Keep all public method names in standard MRI terminology; implementation restrictions belong in dedicated limitation paragraphs.
- [ ] Maintain method citations, upstream software/code provenance, and repository-specific adaptations together when new algorithms or tools are introduced.
- [ ] Keep README and VitePress documentation synchronized for supported acquisition modes, reconstruction features, optional processing, dependencies, and limitations.
- [ ] Continue checking Mermaid/flow diagrams for readable sizing on desktop and narrow screens.

## Recently clarified

- [x] Echo magnitude correction is documented as an **optional** reconstruction preprocessing step with direct RARE/FSE literature support.
- [x] BM3D and other denoisers are documented as **optional** post-reconstruction processing rather than default reconstruction behavior.
- [x] GRAPPA is documented using the standard method name, with package-specific support limits stated separately.
- [x] CS sampling provenance is documented as the Lustig SparseMRI-derived variable-density/Monte-Carlo implementation used by the repository.
- [x] SLR, gSlider, TRAPS, VERSE, coil compression, reconstruction methods, and external software dependencies are linked to their scientific/code provenance.

## Contribution rule

When an item above is implemented, update the relevant source code, tests, documentation, method provenance, and this checklist in the same change whenever practical.
