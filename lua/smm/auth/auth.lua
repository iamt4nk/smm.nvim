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
    return done
  end)
  done = false

  print('redirect location: ' .. redirect_location .. '\ncode_verifier: ' .. code_verifier .. '\nstate_code: ' .. state_code)

  code = sock.create_server(port, state_code)
  if code then
    requests.get_access_token(code, code_verifier, redirect_uri, function(response_body)
      auth_info = response_body
      done = true
    end)
  end

  utils.open_browser(redirect_location)

  vim.wait(200, function()
    return done
  end)
end

return M
