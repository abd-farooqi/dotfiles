function cpuSample(text) {
  var line = text.split("\n")[0].trim().split(/\s+/)
  if (!/^cpu\d*$/.test(line[0]) || line.length < 9) return null
  var values = line.slice(1, 9).map(Number)
  if (values.some(function(value) { return !isFinite(value) })) return null
  return {total: values.reduce(function(a, b) { return a + b }, 0), idle: values[3] + values[4]}
}

function cpuPercent(previous, current) {
  if (!previous || !current || current.total <= previous.total) return null
  return Math.round(Math.max(0, Math.min(100,
    100 * (1 - (current.idle - previous.idle) / (current.total - previous.total)))))
}

function cpuSamples(text) {
  var samples = {}
  text.split("\n").forEach(function(line) {
    if (!/^cpu\d*\s/.test(line)) return
    var sample = cpuSample(line)
    if (sample) samples[line.trim().split(/\s+/)[0]] = sample
  })
  return samples
}

function cpuInfo(text) {
  var model = ""
  var speeds = []
  text.split("\n").forEach(function(line) {
    var pair = line.split(":")
    if (pair.length < 2) return
    var key = pair[0].trim()
    var value = pair.slice(1).join(":").trim()
    if (!model && (key === "model name" || key === "Hardware")) model = value.replace(/\(R\)|\(TM\)/g, "")
    if (key === "cpu MHz" && Number(value) > 0) speeds.push(Number(value))
  })
  return {model: model || "Processor", frequency: speeds.length
    ? (speeds.reduce(function(a, b) { return a + b }, 0) / speeds.length / 1000).toFixed(2) + " GHz" : "Unavailable"}
}

function loadAverage(text) {
  var parts = text.trim().split(/\s+/).slice(0, 3)
  return parts.length === 3 && parts.every(function(value) { return isFinite(Number(value)) })
    ? parts.join(" / ") : "Unavailable"
}

function uptime(text) {
  var seconds = Number(text.trim().split(/\s+/)[0])
  if (!text.trim() || !isFinite(seconds) || seconds < 0) return "Unavailable"
  var minutes = Math.floor(seconds / 60)
  var days = Math.floor(minutes / 1440)
  return (days ? days + "d " : "") + Math.floor(minutes % 1440 / 60) + "h " + minutes % 60 + "m"
}

function powerState(profile, governor, driver) {
  var names = {performance: "Performance", balanced: "Balanced", "power-saver": "Power saver"}
  var selected = String(profile || "").trim()
  return {profile: Object.prototype.hasOwnProperty.call(names, selected) ? names[selected] : "Unavailable",
    governor: governor === "powersave" && driver === "intel_pstate"
      ? "powersave (dynamic)" : governor || "Unavailable"}
}

function powerPreference(text) {
  var names = {performance: "Performance", balance_performance: "Favor performance",
    balance_power: "Favor efficiency", power: "Power saving", default: "Driver default"}
  return Object.prototype.hasOwnProperty.call(names, String(text).trim()) ? names[String(text).trim()] : "Unavailable"
}

function throttleSample(text, previous) {
  var values = {}
  text.trim().split("\n").forEach(function(line) {
    var parts = line.trim().split(/\s+/)
    if (parts.length === 2 && /^\d+$/.test(parts[1])) values[parts[0]] = Number(parts[1])
  })
  var keys = Object.keys(values)
  var comparable = keys.filter(function(key) { return previous && previous[key] !== undefined })
  var increased = comparable.some(function(key) { return values[key] > previous[key] })
  return {values: values, status: !keys.length ? "Unavailable" : !comparable.length
    ? "Measuring..." : increased ? "Events detected" : "No new events"}
}

function memory(text) {
  var values = {}
  text.split("\n").forEach(function(line) {
    var match = line.match(/^(MemTotal|MemAvailable|MemFree|Cached|Buffers|SReclaimable|Shmem|SwapTotal|SwapFree):\s+(\d+)/)
    if (match) values[match[1]] = Number(match[2])
  })
  if (!(values.MemTotal > 0) || values.MemAvailable === undefined) return null
  var used = values.MemTotal - values.MemAvailable
  return {percent: Math.round(100 * used / values.MemTotal),
    used: (used / 1048576).toFixed(1), total: (values.MemTotal / 1048576).toFixed(1),
    available: (values.MemAvailable / 1048576).toFixed(1),
    free: ((values.MemFree || 0) / 1048576).toFixed(1),
    cache: (Math.max(0, (values.Cached || 0) + (values.Buffers || 0)
      + (values.SReclaimable || 0) - (values.Shmem || 0)) / 1048576).toFixed(1),
    shared: ((values.Shmem || 0) / 1048576).toFixed(1),
    swapTotal: ((values.SwapTotal || 0) / 1048576).toFixed(1),
    swap: (((values.SwapTotal || 0) - (values.SwapFree || 0)) / 1048576).toFixed(1)}
}
