# Reconstruction API

The reconstruction interface, processing principles, parameter defaults, examples and source map are now documented together in the engineering-oriented [Reconstruction](/reconstruction) chapter.

This page is retained only so that existing links do not break.

## Entry point

```matlab
result = recon_TSE2D(filename, Name, Value, ...)
```

Continue to:

- [Reconstruction pipeline and principles](/reconstruction#processing-pipeline)
- [Reconstruction methods](/reconstruction#_6-reconstruction-methods)
- [SENSE/CS options](/reconstruction#_7-shared-sense-cs-encoding-operator)
- [Coil compression and ESPIRiT](/reconstruction#_8-coil-compression-and-sensitivity-maps)
- [Source map](/reconstruction#source-map)
- [Optional echo correction](/guide/echo-corrections)
- [Optional denoising](/guide/denoising)

The checked-out [`recon_TSE2D.m`](https://github.com/BennyZhang-Codes/tse-pulseq-matlab/blob/vitepress-style/recon/matlab/recon_TSE2D.m) remains the authoritative source for exact option parsing.
