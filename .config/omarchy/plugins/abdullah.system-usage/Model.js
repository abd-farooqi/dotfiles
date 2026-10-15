function cpuSample(text) {
  var line = text.split("\n")[0].trim().split(/\s+/)
  if (line[0] !== "cpu" || line.length < 9) return null
  var values = line.slice(1, 9).map(Number)
  if (values.some(function(value) { return !isFinite(value) })) return null
  return {total: values.reduce(function(a, b) { return a + b }, 0), idle: values[3] + values[4]}
}

function cpuPercent(previous, current) {
  if (!previous || !current || current.total <= previous.total) return null
  return Math.round(Math.max(0, Math.min(100,
    100 * (1 - (current.idle - previous.idle) / (current.total - previous.total)))))
}

function memory(text) {
  var values = {}
  text.split("\n").forEach(function(line) {
    var match = line.match(/^(MemTotal|MemAvailable|SwapTotal|SwapFree):\s+(\d+)/)
    if (match) values[match[1]] = Number(match[2])
  })
  if (!(values.MemTotal > 0) || values.MemAvailable === undefined) return null
  var used = values.MemTotal - values.MemAvailable
  return {percent: Math.round(100 * used / values.MemTotal),
    used: (used / 1048576).toFixed(1), total: (values.MemTotal / 1048576).toFixed(1),
    available: (values.MemAvailable / 1048576).toFixed(1),
    swap: ((values.SwapTotal - values.SwapFree) / 1048576).toFixed(1)}
}
