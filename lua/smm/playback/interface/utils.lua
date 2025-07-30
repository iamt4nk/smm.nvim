---@param ms integer
---@return string
local function convert_ms_to_timestamp(ms)
  local total_seconds = math.floor(ms / 1000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format('%d:%02d', minutes, seconds)
end

local M = {}

---@param lines string[]
---@param top integer
---@param right integer
---@param bottom integer
---@param left integer
---@return string[]
function M.pad_lines(lines, top, right, bottom, left)
  local padded_lines = {}

  for _ = 1, top do
    table.insert(padded_lines, '')
  end

  for _, line in ipairs(lines) do
    table.insert(padded_lines, string.rep(' ', left) .. line .. string.rep(' ', right))
  end

  for _ = 1, bottom do
    table.insert(padded_lines, '')
  end

  return padded_lines
end

---@param playback_info SMM_PlaybackInfo|nil
---@return string[]
function M.format_playback_lines(playback_info)
  local playback_lines = {}

  if not playback_info then
    playback_lines:insert 'No track currently playing'
  else
    playback_lines:insert('Artist: ' .. playback_info['artist'])
    playback_lines:insert('Track: ' .. playback_info['track'])
    playback_lines:insert('Current: ' .. convert_ms_to_timestamp(playback_info['current_ms']))
    playback_lines:insert('Duration: ' .. convert_ms_to_timestamp(playback_info['duration_ms']))

    local progress = math.floor((playback_info['time'] / playback_info['duration']) * 20)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', 20 - progress) .. ']'
    playback_lines:insert(bar)
  end

  playback_lines = M.pad_lines(playback_lines, 1, 2, 1, 2)

  return playback_lines
end

return M
