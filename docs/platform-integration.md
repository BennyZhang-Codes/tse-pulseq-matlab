# Platform integration

The project goal is to develop **vendor-neutral Cartesian 2D TSE sequences with Pulseq**. The Pulseq acquisition concept should describe RF, gradients, ADC, timing and logical encoding independently of a single scanner vendor.

The **current implementation is not yet fully decoupled from Siemens**, however. Scanner presets, PI line mapping and several exported definitions are still embedded in the shared preparation path because development and validation have so far been performed on Siemens 7 T systems.

Other vendors and scanner models should therefore be treated as new implementation and validation targets, not as already supported systems.

## Portability boundary

The intended architecture is:

<div class="architecture-flow" role="group" aria-label="Target platform integration architecture">
  <div class="arch-node primary">
    <span class="arch-kicker">ACQUISITION</span>
    <strong>Vendor-neutral design</strong>
    <span>RF · gradients · ADC · timing · logical PE order · Pulseq labels</span>
  </div>
  <div class="arch-arrow">→</div>
  <div class="arch-node compact neutral">
    <span class="arch-kicker">INTERFACE</span>
    <strong>.seq</strong>
    <span>Pulseq description</span>
  </div>
  <div class="arch-arrow">→</div>
  <div class="arch-node integration">
    <span class="arch-kicker">PLATFORM</span>
    <strong>Platform integration</strong>
    <span>Interpreter · hardware limits · safety/PNS · orientation · metadata</span>
  </div>
  <div class="arch-arrow">→</div>
  <div class="arch-node validation">
    <span class="arch-kicker">VALIDATION</span>
    <strong>Scanner validation</strong>
    <span>Software checks · phantom tests · scanner-side safety checks</span>
  </div>
  <div class="arch-arrow">→</div>
  <div class="arch-node reconstruction">
    <span class="arch-kicker">OPTIONAL</span>
    <strong>Raw-data reconstruction</strong>
    <span>Vendor reader / metadata → reconstruction model</span>
  </div>
</div>

This is the **target separation of concerns**. It should guide future refactoring and new-platform support even though the current MATLAB prep functions still contain Siemens-specific logic.

## Current code state

::: warning Current implementation is Siemens-coupled
At present, porting to another vendor requires **code changes**, not only a different `ScannerType` value.
:::

The current coupling includes:

- `prep_System` accepts only the `Terra-XJ` and `Terra-XR` scanner profiles and errors on other `ScannerType` values;
- `prep_PE3DOrder` applies the Siemens zero-based LIN mapping directly for accelerated PI;
- `prep_Definition` exports the current Siemens-oriented PE/ACS, `TurboFactor`, `PhaseCorrection`, slice and interpreter definitions in the common sequence-generation path;
- `check_PNS` currently relies on Siemens `.asc` hardware models;
- the bundled offline raw-data reconstruction reads Siemens Twix through `mapVBVD`.

These are the parts that should gradually become explicit platform-integration code as support expands beyond the currently validated Siemens 7 T environment.

## Current platform status

| Layer | Current status |
| --- | --- |
| Design goal | Vendor-neutral Pulseq 2D TSE and gSlider-TSE acquisition design. |
| Current sequence implementation | Pulseq-based, but shared prep code still contains Siemens-specific system and metadata logic. |
| Scanner validation | Performed on Siemens 7 T systems. |
| Hardware presets | `Terra-XJ` and `Terra-XR` only. |
| PNS development model | Siemens `.asc` models in the current `check_PNS` path. |
| Online integration | Siemens interpreter, LIN/iPAT and ICE behavior. |
| Offline raw-data reconstruction | Siemens Twix through `mapVBVD`. |
| Other vendors | Not yet implemented or validated in this repository. |

::: info What “vendor-neutral” means here
It describes the **project objective and the intended Pulseq-level acquisition model**. It is not a claim that the current repository can already execute unchanged on every Pulseq-capable scanner.
:::

## What should become vendor-neutral

When extending or refactoring the project, keep these concepts independent of Siemens-specific field names where possible:

- TSE echo-train timing and effective-TE placement;
- RF pulse definitions and flip-angle schedules;
- gradient areas, rasterization and waveform constraints;
- logical readout, phase-encoding and slice axes;
- logical `ky` ordering and PI/CS sampling design;
- slice acquisition ordering;
- Pulseq RF, gradient, ADC and label events;
- saved user-requested acquisition configuration.

These describe the acquisition itself and should not require Siemens LIN or Twix semantics.

## What belongs in platform integration

A platform-specific layer may need to provide or translate:

- scanner hardware profile and absolute gradient/slew limits;
- PNS or equivalent safety models;
- Pulseq interpreter capabilities and version requirements;
- logical-to-physical axis conventions and orientation metadata;
- PI/ACS metadata expected by the scanner reconstruction;
- navigator and phase-correction metadata;
- online reconstruction configuration;
- raw-data format and metadata parsing;
- scanner-specific validation procedures.

The current Siemens 7 T implementation is the first concrete platform path. See [Siemens 7 T encoding & ICE](phase-encoding-and-ice.md) for its current metadata contract.

## Porting to another scanner platform

A practical port should proceed in stages.

### 1. Establish interpreter compatibility

Confirm that the target scanner has a Pulseq interpreter capable of executing the event types and labels used by the maintained sequence path. Record the interpreter version and unsupported definitions.

### 2. Refactor or add the system profile

Add the target scanner's field strength, gradient/slew limits, raster/dead-time requirements and safety/PNS strategy. The current `prep_System` switch must be extended or refactored rather than reusing a Terra preset.

### 3. Separate logical PE from platform line numbering

Preserve the logical `ky` sampling order, but move or adapt the platform-specific mapping currently embedded in `prep_PE3DOrder`.

For PI, explicitly define:

- full encoded PE matrix size;
- k-space center;
- acceleration factor;
- ACS/reference region;
- imaging versus reference lines;
- index base and line-number convention.

Do not copy Siemens LIN numbering unless the new platform actually uses the same convention.

### 4. Define interpreter-facing metadata

Review the definitions currently written by `prep_Definition`. Determine which are generic acquisition metadata, which are required by the new interpreter, and which are Siemens-only. Prefer a platform-specific export/translation layer instead of accumulating vendor conditionals in the common sequence logic.

### 5. Verify geometry and orientation

Map logical RO/PE/slice axes to the scanner coordinate system and verify gradient polarity, slice order and displayed orientation using an asymmetric phantom.

### 6. Validate the fully sampled baseline

Start with a conservative `R=1` conventional 2D TSE acquisition. Confirm timing, scanner acceptance, geometry, slice order, image orientation and basic image quality before enabling PI, CS, gSlider or VERSE extensions.

### 7. Validate accelerated and navigator paths

Add PI/ACS and phase-correction behavior only after the baseline is stable. Confirm that scanner protocol settings and exported metadata describe the same acquisition.

### 8. Add raw-data reconstruction only if needed

A vendor-neutral sequence does not require a vendor-neutral raw-data reader. For another raw-data format, implement a reader that maps vendor-specific data and metadata into the reconstruction model rather than introducing raw-data assumptions into the sequence design.

### 9. Repeat staged safety and phantom validation

A successful port is a **new validation target**. Repeat scanner-side RF/SAR, gradient/PNS, watchdog and phantom checks before any in-vivo use.

## Current Siemens 7 T implementation

For the platform that has actually been tested, the repository currently uses:

- `ScannerType = 'Terra-XJ'` or `'Terra-XR'`;
- Siemens `.asc` PNS models for development checks;
- Siemens-oriented LIN/ACS mapping for accelerated PI;
- Siemens interpreter definitions for the current acquisition/reconstruction contract;
- Siemens ICE-related phase-correction metadata;
- Siemens Twix + `mapVBVD` for offline raw-data reconstruction.

The long-term vendor-neutral direction is to keep these details **outside the reusable acquisition concepts** as clearly as practical.

## Related pages

- [Sequence generation](sequence-generation.md) — acquisition design and current sequence workflow.
- [Parameter reference](parameter-reference.md) — user-facing sequence controls.
- [Siemens 7 T encoding & ICE](phase-encoding-and-ice.md) — current Siemens metadata and online reconstruction integration.
- [Offline reconstruction](reconstruction.md) — current Siemens Twix reconstruction path.
- [Validation and safety](validation-and-safety.md) — validation principles for any scanner target.
- [Siemens 7 T phantom validation](staged-phantom-validation.md) — staged workflow used for the current validated platform.
