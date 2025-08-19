local BaseMedia = require('smm.models.base').BaseMedia

---@class SMM_Album : SMM_BaseMedia
---@field artists SMM_Artist[] Array of artists
---@field album_type string Type of album ('album', 'single', 'compilation')
---@field total_tracks integer Total number of tracks
---@field release_date string Release date (YYYY-MM-DD or YYYY)
---@field release_date_precision string Precision of release date ('year', 'month', 'day')
---@field genres string[] Array of genre strings
---@field label string|nil Record label
---@field popularity integer Album popularity (0-100)
---@field tracks table|nil Tracks object (if included in response)
local Album = setmetatable({}, { __index = BaseMedia })
Album.__index = Album

---@param album_data table Raw album data from Spotify API
---@return SMM_Album
function Album:new(album_data)
  local instance = BaseMedia:new(album_data)

  -- Add album-specific properties
  ---@cast instance SMM_Album
  instance.artists = album_data.artists or {}
  instance.album_type = album_data.album_type or 'album'
  instance.total_tracks = album_data.total_tracks or 0
  instance.release_date = album_data.release_date or ''
  instance.release_date_precision = album_data.release_date_precision or 'day'
  instance.genres = album_data.genres or {}
  instance.label = album_data.label
  instance.popularity = album_data.popularity or 0
  instance.tracks = album_data.tracks

  setmetatable(instance, self)
  return instance
end

---@return string
function Album:get_primary_artist()
  return (#self.artists > 0) and self.artists[1].name or 'Unknown Artist'
end

---@return string
function Album:get_release_year()
  return self.release_date:match '^%d%d%d%d' or 'Unknown'
end

---@return string -- Formatted album info (e.g., "Album - 2023 - 12 tracks")
function Album:get_formatted_info()
  local type_display = self.album_type:gsub('^%l', string.upper)
  local year = self:get_release_year()
  local track_text = self.total_tracks == 1 and 'track' or 'tracks'

  return string.format('%s | %s | %d %s', type_display, year, self.total_tracks, track_text)
end

local M = {}
M.Album = Album
return M
