local M = {}

---@alias SMM_PlaybackWindowPosition
--- | 'TopLeft'
--- | 'TopRight'
--- | 'BottomLeft'
--- | 'BottomRight'

---@alias SMM_InterfaceConfig { playback_pos: SMM_PlaybackWindowPosition, playback_width: integer, progress_bar_width: integer}

---@type SMM_InterfaceConfig
local config = {}

---@param user_config SMM_InterfaceConfig
function M.setup(user_config)
  config = user_config
end

---@return SMM_InterfaceConfig
function M.get()
  return config
end

return M
