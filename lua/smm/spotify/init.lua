local auth = require 'smm.spotify.auth'
local token = require 'smm.spotify.token'
local logger = require 'smm.utils.logger'

local M = {}

M.auth_info = nil

function M.auth()
  local refresh_token = token.load_refresh_token()

  if not refresh_token then
    logger.info 'No refresh token found - initiating OAuth Flow'
    M.auth_info = auth.initiate_oauth_flow()
  else
    token.delete_refresh_token()
    M.auth_info = auth.refresh_access_token(refresh_token)
  end

  token.save_refresh_token(M.auth_info.refresh_token)
end

return M
