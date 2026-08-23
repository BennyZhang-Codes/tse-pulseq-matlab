# Optional MATLAB denoiser dependencies

Third-party denoisers are installed under `third_party_local/`, which is
ignored by Git. Their source code and binaries must not be copied into this
repository without complying with their own licenses.

## BM3D 4.0.3

- Official site: <https://webpages.tuni.fi/foi/GCF-BM3D/>
- MATLAB archive: `bm3d_matlab_package_4.0.3.zip`
- Expected local function:
  `third_party_local/bm3d-4.0.3/bm3d_matlab_package_4.0.3/bm3d/BM3D.m`
- License: non-commercial education and scientific research only. Read and
  accept the official TAU limited license before downloading or using it.
- This workflow uses the current correlated-noise interface and supplies a
  two-dimensional background-estimated noise PSD.

Relevant publications:

- Dabov K, Foi A, Katkovnik V, Egiazarian K. *Image denoising by sparse 3-D
  transform-domain collaborative filtering*. IEEE Transactions on Image
  Processing. 2007;16:2080-2095.
- Makinen Y, Azzari L, Foi A. *Collaborative filtering of correlated noise:
  Exact transform-domain variance for improved shrinkage and patch matching*.
  IEEE Transactions on Image Processing. 2020;29:8339-8354.

## CAT12 SANLM

- Official repository: <https://github.com/ChristianGaser/cat12>
- Expected local MEX:
  `third_party_local/cat12/cat_sanlm.mexw64` on 64-bit Windows.
- License: GNU GPL version 2 or later; see the repository `COPYING` file.
- The default wrapper uses Gaussian SANLM and emulates 2-D processing by
  replicating each slice. This prevents through-plane mixing in anisotropic
  2-D TSE data. CAT12 itself also defaults to its Gaussian branch.
- The optional legacy Rician branch is not used because RSS multi-coil data
  follow a noncentral-chi rather than a single-coil Rician model.
- SANLM is available for method comparison but is not enabled by the batch
  benchmark default. Both direct slice emulation and unscaled 3-D processing
  were too structure-removing for the current five-slice anisotropic phantom
  data; brain use requires a separate near-isotropic-data validation.

Relevant publication:

- Manjon JV, Coupe P, Marti-Bonmati L, Collins DL, Robles M. *Adaptive
  non-local means denoising of MR images with spatially varying noise levels*.
  Journal of Magnetic Resonance Imaging. 2010;31:192-203.

## Second-order TGV

`denoise_TGV2.m` is a transparent MATLAB implementation of the standard
TGV-L2 model using a conservative Chambolle-Pock primal-dual solver. It has no
external runtime dependency.

Relevant publications:

- Knoll F, Bredies K, Pock T, Stollberger R. *Second order total generalized
  variation (TGV) for MRI*. Magnetic Resonance in Medicine. 2011;65:480-491.
- Chambolle A, Pock T. *A first-order primal-dual algorithm for convex
  problems with applications to imaging*. Journal of Mathematical Imaging and
  Vision. 2011;40:120-145.
