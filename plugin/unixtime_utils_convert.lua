-- Human date -> Unix ms popup converter
pcall(require, "unixtime_utils.convert")

-- User command for runtime timezone change
pcall(function()
  vim.api.nvim_create_user_command("UnixTimeSetTimezone", function(opts)
    local tz = opts.args
    local config = require("unixtime_utils.config")
    if config.set_timezone(tz) then
      vim.notify("unixtime-utils: timezone set to " .. tz)
    end
  end, {
    nargs = 1,
    complete = function()
      return { "local", "UTC", "+0000", "+0100", "+0200", "-0100", "-0200" }
    end,
  })
end)
