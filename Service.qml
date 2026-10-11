import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

// Plays one soft tone on the current output when you set the volume in the
// audio panel, once the level has stopped moving, so you hear the level you
// landed on and which device it is. Dragging the slider stays silent until the
// level rests, and the volume keys stay silent altogether.
//
// It watches one PipeWire sink and Hyprland's layer events, and launches two
// fixed programs. Both are
// launched the same way: an absolute path, never a name resolved through an
// inherited PATH, a closed environment holding only what the child needs, and
// a deadline.
QtObject {
  id: root

  // How long the level must hold still before it counts as landed.
  readonly property int landedAfterMs: 180

  // tick.wav is the volume sound of KDE's Ocean theme (audio-volume-change.oga,
  // kept beside it; Guilherme Marçal Silva, CC-BY-SA-4.0) made much louder: as
  // shipped it peaks at -16 dB and is hard to hear. It is raised 26 dB with a
  // limiter holding the peaks just under full scale. To make it louder or
  // softer, change the dB and rerun in this folder (takes effect on the next
  // tone, no restart):
  //   ffmpeg -y -i audio-volume-change.oga -af "volume=26dB,alimiter=limit=0.89:level=0" -ar 48000 tick.wav
  // The gain lives in the file rather than in `pw-play --volume` because
  // WirePlumber remembers stream volume per stream kind, shared with every
  // other sound of that kind.
  readonly property string sound: decodeURIComponent(Qt.resolvedUrl("tick.wav").toString().replace("file://", ""))

  readonly property var childEnvironment: ({
    "PATH": "/usr/bin",                                    // omarchy-audio-output-sink calls pactl and awk by name
    "XDG_RUNTIME_DIR": Quickshell.env("XDG_RUNTIME_DIR"),  // where the PipeWire sockets live
    "LC_ALL": "C"
  })

  function play() {
    // ponytail: the node name borrows the prefix the stock audio panel already
    // hides from its SOURCES list, so the tone doesn't flash a row there. If
    // that filter changes, the worst case is a row blinking once per tone.
    Quickshell.execDetached({
      command: ["/usr/bin/timeout", "3", "/usr/bin/pw-play", "--media-role", "Notification",
                "-P", "{ node.name = \"omarchy_speaker_tuning.volume-beep\" }", root.sound],
      clearEnvironment: true,
      environment: root.childEnvironment
    })
  }

  // The tone plays on the default output. The level worth listening for is the
  // one the volume keys and the audio panel really move: behind a DSP sink (a
  // speaker tuning, EasyEffects) that is the physical sink underneath, and
  // omarchy-audio-output-sink resolves it the same way they do. A plain
  // hardware or Bluetooth output is its own answer, so nothing is run for it.
  readonly property var output: Pipewire.defaultAudioSink
  readonly property string outputName: output ? String(output.name || "") : ""
  readonly property bool layered: outputName !== ""
    && outputName.indexOf("alsa_output.") !== 0 && outputName.indexOf("bluez_output.") !== 0
  property string levelSinkName: ""

  readonly property var sink: {
    if (!layered || levelSinkName === "" || levelSinkName === outputName) return output
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isSink && !n.isStream && String(n.name) === levelSinkName && n.audio) return n
    }
    return output
  }
  readonly property var audio: sink ? sink.audio : null

  function resolve() {
    if (layered && !resolver.running) resolver.running = true
  }
  onOutputChanged: resolve()

  // The answer is one sink name. It is read as raw chunks and only the first
  // 256 characters are ever kept, so nothing the child prints can pile up here.
  property string answer: ""

  property Process resolver: Process {
    command: ["/usr/bin/omarchy-audio-output-sink"]
    clearEnvironment: true
    environment: root.childEnvironment
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.answer.length < 256) root.answer = (root.answer + chunk).slice(0, 256)
      }
    }
    onStarted: {
      root.answer = ""
      root.resolverDeadline.restart()
    }
    onExited: function(code) {
      root.resolverDeadline.stop()
      if (code === 0) root.levelSinkName = root.answer.split("\n")[0].trim()
    }
  }

  property Timer resolverDeadline: Timer {
    interval: 3000
    onTriggered: root.resolver.running = false
  }

  // A DSP sink links to its hardware a moment after it appears, and can be
  // applied or removed underneath us, so ask again now and then while one is
  // in front.
  property Timer recheck: Timer {
    interval: 15000
    repeat: true
    triggeredOnStart: true
    running: root.layered
    onTriggered: root.resolve()
  }

  // Only a change made with a bar panel open is answered. The plugin cannot see
  // the slider, but Hyprland announces layer surfaces as they open and close:
  // the bar's popup panels share one namespace and the volume OSD has its own.
  // The volume keys always raise the OSD, so a level that lands while it is up
  // came from the keyboard and stays silent even with a panel open.
  property int panelsOpen: 0
  property int osdsOpen: 0

  property Connections layers: Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name !== "openlayer" && event.name !== "closelayer") return
      var step = event.name === "openlayer" ? 1 : -1
      if (event.data === "omarchy-keyboard-panel") root.panelsOpen = Math.max(0, root.panelsOpen + step)
      else if (event.data === "omarchy-osd") root.osdsOpen = Math.max(0, root.osdsOpen + step)
    }
  }

  // A device that just became the output reports its stored level as it binds.
  // That is not somebody changing the volume, so it stays silent.
  property double quietUntil: Date.now() + 1000
  property real heard: -1
  onAudioChanged: {
    quietUntil = Date.now() + 1000
    heard = -1
  }

  property PwObjectTracker tracker: PwObjectTracker {
    objects: [root.sink]
  }

  property Connections watch: Connections {
    target: root.audio

    function onVolumesChanged() {
      // The same level reported twice (set, then confirmed) is one change.
      var level = root.audio.volume
      if (Math.abs(level - root.heard) < 0.004) return
      root.heard = level
      if (root.panelsOpen > 0 && Date.now() >= root.quietUntil) root.landed.restart()
    }
  }

  property Timer landed: Timer {
    interval: root.landedAfterMs
    onTriggered: if (root.osdsOpen === 0) root.play()
  }
}
