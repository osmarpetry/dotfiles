-- Forces the MacBook's built-in mic as default input whenever a Bluetooth/USB
-- device tries to steal it. Reactive (audiodevice watcher), not polling.
local preferredInputNames = {
  "MacBook Pro Microphone",
  "MacBook Air Microphone",
}

local pendingTimer = nil

local function forceInternalMic()
  for _, name in ipairs(preferredInputNames) do
    local device = hs.audiodevice.findInputByName(name)

    if device then
      local current = hs.audiodevice.defaultInputDevice()

      if not current or current:name() ~= name then
        device:setDefaultInputDevice()
        hs.alert.show("Input: " .. name)
      end

      return
    end
  end

  hs.alert.show("Internal mic not found")
end

local function scheduleForceInternalMic()
  if pendingTimer then
    pendingTimer:stop()
  end

  pendingTimer = hs.timer.doAfter(1, function()
    pendingTimer = nil
    forceInternalMic()
  end)
end

forceInternalMic()

hs.audiodevice.watcher.setCallback(function(event)
  if event == "dIn " or event == "dev#" then
    scheduleForceInternalMic()
  end
end)

hs.audiodevice.watcher.start()

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "I", forceInternalMic)
