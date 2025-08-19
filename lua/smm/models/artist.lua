local BaseMedia = require('smm.models.base').BaseMedia

---@class SMM_Artist : SMM_BaseMedia
---@field followers table Follower information with total count
---@field genres string[] Array of genre strings
---@field popularity integer Artist popularity (0-100)
local Artist = setmetatable({}, { __index = BaseMedia })
Artist.__index = Artist

---@param artist_data table Raw artist data from Spotify API
---@return SMM_Artist
function Artist:new(artist_data)
  local instance = BaseMedia:new(artist_data)

  ---@cast instance SMM_Artist
  instance.followers = artist_data.followers or { total = 0 }
  instance.genres = artist_data.genres or {}
  instance.popularity = artist_data.popularity or 0

  setmetatable(instance, self)
  return instance
end

---@return integer
function Artist:get_follower_count()
  return self.followers.total or 0
end

---@return string
function Artist:get_primary_genre()
  return (#self.genres > 0) and self.genres[1] or 'Unknown'
end

---@return string Formatted follower count (e.g., "1.2M followers")
function Artist:get_formatted_followers()
  local count = self:get_follower_count()
  if count >= 1000000 then
    return string.format('%.1fM followers', count / 1000000)
  elseif count >= 1000 then
    return string.format('%.1fK followers', count / 1000)
  else
    return string.format('%d followers', count)
  end
end

local M = {}
M.Artist = Artist
return M
