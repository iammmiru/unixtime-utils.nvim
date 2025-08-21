local Timezone = {}
local config = require("unixtime_utils.config")

local function validate_timezone(tz)
  if tz == "local" or tz == "UTC" then
    return true
  end
  if type(tz) == 'string' and tz:match("^[+-]%d%d%d%d$") then
    local _, hh, mm = tz:match("^([+-])(%d%d)(%d%d)$")
    hh, mm = tonumber(hh), tonumber(mm)
    if hh <= 23 and mm <= 59 then
      return true
    end
  end
  vim.notify("Invalid timezone: " .. tostring(tz) .. " (keeping previous)", vim.log.levels.ERROR)
  return false
end

local function parse_offset(tz)
  local sign, hh, mm = tz:match("^([+-])(%d%d)(%d%d)$")
  if not sign then
    return nil
  end
  local off = (tonumber(hh) * 60 + tonumber(mm)) * 60
  if sign == "-" then
    off = -off
  end
  return off
end

local function compute_local_utc_offset(epoch_local)
  local utc_table = os.date("!*t", epoch_local)
  local reconstructed = os.time({
    year = utc_table.year,
    month = utc_table.month,
    day = utc_table.day,
    hour = utc_table.hour,
    min = utc_table.min,
    sec = utc_table.sec,
    isdst = false,
  })
  return reconstructed - epoch_local
end

function Timezone.format_epoch(epoch_seconds, fmt)
  fmt = fmt or "%Y-%m-%d %H:%M:%S"
  local tz = config.timezone
  if tz == "local" then
    return os.date(fmt, epoch_seconds)
  end
  local local_offset = compute_local_utc_offset(epoch_seconds)
  local off = 0
  if tz == "UTC" then
    off = 0
  else
    local fixed = parse_offset(tz)
    if fixed then
      off = fixed
    else
      return os.date(fmt, epoch_seconds) -- fallback
    end
  end
  local adjusted = epoch_seconds + (local_offset - off)
  return os.date(fmt, adjusted)
end

function Timezone.resolve_epoch(d, m, y, H, M, S)
  local tz = config.timezone
  local local_epoch = os.time({ year = y, month = m, day = d, hour = H, min = M, sec = S })
  if not local_epoch then
    return nil, "os.time failed"
  end
  if tz == "local" then
    return local_epoch
  end
  local offset_local = compute_local_utc_offset(local_epoch)
  local epoch_utc = local_epoch - offset_local
  if tz == "UTC" then
    return epoch_utc
  end
  local fixed = parse_offset(tz)
  if fixed then
    return local_epoch - (offset_local - fixed)
  end
  return local_epoch
end

function Timezone.get_timezone()
  return config.timezone
end

function Timezone.set_timezone(tz)
  if validate_timezone(tz) then
    config.set('timezone', tz)
    return true
  end
  return false
end

return Timezone
