local BaseMedia = require('smm.playback.models.base').BaseMedia

---@class SMM_Track : SMM_BaseMedia
---@field artists SMM_Artist[] Array of artists
---@field album SMM_Album Album ref
---@field duration_ms integer Track duration in milliseconds
---@field explicit boolean Whether track has explicit content
---@field popularity integer Track popularity (0-100)
---@field preview_url string|nil Preview URL if available
---@field track_number integer Track number on album
---@field disc_number integer Disc number
---@field is_local boolean Whether track is from local files
---@field is_playable boolean Whether track can be played
local Track = setmetatable({}, { __index = BaseMedia })
Track.__index = Track

---@param track_data table  Raw track data from Spotify API
---@return SMM_Track
function Track:new(track_data)
  local instance = BaseMedia.new(self, track_data)

  -- Add track-specific properties
  instance.artists = track_data.artists or {}
  instance.album = track_data.album
  instance.duration_ms = track_data.duration_ms or 0
  instance.explicit = track_data.explicit or false
  instance.popularity = track_data.popularity or 0
  instance.preview_url = track_data.preview_url
  instance.track_number = track_data.preview_url
  instance.track_number = track_data.track_number or 1
  instance.disc_number = track_data.disc_number or 1
  instance.is_local = track_data.is_local or false
  instance.is_playable = track_data.is_playable ~= false

  setmetatable(instance, self)
  return instance
end

local M = {}
M.Track = Track
return M
