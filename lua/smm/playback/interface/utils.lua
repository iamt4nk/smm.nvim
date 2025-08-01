local logger = require 'smm.utils.logger'

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

  logger.debug('Playback Info: %s', vim.inspect(playback_info))

  if not playback_info then
    table.insert(playback_lines, 'No track currently playing')
  else
    table.insert(playback_lines, 'Artist: ' .. playback_info['artist'])
    table.insert(playback_lines, 'Track: ' .. playback_info['track'])
    table.insert(playback_lines, 'Current: ' .. convert_ms_to_timestamp(playback_info['current_ms']))
    table.insert(playback_lines, 'Duration: ' .. convert_ms_to_timestamp(playback_info['duration_ms']))

    local progress = math.floor((playback_info['current_ms'] / playback_info['duration_ms']) * 34)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', 34 - progress) .. ']'
    table.insert(playback_lines, bar)
  end

  playback_lines = M.pad_lines(playback_lines, 1, 2, 1, 2)

  return playback_lines
end

return M
