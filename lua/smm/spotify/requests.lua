local api = require 'smm.utils.api_async'
local logger = require 'smm.utils.logger'

local M = {}

local base_url = 'https://api.spotify.com/v1'

---@param available_scope string
---@param scope_required string
---@return boolean
local function check_scope(available_scope, scope_required)
  if available_scope:find(scope_required, 1, true) then
    return true
  end
  return false
end

---@param auth_info SMM_AuthInfo
---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.get_user_profile(callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-read-private') then
    api.get(base_url .. '/me', nil, nil, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API request: Get User Profile. - Permissions not available'
  end
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.get_playback_state(callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-read-playback-state') then
    api.get(base_url .. '/me/player', nil, nil, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API request: Get User Playback State. - Permissions not available'
  end
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.pause_track(callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-modify-playback-state') then
    api.put(base_url .. '/me/player/pause', nil, nil, nil, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API Request: Pause Track. - Permissions not available'
  end
end

---@param position_ms integer
---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.resume_track(position_ms, callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-modify-playback-state') then
    api.put(
      base_url .. '/me/player/play',
      {
        ['Content-Type'] = 'application/json',
      },
      nil,
      {
        position_ms = position_ms,
      },
      auth_info.access_token,
      callback
    )
  else
    logger.error 'Unable to run API Request: Resume Track. - Permissions not available'
  end
end

return M
