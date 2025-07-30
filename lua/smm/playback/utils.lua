local M = {}

---@alias SMM_PlaybackInfo { id: string, device_id: string|nil, artist: string, track: string, duration_ms: integer, current_ms: integer, playing: boolean }

---@param playback_response table|string
---@return SMM_PlaybackInfo
function M.get_playbackinfo(playback_response)
  if not playback_response or not playback_response.item then
    return nil
  end

  if playback_response == '' then
    return nil
  end

  return {
    id = playback_response.id,
    artist = playback_response.item.artists[1].name,
    track = playback_response.item.name,
    duration_ms = playback_response.item.duration_ms,
    current_ms = playback_response.item.progress_ms,
    playing = playback_response.is_playing,
    device_id = playback_response.device and playback_response.device.id or nil,
  }
end

return M
