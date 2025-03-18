local api = require 'smm.api.api'

local M = {}

---@alias Playback_Info { id: string, device_id: string|nil, artist: string, track: string, duration_ms: integer, current_ms: integer, playing: boolean }

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

--- Fetches the inital playback data from Spotify API
---@param auth_info Auth_Info
---@param callback fun(playback_data) Callback(success, playback_data) to run after fetching data
function M.fetch_initial_playback_data(auth_info, callback)
  api.get_playback_state(auth_info, function(playback_data, _, _)
    local playback_info = M.extract_playback_info(playback_data)
    callback(playback_info)
  end)
end

return M
