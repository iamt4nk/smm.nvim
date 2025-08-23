local M = {}

---@alias SMM_PlaybackConfig { enabled: boolean, interface: SMM_PlaybackInterfaceConfig, timer_update_interval: integer, timer_sync_interval: integer, playback_pos: SMM_WindowPos, playback_width: integer, progress_bar_width: integer, }

local config = nil

---@param user_config table
function M.setup(user_config)
  config = user_config
end

---@return SMM_PlaybackConfig|nil
function M.get()
  return config
end

return M
