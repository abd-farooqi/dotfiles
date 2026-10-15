const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

function model(id) {
  const context = vm.createContext({})
  vm.runInContext(fs.readFileSync(path.join(__dirname, "..", ".config", "omarchy", "plugins", id, "Model.js"), "utf8"), context)
  return context
}

const usage = model("abdullah.system-usage")
assert.equal(usage.cpuPercent({total: 100, idle: 60}, {total: 200, idle: 90}), 70)
assert.equal(usage.cpuPercent(null, {total: 100, idle: 60}), null)
assert.equal(usage.cpuSample("cpu 10 20 30 40 5 6 7 8 100 100").total, 126)
assert.equal(usage.memory("MemTotal: 1000 kB\nMemAvailable: 400 kB\nSwapTotal: 100 kB\nSwapFree: 50 kB").percent, 60)
assert.equal(usage.memory("MemTotal: 0 kB"), null)

const prayer = model("abdullah.prayer-times")
const days = [{date: {gregorian: {day: "15", month: {number: 10}, year: "2026"}, readable: "15 Oct 2026"},
  timings: {Fajr: "05:00", Sunrise: "06:20", Dhuhr: "12:00", Asr: "16:00", Maghrib: "17:40", Isha: "19:00"}}]
const view = prayer.display(days, new Date("2026-10-15T10:00:00Z"), "Test", "", 18000)
assert.equal(view.next, "Asr")
assert.equal(view.rows.length, 6)
assert.equal(view.rows[3].time, "4:00 PM")
assert.equal(prayer.display(days, new Date("2026-10-15T15:00:00Z"), "Test", "", 18000).text, "Fajr tomorrow")
assert.equal(prayer.display(days, new Date("2026-10-15T20:00:00Z"), "Test", "", 18000).rows.length, 0)
assert.equal(prayer.dayKey(new Date("2026-10-31T23:00:00Z"), 18000), "2026-11-1")
assert.equal(prayer.dayKey(new Date("2026-11-01T01:00:00Z"), -18000), "2026-10-31")
assert.equal(prayer.display([], new Date(), "", "Offline").rows.length, 0)
console.log("PASS: CPU deltas, memory accounting, prayer selection, timezone/day/month boundaries, unavailable data")
