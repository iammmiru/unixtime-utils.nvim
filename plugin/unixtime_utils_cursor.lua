-- Auto-load on-demand unix timestamp virtual text
-- Default keymaps: <leader>tt (show), <leader>tr (clear line), <leader>tR (clear all)
-- Configure/disable keymaps via vim.g.unixtime_utils.on_demand or vim.g.unixtime_utils_on_demand before this file runs.
pcall(require, "unixtime_utils.cursor")
