local BaseMedia = require('smm.playback.models.base').BaseMedia

---@class SMM_Playlist : SMM_BaseMedia
---@field collaborative boolean
---@field description string|nil
---@field followers table
---@field images table[]
---@field owner table
---@field public boolean
---@field snapshot_id string
---@field tracks table
local Playlist = setmetatable({}, { __index = BaseMedia })
Playlist.__index = Playlist

---@param playlist_data table
---@return SMM_Playlist
function Playlist:new(playlist_data)
  local instance = BaseMedia:new(playlist_data)

  ---@cast instance SMM_Playlist
  instance.collaborative = playlist_data.collaborative or false
  instance.description = playlist_data.description
  instance.followers = playlist_data.followers or { total = 0 }
  instance.images = playlist_data.images or {}
  instance.owner = playlist_data.owner or {}
  instance.public = playlist_data.public
  instance.snapshot_id = playlist_data.snapshot_id or ''
  instance.tracks = playlist_data.tracks or { total = 0, items = {} }

  setmetatable(instance, self)
  return instance
end

---@return string
function Playlist:get_owner_name()
  return self.owner.display_name or self.owner.id or 'Unknown'
end

---@return integer
function Playlist:get_track_count()
  return self.tracks.total or 0
end

---@return integer
function Playlist:get_follower_count()
  return self.followers.total or 0
end

---@return string|nil
function Playlist:get_cover_image_url()
  if #self.images == 0 then
    return nil
  end

  -- Return the largest image
  local largest = self.images[1]
  for _, image in ipairs(self.images) do
    if image.width and largest.width and image.width > largest.width then
      largest = image
    end
  end

  return largest.url
end

---@return string
function Playlist:get_formatted_info()
  local track_text = self:get_track_count() == 1 and 'track' or 'tracks'
  return string.format('by %s | %d %s', self:get_owner_name(), self:get_track_count(), track_text)
end

---@return string
function Playlist:get_formatted_followers()
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
M.Playlist = Playlist
return M
