local Cursor = {}

local ns_id = vim.api.nvim_create_namespace("unixtime-on-demand")

local config = {
  format = "%Y-%m-%d %H:%M:%S", -- os.date format
  highlight = "Comment", -- highlight group for virtual text
  persist = true, -- keep annotations after moving cursor; pressing again updates only that line
  keymap = "<leader>tt", -- default keymap
  accept_seconds = true, -- allow 10-digit unix seconds
  accept_milliseconds = true, -- allow 13-digit unix milliseconds
  priority = 0, -- extmark priority (lower draws first)
}

local state = {
  marks_by_buf = {}, -- [bufnr] = { [line]=extmark_id }
}

local function parse_number_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- row 1-based
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  if line == "" then
    return nil
  end

  -- Scan all digit runs and find one that covers cursor position (inclusive) or where cursor is just after the run.
  local target
  for start_idx, digits, after_idx in line:gmatch("()(%d+)()") do
    local s0 = start_idx - 1 -- convert to 0-based
    local e0 = after_idx - 2 -- inclusive end (0-based)
    -- Conditions for selection:
    -- 1. Cursor is within the run (col between s0 and e0)
    -- 2. Or cursor is immediately after the run (col == e0 + 1)
    if (col >= s0 and col <= e0) or (col == e0 + 1) then
      if (#digits == 10 and config.accept_seconds) or (#digits == 13 and config.accept_milliseconds) then
        target = { text = digits, start_col = s0, end_col = e0 + 1 }
        break
      end
    end
  end
  if not target then
    return nil
  end
  return {
    bufnr = bufnr,
    row = row - 1,
    line = line,
    start_col = target.start_col,
    end_col = target.end_col,
    text = target.text,
  }
end

local function normalize_epoch(num_str)
  if #num_str == 13 and config.accept_milliseconds then
    local ok, val = pcall(tonumber, num_str)
    if not ok or not val then return nil end
    return math.floor(val / 1000)
  elseif #num_str == 10 and config.accept_seconds then
    local ok, val = pcall(tonumber, num_str)
    if not ok or not val then return nil end
    return val
  end
  return nil
end

function Cursor.show_at_cursor()
  vim.schedule(function()
    local data = parse_number_under_cursor()
    if not data then
      return
    end
    local epoch = normalize_epoch(data.text)
    if not epoch then
      return
    end
    local tzmod = require('unixtime_utils.timezone')
    local tz = tzmod.get_timezone()
    local human = tzmod.format_epoch(epoch, config.format, tz)
    if tz ~= 'local' then
      if tz == 'UTC' then
        human = human .. 'Z'
      elseif tz:match('^[+-]%d%d%d%d$') then
        human = human .. ' ' .. tz
      end
    end
    local bufnr = data.bufnr
    local line = data.row

    state.marks_by_buf[bufnr] = state.marks_by_buf[bufnr] or {}

    if config.persist then
      local existing = state.marks_by_buf[bufnr][line]
      if existing then
        pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, existing)
      end
    else
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
      state.marks_by_buf[bufnr] = {}
    end

    local col = #data.line
    local id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, {
      virt_text = { { " ⏰ " .. human, config.highlight } },
      virt_text_pos = "eol",
      priority = config.priority,
    })
    state.marks_by_buf[bufnr][line] = id
  end)
end

function Cursor.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = state.marks_by_buf[bufnr]
  if marks and marks[row] then
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, marks[row])
    marks[row] = nil
  end
end

function Cursor.clear_all()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  state.marks_by_buf[bufnr] = {}
end

local function merge_user_globals()
  local function apply(tbl)
    if type(tbl) ~= "table" then
      return
    end
    for k, v in pairs(tbl) do
      if k == "priority" then
        if type(v) == "number" and v >= 0 then
          config.priority = v
        end
      else
        config[k] = v
      end
    end
  end
  if vim.g.unixtime_utils and type(vim.g.unixtime_utils.on_demand) == "table" then
    apply(vim.g.unixtime_utils.on_demand)
  end
  if type(vim.g.unixtime_utils_on_demand) == "table" then
    apply(vim.g.unixtime_utils_on_demand)
  end
end

-- merge globals immediately on load
merge_user_globals()

-- Removed setup: configuration now via globals only.
-- Keymaps are created immediately below if enabled.

-- establish default clear keymaps if not set (allow explicit false/nil to disable)
if config.clear_keymap == nil then
  config.clear_keymap = "<leader>tr"
end
if config.clear_all_keymap == nil then
  config.clear_all_keymap = "<leader>tR"
end

-- define keymaps immediately (no setup function anymore)
local created_keymaps = false
local function create_keymaps()
  if created_keymaps then
    return
  end
  if config.keymap then
    vim.keymap.set("n", config.keymap, function()
      Cursor.show_at_cursor()
    end, { desc = "Show human-readable time for unix timestamp under cursor" })
  end
  if config.clear_keymap then
    vim.keymap.set("n", config.clear_keymap, function()
      Cursor.clear()
    end, { desc = "Clear on-demand unixtime annotation on current line" })
  end
  if config.clear_all_keymap then
    vim.keymap.set("n", config.clear_all_keymap, function()
      Cursor.clear_all()
    end, { desc = "Clear all on-demand unixtime annotations in buffer" })
  end
  created_keymaps = true
end
create_keymaps()

return Cursor
