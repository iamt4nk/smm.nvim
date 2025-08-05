local M = {}

---@alias SMM_PlaybackConfig { enabled: boolean, interface: SMM_PlaybackInterfaceConfig, timer_update_interval: integer, timer_sync_interval: integer }

local config = nil

function M.setup(user_config)
  config = user_config
end

function M.get()
  return config
end

return M
