local logger = require 'smm.utils.logger'
local config = require 'smm.spotify.auth.config'
local crypto = require 'smm.utils.crypto'
local encoding = require 'smm.utils.encoding'
local sock = require 'smm.spotify.auth.sock'
local requests = require 'smm.spotify.auth.requests'
local os_utils = require 'smm.utils.os'

---@return string oauth_url, string redirect_uri, string code_verifier, string state
local function get_oauth_info()
  local code_verifier = crypto.generate_random_string(64)
  local code_challenge = crypto.get_base64(crypto.get_sha256_sum(code_verifier))
  local state = crypto.generate_random_string(16)

  local query_table = {
    response_type = 'code',
    client_id = config.get().client_id,
    scope = table.concat(config.get().scope, ' '),
    code_challenge_method = 'S256',
    code_challenge = code_challenge,
    redirect_uri = config.get().callback_url .. ':' .. config.get().callback_port,
    state = state,
  }

  local query = encoding.encode_table_as_query(query_table)

  local oauth_url = 'https://accounts.spotify.com/authorize?' .. query

  return oauth_url, query_table['redirect_uri'], code_verifier, state
end

local M = {}

function M.setup(user_config)
  config.setup(user_config or {})
end

function M.initiate_oauth_flow()
  local oauth_url, redirect_uri, code_verifier, state = get_oauth_info()
  local port = config.get().callback_port

  os_utils.open_browser(oauth_url)

  local oauth_code = sock.start_server(port, state)

  local auth_info = requests.get_access_token(oauth_code, code_verifier, redirect_uri)

  return auth_info
end

---@param refresh_token string
---@return SMM_AuthInfo|nil
function M.refresh_access_token(refresh_token)
  local auth_info = requests.refresh_access_token(refresh_token)
  if not auth_info then
    logger.error 'Unable to refresh token'
    return
  end
  return auth_info
end

return M
