vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
  pattern = "*.csv",
  callback = function(args)
    require("unixtime_utils.csv").add_virtual_text(args.buf)
  end,
})
