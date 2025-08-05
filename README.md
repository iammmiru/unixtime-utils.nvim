# csv-utils.nvim

A Neovim plugin collection for working with timeseries CSV files.

## Features
### Virtual text
- Detects a column named `timestamp` (case-insensitive) in the CSV header.
- For each row, if the `timestamp` column contains a numeric Unix timestamp (milliseconds), displays a human-readable date/time as virtual text after the timestamp field.
- Virtual text is rendered using the "Comment" highlight group.

## Installation

**With a plugin manager (e.g., lazy.nvim):**
```lua
{
  "iammmiru/csv-utils.nvim",
  lazy = false, -- already lazy
}
```

## Usage

- Open a `.csv` file with a header containing a `timestamp` column.
- The plugin will show a virtual text (e.g., `⏰ 2001-09-09 01:46:40`) next to each valid timestamp value.

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
