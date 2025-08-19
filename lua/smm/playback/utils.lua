local logger = require 'smm.utils.logger'
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

return M
