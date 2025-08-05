local auth = require 'smm.spotify.auth'
local token = require 'smm.spotify.token'
local config = require 'smm.spotify.config'
local logger = require 'smm.utils.logger'
local requests = require 'smm.spotify.requests'

local M = {}

M.auth_info = nil

function M.authenticate()
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

  --- Inject retry configurations into the requests module specifically
  requests.api_retry_max = config.get().api_retry_max
  requests.api_retry_backoff = config.get().api_retry_backoff

  logger.debug 'Initializing Spotify - Auth Module Config'
  auth.setup(user_config.auth)
end

return M
