local auth = require 'smm.spotify.auth'
local token = require 'smm.spotify.token'
local config = require 'smm.spotify.config'
local logger = require 'smm.utils.logger'

local M = {}

M.auth_info = nil

local function authenticate()
  local refresh_token = token.load_refresh_token()

  if not refresh_token then
    logger.info 'No refresh token found - initiating OAuth Flow'
    M.auth_info = auth.initiate_oauth_flow()
  else
    M.auth_info = auth.refresh_access_token(refresh_token)
  end

  token.delete_refresh_token()
  token.save_refresh_token(M.auth_info.refresh_token)
end

function M.setup(user_config)
  config.setup(user_config)

  logger.debug 'Initializing Spotify - Auth Module Config'
  auth.setup(user_config.auth)

  if M.auth_info == nil then
    authenticate()
  end
end

return M
