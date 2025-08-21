-- Human date -> Unix ms popup converter
pcall(require, "unixtime_utils.convert")

-- User command for runtime timezone change
pcall(function()
  vim.api.nvim_create_user_command("UnixTimeSetTimezone", function(opts)
    local tz = opts.args
    local mod = require('unixtime_utils.timezone')
    if not mod.set_timezone(tz) then
      vim.notify('unixtime-utils: invalid timezone '..tz, vim.log.levels.ERROR)
    else
      vim.notify('unixtime-utils: timezone set to '..tz)
    end
  end, { nargs = 1, complete = function()
    return { 'local', 'UTC', '+0000', '+0100', '-0500', '+0530' }
  end })
end)
