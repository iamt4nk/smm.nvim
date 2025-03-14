local api = require 'smm.api.api'

local M = {}

---@alias Playback_Info { id: string, device_id: string, artist: string, track: string, duration_ms: integer, current_ms: integer, playing: boolean }
---@alias Queue_Info { id: string, artist: string, track: string, duration: integer }

---@param time integer
---@return string
--- A method to convert from ms to time duration
function M.format_time_from_ms(time)
  local total_seconds = math.floor(time / 1000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format('%d', minutes) .. ':' .. string.format('%02d', seconds)
end

---@param playback_info WindowInfo|string|nil
---@return table
--- Formats the current playback info that is set in M.playback_info
function M.format_playback_info(playback_info)
  local playback_table = {}

  if not playback_info or playback_info == '' then
    table.insert(playback_table, 'No track currently playing')
  else
    table.insert(playback_table, 'Artist: ' .. playback_info['artist'])
    table.insert(playback_table, 'Track: ' .. playback_info['track'])
    table.insert(playback_table, 'Current: ' .. M.format_time_from_ms(playback_info['time']))
    table.insert(playback_table, 'Duration: ' .. M.format_time_from_ms(playback_info['duration']))
    local progress = math.floor((playback_info['current_ms'] / playback_info['duration_ms']) * 20)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', 20 - progress) .. ']'
    table.insert(playback_table, bar)
  end

  return playback_table
end

---@param playback_info table|string|nil
---@return WindowInfo|nil
function M.create_playback_data(playback_info)
  local playback_state = playback_info
      and playback_info ~= ''
      and playback_info['item']
      and {
        artist = playback_info['item']['artists'][1]['name'],
        track = playback_info['item']['name'],
        duration = playback_info['item']['duration_ms'],
        time = playback_info['progress_ms'],
      }
    or nil
  return playback_state
end

---@param auth_info Auth_Info
---@param callback function
---@return nil
function M.get_current_playing_async(auth_info, callback)
  api.get_playback_state_async(auth_info, function(playback_state_table)
    if not playback_state_table or not playback_state_table['item'] then
      callback(nil)
      return
    end

    ---@type Playback_Info
    local playback_state = {
      id = playback_state_table['item']['id'],
      artist = playback_state_table['item']['artists'][1]['name'],
      track = playback_state_table['item']['name'],
      duration_ms = playback_state_table['item']['duration_ms'],
      current_ms = playback_state_table['progress_ms'],
      playing = playback_state_table['is_playing'],
    }

    callback(playback_state)
  end)
end

---@return Queue_Info[]
function M.get_user_queue(auth_info)
  local user_queue_table, _, _ = api.get_user_queue(auth_info)

  ---@type Queue_Info[]
  local user_queue = {}

  for _, v in ipairs(user_queue_table['queue']) do
    table.insert(user_queue, {
      id = v['id'],
      artist = v['artists'][1]['name'],
      track = v['name'],
      duration_ms = v['duration_ms'],
    })
  end
  return user_queue
end

---@param auth_info Auth_Info
---@param callback function
---@return nil
function M.get_user_queue_async(auth_info, callback)
  api.get_user_queue_async(auth_info, function(user_queue_table)
    if not user_queue_table or not user_queue_table['queue'] then
      callback {}
      return
    end

    ---@type Queue_Info[]
    local user_queue = {}

    for _, v in ipairs(user_queue_table['queue']) do
      table.insert(user_queue, {
        id = v['id'],
        artist = v['artists'][1]['name'],
        track = v['name'],
        duration_ms = v['duration_ms'],
      })
    end
    callback(user_queue)
  end)
end

return M
