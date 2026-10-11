# Changelog

## 1.0.0 — 2026-10-11

First release.

- One soft tone on the default output once its volume has held still for
  180 ms. Sliding, scrolling and held keys stay silent until the level rests.
- Follows the sink the volume keys and the audio panel really move, including
  the hardware sink behind a speaker tuning or EasyEffects.
- Silent when a device merely becomes the output, at shell start, and on mute.
