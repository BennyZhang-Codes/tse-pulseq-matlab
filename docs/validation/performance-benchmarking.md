# Performance & benchmarking

Performance results in a scientific software package should be interpreted together with **accuracy, memory, and the exact workload**. This page therefore defines how TSE reconstruction benchmarks should be reported before any headline speedup is quoted.

::: warning No standalone speed claim
A reconstruction that changes regularization, coil compression, stopping criteria, calibration, or output quality is not the same operating point. Runtime comparisons are meaningful only after the reconstruction protocol and accuracy target have been frozen.
:::

## Accuracy first, performance second

For each operating point, report at least:

- reconstruction method;
- accuracy/error metric relative to a predefined reference;
- preprocessing and calibration state;
- solver tolerance or iteration count;
- setup time;
- iterative/reconstruction time;
- end-to-end time;
- peak memory; and
- hardware/software environment.

A useful result table is therefore structured as

| Method | Accuracy | Setup | Reconstruction | End-to-end | Peak memory |
| --- | ---: | ---: | ---: | ---: | ---: |
| RSS | — / baseline | … | … | … | … |
| PE-GRAPPA | … | … | … | … | … |
| ESPIRiT-SENSE | … | … | … | … | … |
| Cartesian CS | … | … | … | … | … |

Do not fill this table with numbers from unmatched experiments.

## Timing scopes

Report timing scopes separately because they answer different engineering questions.

### Setup time

Examples include

- Twix parsing;
- noise covariance estimation;
- navigator model estimation;
- k-space packing;
- coil compression;
- ESPIRiT calibration;
- operator construction.

### Reconstruction time

Examples include

- coil-by-coil IFFT + RSS;
- GRAPPA synthesis;
- SENSE CG iterations;
- CS primal-dual iterations.

### End-to-end time

This should include all operations needed to produce the reported reconstruction from the defined input state. If file I/O or NIfTI export is excluded, say so explicitly.

## Warm-up and repetition

MATLAB/GPU timing can be distorted by first-use effects. A reproducible benchmark should specify

- whether the first run is discarded as warm-up;
- number of timed repetitions;
- statistic reported (median is usually more robust than minimum);
- whether GPU synchronization is enforced before stopping the timer; and
- whether cached calibration/results are reused.

For iterative GPU methods, make sure the timer measures completed GPU work rather than only asynchronous launch overhead.

## Peak memory

Peak memory is often as important as runtime for high-resolution multicoil data.

Record the measurement method. Examples include MATLAB/GPU allocator statistics or external polling. If `nvidia-smi` polling is used, report the sampling interval and note that a short allocation peak can be missed.

Distinguish when possible between

- live array memory;
- allocator-reserved/cached memory;
- process-level device memory; and
- host memory.

A single unexplained “GPU memory” number is ambiguous.

## Accuracy–runtime operating points

SENSE and CS can trade reconstruction error against computation through iteration count, tolerance, and regularization. Rather than comparing one arbitrary configuration per method, it can be more informative to show several predefined operating points.

For example:

```text
SENSE 25 iterations
SENSE 50 iterations
SENSE 100 iterations
```

with complex NRMSE and runtime reported for each. The same principle applies to CS regularization/iteration sweeps, provided the tuning procedure is fixed before the final benchmark is reported.

## Echo correction and denoising

Echo-magnitude equalization and image-domain denoising change the statistical properties of the output. They should therefore be benchmarked as explicit processing variants rather than silently included in one method and omitted in another.

For echo equalization, report

- correction method;
- regularization/gain parameters;
- residual echo-envelope metric;
- noise amplification; and
- reconstruction metric.

For denoising, report the unfiltered reconstruction alongside the filtered result and identify the metric/reference used to avoid conflating reconstruction accuracy with post-processing appearance.

## CPU/GPU reporting

At minimum record

- MATLAB release;
- operating system;
- CPU model;
- GPU model;
- GPU driver/runtime information;
- precision; and
- `IterativeUseGPU` value.

A statement such as “GPU was faster” is not reproducible without the hardware and numerical context.

## Scaling experiments

The current MATLAB pipeline is not documented as a multi-GPU reconstruction framework. If future work introduces parallel scaling, report speedup and efficiency separately:

$$
S_G=\frac{T_1}{T_G},\qquad
E_G=\frac{S_G}{G}.
$$

Also state which stage is parallelized; setup and iterative operators may scale differently.

## Benchmark publication checklist

Before publishing benchmark numbers in this documentation, confirm that

1. [Reconstruction protocol](/validation/reconstruction-protocol) is frozen;
2. the reference reconstruction is defined;
3. error and runtime are measured on the same data and ROI;
4. no method receives additional calibration or preprocessing without disclosure;
5. warm-up/repetition policy is documented;
6. peak-memory measurement method is documented;
7. failed/invalid runs are not silently discarded; and
8. the result can be reproduced from the recorded repository and dependency revisions.

## Current status

This page currently defines the **benchmarking contract**, not a release-level performance claim. Numerical timings should only be promoted to the main documentation after the corresponding data, protocol, code revision, and accuracy metrics have been frozen.

See [Scientific validation strategy](/validation/scientific-validation) for why validation precedes performance in the documentation structure.
