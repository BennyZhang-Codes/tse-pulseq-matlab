# 7 T staged phantom validation SOP

This is a conservative development workflow for the Siemens-targeted 2D TSE and gSlider-TSE paths. It is not a clinical protocol or substitute for local MR safety procedures.

## Stage 0 — Freeze the software configuration

Record the main-repository commit, Pulseq and VERSE submodule SHAs, MATLAB release, scanner/interpreter version, `Setup`, resolved `Actual`, and reconstruction options. Generate a fresh `.seq`; do not reuse a similarly named file from another commit.

## Stage 1 — Offline acceptance

Before scanner transfer:

- confirm `seq.checkTiming` passes;
- inspect `seq.testReport` for gradient/slew maxima;
- inspect PE order, the physical `ky=0` echo, PI LIN/ACS metadata, and labels;
- inspect gradient continuity around crushers, rephasers, and spoilers;
- for VERSE/gSlider, inspect RF peak B1, pulse duration, slice profile, and nominal RF-energy metrics.

A pass at this stage establishes only software consistency.

## Stage 2 — Conservative phantom baseline

Start with a low-duty-cycle `R=1` conventional TSE phantom protocol. Verify:

- scanner acceptance and no unexpected watchdog messages;
- displayed orientation, slice order, RO/PE polarity, and geometric scale;
- central-slice signal, background noise, ringing, ghosting, and edge sharpness;
- agreement between saved sequence metadata and protocol settings.

Use an asymmetric object when checking orientation. Do not infer anatomical direction from the displayed label alone.

## Stage 3 — Echo-train and ordering assessment

Acquire matched variants while changing one factor at a time:

1. linear versus centric ordering;
2. short versus longer echo train;
3. selected `TEeff` position;
4. crusher/spoiler cycles if residual coherence or stimulated-echo behavior is suspected.

Compare blur/ringing along PE, phase-direction ghosting, intensity modulation, and object displacement. Echo-amplitude correction may sharpen the image but can amplify noise; assess its gain map and noise penalty separately from acquisition artifacts.

## Stage 4 — PI and phase correction

With geometry and contrast fixed:

1. establish the `R=1` reference;
2. test PI at R=2, then R=3 and R=4 only after validating each preceding setting;
3. match scanner iPAT acceleration and ACS/reference settings to exported metadata;
4. compare online reconstruction with offline reconstruction;
5. test TSE phase correction off/on with otherwise identical data.

For each R, confirm that `ky=0` uses the intended LIN, ACS is contiguous, and phase-direction artifacts do not increase unexpectedly. A one-line LIN convention mismatch can appear primarily as linear phase or direction-dependent artifacts.

## Stage 5 — High-resolution and gSlider/VERSE extensions

Increase resolution or enable gSlider/VERSE only after the conventional baseline is stable. Re-evaluate RF/SAR duty cycle, peak B1, gradient fidelity, slice profile, and image artifacts. At 7 T, waveform agreement on paper does not guarantee equivalent eddy-current behavior on the scanner.

## Stop criteria and evidence

Stop and investigate before further escalation if scanner warnings occur, geometric/orientation errors appear, PI reconstruction is inconsistent with its R=1 reference, or artifacts systematically follow PE direction.

Archive de-identified phantom images, window/level settings, raw-data identifiers permitted by local policy, reconstruction logs, and scanner messages together with the software record. Never commit identifiable raw scanner data to this repository.