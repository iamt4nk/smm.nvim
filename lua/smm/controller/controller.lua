local playback_utils = require 'smm.controller.playback_utils'
local timer = require 'smm.timer.timer'
local api = require 'smm.api.api'
local playback = require 'smm.ui.playback'

local M = {}

---@type Playback_Info|nil
M.playback_info = nil

---@type Auth_Info|nil
M.auth_info = nil
.
---@type SpotifyTimer|nil
M.timer = nil

---@type boolean
M.playback_window_is_showing = false

---@param callback fun(sync_data: SyncData|nil) call back to the timer with the appropriate data
local function handle_timer_sync(callback)
  api.get_playback_state(M.auth_info, function(playback_data, _, status_code)
    if status_code == 200 or status_code == 204 then
      local playback_info = playback_utils.extract_playback_info(playback_data)
      M.playback_info = playback_info

      if playback_info and playback_info.current_ms and playback_info.playing ~= nil then
        callback {
          current_pos = playback_info.current_ms,
          is_playing = playback_info.playing,
        }
      else
        callback(nil)
      end
    else
      vim.schedule(function()
        vim.notify('Error: getting playback state failed:\nStatus Code: ' .. status_code, vim.log.levels.ERROR)
        callback(nil)
      end)
    end
  end)
end

---@param current_ms integer|nil Current position in milliseconds
local function handle_timer_update(current_ms)
  if not current_ms then
    playback.update_window_info(nil)
    return
  end

  if not M.playback_info then
    return
  end

  M.playback_info.current_ms = current_ms

  vim.schedule(function()
    local playback_info = playback_utils.create_playback_data(M.playback_info)
    playback.update_window_info(playback_info)
  end)
end

function M.setup_timer()
  M.timer = timer.create_timer {
    current_pos = M.playback_info and M.playback_info.current_ms or 0,
    update_interval = 100,
    send_update = handle_timer_update,
    sync = handle_timer_sync,
  }

  timer.start(M.timer)

  if M.playback and M.playback_info.playing then
    timer.resume(M.timer)
  end
end

---@param auth_info Auth_Info
---Creates the playback window, using the current playback_info state
function M.start_playback(auth_info)
  M.auth_info = auth_info

  playback.show_window()
  M.playback_window_is_showing = true

  M.setup_timer()
end

---Hides window and stops playback
function M.cleanup()
  M.auth_info = nil
  playback.close_playback_window()
  playback.cleanup()
  timer.pause(M.timer)
  timer.close(M.timer)
end

return M
