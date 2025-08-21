# unixtime-utils.nvim

A Neovim plugin collection for working with Unix timestamps.

## Features

### Popup conversion from human date to Unix ms
- Press <leader>tu to open an input popup.
- Enter a date in the form `DD.MM.YYYY[ HH:MM[:SS]]` (4-digit year).
  - Examples: `21.01.1990`, `21.01.1990 12:34`, `21.01.1990 12:34:56`
  - Missing time defaults to `00:00:00`; missing seconds default to `:00`.
- Type the date and press Enter to convert to Unix time in milliseconds, copy it to the system clipboard (`+` register), and show a notification including the configured timezone.


### Virtual text on CSV files
- Detects a column named `timestamp` (case-insensitive) in the CSV header.
- For each row, if the `timestamp` column contains a numeric Unix timestamp (milliseconds), displays a human-readable date/time as virtual text after the timestamp field.
- Virtual text is rendered using the "Comment" highlight group.

### On-demand virtual text for single timestamps
- Press <leader>tt while the cursor is on (or just after) a Unix timestamp (10 or 13 digits) to display a human-readable time at end of line.
- Supports both seconds (10 digits) and milliseconds (13 digits) epochs.
- Persistent by default: annotations stay after moving the cursor; re-trigger on the same line updates that line.
- To make it ephemeral (only one annotation at a time), set `persist = false` (then `clear_previous` governs whether all previous are cleared or just that line).

## Installation (updated)


**With a plugin manager (e.g., lazy.nvim):**
```lua
{
  "iammmiru/unixtime-utils.nvim",
  lazy = false, -- already lazy
}
```

Use the Lua setup API. The on-demand feature auto-initializes with default keymaps; override them in setup. To disable a keymap set it to nil/false.

## Usage

### CSV automatic annotations
- Open a `.csv` file with a header containing a `timestamp` column.
- The plugin will show a virtual text (e.g., `⏰ 2001-09-09 01:46:40`) next to each valid timestamp value.

### On-demand annotation
- Place cursor on a Unix timestamp (seconds or milliseconds) in any buffer and press <leader>tt.
- A human-readable date/time appears at the end of the line.
- <leader>tr clears the annotation on the current line. <leader>tR clears all annotations in the buffer.
- Configurable via setup() or direct config table mutation.

### Configuration
Configure early (e.g. in lazy.nvim spec) with:
```lua
require('unixtime_utils').setup({
  timezone = 'local', -- 'local' | 'UTC' | '+HHMM' | '-HHMM'
  convert = {
    keymap = '<leader>tu',
    prompt = 'Enter date (DD.MM.YYYY [HH:MM[:SS]]):',
    popup = { highlight = 'UnixTimeUtilsFloat', background = nil, winblend = 0, show_timezone = true },
  },
  cursor = {
    format = '%Y-%m-%d %H:%M:%S',
    keymaps = { show = '<leader>tt', clear = '<leader>tr', clear_all = '<leader>tR' },
    persist = true,
    accept_seconds = true,
    accept_milliseconds = true,
  },
  csv = { highlight = 'Comment', priority = 0 },
})
```
Disable a keymap by setting it to false or nil.

Mutate config at runtime directly if needed:
```lua
local cfg = require('unixtime_utils.config')
cfg.timezone = 'UTC'
```

### Timezone sharing across modules
The `timezone` setting is honored by:
- Date->Unix popup conversion
- On-demand cursor annotations
- CSV virtual text annotations

Displayed human times:
- Local timezone: no suffix
- UTC: appended suffix ` UTC+0000`
- Fixed offset: appended suffix ` UTC±HHMM` (e.g. ` UTC+0530`, ` UTC-0500`)

### Runtime API
Change timezone at runtime (affects all modules):
```vim
:UnixTimeSetTimezone UTC
```
Lua:
```lua
local tz = require('unixtime_utils.timezone')
tz.set_timezone('UTC')
tz.set_timezone('+0530')
print(tz.get_timezone())
```

## Example
Given a CSV like:
```csv
timestamp,signal_value
1688197085000,280.0
1688208607000,0.0
1688225529000,140.0
```
You will see a virtual text (e.g., `⏰ 2023-07-01 09:38:05`) next to the actual
text.

## Example Data
See the `example_csvs/` directory for sample CSV files.

## License
MIT
