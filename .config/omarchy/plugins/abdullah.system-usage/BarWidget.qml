import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "abdullah.system-usage"
  property var previousCpu: null
  property var cpu: null
  property var ram: null

  function openMonitor() {
    if (bar) bar.run("omarchy-launch-or-focus-tui btop")
  }

  FileView {
    id: cpuFile
    path: "/proc/stat"
    onLoaded: {
      var sample = Model.cpuSample(text())
      root.cpu = Model.cpuPercent(root.previousCpu, sample)
      root.previousCpu = sample
    }
  }
  FileView {
    id: memoryFile
    path: "/proc/meminfo"
    onLoaded: root.ram = Model.memory(text())
  }
  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: { cpuFile.reload(); memoryFile.reload() }
  }

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight
  Row {
    id: content
    WidgetButton {
      bar: root.bar
      text: " " + (root.cpu === null ? "--" : root.cpu) + "%"
      fontSize: Style.font.caption
      horizontalMargin: 7
      tooltipText: "Total CPU usage across all cores\nUpdates every 3 seconds\nClick to open btop"
      onPressed: root.openMonitor()
    }
    WidgetButton {
      bar: root.bar
      text: "󰍛 " + (root.ram ? root.ram.percent : "--") + "%"
      fontSize: Style.font.caption
      horizontalMargin: 7
      tooltipText: root.ram
        ? "RAM: " + root.ram.used + " / " + root.ram.total + " GiB\nAvailable: " + root.ram.available
          + " GiB\nSwap used: " + root.ram.swap + " GiB\nReclaimable cache counts as available.\nClick to open btop"
        : "Reading memory usage..."
      onPressed: root.openMonitor()
    }
  }
}
