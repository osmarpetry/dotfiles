-- Polls the macOS Calendar via icalBuddy (brew "ical-buddy"). Notifies 5 min
-- before a meeting starts, opens its URL in the default browser at start time.
--
-- icalBuddy's exact output format hasn't been spiked against a real populated
-- calendar (Calendar access wasn't granted yet when this was written) — this
-- parses defensively: it doesn't depend on exact property-line layout, just
-- greps each event's whole text block for a date, a time, and a URL. If
-- icalBuddy's format turns out to need adjustment, the parsing lives entirely
-- in parseEvents() below.

local EVENT_MARKER = "@@EVT@@"

local notified = {}   -- key -> {reminded=bool, opened=bool}

local function eventKey(title, startTime)
  return title .. "|" .. tostring(startTime)
end

local function firstUrl(text)
  return text:match("https?://%S+")
end

-- Lua patterns have no lookahead, so split on the marker directly.
local function splitEvents(output)
  local blocks = {}
  local start = 1
  while true do
    local s, e = output:find(EVENT_MARKER, start, true)
    if not s then break end
    local nextS = output:find(EVENT_MARKER, e + 1, true)
    local block = output:sub(e + 1, (nextS or #output + 1) - 1)
    table.insert(blocks, block)
    start = e + 1
  end
  return blocks
end

local function parseBlock(block)
  local title = block:match("^%s*(.-)%s*\n") or block:match("^%s*(.-)%s*$")
  local y, mo, d = block:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  local h, mi = block:match("(%d%d):(%d%d)")
  if not (title and y and h) then return nil end

  local startTime = os.time({
    year = tonumber(y), month = tonumber(mo), day = tonumber(d),
    hour = tonumber(h), min = tonumber(mi), sec = 0,
  })

  return {
    title = title,
    startTime = startTime,
    url = firstUrl(block),
  }
end

local function checkMeetings()
  local cmd = "/opt/homebrew/bin/icalBuddy"
  if not hs.fs.attributes(cmd) then cmd = "/usr/local/bin/icalBuddy" end
  if not hs.fs.attributes(cmd) then return end

  local args = {
    "-npn", "-nc", "-nrd",
    "-b", EVENT_MARKER,
    "-tf", "HH:mm",
    "-df", "yyyy-MM-dd",
    "-iep", "title,datetime,location,notes,url",
    "eventsToday",
  }

  hs.task.new(cmd, function(exitCode, stdout, _)
    if exitCode ~= 0 or not stdout then return end

    local now = os.time()
    for _, block in ipairs(splitEvents(stdout)) do
      local ev = parseBlock(block)
      if ev then
        local key = eventKey(ev.title, ev.startTime)
        notified[key] = notified[key] or { reminded = false, opened = false }
        local delta = ev.startTime - now

        if delta > 270 and delta <= 330 and not notified[key].reminded then
          hs.notify.new({
            title = ev.title,
            informativeText = "starts in 5 minutes",
          }):send()
          notified[key].reminded = true
        end

        if delta > -30 and delta <= 30 and not notified[key].opened then
          if ev.url then
            hs.urlevent.openURL(ev.url)
          end
          notified[key].opened = true
        end
      end
    end
  end, args):start()
end

hs.timer.doEvery(60, checkMeetings)
checkMeetings()
