-- Manual test script for unixtime_utils.convert timezone handling
-- Run inside nvim: :lua dofile('lua/unixtime_utils/tests_convert.lua')

local tzmod = require('unixtime_utils.timezone')

local samples = {
  { input = "01.01.2025 00:00:00", tzs = { "local", "UTC", "+0000", "+0100", "-0500", "+0530" } },
  { input = "28.03.2025 12:34:56", tzs = { "local", "UTC", "+0100" } },
  { input = "31.12.2025 23:59:59", tzs = { "local", "UTC", "-0800" } },
}

local function parse(str)
  local d, m, y, H, M, S = str:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)%s+(%d%d):(%d%d):(%d%d)$")
  return tonumber(d), tonumber(m), tonumber(y), tonumber(H), tonumber(M), tonumber(S)
end

local function compute_epoch(d, m, y, H, M, S, tz)
  local ok = tzmod.set_timezone(tz)
  if not ok then
    return nil, 'bad tz'
  end
  -- replicate resolve_epoch logic through timezone module directly
  return tzmod.resolve_epoch(d, m, y, H, M, S)
end

-- (debug helper removed; using public API)

print("Timezone test results:")
for _, sample in ipairs(samples) do
  local d, m, y, H, M, S = parse(sample.input)
  if d then
    for _, tz in ipairs(sample.tzs) do
      tzmod.set_timezone(tz)
      local epoch = (function()
        -- replicate resolve (private) via public API path
        local line = sample.input
        local pd, pm, py, pH, pM, pS = d, m, y, H, M, S
        local t = { year = py, month = pm, day = pd, hour = pH, min = pM, sec = pS }
        local local_epoch = os.time(t)
        local utc_table = os.date("!*t", local_epoch)
        local reconstructed = os.time({
          year = utc_table.year,
          month = utc_table.month,
          day = utc_table.day,
          hour = utc_table.hour,
          min = utc_table.min,
          sec = utc_table.sec,
          isdst = false,
        })
        local offset_local = reconstructed - local_epoch
        local tzcur = tzmod.get_timezone()
        if tzcur == "local" then
          return local_epoch
        end
        local epoch_utc = local_epoch - offset_local
        if tzcur == "UTC" then
          return epoch_utc
        end
        local sign, hh, mm = tzcur:match("^([+-])(%d%d)(%d%d)$")
        if sign then
          local fixed = (tonumber(hh) * 60 + tonumber(mm)) * 60
          if sign == "-" then
            fixed = -fixed
          end
          return local_epoch - (offset_local - fixed)
        end
        return local_epoch
      end)()
      print(string.format("%s | %s -> %d", sample.input, tz, epoch or -1))
    end
  end
end
