# unixtime-utils.nvim

A Neovim plugin collection for working with Unix timestamps.

## Features
### Virtual text on CSV files
- Detects a column named `timestamp` (case-insensitive) in the CSV header.
- For each row, if the `timestamp` column contains a numeric Unix timestamp (milliseconds), displays a human-readable date/time as virtual text after the timestamp field.
- Virtual text is rendered using the "Comment" highlight group.

### On-demand virtual text for single timestamps
- Press <leader>tt while the cursor is on (or just after) a Unix timestamp (10 or 13 digits) to display a human-readable time at end of line.
- Supports both seconds (10 digits) and milliseconds (13 digits) epochs.
- Persistent by default: annotations stay after moving the cursor; re-trigger on the same line updates that line.
- To make it ephemeral (only one annotation at a time), set `persist = false` (then `clear_previous` governs whether all previous are cleared or just that line).

## Installation

**With a plugin manager (e.g., lazy.nvim):**
```lua
{
  "iammmiru/unixtime-utils.nvim",
  lazy = false, -- already lazy
}
```

The on-demand feature auto-initializes with default keymap <leader>tt. Configure via global variables (no setup call) – see below. To disable keymaps set them to nil/false in globals.

## Usage

### CSV automatic annotations
- Open a `.csv` file with a header containing a `timestamp` column.
- The plugin will show a virtual text (e.g., `⏰ 2001-09-09 01:46:40`) next to each valid timestamp value.

### On-demand annotation
- Place cursor on a Unix timestamp (seconds or milliseconds) in any buffer and press <leader>tt.
- A human-readable date/time appears at the end of the line.
- <leader>tr clears the annotation on the current line. <leader>tR clears all annotations in the buffer.
- Configuration is via globals only (no setup function).

### Global configuration (no setup call needed)
Set globals before the plugin loads (e.g. in init.lua). Priority must be a non-negative number; lower draws first at end-of-line. To disable any keymap set its value to false or nil.
```lua
-- Unified table
vim.g.unixtime_utils = {
  on_demand = {
    priority = 0,
    keymap = '<leader>tt',
  },
  csv = {
    priority = 0,
    highlight = 'Comment',
  },
}

-- Or per-module flat tables
vim.g.unixtime_utils_on_demand = {
  priority = 0,
  keymap = '<leader>tt',          -- set to false/nil to disable
  clear_keymap = '<leader>tr',     -- set to false/nil to disable
  clear_all_keymap = '<leader>tR', -- set to false/nil to disable
}
vim.g.unixtime_utils_csv = { priority = 0 }
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
