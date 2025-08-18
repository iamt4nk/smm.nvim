local logger = require 'smm.utils.logger'
local Track = require('smm.models.track').Track
local Album = require('smm.models.album').Album
local Artist = require('smm.models.artist').Artist
local Playlist = require('smm.models.playlist').Playlist

local M = {}

---@param playback_response table|string
---@return SMM_PlaybackInfo|nil
function M.get_playbackinfo(playback_response)
  logger.debug('Playback Response: %s', vim.inspect(playback_response))

  -- API returns back `""` so we have to test for that if empty
  if not playback_response or playback_response == '""' then
    return nil
  end

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

  -- Create Artist models from track's artists
  ---@type SMM_Artist[]
  local artists = {}
  for _, artist_data in ipairs(playback_response.item.artists or {}) do
    table.insert(artists, Artist:new(artist_data))
  end

  logger.debug('Artists: %s', vim.inspect(artists))

  -- Create Album model if album data exists
  ---@type SMM_Album
  local album = nil
  if playback_response.item.album then
    album = Album:new(playback_response.item.album)
  end

  logger.debug('Album: %s', vim.inspect(album))

  -- Create Track model with the artists and album data
  ---@type SMM_Track
  local track = Track:new(playback_response.item)
  track.artists = artists
  track.album = album

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
