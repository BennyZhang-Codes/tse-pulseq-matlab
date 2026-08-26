# Platform integration

Pulseq describes the RF, gradients, ADC, timing, and logical encoding of the sequence. Running the exported `.seq` file on a scanner still requires a compatible Pulseq interpreter and correct target-system configuration.

## What the target platform must provide

Depending on the scanner/interpreter, platform integration may include:

- hardware and raster limits;
- interpreter support for the sequence events and labels;
- PE/ACS metadata required by online reconstruction;
- coordinate/orientation conventions;
- PNS/safety inputs; and
- scanner-side validation.

These are platform details rather than definitions of the TSE sequence itself.

## Current implementation

Scanner development/testing to date has used Siemens 7 T systems, and some system/profile and metadata handling in the current source still reflects that environment. Separating reusable sequence logic from scanner-specific integration is a confirmed [TO DO](/todo).

The maintained offline raw-data reader currently uses Siemens Twix through `mapVBVD`. This affects the companion reconstruction input, not the Pulseq sequence format.

## PNS prediction

The current PNS path uses Pulseq `Sequence.calcPNS`, external `safe_pns_prediction`, and a target-system hardware model. The hardware model is supplied outside this repository.

PNS prediction is intended as a platform-dependent development check. The current entry scripts still call it directly; making it cleanly optional is tracked in [TO DO](/todo).

For normal sequence use, continue with [Quick Start](/quickstart), [Sequence Implementation](/sequence-generation), and [Validation & Safety](/validation-and-safety).
