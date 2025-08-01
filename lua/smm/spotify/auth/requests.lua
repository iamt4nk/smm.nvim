local config = require 'smm.spotify.auth.config'
local api_sync = require 'smm.utils.api_sync'
local logger = require 'smm.utils.logger'

---@alias SMM_AuthInfo { access_token: string, token_type: string, expires_in: integer, expires_at: integer, refresh_token: string, scope: string }

local M = {}

---@param code string
---@param code_verifier string
---@param redirect_uri string
---@return SMM_AuthInfo
function M.get_access_token(code, code_verifier, redirect_uri)
  local url = 'https://accounts.spotify.com'
  local endpoint = 'api/token'

  local body = {
    code = code,
    redirect_uri = redirect_uri,
    grant_type = 'authorization_code',
    client_id = config.get_value 'client_id',
    code_verifier = code_verifier,
  }

  logger.debug('URL: %s/%s', url, endpoint)
  logger.debug('Body: \n%s', vim.inspect(body))

  local response_body, response_headers, status_code = api_sync.send_post_request {
    base_url = url,
    endpoint = endpoint,
    body = body,
  }

  if status_code == 400 then
    logger.error('Unable to authenticate. Returned status code: %s', code)
  end

  logger.debug('Response: %s', vim.inspect(response_body))

  response_body['expires_at'] = os.time() + response_body.expires_in

  return response_body
end

---@param refresh_token
---@return SMM_AuthInfo|nil
function M.refresh_access_token(refresh_token)
  local url = 'https://accounts.spotify.com'
  local endpoint = 'api/token'

  local body = {
    grant_type = 'refresh_token',
    refresh_token = refresh_token,
    client_id = config.get_value 'client_id',
  }

  local response_body, _, code = api_sync.send_post_request {
    base_url = url,
    endpoint = endpoint,
    body = body,
  }

  if code == 400 then
    logger.error('Unable to authenticate. Returned status code: %s', code)
  end

  response_body['expires_at'] = os.time() + response_body.expires_in

  response_body.refresh_token = response_body.refresh_token or refresh_token

  return response_body
end

return M
