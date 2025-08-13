local api = require 'smm.spotify.requests'
local utils = require 'smm.playback.utils'
local logger = require 'smm.utils.logger'

local M = {}

---@alias SMM_SyncData { is_playing: boolean, current_pos: integer }

---Handles syncing with Spotify API to get current playback state
---@param on_playback_update fun(sync_data: SMM_PlaybackInfo|nil, status_code: integer) callback to the timer with the appropriate data
---@return fun(callback: fun(sync_data: SMM_SyncData|nil))
function M.create_sync_handler(on_playback_update)
  return function(callback)
    api.get_playback_state(function(playback_response, playback_headers, status_code)
      if status_code == 200 or status_code == 204 then
        logger.debug('Playback Response: \n%s', vim.inspect(playback_response))
        logger.debug('Playback Response headers: \n%s', vim.inspect(playback_headers))

        local playback_info = utils.get_playbackinfo(playback_response)

        -- Notify manager of updated playback info
        if on_playback_update then
          on_playback_update(playback_info, status_code)
        end

        if playback_info and playback_info.progress_ms and playback_info.playing ~= nil then
          logger.debug('Syncing: pos=%d, playing=%s', playback_info.progress_ms, playback_info.playing)
          callback {
            current_pos = playback_info.progress_ms,
            is_playing = playback_info.playing,
          }
        else
          logger.debug 'No playback data - calling timer back with nil'
          callback(nil)
        end
      elseif status_code >= 500 and status_code <= 510 then
        logger.warn('Received status code: %d - Will try again next sync', status_code)
        if on_playback_update then
          on_playback_update(nil, status_code)
        end
        callback(nil)
      else
        logger.error('Getting playback state failed:\nStatus Code: %s\nError: %s', status_code, vim.inspect(playback_response))
        if on_playback_update then
          on_playback_update(nil, status_code)
        end
      end
    end, true)
  end
end

---Handles timer update events and determines if sync is needed
---@param get_playback_info fun(): SMM_PlaybackInfo|nil
---@param on_interface_update fun(playback_info: SMM_PlaybackInfo|nil)
---@return fun(current_ms: integer|nil): boolean
function M.create_update_handler(get_playback_info, on_interface_update)
  return function(current_ms)
    local END_SONG_BUFFER = 200
    local playback_info = get_playback_info()

    if not playback_info or not current_ms then
      on_interface_update(nil)
      return false
    end

    -- Check if track is near end - force sync
    if playback_info.progress_ms >= playback_info.track.duration_ms - END_SONG_BUFFER then
      return true
    end

    -- Update progress and interface
    playback_info.progress_ms = current_ms
    on_interface_update(playback_info)
    return false
  end
end

---Handles pause requests
---@param get_timer fun(): SMM_PlaybackTimer|nil
---@param update_playback_info fun(updates: table)
---@return fun()
function M.create_pause_handler(get_timer, update_playback_info)
  return function()
    api.pause(function(pause_response, pause_headers, status_code)
      local timer = get_timer()
      if status_code == 200 or status_code == 204 then
        if timer then
          timer:pause()
        end
        update_playback_info { playing = false }
      else
        logger.error('Unable to pause current track:\nStatus Code: %s\nError: %s', status_code, vim.inspect(pause_response))
      end
    end)
  end
end

---Handles play/resume requests
---@param get_timer fun(): SMM_PlaybackTimer|nil
---@param update_playback_info fun(updates: table}
---@return fun(context_uri: string|nil, offset: integer|nil, position_ms: integer|nil)
function M.create_play_handler(get_timer, update_playback_info)
  return function(context_uri, offset, position_ms)
    position_ms = position_ms or 0

    api.play(context_uri, offset, position_ms, function(resume_response, resume_headers, status_code)
      local timer = get_timer()
      if status_code == 200 or status_code == 204 then
        if timer then
          timer:resume()
        end
        update_playback_info { playing = true }
      else
        logger.error('Unable to play track:\nStatus Code: %s\nError: %s', status_code, vim.inspect(resume_response))
      end
    end)
  end
end

return M
