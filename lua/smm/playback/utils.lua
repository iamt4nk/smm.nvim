local logger = require 'smm.utils.logger'
local config = require 'smm.playback.config'
local Track = require('smm.models.track').Track
local Album = require('smm.models.album').Album
local Artist = require('smm.models.artist').Artist
local Playlist = require('smm.models.playlist').Playlist

local M = {}

---@param artist_data table[]
---@return SMM_Artist[]
local function parse_artists(artist_data)
  logger.debug 'Parsing artist data'
  logger.debug('%s', vim.inspect(artist_data))
  ---@type SMM_Artist[]
  local artists = {}
  for _, artist in ipairs(artist_data or {}) do
    table.insert(artists, Artist:new(artist))
  end

  return artists
end

---@param album_data table
---@return SMM_Album[]
local function parse_album(album_data)
  ---@type SMM_Album
  local album = nil
  if album_data then
    album = Album:new(album_data)
  end

  return album
end

---@param track_data table
---@param artists SMM_Artists[]
---@param album SMM_Album
---@return SMM_Track
local function parse_track(track_data, artists, album)
  ---@type SMM_Track
  local track = nil
  if track_data and artists and album then
    track = Track:new(track_data)
    track.artists = artists
    track.album = album
  end

  return track
end

---@param playback_response table|string
---@return SMM_PlaybackInfo|nil
function M.get_playbackinfo(playback_response)
  logger.debug('Playback Response: %s', vim.inspect(playback_response))

  if playback_response.currently_playing_type == 'ad' then
    logger.debug 'Advertisement detected'

    return {
      id = 'advertisement',
      device_id = playback_response.device and playback_response.device.id or nil,
      context_uri = '',
      context_type = 'advertisement',
      playlist = nil,
      track = nil,
      playing = playback_response.is_playing,
      progress_ms = playback_response.progress_ms,
      is_advertisement = true,
    }
  end

  -- API returns back `""` so we have to test for that if empty
  if playback_response == '""' or not playback_response or not playback_response.item then
    return nil
  end

  local artists = parse_artists(playback_response.item.artists)
  local album = parse_album(playback_response.item.album)
  local track = parse_track(playback_response.item, artists, album)

  local context_uri = playback_response.context ~= vim.NIL and playback_response.context.uri or ''
  local context_type = nil
  local playlist = nil

  if context_uri ~= '' then
    if context_uri:match '^spotify:playlist:' then
      context_type = 'playlist'
      playlist = Playlist:new {
        id = context_uri:match 'spotify:playlist:(.+)',
        uri = context_uri,
        type = 'playlist',
        name = 'Current Playlist', -- Placeholder
        external_urls = {},
      }
    elseif context_uri:match '^spotify:album' then
      context_type = 'album'
    elseif context_uri:match '^spotify:artist' then
      context_type = 'artist'
    end
  end

  logger.debug('Track: %s', vim.inspect(track))

  return {
    id = playback_response.id,
    device_id = playback_response.device and playback_response.device.id or nil,
    context_uri = context_uri,
    context_type = context_type,
    is_advertisement = false,
    playlist = playlist,
    track = track,
    playing = playback_response.is_playing,
    progress_ms = playback_response.progress_ms,
  }
end

---@param playback_info SMM_PlaybackInfo
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
    table.insert(playback_lines, 'Progress: ' .. M.convert_ms_to_timestamp(playback_info.progress_ms))
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
    table.insert(playback_lines, CURRENT_MS_LABEL .. M.convert_ms_to_timestamp(playback_info['progress_ms']))
    table.insert(playback_lines, DURATION_MS_LABEL .. track:get_formatted_duration())

    local progress = math.floor((playback_info['progress_ms'] / track.duration_ms) * progress_bar_width)
    local bar = '[' .. string.rep('=', progress) .. string.rep(' ', progress_bar_width - progress) .. ']'
    table.insert(playback_lines, bar)
  end

  return playback_lines
end

---@param ms integer
---@return string
function M.convert_ms_to_timestamp(ms)
  local total_seconds = math.floor(ms / 1000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format('%d:%02d', minutes, seconds)
end

return M
