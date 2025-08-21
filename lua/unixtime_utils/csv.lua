local Csv = {}

local ns_id = vim.api.nvim_create_namespace("csv-virtual-text")
local default_config = require("unixtime_utils.config").csv

local function ms_to_human(ms)
  local sec = math.floor(ms / 1000)
  local tzmod = require("unixtime_utils.timezone")
  local tz = tzmod.get_timezone()
  local human = tzmod.format_epoch(sec, "%Y-%m-%d %H:%M:%S")
  if tz ~= "local" then
    if tz == "UTC" then
      human = human .. " UTC+0000"
    elseif tz:match("^[+-]%d%d%d%d$") then
      human = human .. " UTC" .. tz
    end
  end
  return human
end

function Csv.add_virtual_text(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines < 2 then
    return
  end
  -- Find timestamp column index
  local header = lines[1]
  local col_idx = nil
  for col, field in ipairs(vim.split(header, ",")) do
    if not col_idx and field:lower():find("timestamp") then
      col_idx = col
    end
  end
  if not col_idx then
    return
  end
  -- Add virtual text for each data row
  for i = 2, #lines do
    local fields = vim.split(lines[i], ",")
    local ts = fields[col_idx]
    if ts and ts:match("^%d+$") then
      local human = ms_to_human(tonumber(ts))
      -- Find the start column of the timestamp field
      local virt_col = 0
      for j = 1, col_idx - 1 do
        virt_col = virt_col + #(fields[j] or "") + 1 -- +1 for comma
      end
      virt_col = virt_col + #ts
      -- Clamp virt_col to line length
      local line_len = #lines[i]
      if virt_col > line_len then
        virt_col = line_len
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, virt_col, {
        virt_text = { { " ⏰ " .. human, default_config.highlight } },
        virt_text_pos = "eol",
        priority = default_config.priority,
      })
    end
  end
end

return Csv
