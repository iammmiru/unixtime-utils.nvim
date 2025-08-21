local M = {}

-- Simple floating input helper returning entered line via callback(value|nil)
function M.open(opts)
  opts = opts or {}
  local prompt = opts.prompt or "Enter value:" -- first line shown
  local width = math.max(40, #prompt + 2)
  local height = 3
  local buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((ui.height - height) / 2),
    col = math.floor((ui.width - width) / 2),
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title or "unixtime-utils",
  })

  -- Apply popup styling if provided
  if opts.popup_config then
    local pc = opts.popup_config
    if pc.highlight then
      pcall(vim.api.nvim_set_option_value, "winhl", "Normal:" .. pc.highlight .. ",NormalNC:" .. pc.highlight, { win = win })
    end
    if type(pc.winblend) == "number" then
      pcall(vim.api.nvim_set_option_value, "winblend", pc.winblend, { win = win })
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt, "" })
  vim.api.nvim_win_set_cursor(win, { 2, 0 })
  vim.cmd("startinsert")

  local function get_line()
    return (vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1] or ""):gsub("^%s+", ""):gsub("%s+$", "")
  end
  local function close_with(val)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if opts.on_close then
      opts.on_close(val)
    end
    vim.cmd("stopinsert")
  end

  -- Normal mode mappings
  vim.keymap.set("n", "q", function()
    close_with(nil)
  end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function()
    close_with(nil)
  end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", function()
    local line = get_line()
    close_with(line ~= "" and line or nil)
  end, { buffer = buf, nowait = true })

  -- Insert mode mappings
  vim.keymap.set("i", "<Esc>", function()
    close_with(nil)
  end, { buffer = buf })
  vim.keymap.set("i", "<CR>", function()
    local line = get_line()
    close_with(line ~= "" and line or nil)
  end, { buffer = buf })
  vim.bo[buf].modifiable = true
  vim.bo[buf].bufhidden = "wipe"
end

return M
