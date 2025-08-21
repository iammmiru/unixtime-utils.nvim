local Input = require("unixtime_utils.input")
local Convert = {}
local full_config = require("unixtime_utils.config")
local config = full_config.convert
local timezone = require("unixtime_utils.timezone")

-- setup() can be called by user before plugin load to modify defaults; no need to read vim.g tables

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
    title = "Date -> Unix ms | tz: " .. timezone.get_timezone(),
    on_close = function(val)
      if not val then
        return
      end
      local d, m, y, H, M, S = parse_date(val)
      if not d then
        vim.notify("unixtime-utils: parse error: " .. (m or ""), vim.log.levels.ERROR)
        return
      end
      local epoch, err = timezone.resolve_epoch(d, m, y, H, M, S)
      if not epoch then
        vim.notify("unixtime-utils: " .. err, vim.log.levels.ERROR)
        return
      end
      local ms = epoch * 1000
      vim.fn.setreg("+", tostring(ms))
      vim.notify(("Unix ms: %s (copied) TZ:%s"):format(ms, timezone.get_timezone()))
    end,
    popup_config = config.popup,
  })
end

if config.keymap then
  vim.keymap.set("n", config.keymap, function()
    Convert.open_popup()
  end, { desc = "Convert human date to unix ms" })
end

return Convert
