import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "abdullah.system-usage"
  property var previousSamples: ({})
  property var cpu: null
  property var coreRows: []
  property var ram: null
  property var processor: ({model: "Processor", frequency: "Unavailable"})
  property string load: "Unavailable"
  property string uptimeText: "Unavailable"
  property string governor: "Unavailable"
  property string temperaturePath: ""
  property string temperature: "Unavailable"
  property bool opened: false
  property string panelKind: "cpu"
  readonly property bool cpuPanel: panelKind === "cpu"
  readonly property var detailRows: cpuPanel ? [
    {label: "Average clock", value: processor.frequency},
    {label: "Temperature", value: temperature},
    {label: "Load (1 / 5 / 15 min)", value: load},
    {label: "Logical CPUs", value: String(coreRows.length)},
    {label: "Governor", value: governor},
    {label: "Uptime", value: uptimeText}
  ] : [
    {label: "Used", value: ram ? ram.used + " GiB" : "--"},
    {label: "Available", value: ram ? ram.available + " GiB" : "--"},
    {label: "Free", value: ram ? ram.free + " GiB" : "--"},
    {label: "File cache", value: ram ? ram.cache + " GiB" : "--"},
    {label: "Shared memory", value: ram ? ram.shared + " GiB" : "--"},
    {label: "Swap", value: ram ? ram.swap + " / " + ram.swapTotal + " GiB" : "--"}
  ]

  function refreshDetails() {
    if (cpuPanel) {
      processorFile.reload()
      loadFile.reload()
      uptimeFile.reload()
      governorFile.reload()
      if (temperaturePath) temperatureFile.reload()
    } else memoryFile.reload()
  }
  function open(kind) {
    panelKind = kind === "memory" ? "memory" : "cpu"
    opened = true
    refreshDetails()
  }
  function close() { opened = false }
  function togglePanel(kind) {
    if (opened && panelKind === kind) close()
    else open(kind)
  }

  Component.onCompleted: sensorDiscovery.running = true

  QtObject {
    id: popupOwner
    function close() { root.close() }
  }

  FileView {
    id: cpuFile
    path: "/proc/stat"
    onLoaded: {
      var samples = Model.cpuSamples(text())
      root.cpu = Model.cpuPercent(root.previousSamples.cpu, samples.cpu)
      root.coreRows = Object.keys(samples).filter(function(name) { return name !== "cpu" }).map(function(name) {
        return {name: name, percent: Model.cpuPercent(root.previousSamples[name], samples[name])}
      })
      root.previousSamples = samples
    }
  }
  FileView {
    id: memoryFile
    path: "/proc/meminfo"
    onLoaded: root.ram = Model.memory(text())
  }
  FileView {
    id: processorFile
    path: "/proc/cpuinfo"
    onLoaded: root.processor = Model.cpuInfo(text())
  }
  FileView {
    id: loadFile
    path: "/proc/loadavg"
    onLoaded: root.load = Model.loadAverage(text())
  }
  FileView {
    id: uptimeFile
    path: "/proc/uptime"
    onLoaded: root.uptimeText = Model.uptime(text())
  }
  FileView {
    id: governorFile
    path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    printErrors: false
    onLoaded: root.governor = text().trim() || "Unavailable"
    onLoadFailed: root.governor = "Unavailable"
  }
  Process {
    id: sensorDiscovery
    command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*; do case $(cat \"$d/name\" 2>/dev/null) in coretemp|k10temp|zenpower|cpu_thermal) if [ -r \"$d/temp1_input\" ]; then printf '%s' \"$d/temp1_input\"; break; fi;; esac; done"]
    stdout: StdioCollector { onStreamFinished: root.temperaturePath = text.trim() }
  }
  FileView {
    id: temperatureFile
    path: root.temperaturePath
    printErrors: false
    onLoaded: {
      var value = Number(text().trim())
      root.temperature = isFinite(value) && value > 0 ? Math.round(value / 1000) + "°C" : "Unavailable"
    }
    onLoadFailed: root.temperature = "Unavailable"
  }
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      cpuFile.reload()
      memoryFile.reload()
      if (root.opened) root.refreshDetails()
    }
  }
  IpcHandler {
    target: "abdullah.system-usage"
    function openCpu(): void { root.open("cpu") }
    function openMemory(): void { root.open("memory") }
    function close(): void { root.close() }
  }

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight
  Row {
    id: content
    WidgetButton {
      id: cpuButton
      bar: root.bar
      text: " " + (root.cpu === null ? "--" : root.cpu) + "%"
      fontSize: Style.font.caption
      horizontalMargin: 7
      tooltipText: ""
      onPressed: root.togglePanel("cpu")
    }
    WidgetButton {
      id: ramButton
      bar: root.bar
      text: "󰍛 " + (root.ram ? root.ram.percent : "--") + "%"
      fontSize: Style.font.caption
      horizontalMargin: 7
      tooltipText: ""
      onPressed: root.togglePanel("memory")
    }
  }

  Rectangle {
    parent: root.cpuPanel ? cpuButton : ramButton
    visible: root.opened
    width: parent.labelWidth
    height: Style.space(2)
    x: Math.round((parent.width - width) / 2)
    y: root.bar && root.bar.position === "bottom" ? Style.space(2)
      : parent.height - height - Style.space(2)
    radius: height / 2
    color: Color.accent
    opacity: 0.9
    z: 50
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.cpuPanel ? cpuButton : ramButton
    owner: popupOwner
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(Style.space(370))
    contentHeight: panel.fittedContentHeight(Math.min(info.implicitHeight, Style.space(580)))

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) {
        if (dx) root.open(root.cpuPanel ? "memory" : "cpu")
        scroll.contentY = Math.max(0, Math.min(Math.max(0, scroll.contentHeight - scroll.height),
          scroll.contentY + dy * Style.space(50)))
      }
      onTabRequested: root.open(root.cpuPanel ? "memory" : "cpu")
      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: info.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
          id: info
          width: parent.width
          spacing: Style.space(12)
          Text {
            text: root.cpuPanel ? "CPU" : "Memory"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            width: parent.width
            text: root.cpuPanel ? root.processor.model : root.ram ? root.ram.total + " GiB total RAM" : "Reading memory..."
            color: Color.foreground
            opacity: 0.65
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Text {
            text: root.cpuPanel ? (root.cpu === null ? "Measuring..." : root.cpu + "% usage")
              : root.ram ? root.ram.percent + "% used" : "Measuring..."
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Rectangle {
            width: parent.width
            height: Style.space(5)
            radius: height / 2
            color: Style.normalFill
            Rectangle {
              width: parent.width * Math.max(0, Math.min(100, root.cpuPanel ? (root.cpu || 0) : root.ram ? root.ram.percent : 0)) / 100
              height: parent.height
              radius: parent.radius
              color: Color.accent
            }
          }
          Repeater {
            model: root.detailRows
            Item {
              required property var modelData
              width: info.width
              height: Style.space(27)
              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: Color.foreground
                opacity: 0.65
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.value
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
          PanelSeparator { width: parent.width }
          Text {
            visible: root.cpuPanel
            text: "PER-CORE USAGE"
            color: Color.foreground
            opacity: 0.65
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
          }
          Grid {
            id: cores
            visible: root.cpuPanel
            width: parent.width
            columns: 4
            spacing: Style.space(10)
            Repeater {
              model: root.coreRows
              Column {
                required property var modelData
                width: (cores.width - cores.spacing * 3) / 4
                spacing: Style.space(6)
                Text {
                  text: modelData.name.replace("cpu", "CPU ") + "  " + (modelData.percent === null ? "--" : modelData.percent) + "%"
                  color: Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                }
                Rectangle {
                  width: parent.width
                  height: Style.space(3)
                  color: Style.normalFill
                  Rectangle {
                    width: parent.width * (modelData.percent || 0) / 100
                    height: parent.height
                    color: Color.accent
                  }
                }
              }
            }
          }
          Text {
            width: parent.width
            text: root.cpuPanel ? "Live every second · Load is queued/running work, not a percentage.\nTab to switch to memory · Esc to close"
              : "Available includes reclaimable cache. Figures overlap; don't add the rows.\nLive every second · Tab for CPU · Esc to close"
            color: Color.foreground
            opacity: 0.55
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
