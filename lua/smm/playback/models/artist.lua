local BaseMedia = require('smm.playback.models.base').BaseMedia

---@class SMM_Artist : SMM_BaseMedia
---@field followers table Follower information with total count
---@field genres string[] Array of genre strings
---@field images table[] Array of image objects with url, width, height
---@field popularity integer Artist popularity (0-100)
local Artist = setmetatable({}, { __index = BaseMedia })
Artist.__index = Artist

---@param artist_data table Raw artist data from Spotify API
---@return SMM_Artist
function Artist:new(artist_data)
  local instance = BaseMedia.new(self, artist_data)

  instance.followers = artist_data.followers or { total = 0 }
  instance.genres = artist_data.genres or {}
  instance.images = artist_data.images or {}
  instance.popularity = artist_data.popularity or 0

  setmetatable(instance, self)
  return instance
end

local M = {}
M.Artist = Artist
return M
