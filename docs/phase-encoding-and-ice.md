# Platform metadata notes

This URL is retained for compatibility with older documentation links. Platform-specific metadata is no longer a primary documentation section because `tse-pulseq-matlab` is an open-source Pulseq sequence package rather than a scanner-vendor integration manual.

Use the following pages instead:

- **[Platform Integration](/platform-integration)** — boundary between the reusable Pulseq acquisition and target-scanner integration.
- **[Phase Encoding & Acceleration](/theory/phase-encoding)** — logical $k_y$, PI/CS sampling, ACS, echo ordering, and effective TE.
- **[Reconstruction](/reconstruction)** — current raw-data reader, k-space packing, reconstruction methods, and implementation limits.
- **[TO DO & implementation checklist](/todo)** — planned work to move remaining platform-specific assumptions out of the reusable sequence core.

## Current implementation note

Development and scanner testing have so far used a Siemens 7 T environment, so some source files still contain platform-specific line-index, interpreter, metadata, PNS, and Twix assumptions. These are **implementation constraints of the current code**, not part of the TSE method definition and not intended to become the public terminology of the package.

In particular:

- logical phase encoding and echo-to-$k_y$ ordering should be treated as the portable acquisition definition;
- target-platform line counters and interpreter metadata are adapter responsibilities;
- raw-data metadata conventions belong to the current reader implementation;
- scanner-specific safety/PNS hardware parameters are external platform inputs; and
- new scanner support requires its own adapter and validation.

The planned refactoring is tracked in [TO DO & implementation checklist](/todo).
