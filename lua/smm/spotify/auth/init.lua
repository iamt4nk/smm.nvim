local logger = require 'smm.utils.logger'
local config = require 'smm.spotify.auth.config'
local utils = require 'smm.spotify.auth.crypto'
local api_utils = require 'smm.spotify.auth.api_utils'

---@return string oauth_url, string redirect_uri, string code_verifier, string state
local function get_oauth_info()
  local code_verifier = utils.generate_random_string(64)
  local code_challenge = utils.get_base64(utils.get_sha256_sum(code_verifier))
  local state = utils.generate_random_string(16)

  local query_table = {
    response_type = 'code',
    client_id = config.get_value 'client_id',
    scope = table.concat(config.get_value 'scope', ' '),
    code_challenge_method = 'S256',
    code_challenge = code_challenge,
    redirect_uri = config.get_value 'callback_url' .. ':' .. config.get_value 'callback_port',
    state = state,
  }

  local query = api_utils.encode_table_as_query(query_table)

  oauth_url = 'https://accounts.spotify.com/authorize?' .. query

  return oauth_url, query_table['redirect_uri'], code_verifier, state
end

local M = {}

function M.initiate_oauth_flow()
  local oauth_url, redirect_uri, code_verifier, state = get_oauth_info()
  logger.debug('OAuth URL: %s', oauth_url)
  logger.debug('Redirect URI: %s', redirect_uri)
  logger.debug('Code Verifier: %s', code_verifier)
  logger.debug('State: %s', state)
end
return M
