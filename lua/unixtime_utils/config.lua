---@class UnixTimeUtilsConvertPopupConfig
---@field highlight string Highlight group for popup window border/text
---@field background string|nil Hex color (e.g. "#1e1e2e") to create highlight dynamically
---@field winblend integer Winblend transparency (0-100)
---@field show_timezone boolean Show active timezone in popup

---@class UnixTimeUtilsConvertConfig
---@field keymap string Keymap to trigger date->Unix conversion
---@field prompt string Prompt text shown in input popup
---@field highlight string Highlight group for input line
---@field popup UnixTimeUtilsConvertPopupConfig Popup appearance options

---@class UnixTimeUtilsCsvConfig
---@field priority integer Extmark priority (lower draws first)
---@field highlight string Highlight group for virtual text

---@class UnixTimeUtilsCursorConfig
---@field format string os.date format string for display
---@field highlight string Highlight group for virtual text
---@field persist boolean Keep annotations after moving cursor
---@field keymaps CursorKeymaps Keymaps
---@field accept_seconds boolean Accept 10-digit (seconds) timestamps
---@field accept_milliseconds boolean Accept 13-digit (ms) timestamps
---@field priority integer Extmark priority (lower draws first)

---@class CursorKeymaps
---@field show string show human readable time of Unix time under the cursor
---@field clear string clear virtual text under the cursor
---@field clear_all string clear all virtual texts

---@class UnixTimeUtilsUserConfig
---@field timezone string 'local' | 'UTC' | '+HHMM' | '-HHMM'
---@field convert UnixTimeUtilsConvertConfig
---@field csv UnixTimeUtilsCsvConfig
---@field cursor UnixTimeUtilsCursorConfig

---@class UnixTimeUtilsConfigModule: UnixTimeUtilsUserConfig
---@field _listeners (fun(new_timezone:string))[]
---@field setup fun(opts:UnixTimeUtilsUserConfig|nil)
---@field set fun(key:string, value:any)
---@field on_change fun(cb:fun(new_timezone:string))

-- config table (methods annotated after definition)
local M = {
  timezone = "local", -- 'local' | 'UTC' | '+HHMM' | '-HHMM'
  convert = {
    keymap = "<leader>tu", -- trigger for date->Unix conversion popup
    prompt = "Enter date (DD.MM.YYYY [HH:MM[:SS]]):",
    highlight = "Comment",
    popup = {
      highlight = "UnixTimeUtilsFloat",
      background = nil, -- hex like '#1e1e2e' to define highlight dynamically
      winblend = 0,
      show_timezone = true,
    },
  },
  csv = {
    priority = 0, -- lower draws first
    highlight = "Comment",
  },
  cursor = {
    format = "%Y-%m-%d %H:%M:%S", -- os.date format
    highlight = "Comment", -- highlight group for virtual text
    persist = true, -- keep annotations after moving cursor; pressing again updates only that line
    keymaps = {
      show = "<leader>tt",
      clear = "<leader>tr",
      clear_all = "<leader>tR",
    }, -- default keymap
    accept_seconds = true, -- allow 10-digit unix seconds
    accept_milliseconds = true, -- allow 13-digit unix milliseconds
    priority = 0, -- extmark priority (lower draws first)
  },
  _listeners = {},
}

local function shallow_merge(dest, src)
  if not src then return dest end
  for k,v in pairs(src) do
    if type(v) == 'table' and type(dest[k]) == 'table' then
      for k2,v2 in pairs(v) do
        dest[k][k2] = v2
      end
    else
      dest[k] = v
    end
  end
  return dest
end

---@param opts UnixTimeUtilsUserConfig|nil
function M.setup(opts)
  if opts then
    shallow_merge(M, opts)
  end
end

---@param key string
---@param value any
function M.set(key, value)
  if key == 'timezone' then
    M.timezone = value
    for _, cb in ipairs(M._listeners) do pcall(cb, value) end
  else
    M[key] = value
  end
end

---@param cb fun(new_timezone:string)
function M.on_change(cb)
  table.insert(M._listeners, cb)
end

---@cast M UnixTimeUtilsConfigModule
return M
