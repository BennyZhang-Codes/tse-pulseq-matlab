# Literature references

This page collects the main references used by the sequence, reconstruction, correction, and denoising documentation. Method pages link here with stable numbered anchors.

<ol class="tse-references">
  <li id="ref-rare"><strong>Hennig J, Nauerth A, Friedburg H.</strong> RARE imaging: a fast imaging method for clinical MR. <em>Magnetic Resonance in Medicine</em>. 1986;3(6):823–833. doi:10.1002/mrm.1910030602.</li>
  <li id="ref-pulseq"><strong>Layton KJ, Kroboth S, Jia F, et al.</strong> Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. <em>Magnetic Resonance in Medicine</em>. 2017;77(4):1544–1552. doi:10.1002/mrm.26235.</li>
  <li id="ref-roemer"><strong>Roemer PB, Edelstein WA, Hayes CE, Souza SP, Mueller OM.</strong> The NMR phased array. <em>Magnetic Resonance in Medicine</em>. 1990;16(2):192–225. doi:10.1002/mrm.1910160203.</li>
  <li id="ref-kellman"><strong>Kellman P, McVeigh ER.</strong> Image reconstruction in SNR units: a general method for SNR measurement. <em>Magnetic Resonance in Medicine</em>. 2005;54(6):1439–1447. doi:10.1002/mrm.20713.</li>
  <li id="ref-grappa"><strong>Griswold MA, Jakob PM, Heidemann RM, et al.</strong> Generalized autocalibrating partially parallel acquisitions (GRAPPA). <em>Magnetic Resonance in Medicine</em>. 2002;47(6):1202–1210. doi:10.1002/mrm.10171.</li>
  <li id="ref-espirit"><strong>Uecker M, Lai P, Murphy MJ, et al.</strong> ESPIRiT: an eigenvalue approach to autocalibrating parallel MRI. <em>Magnetic Resonance in Medicine</em>. 2014;71(3):990–1001. doi:10.1002/mrm.24751.</li>
  <li id="ref-sparse-mri"><strong>Lustig M, Donoho D, Pauly JM.</strong> Sparse MRI: the application of compressed sensing for rapid MR imaging. <em>Magnetic Resonance in Medicine</em>. 2007;58(6):1182–1195. doi:10.1002/mrm.21391.</li>
  <li id="ref-chambolle-pock"><strong>Chambolle A, Pock T.</strong> A first-order primal-dual algorithm for convex problems with applications to imaging. <em>Journal of Mathematical Imaging and Vision</em>. 2011;40:120–145. doi:10.1007/s10851-010-0251-1.</li>
  <li id="ref-tgv"><strong>Knoll F, Bredies K, Pock T, Stollberger R.</strong> Second order total generalized variation (TGV) for MRI. <em>Magnetic Resonance in Medicine</em>. 2011;65(2):480–491. doi:10.1002/mrm.22595.</li>
  <li id="ref-bm3d"><strong>Dabov K, Foi A, Katkovnik V, Egiazarian K.</strong> Image denoising by sparse 3-D transform-domain collaborative filtering. <em>IEEE Transactions on Image Processing</em>. 2007;16(8):2080–2095.</li>
  <li id="ref-bm3d-correlated"><strong>Mäkinen Y, Azzari L, Foi A.</strong> Collaborative filtering of correlated noise: exact transform-domain variance for improved shrinkage and patch matching. <em>IEEE Transactions on Image Processing</em>. 2020;29:8339–8354.</li>
  <li id="ref-sanlm"><strong>Manjón JV, Coupé P, Martí-Bonmatí L, Collins DL, Robles M.</strong> Adaptive non-local means denoising of MR images with spatially varying noise levels. <em>Journal of Magnetic Resonance Imaging</em>. 2010;31:192–203.</li>
  <li id="ref-gslider"><strong>Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z.</strong> gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. In: <em>Proceedings of the 2024 ISMRM and ISMRT Annual Meeting and Exhibition</em>, Singapore. Program #3256.</li>
  <li id="ref-mapvbvd"><strong>Schmitt P, et al.</strong> <code>mapVBVD</code>: Siemens Twix raw-data reader for MATLAB. Open-source software repository.</li>
  <li id="ref-wiener"><strong>Wiener N.</strong> <em>Extrapolation, Interpolation, and Smoothing of Stationary Time Series, with Engineering Applications</em>. MIT Press; 1949.</li>
</ol>

## Software citation

For the repository itself, use the metadata in `CITATION.cff`. The reproducibility page records the current repository DOI and the recommended release/commit information to report with an acquisition: [Reproducibility & Citation](/reproducibility).

## Vendor documentation

The Siemens-specific integration notes also draw on the applicable Siemens ICE and IDEA developer documentation for the validated platform. These are vendor materials rather than redistributable project documentation, so this site describes only the integration behavior needed to understand the open implementation.
