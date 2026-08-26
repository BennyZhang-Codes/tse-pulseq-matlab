# Dependencies & method provenance

This page records **where implemented functionality comes from**. It distinguishes the scientific method from the concrete software, adapted code, generated assets, and repository-local implementation used here.

::: info Why this page exists
`tse-pulseq-matlab` is an open-source sequence package. Reproducibility therefore requires both **method citations** and **code/software provenance**. Method names below use standard MRI terminology; implementation restrictions are described separately rather than embedded into the method name.
:::

## Acquisition and sequence generation

| Functionality | Implementation used here | Source / provenance | Scientific basis |
| --- | --- | --- | --- |
| Pulseq | Pulseq MATLAB `mr.*` events and `Sequence` object through the `pulseq/` submodule | [`pulseq/pulseq`](https://github.com/pulseq/pulseq) | [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552.") |
| RARE / TSE | Repository sequence loops and RF/gradient preparation | `TSE_2D.m`, `prep/prep_Seqloop*.m` | [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.") |
| SLR | Refocusing/inversion pulse banks generated offline by `prep/pulse/RF_pulse.ipynb` using `sigpy.mri.rf.slr.dzrf` | [SigPy](https://github.com/mikgroup/sigpy); generated `.mat` files stored in `prep/pulse/` | [[20]](/references#ref-20 "Pauly JM, Le Roux P, Nishimura DG, Macovski A. Parameter relations for the Shinnar-Le Roux selective excitation pulse design algorithm. IEEE Trans Med Imaging. 1991;10:53-65.") |
| gSlider | Excitation pulse bank generated offline by `prep/pulse/RF_pulse.ipynb` using `sigpy.mri.rf.slr.dz_gslider_rf`; sequence implemented by `TSE_2D_gSlider.m` | SigPy-generated pulse bank + repository sequence implementation | [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.") and repository gSlider-TSE abstract [[14]](/references#ref-14 "Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. Proc Intl Soc Magn Reson Med. 2024; Program #3256.") |
| TRAPS | `utils/fliptraps.m`; schedule selected by `TSE_2D_gSlider.m` | Repository implementation of the TRAPS concept; not claimed to be original distributed TRAPS code | [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535.") |
| VERSE | `VERSE/` Git submodule | [`BennyZhang-Codes/VERSE-RF-Pulse`](https://github.com/BennyZhang-Codes/VERSE-RF-Pulse), with upstream lineage recorded there | [[23]](/references#ref-23 "Lee D, Lustig M, Grissom WA, Pauly JM. Time-optimal design for multidimensional and parallel transmit variable-rate selective excitation. Magn Reson Med. 2009;61:1471-1479.") |
| PNS prediction | `check/check_PNS.m` calls Pulseq `Sequence.calcPNS` | Pulseq `calcPNS` calls external [`safe_pns_prediction`](https://github.com/filip-szczepankiewicz/safe_pns_prediction); target-system hardware parameters are supplied outside this repository | SAFE model [[26]](/references#ref-26 "Hebrank FX, Gebhardt M. SAFE-Model—A new method for predicting peripheral nerve stimulations in MRI. Proc Intl Soc Magn Reson Med. 2000;8. Abstract #2007."); software/review citation [[27]](/references#ref-27 "Szczepankiewicz F, Westin C-F, Nilsson M. Gradient waveform design for tensor-valued encoding in diffusion MRI. J Neurosci Methods. 2021;348:109007.") |

### PNS dependency chain

The current PNS check is not implemented entirely inside this repository:

```text
check_PNS
  → Pulseq Sequence.calcPNS
  → safe_pns_prediction
  → scanner-specific hardware model
```

The tracked Pulseq `calcPNS.m` explicitly states that `safe_pns_prediction` must be downloaded and installed on the MATLAB path. The target scanner's hardware parameters are an external input to that calculation and are **not part of the open-source sequence package or distributed by this repository**. PNS prediction remains a development check and does not replace scanner-side safety supervision.

## Compressed-sensing acquisition pattern

The package uses **compressed sensing (CS)** acquisition with a one-dimensional variable-density phase-encoding mask. The current implementation is based on Michael Lustig's SparseMRI sampling utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.").

Implementation details:

```text
prep_PE3DOrder_CS
    ↓
genPDF
    ↓ polynomial variable-density PDF along PE
genSampling_TSE
    ↓ Monte-Carlo candidates / minimum interference
ETL-compatible sample count
    ↓
logical ky list and echo ordering
```

- `prep/CS/genPDF.m` retains `(c) Michael Lustig 2007` and generates the polynomial variable-density PDF.
- `prep/CS/genSampling.m` retains the same attribution and evaluates Monte-Carlo masks using the off-center interference of `ifft2(mask ./ pdf)`.
- `prep/CS/genSampling_TSE.m` is the repository adaptation that constrains the acquired PE count to be compatible with the echo-train length.
- The implemented mask is **not Poisson-disc sampling**; that is an implementation limitation/choice, not part of the method name.

## Reconstruction methods

| Functionality | Implementation used here | Source / dependency | Scientific basis |
| --- | --- | --- | --- |
| Twix read | `read_TSE2D_twix.m` | external [mapVBVD](https://github.com/pehses/mapVBVD) | software dependency |
| Prewhitening | `estimate_noise_whitener.m`, `apply_coil_matrix.m` | repository MATLAB implementation | [[3]](/references#ref-3 "Roemer PB, Edelstein WA, Hayes CE, Souza SP, Mueller OM. The NMR phased array. Magn Reson Med. 1990;16:192-225.") [[4]](/references#ref-4 "Kellman P, McVeigh ER. Image reconstruction in SNR units: a general method for SNR measurement. Magn Reson Med. 2005;54:1439-1447.") |
| GRAPPA | `recon_TSE2D_GRAPPA.m` | repository MATLAB implementation | [[5]](/references#ref-5 "Griswold MA, Jakob PM, Heidemann RM, et al. Generalized autocalibrating partially parallel acquisitions (GRAPPA). Magn Reson Med. 2002;47:1202-1210.") |
| SENSE | `recon_TSE2D_SENSE.m`, shared `PFS` operator | repository MATLAB implementation | [[6]](/references#ref-6 "Pruessmann KP, Weiger M, Scheidegger MB, Boesiger P. SENSE: sensitivity encoding for fast MRI. Magn Reson Med. 1999;42:952-962.") |
| ESPIRiT | `estimate_TSE2D_espirit.m` | repository MATLAB implementation | [[7]](/references#ref-7 "Uecker M, Lai P, Murphy MJ, et al. ESPIRiT: an eigenvalue approach to autocalibrating parallel MRI. Magn Reson Med. 2014;71:990-1001.") |
| Coil compression | `compress_TSE2D_coils.m`; eigendecomposition of ACS coil covariance with energy-fraction truncation | repository MATLAB implementation | [[24]](/references#ref-24 "Buehrer M, Pruessmann KP, Boesiger P, Kozerke S. Array compression for MRI with large coil arrays. Magn Reson Med. 2007;57:1131-1139.") |
| CS | `recon_TSE2D_CS.m`; common `PFS` data consistency + TV + Haar-L1 | repository MATLAB implementation | Sparse MRI [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195."); Chambolle-Pock [[9]](/references#ref-9 "Chambolle A, Pock T. A first-order primal-dual algorithm for convex problems with applications to imaging. J Math Imaging Vis. 2011;40:120-145.") |
| Echo magnitude correction | `apply_TSE_echomagcor.m`; optional power / normalized Wiener-style gain from measured TSE navigators | repository MATLAB implementation | [[16]](/references#ref-16 "Oshio K, Singh M. Correction of T2 distortion in multi-excitation RARE sequence. IEEE Trans Med Imaging. 1992;11:123-128.")–[[19]](/references#ref-19 "Busse RF, Riederer SJ, Fletcher JG, Bharucha AE, Brandt KR. Interactive fast spin-echo imaging. Magn Reson Med. 2000;44:339-348.") |

### GRAPPA implementation limits

The method is referred to simply as **GRAPPA** throughout the public documentation. The current implementation is limited to Cartesian undersampling with acceleration along PE, integer acceleration, and integrated contiguous ACS calibration. It does not currently implement partial-Fourier GRAPPA, SMS/slice-GRAPPA, non-Cartesian GRAPPA, irregular variable-density masks, or proprietary Siemens ICE reconstruction details.

## Optional image-domain denoising

Denoising is not part of the default raw-data reconstruction. It is separately invoked post-processing.

| Method | Concrete implementation | Dependency status | Scientific basis |
| --- | --- | --- | --- |
| NLM | MATLAB `imnlmfilt` through `denoise_TSE2D.m` | MATLAB Image Processing Toolbox | [[25]](/references#ref-25 "Buades A, Coll B, Morel JM. A non-local algorithm for image denoising. CVPR. 2005;2:60-65.") |
| BM3D | external BM3D 4.x called by `denoise_TSE2D.m` | optional; not vendored | [[11]](/references#ref-11 "Dabov K, Foi A, Katkovnik V, Egiazarian K. Image denoising by sparse 3-D transform-domain collaborative filtering. IEEE Trans Image Process. 2007;16:2080-2095.") [[12]](/references#ref-12 "Mäkinen Y, Azzari L, Foi A. Collaborative filtering of correlated noise. IEEE Trans Image Process. 2020;29:8339-8354.") |
| SANLM | external CAT12 `cat_sanlm` | optional; not vendored | [[13]](/references#ref-13 "Manjón JV, Coupé P, Martí-Bonmatí L, Collins DL, Robles M. Adaptive non-local means denoising of MR images with spatially varying noise levels. J Magn Reson Imaging. 2010;31:192-203.") |
| TGV2 | `denoise_TGV2.m` | repository implementation | [[10]](/references#ref-10 "Knoll F, Bredies K, Pock T, Stollberger R. Second order total generalized variation (TGV) for MRI. Magn Reson Med. 2011;65:480-491.") [[9]](/references#ref-9 "Chambolle A, Pock T. A first-order primal-dual algorithm for convex problems with applications to imaging. J Math Imaging Vis. 2011;40:120-145.") |

## Platform-specific tooling

Implementation dependencies that are not vendor-neutral sequence concepts include:

- Siemens MDH/Twix conventions and the current LIN/ICE integration;
- mapVBVD for offline Twix reading;
- `safe_pns_prediction` for the SAFE-model calculation called through Pulseq `calcPNS`;
- target-system hardware parameters required by PNS prediction; and
- applicable Siemens IDEA/ICE documentation for the validated environment.

## Attribution rule for future contributions

When a new method or utility is added, document all three levels when applicable:

1. **scientific method** — peer-reviewed paper or primary method publication;
2. **software/code source** — upstream repository, package, toolbox or retained copyright header;
3. **repository adaptation** — exactly what was changed or wrapped here.

Use the **standard method name** in navigation, headings and tables; document package-specific restrictions in an implementation/limitations paragraph rather than changing the method name.
