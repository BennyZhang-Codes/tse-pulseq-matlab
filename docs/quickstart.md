# Quick start

This page covers the shortest path from a fresh clone to a generated TSE sequence and a first offline reconstruction.

## 1. Clone

```bash
git clone --recurse-submodules https://github.com/BennyZhang-Codes/tse-pulseq-matlab.git
cd tse-pulseq-matlab
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

## 2. Generate conventional 2D TSE

Open MATLAB in the repository root and edit the configuration block in `TSE_2D.m`.

Common parameters include:

| Parameter | Meaning |
| --- | --- |
| `fovRO`, `fovPE` | in-plane FOV |
| `nRO`, `nPE` | readout / phase-encoding matrix |
| `nSlice`, `SliceThickness` | slice coverage |
| `TE1`, `TEeff`, `TR` | TSE timing |
| `nEcho` | echo-train length / turbo factor |
| `PEMode` | `Linear`, `CentricFull`, or `CentricHalf` |
| `AccelerationMode` | `PI` or `CS` |
| `R` | acceleration factor |

Generate the sequence:

```matlab
run('TSE_2D.m')
```

The script writes the generated `.seq` file and resolved MATLAB configuration under `seq/`.

See [Parameter Reference](/parameter-reference) and [Sequence Implementation](/sequence-generation) for all options and implementation details.

## 3. Choose PI or CS sampling

```matlab
Setup.AccelerationMode = 'PI';
% or
Setup.AccelerationMode = 'CS';
```

The current CS acquisition path uses a one-dimensional variable-density PE pattern derived from the SparseMRI sampling utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195."). See [Phase Encoding & Acceleration](/theory/phase-encoding).

## 4. Generate gSlider-TSE

Run:

```matlab
run('TSE_2D_gSlider.m')
```

The gSlider sequence can use the bundled gSlider RF pulse bank and optional TRAPS-style variable refocusing. See [gSlider-TSE & TRAPS](/guide/gslider-traps).

The bundled MATLAB reconstruction does not currently implement offline gSlider decoding.

## 5. PNS prediction

The current sequence scripts call `check_PNS`, which uses Pulseq `Sequence.calcPNS`. In the tracked Pulseq version this path requires external `safe_pns_prediction` and a hardware model for the target gradient system.

These are platform-dependent inputs. Making PNS prediction a clean optional dependency is a confirmed [TO DO](/todo). See [Installation](/installation) for setup details.

## 6. Reconstruct conventional 2D TSE data

The maintained raw-data reader currently uses Siemens Twix through external `mapVBVD`.

Edit:

```text
recon/matlab/examples/run_recon_TSE2D.m
```

Set the input/output paths, for example:

```matlab
twixFile = "path-to-meas.dat";
outputDir = "path-to-output";
mapVBVDPath = "path-to-mapVBVD";
```

Then run:

```matlab
run(fullfile('recon','matlab','examples','run_recon_TSE2D.m'))
```

The reconstruction entry point supports:

```text
rss
grappa
sense
cs
```

Prewhitening and navigator phase correction are available in the main pipeline. Echo magnitude correction and image-domain denoising are optional. See [Reconstruction](/reconstruction).

## 7. Before scanner use

A generated `.seq` file is not by itself evidence of scanner safety. Use the target scanner's hardware limits, RF/SAR, gradient/PNS, interpreter/watchdog, orientation, and phantom validation procedures. See [Validation & Safety](/validation-and-safety).
