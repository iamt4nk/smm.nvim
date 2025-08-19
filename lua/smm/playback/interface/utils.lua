local config = require 'smm.playback.interface.config'

---@param ms integer
---@return string
local function convert_ms_to_timestamp(ms)
  local total_seconds = math.floor(ms / 1000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format('%d:%02d', minutes, seconds)
end

-- -- TODO: Currently we don't have a way of displaying links in Neovim. Rough :(
-- ---@param text string
-- ---@param url string
-- local function create_hyperlink(text, url)
--   if not url or url == '' then
--     return text
--   end
--   -- https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
--   -- OSC 8 hyperlink format: \033]8;;URL\033\\TEXT\033]8;;\033\\
--   return string.format([[\e]8;;]] .. '%s' .. [[\e\\]] .. '%s' .. [[\e]8;;\e\\]], text, url)
-- end

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

  local ARTIST_LABEL = 'Artist: '
  local ALBUM_LABEL = 'Album: '
  local TRACK_LABEL = 'Track: '
  local CURRENT_MS_LABEL = 'Current: '
  local DURATION_MS_LABEL = 'Duration: '

  local ELLIPSES = '...'

  local X_PADDING = 2
  local Y_PADDING = 1

  if not playback_info then
    table.insert(playback_lines, 'No track currently playing')
  elseif playback_info.is_advertisement then
    table.insert(playback_lines, 'Advertisement currently playing')
    table.insert(playback_lines, 'Progress: ' .. convert_ms_to_timestamp(playback_info.progress_ms))
  elseif not playback_info.track then
    table.insert(playback_lines, 'No track currently playing')
  else
    local track = playback_info.track
    local progress_bar_width = config.get().progress_bar_width
    local playback_width = config.get().playback_width

    local artist_text = track:get_primary_artist()
    if #artist_text > playback_width - (#ARTIST_LABEL + (X_PADDING * 2) + #ELLIPSES) then
      artist_text = artist_text:sub(1, playback_width - (#ARTIST_LABEL + (X_PADDING * 2) + #ELLIPSES)) --- Truncates
      artist_text = vim.trim(artist_text)
      artist_text = artist_text .. '...'
    end

    local track_text = track.name
    if #track_text > playback_width - (#TRACK_LABEL + (X_PADDING * 2) + #ELLIPSES) then
      track_text = track_text:sub(1, playback_width - (#TRACK_LABEL + (X_PADDING * 2) + #ELLIPSES))
      track_text = vim.trim(track_text)
      track_text = track_text .. '...'
    end

    local album_text = track.album.name
    if #album_text > playback_width - (#ALBUM_LABEL + (X_PADDING * 2) + #ELLIPSES) then
      album_text = album_text:sub(1, playback_width - (#ALBUM_LABEL + (X_PADDING * 2) + #ELLIPSES))
      album_text = vim.trim(album_text)
      album_text = album_text .. '...'
    end

    table.insert(playback_lines, ARTIST_LABEL .. artist_text)
    table.insert(playback_lines, ALBUM_LABEL .. album_text)
    table.insert(playback_lines, TRACK_LABEL .. track_text)
    table.insert(playback_lines, CURRENT_MS_LABEL .. convert_ms_to_timestamp(playback_info['progress_ms']))
    table.insert(playback_lines, DURATION_MS_LABEL .. track:get_formatted_duration())

    local progress = math.floor((playback_info['progress_ms'] / track.duration_ms) * progress_bar_width)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', progress_bar_width - progress) .. ']'
    table.insert(playback_lines, bar)
  end

  playback_lines = M.pad_lines(playback_lines, Y_PADDING, X_PADDING, Y_PADDING, X_PADDING)

  return playback_lines
end

return M
