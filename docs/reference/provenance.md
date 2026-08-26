# Dependencies & method provenance

This page records **where implemented functionality comes from**. It is intentionally more specific than a normal bibliography: for each external method, software package, inherited code fragment or generated pulse bank, it distinguishes the scientific method from the concrete implementation used in this repository.

::: info Why this page exists
`tse-pulseq-matlab` is an open-source sequence package. Reproducibility therefore requires both **method citations** and **code/software provenance**. A paper can explain why an algorithm is valid; it does not by itself identify which implementation, adaptation or generated data file is present in the repository.
:::

## Acquisition and sequence generation

| Functionality | Implementation used here | Source / provenance | Scientific basis |
| --- | --- | --- | --- |
| Pulse sequence construction | Pulseq MATLAB `mr.*` events and `Sequence` object through the `pulseq/` submodule | [`pulseq/pulseq`](https://github.com/pulseq/pulseq) | [[2]](/references#ref-2 "Layton KJ, Kroboth S, Jia F, et al. Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. Magn Reson Med. 2017;77:1544-1552.") |
| Cartesian RARE/TSE echo train | Repository sequence loops and RF/gradient preparation | `TSE_2D.m`, `prep/prep_Seqloop*.m` | [[1]](/references#ref-1 "Hennig J, Nauerth A, Friedburg H. RARE imaging: a fast imaging method for clinical MR. Magn Reson Med. 1986;3:823-833.") |
| SLR refocusing / inversion pulse banks | Generated offline by `prep/pulse/RF_pulse.ipynb` using `sigpy.mri.rf.slr.dzrf`; loaded by MATLAB at sequence-generation time | [SigPy](https://github.com/mikgroup/sigpy); generated `.mat` files are stored in `prep/pulse/` | [[20]](/references#ref-20 "Pauly JM, Le Roux P, Nishimura DG, Macovski A. Parameter relations for the Shinnar-Le Roux selective excitation pulse design algorithm. IEEE Trans Med Imaging. 1991;10:53-65.") |
| gSlider excitation pulse bank | Generated offline by `prep/pulse/RF_pulse.ipynb` using `sigpy.mri.rf.slr.dz_gslider_rf` | [SigPy](https://github.com/mikgroup/sigpy); bundled `gSlider_excit_0.01_0.01.mat` | [[21]](/references#ref-21 "Setsompop K, Fan Q, Stockmann J, et al. High-resolution in vivo diffusion imaging of the human brain with generalized slice dithered enhanced resolution: simultaneous multislice (gSlider-SMS). Magn Reson Med. 2018;79:141-151.") |
| Repository gSlider-TSE sequence | `TSE_2D_gSlider.m` and gSlider-specific sequence loops | Repository implementation | [[14]](/references#ref-14 "Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. Proc Intl Soc Magn Reson Med. 2024; Program #3256.") |
| TRAPS-style variable refocusing train | `utils/fliptraps.m`; schedule selected by `TSE_2D_gSlider.m` | Repository implementation of the TRAPS concept; no claim that `fliptraps.m` is the authors' original distributed code | [[22]](/references#ref-22 "Hennig J, Weigel M, Scheffler K. Multiecho sequences with variable refocusing flip angles: optimization of signal behavior using smooth transitions between pseudo steady states (TRAPS). Magn Reson Med. 2003;49:527-535.") |
| VERSE RF reshaping | `VERSE/` Git submodule | [`BennyZhang-Codes/VERSE-RF-Pulse`](https://github.com/BennyZhang-Codes/VERSE-RF-Pulse), which records upstream lineage to `mriphysics/verse-mb`, `mriphysics/reVERSE-GIRF`, Shaihan Malik's VERSE code and Michael Lustig's `minTimeGradient` framework | [[23]](/references#ref-23 "Lee D, Lustig M, Grissom WA, Pauly JM. Time-optimal design for multidimensional and parallel transmit variable-rate selective excitation. Magn Reson Med. 2009;61:1471-1479.") |

## Compressed-sensing acquisition pattern

The CS acquisition path is **not Poisson-disc sampling**. It is a one-dimensional phase-encoding variable-density pattern based on Michael Lustig's SparseMRI sampling utilities [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195.").

The concrete implementation is:

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

Source-level provenance:

- `prep/CS/genPDF.m` retains the header `(c) Michael Lustig 2007` and generates a polynomial variable-density probability density function.
- `prep/CS/genSampling.m` retains the same attribution and generates Monte-Carlo masks while minimizing the maximum off-center interference of `ifft2(mask ./ pdf)`.
- `prep/CS/genSampling_TSE.m` is the TSE-oriented repository adaptation. It targets an explicit number of acquired PE samples so the sample count is compatible with the echo-train length.
- `prep/prep_PE3DOrder_CS.m` computes

$$
N_{\mathrm{acq}}
=
\operatorname{round}\!\left(\frac{N_{\mathrm{PE}}}{R N_E}\right)N_E,
$$

uses `genPDF(nPE,p,Nacq/nPE,2,r,1)`, performs 500 Monte-Carlo trials through `genSampling_TSE`, and then maps the selected logical PE locations into the TSE acquisition order.

The historical SparseMRI software distribution associated with these functions is documented on Michael Lustig's SparseMRI software page: <http://web.stanford.edu/~mlustig/SparseMRI.html>.

## Reconstruction methods

| Functionality | Implementation used here | Source / dependency | Scientific basis |
| --- | --- | --- | --- |
| Siemens Twix read | `read_TSE2D_twix.m` | external [mapVBVD](https://github.com/pehses/mapVBVD) | software dependency; no paper is substituted for the code source |
| Receive-noise prewhitening | `estimate_noise_whitener.m`, `apply_coil_matrix.m` | repository MATLAB implementation | [[3]](/references#ref-3 "Roemer PB, Edelstein WA, Hayes CE, Souza SP, Mueller OM. The NMR phased array. Magn Reson Med. 1990;16:192-225.") [[4]](/references#ref-4 "Kellman P, McVeigh ER. Image reconstruction in SNR units: a general method for SNR measurement. Magn Reson Med. 2005;54:1439-1447.") |
| PE-GRAPPA | `recon_TSE2D_GRAPPA.m` | repository MATLAB implementation | [[5]](/references#ref-5 "Griswold MA, Jakob PM, Heidemann RM, et al. Generalized autocalibrating partially parallel acquisitions (GRAPPA). Magn Reson Med. 2002;47:1202-1210.") |
| SENSE encoding | `recon_TSE2D_SENSE.m`, shared `PFS` operator | repository MATLAB implementation | [[6]](/references#ref-6 "Pruessmann KP, Weiger M, Scheidegger MB, Boesiger P. SENSE: sensitivity encoding for fast MRI. Magn Reson Med. 1999;42:952-962.") |
| ESPIRiT sensitivity maps | `estimate_TSE2D_espirit.m` | repository MATLAB implementation | [[7]](/references#ref-7 "Uecker M, Lai P, Murphy MJ, et al. ESPIRiT: an eigenvalue approach to autocalibrating parallel MRI. Magn Reson Med. 2014;71:990-1001.") |
| Global PCA coil compression | `compress_TSE2D_coils.m`; eigendecomposition of ACS coil covariance with energy-fraction truncation | repository MATLAB implementation | [[24]](/references#ref-24 "Buehrer M, Pruessmann KP, Boesiger P, Kozerke S. Array compression for MRI with large coil arrays. Magn Reson Med. 2007;57:1131-1139.") |
| Cartesian CS reconstruction | `recon_TSE2D_CS.m`; common `PFS` data consistency + TV + Haar-L1 | repository MATLAB implementation | sparse MRI [[8]](/references#ref-8 "Lustig M, Donoho D, Pauly JM. Sparse MRI: the application of compressed sensing for rapid MR imaging. Magn Reson Med. 2007;58:1182-1195."); primal-dual solver [[9]](/references#ref-9 "Chambolle A, Pock T. A first-order primal-dual algorithm for convex problems with applications to imaging. J Math Imaging Vis. 2011;40:120-145.") |
| Echo-envelope equalization | `apply_TSE_echomagcor.m`; optional power / normalized Wiener-style gain from measured TSE navigators | repository MATLAB implementation | RARE/FSE correction literature [[16]](/references#ref-16 "Oshio K, Singh M. Correction of T2 distortion in multi-excitation RARE sequence. IEEE Trans Med Imaging. 1992;11:123-128.")–[[19]](/references#ref-19 "Busse RF, Riederer SJ, Fletcher JG, Bharucha AE, Brandt KR. Interactive fast spin-echo imaging. Magn Reson Med. 2000;44:339-348."); Wiener basis [[15]](/references#ref-15 "Wiener N. Extrapolation, Interpolation, and Smoothing of Stationary Time Series, with Engineering Applications. MIT Press; 1949.") |

## Optional image-domain denoising

Denoising is not part of the default raw-data reconstruction. It is a separately invoked post-processing module.

| Method | Concrete implementation | Dependency status | Scientific basis |
| --- | --- | --- | --- |
| NLM | MATLAB `imnlmfilt` through `denoise_TSE2D.m` | MATLAB Image Processing Toolbox | [[25]](/references#ref-25 "Buades A, Coll B, Morel JM. A non-local algorithm for image denoising. CVPR. 2005;2:60-65.") |
| BM3D | external BM3D 4.x called by `denoise_TSE2D.m` | optional; not vendored | original BM3D [[11]](/references#ref-11 "Dabov K, Foi A, Katkovnik V, Egiazarian K. Image denoising by sparse 3-D transform-domain collaborative filtering. IEEE Trans Image Process. 2007;16:2080-2095."); correlated-noise formulation [[12]](/references#ref-12 "Mäkinen Y, Azzari L, Foi A. Collaborative filtering of correlated noise: exact transform-domain variance for improved shrinkage and patch matching. IEEE Trans Image Process. 2020;29:8339-8354.") |
| SANLM | external CAT12 `cat_sanlm` | optional; not vendored | [[13]](/references#ref-13 "Manjón JV, Coupé P, Martí-Bonmatí L, Collins DL, Robles M. Adaptive non-local means denoising of MR images with spatially varying noise levels. J Magn Reson Imaging. 2010;31:192-203.") |
| TGV2 | `denoise_TGV2.m` | repository implementation | TGV MRI [[10]](/references#ref-10 "Knoll F, Bredies K, Pock T, Stollberger R. Second order total generalized variation (TGV) for MRI. Magn Reson Med. 2011;65:480-491."); Chambolle-Pock solver [[9]](/references#ref-9 "Chambolle A, Pock T. A first-order primal-dual algorithm for convex problems with applications to imaging. J Math Imaging Vis. 2011;40:120-145.") |

## Platform-specific tooling

The following items are implementation dependencies rather than vendor-neutral sequence concepts:

- Siemens MDH/Twix conventions and the current LIN/ICE integration;
- mapVBVD for offline Twix reading;
- Siemens `.asc` PNS models used by the currently implemented development check;
- applicable Siemens IDEA/ICE documentation for the validated environment.

These items are documented under [Platform integration](/platform-integration) and [Siemens 7 T LIN & ICE](/phase-encoding-and-ice). They should not be generalized to other scanner platforms without an explicit adapter and validation.

## Attribution rule for future contributions

When a new method or utility is added, document all three levels when applicable:

1. **scientific method** — peer-reviewed paper or primary method publication;
2. **software/code source** — upstream repository, package, toolbox or retained copyright header;
3. **repository adaptation** — exactly what was changed or wrapped here.

Do not describe copied/adapted code as an independent implementation, and do not describe an independent implementation as upstream source code merely because it follows the same paper.
