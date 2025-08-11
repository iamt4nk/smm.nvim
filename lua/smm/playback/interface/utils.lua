local logger = require 'smm.utils.logger'
local config = require 'smm.playback.interface.config'

---@param ms integer
---@return string
local function convert_ms_to_timestamp(ms)
  local total_seconds = math.floor(ms / 1000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format('%d:%02d', minutes, seconds)
end

-- TODO: Currently we don't have a way of displaying links in Neovim. Rough :(
---@param text string
---@param url string
local function create_hyperlink(text, url)
  return text
  -- if not url or url == '' then
  --   return text
  -- end
  -- -- https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
  -- -- OSC 8 hyperlink format: \033]8;;URL\033\\TEXT\033]8;;\033\\
  -- return string.format([[\e]8;;]] .. '%s' .. [[\e\\]] .. '%s' .. [[\e]8;;\e\\]], text, url)
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

  if not playback_info or not playback_info.track then
    table.insert(playback_lines, 'No track currently playing')
  else
    local track = playback_info.track
    local progress_bar_width = config.get().progress_bar_width

    logger.debug('Album: %s', vim.inspect(track.album))
    local artist_text = create_hyperlink(track:get_primary_artist(), track.artists[1]:get_spotify_url())
    local track_text = create_hyperlink(track.name, track:get_spotify_url())
    local album_text = create_hyperlink(track.album.name, track.album:get_spotify_url())

    table.insert(playback_lines, 'Artist: ' .. artist_text)
    table.insert(playback_lines, 'Album: ' .. album_text)
    table.insert(playback_lines, 'Track: ' .. track_text)
    table.insert(playback_lines, 'Current: ' .. convert_ms_to_timestamp(playback_info['progress_ms']))
    table.insert(playback_lines, 'Duration: ' .. track:get_formatted_duration())

    local progress = math.floor((playback_info['progress_ms'] / track.duration_ms) * progress_bar_width)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', progress_bar_width - progress) .. ']'
    table.insert(playback_lines, bar)
  end

  playback_lines = M.pad_lines(playback_lines, 1, 2, 1, 2)

  return playback_lines
end

return M
