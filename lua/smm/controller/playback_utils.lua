local api = require 'smm.api.api'

local M = {}

--- Fetches the inital playback data from Spotify API
---@param auth_info Auth_Info
---@param callback fun(playback_info) Callback(playback_data) to run after fetching data
function M.get_current_playing(auth_info, callback)
  api.get_playback_state(auth_info, function(playback_data, _, _)
    callback(playback_data)
  end)
end

--- Sends a request to pause a track

---@param playback_data table
---@return Playback_Info|nil
function M.extract_playback_info(playback_data)
  if not playback_data or not playback_data.item then
    return nil
  end

  return {
    id = playback_data.id,
    artist = playback_data.item.artists[1].name,
    track = playback_data.item.name,
    duration_ms = playback_data.item.duration_ms,
    current_ms = playback_data.progress_ms,
    playing = playback_data.is_playing,
    device_id = playback_data.device and playback_data.device.id or nil,
  }
end

---@param playback_info Playback_Info|string|nil
---@return WindowInfo|nil
function M.create_playback_data(playback_info)
  local playback_state = playback_info
      and playback_info ~= ''
      and {
        artist = playback_info['artist'],
        track = playback_info['track'],
        duration = playback_info['duration_ms'],
        time = playback_info['current_ms'],
      }
    or nil
  return playback_state
end

return M
