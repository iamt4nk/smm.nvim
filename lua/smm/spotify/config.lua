local logger = require 'smm.utils.logger'

local M = {}

---@alias SMM_SpotifyConfig { enabled: boolean, api_retry_max: integer, api_retry_backoff: integer, auth: SMM_SpotifyAuthConfig,  }

---@type SMM_SpotifyConfig
local config = {}

---@param user_config SMM_SpotifyConfig
function M.setup(user_config)
  config = user_config
end

---@return SMM_SpotifyConfig
function M.get()
  return config
end

return M
