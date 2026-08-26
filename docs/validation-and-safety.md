# Validation & safety

This repository provides software checks for sequence development. They are **not scanner safety certification**.

::: danger Research use only
Before volunteer or patient scanning, use the target scanner's RF/SAR, gradient/PNS, interpreter/watchdog, protocol, phantom, and local institutional safety procedures.
:::

## Checks included

The maintained sequence scripts currently run

```matlab
check_Timing(seq)
check_Label(seq)
check_PNS(seq, Actual)
```

and generate sequence/k-space plots.

- `check_Timing` uses Pulseq timing validation.
- `check_Label` checks the acquisition labels used by the sequence.
- `check_PNS` provides a model-based PNS development calculation when its external dependencies and target-system inputs are available.

These checks help catch software/configuration problems; they do not establish RF/SAR safety, scanner acceptance, correct interpreter behavior, or image quality.

## PNS prediction

`check_PNS` calls Pulseq `Sequence.calcPNS`. In the Pulseq revision tracked by this repository, that path uses external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction) together with a hardware model compatible with the target gradient system.

The target-system hardware model is an external platform input and is not distributed by this repository. The underlying SAFE-model method is documented in [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007.") and the software provenance is listed in [Dependencies & Method Provenance](/reference/provenance).

The current sequence scripts still call `check_PNS` directly. Making PNS prediction a clean optional dependency is tracked in [TO DO](/todo).

A software PNS prediction does not replace scanner-side gradient/PNS supervision.

## Before scanner use

At minimum, verify on the target platform:

- hardware/raster limits and interpreter compatibility;
- RF peak B1 and scanner-side SAR supervision;
- gradient/PNS supervision;
- PE/ACS metadata, orientation, and slice order where applicable; and
- phantom behavior before in-vivo use.

Scanner development/testing to date has used Siemens 7 T systems. This is the current testing boundary; it should not be interpreted as validation for other scanners or interpreters.
