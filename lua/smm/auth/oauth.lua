local sock = require 'smm.auth.socket_server'
local os_utils = require 'smm.auth.os'
local utils = require 'smm.api.api_utils'
local requests = require 'smm.auth.requests'
local token = require 'smm.auth.token'

---@alias Auth_Info { access_token: string, token_type: string, expires_in: integer, refresh_token: string, scope: string }

local client_id = 'c43057d088204249bca8d5bde4e93bd3'

-- Gets the Authorization URL that we need to call. This will contain our redirect
---@return string, string, string, string
local function get_oauth_url()
  local code_verifier = utils.generate_random_string(64)
  local code_challenge = utils.get_sha256_sum_base64(code_verifier)

  local query_table = {
    response_type = 'code',
    client_id = client_id,
    scope = 'user-read-playback-state user-read-currently-playing user-modify-playback-state user-read-private',
    code_challenge_method = 'S256',
    code_challenge = code_challenge,
    redirect_uri = 'http://localhost:8080/callback',
    state = utils.generate_random_string(16),
  }

  local _, response_headers, _ = requests.send_get_request {
    base_url = 'https://accounts.spotify.com',
    endpoint = 'authorize',
    query_table = query_table,
  }

  local redirect_location = response_headers['location']

  return redirect_location, query_table['redirect_uri'], code_verifier, query_table['state']
end

---@return Auth_Info
local function get_access_token(code, code_verifier, redirect_uri)
  local url = 'https://accounts.spotify.com'
  local endpoint = 'api/token'

  local form_table = {
    code = code,
    redirect_uri = redirect_uri,
    grant_type = 'authorization_code',
    client_id = client_id,
    code_verifier = code_verifier,
  }

  local response_body, response_headers, code = requests.send_post_form_request {
    base_url = url,
    endpoint = endpoint,
    body_table = form_table,
  }

  return response_body
end

local M = {}

---@return Auth_Info | nil
function M.initiate_oauth_flow()
  local port = 8080
  local auth_url, redirect_uri, code_verifier, state = get_oauth_url()
  local auth_info = nil
  local done = false

  vim.schedule(function()
    local code = sock.create_server(port, state)
    if code then
      auth_info = get_access_token(code, code_verifier, redirect_uri)
    end
    done = true
  end)

  os_utils.open_browser(auth_url)

  vim.wait(200, function()
    return done
  end)

  -- Save the refresh token if we got one
  if auth_info and auth_info.refresh_token then
    token.save_refresh_token(auth_info.refresh_token)
  end

  return auth_info
end

---@param refresh_token string
---@return Auth_Info|nil
function M.refresh_access_token(refresh_token)
  local form_table = {
    grant_type = 'refresh_token',
    refresh_token = refresh_token,
    client_id = client_id,
  }

  local response_body, _, code = requests.send_post_form_request {
    base_url = 'https://accounts.spotify.com',
    endpoint = 'api/token',
    body_table = form_table,
  }

  if code == 400 then
    vim.schedule(function()
      vim.notify('Unable to authenticate. Returned status code: ' .. code, vim.log.levels.ERROR)
    end)
    return nil
  end

  -- Preserve the refresh token as its not always returned in the refresh response
  response_body.refresh_token = response_body.refresh_token or refresh_token
  token.clear_refresh_token()
  token.save_refresh_token(response_body.refresh_token)

  return response_body
end

---@param auth_info Auth_Info
---@return Auth_Info|nil
function M.ensure_valid_token(auth_info)
  -- Check if we need to refresh the token
  if auth_info and auth_info.refresh_token then
    return auth_info
  end

  -- Try to load a stored refresh token
  local stored_token = token.load_refresh_token()
  if stored_token then
    return M.refresh_access_token(stored_token)
  end

  -- If no refresh token, we need to do the full flow
  return M.initiate_oauth_flow()
end

return M
