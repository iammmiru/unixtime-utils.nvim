-- Minimal init for running plenary tests for unixtime-utils.nvim
-- Adjust runtimepath to include plugin root
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h:h")
-- The path trick: current file -> lua/unixtime_utils/tests/minimal_init.lua (go up 4 levels)
-- Ensure plenary is installed / available on runtimepath (user must have it)
vim.opt.rtp:append(root)
-- Attempt to detect if plenary already in rtp; if not, try common locations
local function ensure_plenary()
  if pcall(require, "plenary") then
    return true
  end
  -- if using packer/lazy, user should have loaded it; we just notify if missing
  vim.notify("plenary.nvim not found in runtimepath; install nvim-lua/plenary.nvim for tests", vim.log.levels.WARN)
  return false
end
ensure_plenary()

-- Load plugin (implicit by being on rtp)
require("unixtime_utils")
