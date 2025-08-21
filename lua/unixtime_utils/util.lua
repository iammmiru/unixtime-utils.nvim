local Util = {}

-- Normalize a numeric string representing epoch seconds (10) or milliseconds (13) to seconds
-- Returns nil if not acceptable per flags
function Util.normalize_epoch(num_str, accept_seconds, accept_ms)
  if #num_str == 13 and accept_ms then
    local ok, val = pcall(tonumber, num_str)
    if not ok or not val then
      return nil
    end
    return math.floor(val / 1000)
  elseif #num_str == 10 and accept_seconds then
    local ok, val = pcall(tonumber, num_str)
    if not ok or not val then
      return nil
    end
    return val
  end
  return nil
end

function Util.validate_timezone(tz)
  if tz == "local" or tz == "UTC" then
    return true
  end
  if type(tz) == "string" and tz:match("^[+-]%d%d%d%d$") then
    local _, hh, mm = tz:match("^([+-])(%d%d)(%d%d)$")
    hh, mm = tonumber(hh), tonumber(mm)
    if hh <= 23 and mm <= 59 then
      return true
    end
  end
  vim.notify("Invalid timezone: " .. tostring(tz) .. " (keeping previous)", vim.log.levels.ERROR)
  return false
end

-- Build standard virtual text tuple list
function Util.build_virt_text(human, highlight, prefix)
  prefix = prefix or " ⏰ "
  return { { prefix .. human, highlight } }
end

return Util
