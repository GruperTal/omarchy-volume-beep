# Volume Beep for Omarchy

<p>
  <a href="https://github.com/GruperTal/omarchy-volume-beep/actions/workflows/test.yml"><img alt="CI status" height="20" src="https://github.com/GruperTal/omarchy-volume-beep/actions/workflows/test.yml/badge.svg?branch=main"></a>
  <a href="LICENSE"><img alt="License: MIT" height="20" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"></a>
  <a href="https://github.com/tcballard/omarchy-badges"><img alt="Built for Omarchy: Plugin" height="20" src="https://raw.githubusercontent.com/tcballard/omarchy-badges/75975e5b5bf75e7ede3764bcd2950046f7abfe2c/badges/v1/omarchy-plugin.svg"></a>
</p>

Change the volume and hear where it landed. One soft tone plays on your
current output once the level stops moving, so you know how loud it is now and
which device is actually playing: the monitor, the headphones or the laptop.

![Volume Beep](preview.png)

Windows does this when you let go of its volume slider, usually after a
noticeable wait. This one answers about a fifth of a second after the level
rests, and it works the same from the audio panel's slider, the volume keys
and scrolling on the bar icon.

- Sliding, scrolling and holding a key are silent. You get one tone at the
  end, at the level you chose.
- A device merely becoming the output is silent, and so are mute and shell
  start.
- There is no bar widget and nothing to configure. It is a service.

## Requirements

- Omarchy 4 with Quattro shell-plugin support (see [Compatibility](#compatibility)).
- PipeWire with `pw-play`, and `omarchy-audio-output-sink`. Both are in the
  Omarchy base install. Nothing else is installed or downloaded.

## Install

```bash
omarchy plugin add https://github.com/GruperTal/omarchy-volume-beep.git --enable
```

Then change the volume.

## Use

Change the output volume any way you like. When it has held still for 180 ms
you hear the tone at the new level.

The tone is an ordinary stream on the default output, so it is exactly as
loud as that output currently is. With a speaker tuning or EasyEffects in
front of your speakers, it follows the hardware level the volume keys and the
audio panel really move.

### Tuning

Both knobs are in the plugin folder,
`~/.config/omarchy/plugins/gruper.volume-beep/`.

- **Loudness.** `tick.wav` is generated from `audio-volume-change.oga`. Change
  the dB and rerun; it takes effect on the next tone:

  ```bash
  ffmpeg -y -i audio-volume-change.oga -af "volume=26dB,alimiter=limit=0.89:level=0" -ar 48000 tick.wav
  ```

  Any short 48 kHz WAV saved as `tick.wav` works if you want a different sound.
- **How soon it answers.** `landedAfterMs` at the top of `Service.qml`, 180
  by default. Lower is snappier and more likely to sound in the middle of a
  slow drag. Run `omarchy restart shell` after editing QML.

Local edits make `omarchy plugin update` refuse until you stash or drop them.

## How it works

`Service.qml` watches the volume of one PipeWire sink through Quickshell's
PipeWire service. Each change restarts a 180 ms timer; when it fires, the
service runs `pw-play` on `tick.wav`. A level reported twice is counted once,
and changes in the first second after an output appears are ignored, because
that is the device reporting its stored level.

The sink it watches is the default output. When the default output is a DSP
sink, it asks `omarchy-audio-output-sink` for the hardware sink underneath,
the same resolution the volume keys and the audio panel use, and asks again
every 15 seconds while a DSP sink is in front.

Two limits worth knowing:

- A click on the slider that leaves the level unchanged is silent. Nothing
  outside the audio panel can see that click.
- The tone's stream is named with the `omarchy_speaker_tuning` prefix. The
  stock audio panel hides that prefix from its per-app list, which keeps the
  tone from flashing a row there after every change. If the panel's filter
  changes, a row will blink once per tone and nothing else breaks.

## Validation and tests

```bash
./tests/run          # portable: manifest, entry point, launch paths, the tone file
./tests/live         # on a running desktop: counts the tones for a press and a slide
omarchy plugin validate .
```

`tests/run` needs only `python3` and `bash`; GitHub Actions runs it on every
push. `tests/live` nudges your volume by 1% a few times and puts it back, and
you will hear the tones.

## Update

```bash
omarchy plugin update gruper.volume-beep
```

## Removal

```bash
omarchy plugin remove gruper.volume-beep
```

That is everything. The plugin writes no files and changes no other
configuration.

## Compatibility

Tested on Omarchy `4.0.4-1` (quickshell `0.3.1-1`, Hyprland `0.56.2-2`,
PipeWire `1.6.8`, WirePlumber `0.5.17`) on 2026-10-11, on a Dell XPS 9320
(x86_64) playing through an HDMI output. The DSP-sink path was tested with a
loopback sink placed in front of that output, not with a shipped speaker
tuning or EasyEffects. Not tested: Bluetooth outputs, other architectures, and
other Omarchy versions.

## Security and privacy

Omarchy plugins run as unsandboxed code inside `omarchy-shell`. Review this
repository before enabling it. It is about 150 lines of QML.

The plugin reads the volume of one audio sink. It uses no network, writes no
files and reads no input. It launches two programs, both by absolute path,
with an environment cleared down to `PATH=/usr/bin`, `XDG_RUNTIME_DIR` and
`LC_ALL=C`, and both with a 3 second deadline:

- `/usr/bin/timeout 3 /usr/bin/pw-play … tick.wav`, once per tone.
- `/usr/bin/omarchy-audio-output-sink`, only while the default output is not
  a plain hardware or Bluetooth sink. Its output is one sink name, read in raw
  chunks and capped at 256 characters.

Report security problems through
[GitHub issues](https://github.com/GruperTal/omarchy-volume-beep/issues) or a
[private vulnerability report](https://github.com/GruperTal/omarchy-volume-beep/security/advisories/new).

## Third-party

- `audio-volume-change.oga` is the volume sound of KDE's
  [Ocean sound theme](https://invent.kde.org/plasma/ocean-sound-theme),
  © 2023 Guilherme Marçal Silva,
  [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/). It is
  included unmodified.
- `tick.wav` is that sound resampled to 48 kHz WAV, raised 26 dB and limited
  to just under full scale. As an adaptation it is under CC-BY-SA-4.0 too.
- This is an independent community plugin, not affiliated with or endorsed by
  KDE or Omarchy.

## License

The code, the logo and this documentation are [MIT](LICENSE). The two sound
files are CC-BY-SA-4.0 as described above.
