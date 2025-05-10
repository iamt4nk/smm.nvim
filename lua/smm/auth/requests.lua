local api = require 'smm.api.requests'
local api_utils = require 'smm.api.utils'
local spotify_client = require('smm.auth.models').spotify

local M = {}

---Gets the Authorization URL that we need to call. This will contain our redirect
---@return string, string, string
function M.get_oauth_url()
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
  local resp_body, resp_headers, resp_status = api.get {
    request_name = 'GET OAuth URL',
    url = 'https://accounts.spotify.com/authorize',
    headers = nil,
    query = query_table,
  }

  local response_headers = api_utils.convert_headers_list_to_map(resp_headers)

  return response_headers['location'], code_verifier, query_table['state']
end

---Get the access token from the spotify server
---@param code string
---@param code_verifier string
---@param redirect_uri string
function M.get_access_token(code, code_verifier, redirect_uri)
  print 'getting access token'
  local form_table = {
    code = code,
    redirect_uri = redirect_uri,
    grant_type = 'authorization_code',
    client_id = spotify_client.client_id,
    code_verifier = code_verifier,
  }

  local headers = {
    ['Content-Type'] = 'application/x-www-form-urlencoded',
  }

  local resp_body, _, _ = api.post {
    request_name = 'GET OAuth Access Token',
    url = 'https://accounts.spotify.com/api/token',
    query = nil,
    headers = headers,
    body = form_table,
  }

  return resp_body
end

---Refresh access token
---@param refresh_token string
---@return string|nil
function M.refresh_access_token(refresh_token)
  local form_table = {
    grant_type = 'refresh_token',
    refresh_token = refresh_token,
    client_id = spotify_client.client_id,
  }

  local headers = {
    ['Content-Type'] = 'application/x-www-form-urlencoded',
  }

  local resp_body, _, resp_status = api.post {
    request_name = 'GET Refresh access token',
    url = 'https://accounts.spotify.com/api/token',
    query = nil,
    headers = headers,
    body = form_table,
  }

  if resp_status == 400 then
    print('Unable to authenticate. Returned status code: ' .. resp_status)
    return nil
  end

  return resp_body
end

return M
