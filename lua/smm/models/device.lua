---@class SMM_Device
---@field id string Spotify ID
---@field name string Display name
---@field type string Device type ('computer', 'smartphone', 'speaker)
---@field is_active boolean
---@field is_private_session boolean
---@field is_restricted boolean
---@field volume_percent integer (Range: 0-100)
---@field supports_volume boolean
local Device = {}
Device.__index = Device

---@param device_data table raw data from Spotify API
---@return SMM_Device
function Device:new(device_data)
  local instance = {
    id = device_data.id,
    is_active = device_data.is_active,
    is_private_session = device_data.is_private_session,
    is_restricted = device_data.is_restricted,
    name = device_data.name,
    type = device_data.type,
    volume_percent = device_data.volume_percent,
    supports_volume = device_data.supports_volume,
  }

  setmetatable(instance, self)
  return instance
end

---@return string
function Device:get_id()
  return self.id
end

---@return string
function Device:get_display_name()
  return self.name
end

local M = {}

M.Device = Device

return M
