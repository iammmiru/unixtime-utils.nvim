---@diagnostic disable: undefined-field
local tz = require("unixtime_utils.timezone")
local config = require("unixtime_utils.config")
local convert = require("unixtime_utils.convert")

local BASE_MS = 1735689600000
local TEST_DATE = "01.01.2025 00:00:00"

-- We will test core logic indirectly by invoking timezone.resolve_epoch with parsed date parts.

describe("convert integration", function()
  it("computes ms value for UTC", function()
    config.set_timezone("UTC")
    local d, m, y, H, M, S = convert.parse_date(TEST_DATE)
    local epoch = tz.resolve_epoch(d, m, y, H, M, S)
    assert.is_number(epoch)
    local ms = epoch * 1000
    assert.equals(ms, BASE_MS)
  end)
  it("computes ms value for UTC-0400", function()
    config.set_timezone("-0400")
    local d, m, y, H, M, S = convert.parse_date(TEST_DATE)
    local epoch = tz.resolve_epoch(d, m, y, H, M, S)
    assert.is_number(epoch)
    local ms = epoch * 1000
    assert.equals(ms, BASE_MS - 1000 * 60 * 60 * 4)
  end)
  it("computes ms value for UTC+0400", function()
    config.set_timezone("+0400")
    local d, m, y, H, M, S = convert.parse_date(TEST_DATE)
    local epoch = tz.resolve_epoch(d, m, y, H, M, S)
    assert.is_number(epoch)
    local ms = epoch * 1000
    assert.equals(ms, BASE_MS + 1000 * 60 * 60 * 4)
  end)
  it("date only expands to midnight", function()
    config.set_timezone("UTC")
    local d, m, y, H, M, S = convert.parse_date("02.02.2025")
    local epoch = tz.resolve_epoch(d, m, y, H, M, S)
    local as_table = os.date("!*t", epoch) -- in UTC after adjusting
    assert.equals(2, as_table.day)
    assert.equals(2, as_table.month)
    assert.equals(2025, as_table.year)
    assert.equals(0, as_table.hour)
  end)
end)
