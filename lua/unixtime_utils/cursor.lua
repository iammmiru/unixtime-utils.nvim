local Cursor = {}

local ns_id = vim.api.nvim_create_namespace("unixtime-on-demand")
local default_config = require("unixtime_utils.config").cursor

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
      if
        (#digits == 10 and default_config.accept_seconds) or (#digits == 13 and default_config.accept_milliseconds)
      then
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

local util = require("unixtime_utils.util")

function Cursor.show_at_cursor()
  vim.schedule(function()
    local data = parse_number_under_cursor()
    if not data then
      return
    end
    local epoch = util.normalize_epoch(data.text, default_config.accept_seconds, default_config.accept_milliseconds)
    if not epoch then
      return
    end
    local timezone = require("unixtime_utils.timezone")
    local human = timezone.format_epoch(epoch, default_config.format)
    local bufnr = data.bufnr
    local line = data.row

    state.marks_by_buf[bufnr] = state.marks_by_buf[bufnr] or {}

    if default_config.persist then
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
      virt_text = util.build_virt_text(human, default_config.highlight),
      virt_text_pos = "eol",
      priority = default_config.priority,
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

-- define keymaps immediately (no setup function anymore)
local created_keymaps = false
local function create_keymaps()
  if created_keymaps then
    return
  end
  if default_config.keymaps.show then
    vim.keymap.set("n", default_config.keymaps.show, function()
      Cursor.show_at_cursor()
    end, { desc = "Show human-readable time for unix timestamp under cursor" })
  end
  if default_config.keymaps.clear then
    vim.keymap.set("n", default_config.keymaps.clear, function()
      Cursor.clear()
    end, { desc = "Clear on-demand unixtime annotation on current line" })
  end
  if default_config.keymaps.clear_all then
    vim.keymap.set("n", default_config.keymaps.clear_all, function()
      Cursor.clear_all()
    end, { desc = "Clear all on-demand unixtime annotations in buffer" })
  end
  created_keymaps = true
end
create_keymaps()

return Cursor
