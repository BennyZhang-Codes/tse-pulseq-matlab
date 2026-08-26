# Performance notes

Performance benchmarking is not part of the main package workflow.

For normal use, see **[Sequence Implementation](/sequence-generation)** and **[Reconstruction](/reconstruction)**.

When measuring reconstruction runtime or memory, record the MATLAB version, CPU/GPU, precision, reconstruction method/settings, and whether the first run includes initialization/warm-up. Dataset-specific benchmark or evaluation scripts belong under `recon/matlab/experiments/` rather than in the main user documentation.
