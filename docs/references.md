# Literature references

Scientific references use numbered citations in the main text. Numbers are ordered by the first appearance of the core methods in the documentation. The legacy named anchors are retained inside the same list items so older internal links remain valid.

<ol class="tse-references">
  <li id="ref-1"><span id="ref-rare"></span><strong>Hennig J, Nauerth A, Friedburg H.</strong> RARE imaging: a fast imaging method for clinical MR. <em>Magn Reson Med.</em> 1986;3(6):823–833. doi:10.1002/mrm.1910030602.</li>
  <li id="ref-2"><span id="ref-pulseq"></span><strong>Layton KJ, Kroboth S, Jia F, et al.</strong> Pulseq: a rapid and hardware-independent pulse sequence prototyping framework. <em>Magn Reson Med.</em> 2017;77(4):1544–1552. doi:10.1002/mrm.26235.</li>
  <li id="ref-3"><span id="ref-roemer"></span><strong>Roemer PB, Edelstein WA, Hayes CE, Souza SP, Mueller OM.</strong> The NMR phased array. <em>Magn Reson Med.</em> 1990;16(2):192–225. doi:10.1002/mrm.1910160203.</li>
  <li id="ref-4"><span id="ref-kellman"></span><strong>Kellman P, McVeigh ER.</strong> Image reconstruction in SNR units: a general method for SNR measurement. <em>Magn Reson Med.</em> 2005;54(6):1439–1447. doi:10.1002/mrm.20713.</li>
  <li id="ref-5"><span id="ref-grappa"></span><strong>Griswold MA, Jakob PM, Heidemann RM, et al.</strong> Generalized autocalibrating partially parallel acquisitions (GRAPPA). <em>Magn Reson Med.</em> 2002;47(6):1202–1210. doi:10.1002/mrm.10171.</li>
  <li id="ref-6"><span id="ref-sense"></span><strong>Pruessmann KP, Weiger M, Scheidegger MB, Boesiger P.</strong> SENSE: sensitivity encoding for fast MRI. <em>Magn Reson Med.</em> 1999;42(5):952–962. doi:10.1002/(SICI)1522-2594(199911)42:5&lt;952::AID-MRM16&gt;3.0.CO;2-S.</li>
  <li id="ref-7"><span id="ref-espirit"></span><strong>Uecker M, Lai P, Murphy MJ, et al.</strong> ESPIRiT: an eigenvalue approach to autocalibrating parallel MRI. <em>Magn Reson Med.</em> 2014;71(3):990–1001. doi:10.1002/mrm.24751.</li>
  <li id="ref-8"><span id="ref-sparse-mri"></span><strong>Lustig M, Donoho D, Pauly JM.</strong> Sparse MRI: the application of compressed sensing for rapid MR imaging. <em>Magn Reson Med.</em> 2007;58(6):1182–1195. doi:10.1002/mrm.21391.</li>
  <li id="ref-9"><span id="ref-chambolle-pock"></span><strong>Chambolle A, Pock T.</strong> A first-order primal-dual algorithm for convex problems with applications to imaging. <em>J Math Imaging Vis.</em> 2011;40:120–145. doi:10.1007/s10851-010-0251-1.</li>
  <li id="ref-10"><span id="ref-tgv"></span><strong>Knoll F, Bredies K, Pock T, Stollberger R.</strong> Second order total generalized variation (TGV) for MRI. <em>Magn Reson Med.</em> 2011;65(2):480–491. doi:10.1002/mrm.22595.</li>
  <li id="ref-11"><span id="ref-bm3d"></span><strong>Dabov K, Foi A, Katkovnik V, Egiazarian K.</strong> Image denoising by sparse 3-D transform-domain collaborative filtering. <em>IEEE Trans Image Process.</em> 2007;16(8):2080–2095. doi:10.1109/TIP.2007.901238.</li>
  <li id="ref-12"><span id="ref-bm3d-correlated"></span><strong>Mäkinen Y, Azzari L, Foi A.</strong> Collaborative filtering of correlated noise: exact transform-domain variance for improved shrinkage and patch matching. <em>IEEE Trans Image Process.</em> 2020;29:8339–8354. doi:10.1109/TIP.2020.3014721.</li>
  <li id="ref-13"><span id="ref-sanlm"></span><strong>Manjón JV, Coupé P, Martí-Bonmatí L, Collins DL, Robles M.</strong> Adaptive non-local means denoising of MR images with spatially varying noise levels. <em>J Magn Reson Imaging.</em> 2010;31(1):192–203. doi:10.1002/jmri.22003.</li>
  <li id="ref-14"><span id="ref-gslider"></span><strong>Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z.</strong> gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. In: <em>Proc Intl Soc Magn Reson Med.</em> 2024. Program #3256.</li>
  <li id="ref-15"><span id="ref-wiener"></span><strong>Wiener N.</strong> <em>Extrapolation, Interpolation, and Smoothing of Stationary Time Series, with Engineering Applications.</em> Cambridge, MA: MIT Press; 1949.</li>
</ol>

## Software resources

Software dependencies are cited separately from peer-reviewed method references.

- **Pulseq** — sequence description is tracked as the `pulseq/` submodule; scientific citation is reference [2].
- **mapVBVD** — Siemens Twix raw-data reader used by the current MATLAB reconstruction path: <https://github.com/pehses/mapVBVD>.
- **VERSE-RF-Pulse** — tracked in the `VERSE/` submodule; see the submodule repository for its upstream source and licensing notes.

## Software citation

For this repository, use the metadata in `CITATION.cff`. A reproducible report should also record the exact repository commit and submodule SHAs used to generate the sequence/reconstruction. See [Reproducibility & Citation](/reproducibility).

## Vendor documentation

The Siemens-specific integration notes rely in part on the applicable ICE/IDEA developer documentation for the validated environment. These vendor materials are not substituted for public scientific references and are not redistributed by this documentation site.
