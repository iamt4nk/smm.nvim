local api = require 'smm.api.requests'
local api_utils = require 'smm.api.utils'
local spotify_client = require('smm.auth.models').spotify

local M = {}

---Gets the Authorization URL that we need to call. This will contain our redirect
---@param callback fun(redirect_location: string, code_verifier: string, state_code: string)
function M.get_oauth_url(callback)
  local code_verifier = api_utils.generate_random_string(64)
  local code_challenge = api_utils.get_sha256_sum(code_verifier)
  local code_challenge_b64 = api_utils.get_b64_encoded(code_challenge)

  local query_table = {
    response_type = 'code',
    client_id = spotify_client.client_id,
    scope = table.concat(spotify_client.scope, ' '),
    code_challenge_method = 'S256',
    code_challenge = code_challenge_b64,
    redirect_uri = spotify_client.callback_url,
    state = api_utils.generate_random_string(16),
  }

  print 'Sending API request'
  api.get({
    request_name = 'GET OAuth URL',
    url = 'https://accounts.spotify.com/authorize',
    headers = nil,
    query = query_table,
  }, function(_, response_headers, _)
    callback(response_headers['location'], code_verifier, query_table.state)
  end)
end

---Get the access token from the spotify server
---@param code string
---@param code_verifier string
---@param redirect_uri string
---@param callback fun(response_body: table)
function M.get_access_token(code, code_verifier, redirect_uri, callback)
  local form_table = {
    code = code,
    redirect_uri = redirect_uri,
    grant_type = 'authorization_code',
    client_id = spotify_client.client_id,
    code_verifier = code_verifier,
  }

  api.post({
    request_name = 'GET OAuth Access Token',
    url = 'https://accounts.spotify.com/api/token',
    query = nil,
    headers = nil,
    body = form_table,
  }, function(response_body)
    callback(response_body)
  end)
end

return M
