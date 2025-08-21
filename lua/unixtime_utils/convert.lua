local Input = require("unixtime_utils.input")
local Convert = {}

local config = {
  keymap = "<leader>tu", -- trigger for date->unix conversion popup
  prompt = "Enter date (DD.MM.YYYY [HH:MM[:SS]]):",
  highlight = "Comment",
  timezone = "local", -- 'local' | 'UTC' | '+HHMM' | '-HHMM'
  popup = {
    highlight = "UnixtimeUtilsFloat",
    background = nil, -- hex like '#1e1e2e' to define highlight dynamically
    winblend = 0,
    show_timezone = true,
  },
}

local function merge_user_globals()
  local function apply(tbl)
    if type(tbl) ~= "table" then
      return
    end
    for k, v in pairs(tbl) do
      config[k] = v
    end
  end
  if vim.g.unixtime_utils and type(vim.g.unixtime_utils.convert) == "table" then
    apply(vim.g.unixtime_utils.convert)
  end
  if type(vim.g.unixtime_utils_convert) == "table" then
    apply(vim.g.unixtime_utils_convert)
  end
  -- legacy or flat tables for config overrides (timezone/popup)
  if vim.g.unixtime_utils_config and type(vim.g.unixtime_utils_config) == "table" then
    apply(vim.g.unixtime_utils_config)
  end
end
merge_user_globals()

local function parse_date(str)
  -- Accept:
  --  DD.MM.YYYY
  --  DD.MM.YYYY HH:MM
  --  DD.MM.YYYY HH:MM:SS
  if not str then
    return nil, "empty input"
  end
  str = str:gsub("%s+$", "")
  local d, m, y, H, M, S
  -- Full with seconds
  d, m, y, H, M, S = str:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)%s+(%d%d):(%d%d):(%d%d)$")
  if not d then
    -- Without seconds
    d, m, y, H, M = str:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)%s+(%d%d):(%d%d)$")
    if d then
      S = "00"
    end
  end
  if not d then
    -- Date only
    d, m, y = str:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)$")
    if d then
      H, M, S = "00", "00", "00"
    end
  end
  if not d then
    return nil, "format mismatch"
  end
  d, m, y = tonumber(d), tonumber(m), tonumber(y)
  H, M, S = tonumber(H), tonumber(M), tonumber(S)
  if not (d and m and y and H and M and S) then
    return nil, "number parse error"
  end
  if m < 1 or m > 12 then
    return nil, "month out of range"
  end
  if d < 1 or d > 31 then
    return nil, "day out of range"
  end
  if H > 23 or M > 59 or S > 59 then
    return nil, "time out of range"
  end
  return d, m, y, H, M, S
end

local function compute_local_utc_offset(epoch_local_guess)
  -- Determine local offset (local - UTC) in seconds for provided epoch.
  -- We create a UTC broken-down table via os.date("!*t") and then os.time() it (local assumption)
  -- The difference between the guessed local epoch and recomputed UTC->local gives offset.
  local utc_table = os.date("!*t", epoch_local_guess)
  -- Reconstruct as if utc_table is local to get the local epoch representing the same wall clock components.
  local reconstructed = os.time({
    year = utc_table.year,
    month = utc_table.month,
    day = utc_table.day,
    hour = utc_table.hour,
    min = utc_table.min,
    sec = utc_table.sec,
    isdst = false, -- force standard; os.time will adjust if needed
  })
  return reconstructed - epoch_local_guess
end

local function parse_tz_offset(tz)
  local sign, hh, mm = tz:match("^([+-])(%d%d)(%d%d)$")
  if not sign then
    return nil
  end
  local offset = (tonumber(hh) * 60 + tonumber(mm)) * 60
  if sign == "-" then
    offset = -offset
  end
  return offset
end

local function resolve_epoch(d, m, y, H, M, S)
  local tz = config.timezone or "local"
  -- First obtain local epoch for the provided wall time (interpreted as local clock time)
  local local_epoch = os.time({ year = y, month = m, day = d, hour = H, min = M, sec = S })
  if not local_epoch then
    return nil, "os.time failed"
  end
  if tz == "local" then
    return local_epoch
  end

  -- Compute local offset at that instant
  local offset_local = compute_local_utc_offset(local_epoch) -- local - UTC
  local epoch_utc = local_epoch - offset_local

  if tz == "UTC" then
    return epoch_utc
  end

  local fixed = parse_tz_offset(tz)
  if fixed then
    -- Interpret input wall clock as being in the fixed offset zone rather than local.
    -- So: wall_time(fixed) -> epoch UTC = (wall_time interpreted as local) - (local_offset) - (fixed - local_offset)
    -- Easier: rebuild epoch assuming clock components are in that fixed offset.
    -- Approach: compute epoch_utc = local_epoch - (offset_local - fixed)
    return local_epoch - (offset_local - fixed)
  end
  return local_epoch
end

local function ensure_popup_hl()
  local p = config.popup or {}
  if not p.highlight then
    return
  end
  if p.background then
    -- define / override highlight
    vim.api.nvim_set_hl(0, p.highlight, { bg = p.background })
  end
end

function Convert.open_popup()
  ensure_popup_hl()
  Input.open({
    prompt = config.prompt,
    title = "Date -> Unix ms | tz: " .. (config.timezone or "local"),
    on_close = function(val)
      if not val then
        return
      end
      local d, m, y, H, M, S = parse_date(val)
      if not d then
        vim.notify("unixtime-utils: parse error: " .. (m or ""), vim.log.levels.ERROR)
        return
      end
      local epoch, err = resolve_epoch(d, m, y, H, M, S)
      if not epoch then
        vim.notify("unixtime-utils: " .. err, vim.log.levels.ERROR)
        return
      end
      local ms = epoch * 1000
      vim.fn.setreg("+", tostring(ms))
      local tzlabel = config.timezone or "local"
      vim.notify(("Unix ms: %s (copied) TZ:%s"):format(ms, tzlabel))
    end,
    popup_config = config.popup,
  })
end

local function validate_timezone(tz)
  if tz == "local" or tz == "UTC" then
    return true
  end
  if tz:match("^[+-]%d%d%d%d$") then
    local _, hh, mm = tz:match("^([+-])(%d%d)(%d%d)$")
    hh, mm = tonumber(hh), tonumber(mm)
    if hh <= 23 and mm <= 59 then
      return true
    end
  end
  return false
end

function Convert.validate_timezone(tz)
  return validate_timezone(tz)
end

function Convert.set_timezone(tz)
  if type(tz) ~= "string" then
    vim.notify("unixtime-utils: timezone must be string", vim.log.levels.ERROR)
    return false
  end
  if not validate_timezone(tz) then
    vim.notify("unixtime-utils: invalid timezone (use local, UTC, or +HHMM/-HHMM)", vim.log.levels.ERROR)
    return false
  end
  config.timezone = tz
  return true
end

function Convert.get_timezone()
  return config.timezone
end

function Convert.reload_config()
  merge_user_globals()
end

if config.keymap then
  vim.keymap.set("n", config.keymap, function()
    Convert.open_popup()
  end, { desc = "Convert human date to unix ms" })
end

return Convert
