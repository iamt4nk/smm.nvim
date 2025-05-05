local requests = require 'smm.auth.requests'
local sock = require 'smm.auth.sock'
local utils = require 'smm.auth.utils'

local M = {}

---Initiates the OAuth flow
---@return Auth_Info|nil
function M.initiate_oauth_flow()
  local port = 8080
  local auth_info = nil
  local done = false

  print 'Getting OAuth URL'
  requests.get_oauth_url(function(redirect_location, code_verifier, state_code)
    print 'OAuth URL Received'
    print('Redirect Location: ' .. redirect_location)
    local code = sock.create_server(port, state_code)
    print('Got code from socket server: ' .. code)
    if code then
      requests.get_access_token(code, code_verifier, redirect_location, function(response_body)
        auth_info = response_body
      end)
    end
    done = true
  end)

  vim.wait(200, function()
    return done
  end)

  -- Save the refresh token if we got one
  if auth_info and auth_info.refresh_token then
    utils.save_refresh_token(auth_info.refresh_token)
  end

  return auth_info
end

return M
