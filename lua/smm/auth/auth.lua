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
  local redirect_location, code_verifier, state_code = requests.get_oauth_url()
  print('redirect_location: ' .. redirect_location .. '\ncode_verifier: ' .. code_verifier .. '\nstate_code: ' .. state_code)
  local done = false

  print 'Getting OAuth URL'
  vim.schedule(function()
    print 'Creating Socket Server'
    local code = sock.create_server(port, state_code)
    if code then
      print 'Getting access token'
      auth_info = requests.get_access_token(code, code_verifier, spotify.callback_url)
    end
    done = true
  end)

  utils.open_browser(redirect_location)

  vim.wait(200, function()
    return done
  end)

  -- Save the refresh token if we got one
  if auth_info and auth_info.refresh_token then
    utils.save_refresh_token(auth_info.refresh_token)
  end

  return auth_info
end

---Refreshes access token
-- ---@param refresh_token string
-- ---@return string
-- function M.refresh_access_token(refresh_token)
--   local done = false
--
--   requests.refresh_access_token(refresh_token, function(new_refresh_token)
--     refresh_token = (new_refresh_token ~= nil and new_refresh_token) or refresh_token
--     done = true
--   end)
--
--   vim.wait(200, function()
--     return done
--   end)
--
--   return refresh_token
-- end
--
return M
