local M = {}

-- Derive global timezone preference from any of the config tables.
-- Order of precedence: explicit module config (passed in), vim.g.unixtime_utils.convert.timezone,
-- vim.g.unixtime_utils_config.timezone, fallback 'local'.

local function extract_global_timezone()
  local tz
  if vim.g.unixtime_utils and type(vim.g.unixtime_utils.convert) == "table" then
    tz = vim.g.unixtime_utils.convert.timezone or tz
  end
  if not tz and type(vim.g.unixtime_utils_convert) == "table" then
    tz = vim.g.unixtime_utils_convert.timezone or tz
  end
  if not tz and vim.g.unixtime_utils_config and type(vim.g.unixtime_utils_config) == "table" then
    tz = vim.g.unixtime_utils_config.timezone or tz
  end
  return tz or "local"
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

-- Convert a unix epoch seconds (assumed UTC) to a human string in target timezone.
function M.format_epoch(epoch_seconds, fmt, tz)
  fmt = fmt or "%Y-%m-%d %H:%M:%S"
  tz = tz or extract_global_timezone()
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
  -- Adjust epoch from UTC to local; we need to account for Lua's os.date using local timezone.
  -- os.date interprets given epoch as local, so to display target timezone we shift by (local_offset - target_offset)
  local adjusted = epoch_seconds + (local_offset - off)
  return os.date(fmt, adjusted)
end

function M.get_timezone()
  return extract_global_timezone()
end

return M
