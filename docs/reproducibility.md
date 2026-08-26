# Reproducibility & citation

For a reproducible acquisition or reconstruction, keep the exact software/configuration used rather than only the final image or `.seq` file.

## What to save

For sequence generation, keep:

- repository commit or release;
- Pulseq submodule SHA and VERSE SHA when used;
- `Setup`, `SetupRF`, and `SetupSpoiling`;
- resolved `Actual`;
- generated `.seq`; and
- scanner/interpreter information needed to reproduce execution.

For reconstruction, also keep:

- raw-data reader/dependency version when relevant;
- preprocessing options;
- reconstruction method and its parameters;
- sensitivity/coil-compression settings for SENSE/CS; and
- any optional echo correction or denoising settings.

The [Reconstruction](/reconstruction) page documents the available options.

## Generated RF assets

The bundled SLR and gSlider RF pulse banks are stored in the repository. If you regenerate or replace them, record the generating notebook/script, SigPy version when relevant, RF design parameters, and any subsequent VERSE/scaling steps.

Method and software provenance are listed in [Dependencies & Method Provenance](/reference/provenance).

## CS sampling

When using `AccelerationMode='CS'`, save the resolved PE order or sampling mask in addition to the nominal acceleration and sampling parameters. The current mask generation contains randomized sampling, so the resolved pattern is the most direct reproducibility record.

See [Phase Encoding & Acceleration](/theory/phase-encoding).

## Citation

Use the repository DOI:

**10.5281/zenodo.22076863**

and cite the scientific methods actually used in the acquisition/reconstruction. The DOI-linked bibliography is in [Literature References](/references).

If `TSE_2D_gSlider.m` is used, also cite the repository's associated gSlider-TSE work [[14]](/references#ref-14 "Zhang J, Wu Y, Xue R, Zhuo Y, Zhang Z. gSlider-TSE for high-resolution isotropic T2-weighted imaging with high contrast and high SNR. Proc Intl Soc Magn Reson Med. 2024; Program #3256.") together with the relevant gSlider method reference when appropriate.

A compact methods record is usually sufficient:

```text
Software: repository release/commit + submodule SHAs
Acquisition: Setup/Actual + generated .seq + target scanner/interpreter
Reconstruction: reader + preprocessing + method + parameters
Optional processing: method + parameters, or none
```
