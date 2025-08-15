---@alias SMM_MediaType 'track'
--- | 'album'
--- | 'artist'
--- | 'playlist'

---@class SMM_BaseMedia
---@field id string Spotify ID
---@field name string Display name
---@field uri string Spotify URI
---@field external_urls table External URLs (like Spotify web link)
---@field type SMM_MediaType
local BaseMedia = {}
BaseMedia.__index = BaseMedia

---@param media_data table raw data from Spotify API
---@return SMM_BaseMedia
function BaseMedia:new(media_data)
  local instance = {
    id = media_data.id,
    name = media_data.name,
    uri = media_data.uri,
    external_urls = media_data.external_urls or {},
    type = media_data.type,
  }

  setmetatable(instance, self)
  return instance
end

---@return string
function BaseMedia:get_display_name()
  return self.name
end

---@return string
function BaseMedia:get_spotify_url()
  return self.external_urls.spotify or ''
end

local M = {}
M.BaseMedia = BaseMedia
return M
