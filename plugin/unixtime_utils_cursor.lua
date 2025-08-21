-- Auto-load on-demand unix timestamp virtual text
-- Default keymaps: <leader>tt (show), <leader>tr (clear line), <leader>tR (clear all)
-- Configure with require('unixtime_utils.config').setup{ cursor = { keymaps = {...} } } before this file loads (optional).
pcall(require, "unixtime_utils.cursor")
