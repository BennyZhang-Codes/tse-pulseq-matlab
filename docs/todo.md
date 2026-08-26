# TO DO

This page records only **confirmed open issues in the current implementation**. Unsupported features are documented in their relevant sections and are not automatically treated as planned work.

## Sequence

- [ ] **Make PNS prediction optional.** The maintained sequence scripts currently call `check_PNS` directly. Sequence generation should remain usable when `safe_pns_prediction` or a target-system PNS hardware model is unavailable, while still allowing PNS prediction to be enabled when the required platform inputs are present.

- [ ] **Further separate scanner-specific integration from the reusable Pulseq sequence core.** The current implementation still contains scanner-specific system profiles, line/index metadata and interpreter-facing definitions in shared preparation code. These should be kept as platform-integration details rather than defining the TSE sequence itself.

## Reconstruction

- [ ] **Implement offline gSlider decoding/reconstruction.** `TSE_2D_gSlider.m` generates gSlider-TSE acquisitions, but the bundled MATLAB reconstruction currently supports conventional 2D TSE only.

## Notes

Features listed elsewhere as unsupported—such as partial Fourier, SMS, non-Cartesian reconstruction or additional reconstruction variants—describe the **current support boundary**. They are not listed here unless they become an explicit development task.

When an item above is resolved, update the corresponding code and documentation together.
