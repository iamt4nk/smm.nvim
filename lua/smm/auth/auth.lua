local requests = require 'smm.auth.requests'
local sock = require 'smm.auth.sock'
local utils = require 'smm.auth.utils'
local spotify = require('smm.auth.models').spotify

local M = {}

---Initiates the OAuth flow
---@return Auth_Info|nil
function M.initiate_oauth_flow()
  local port = 8080
  local auth_info = nil
  local done = false
  local redirect_location, code_verifier, state_code = nil, nil, nil

  print 'Getting OAuth URL'
  requests.get_oauth_url(function(temp_redirect_location, temp_code_verifier, temp_state_code)
    print 'OAuth URL Receive'
    redirect_location = temp_redirect_location
    code_verifier = temp_code_verifier
    state_code = temp_state_code
    done = true
  end)

  vim.wait(200, function()
    print('redirect: ' .. tostring(redirect_location) .. ' code_verifier: ' .. tostring(code_verifier) .. ' state_code: ' .. tostring(state_code))
    return redirect_location ~= nil and code_verifier ~= nil and state_code ~= nil
  end)

  print(redirect_location)
  done = false

  print 'Creating socket server'
  vim.schedule(function()
    local code = sock.create_server(port, state_code)
    if code then
      requests.get_access_token(code, code_verifier, spotify.callback_url, function(response_body)
        auth_info = vim.json.decode(response_body)
      end)
    end
    done = true
  end)
  utils.open_browser(redirect_location)

  vim.wait(200, function()
    return done
  end)

  -- Save the refresh token if we got one
  if auth_info and auth_info.refresh_token then
    print('refresh token: ' .. auth_info.refresh_token)
    utils.save_refresh_token(auth_info.refresh_token)
  end

  return auth_info
end

---Refreshes access token
---@param refresh_token string
---@return string
function M.refresh_access_token(refresh_token)
  local done = false

  requests.refresh_access_token(refresh_token, function(new_refresh_token)
    refresh_token = (new_refresh_token ~= nil and new_refresh_token) or refresh_token
    done = true
  end)

  vim.wait(200, function()
    return done
  end)

  return refresh_token
end

return M
