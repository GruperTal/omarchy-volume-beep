# Changelog

## 1.2.0 — 2026-10-11

- New sound: a single soft harp note, a real recording from VSCO 2: Community
  Edition by Versilian Studios (CC0). It replaces the KDE Ocean theme sound,
  so nothing in the repository is tied to a desktop environment any more and
  the CC-BY-SA files are gone.

## 1.1.0 — 2026-10-11

- The tone now answers only changes made with a bar panel open, which in
  practice means the audio panel's slider. The volume keys, scrolling on the
  bar icon and other mixers are silent.
- Reads Hyprland's `openlayer` / `closelayer` events to know when a panel or
  the volume OSD is on screen.

## 1.0.0 — 2026-10-11

First release.

- One soft tone on the default output once its volume has held still for
  180 ms. Sliding, scrolling and held keys stay silent until the level rests.
- Follows the sink the volume keys and the audio panel really move, including
  the hardware sink behind a speaker tuning or EasyEffects.
- Silent when a device merely becomes the output, at shell start, and on mute.
