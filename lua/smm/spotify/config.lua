local logger = require 'smm.utils.logger'

local M = {}

---@alias SMM_SpotifyConfig { auth: SMM_SpotifyAuthConfig }

---@type SMM_SpotifyConfig
local config = {}

---@param user_config SMM_SpotifyConfig
function M.setup(user_config)
  config = user_config

  logger.debug 'Initializing Spotify - Auth Module Config'
  require('smm.spotify.auth.config').setup(user_config.auth)
end

---@return SMM_SpotifyConfig
function M.get()
  return config
end

return M
