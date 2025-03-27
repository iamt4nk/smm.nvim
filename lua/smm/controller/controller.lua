local playback_utils = require 'smm.controller.playback_utils'
local timer = require 'smm.timer.timer'
local api = require 'smm.api.api'
local playback = require 'smm.ui.playback'
local ui_utils = require 'smm.ui.utils'

local M = {}

---@type Playback_Info|nil
M.playback_info = nil

---@type Auth_Info|nil
M.auth_info = nil

---@type SpotifyTimer|nil
M.timer = nil

---@type boolean
M.playback_window_is_showing = false

---@return SyncData
local function handle_timer_sync()
  ---@type SyncData
  local sync_data

  api.get_playback_state(M.auth_info, function(playback_data, _, status_code)
    if status_code == 200 then
      local new_playback_info = playback_utils.extract_playback_info(playback_data)
      sync_data.current_pos = new_playback_info and new_playback_info.current_ms and new_playback_info.current_ms or 0
      sync_data.is_playing = new_playback_info and new_playback_info.playing and new_playback_info.playing or false
    end
  end)

  print(vim.inspect(sync_data))

  return sync_data
end

---@param current_ms integer Current position in milliseconds
local function handle_timer_update(current_ms)
  if not M.playback_info then
    return
  end

  M.playback_info.current_ms = current_ms

  vim.schedule(function()
    local playback_data = ui_utils.create_playback_data(M.playback_info)
    local playback_info = ui_utils.format_playback_info(playback_data)
    playback.update_window(playback_info)
  end)
end

function M.setup_timer()
  M.timer = timer.create_timer {
    current_pos = M.playback_info.current_ms,
    update_interval = 100,
    send_update = handle_timer_update,
    sync = handle_timer_sync,
  }

  timer.start(M.timer)

  if M.playback_info.playing then
    timer.resume(M.timer)
  end
end

--- @param auth_info Auth_Info
--- Creates the playback window, using the current playback_info state
function M.start_playback(auth_info)
  M.auth_info = auth_info

  playback.show_window()
  M.playback_window_is_showing = true

  M.is_syncing_playback = true
  playback_utils.get_current_playing(auth_info, function(playback_data)
    M.playback_info = playback_data

    vim.schedule(function()
      local playback_info = playback_utils.extract_playback_info(playback_data)
      local window_info = playback_utils.create_playback_data(playback_info)
      playback.update_window_info(window_info)
    end)

    M.setup_timer()
    M.is_syncing_playback = false
  end)
end

return M
