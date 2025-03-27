local M = {}

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

  print(vim.inspect(playback_info))

  if not playback_info or playback_info == '' or (type(playback_info) == 'table' and next(playback_info) == nil) then
    table.insert(playback_table, 'No track currently playing')
  else
    table.insert(playback_table, 'Artist: ' .. playback_info['artist'])
    table.insert(playback_table, 'Track: ' .. playback_info['track'])
    table.insert(playback_table, 'Current: ' .. M.format_time_from_ms(playback_info['time']))
    table.insert(playback_table, 'Duration: ' .. M.format_time_from_ms(playback_info['duration']))
    local progress = math.floor((playback_info['time'] / playback_info['duration']) * 20)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', 20 - progress) .. ']'
    table.insert(playback_table, bar)
  end

  return playback_table
end

return M
