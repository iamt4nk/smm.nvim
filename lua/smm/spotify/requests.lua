local api = require 'smm.utils.api_async'
local logger = require 'smm.utils.logger'
local utils = require 'smm.spotify.utils'
local config = require 'smm.spotify.config'

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
local function check_session(auth_info)
  local current_time = os.time()
  logger.debug('Current Time: %d\nSession Expires atw %d\nSession remaining time: %d', current_time, auth_info.expires_at, auth_info.expires_at - current_time)
  if auth_info.expires_at < current_time + 30 then
    require('smm.spotify').authenticate()
  end
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.get_user_profile(callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-read-private') then
    check_session(auth_info)
    api.get(base_url .. '/me', nil, nil, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API request: Get User Profile. - Permissions not available'
  end
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.get_playback_state(callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-read-playback-state') then
    check_session(auth_info)
    api.get(base_url .. '/me/player', nil, nil, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API request: Get User Playback State. - Permissions not available'
  end
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.pause_track(callback)
  local auth_info = require('smm.spotify').auth_info

  if check_scope(auth_info.scope, 'user-modify-playback-state') then
    check_session(auth_info)
    api.put(base_url .. '/me/player/pause', nil, nil, nil, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API Request: Pause Track. - Permissions not available'
  end
end

---@param context_uri string|nil
---@param offset integer|nil
---@param position_ms integer
---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
function M.resume_track(context_uri, offset, position_ms, callback)
  local auth_info = require('smm.spotify').auth_info

  local body = {
    position_ms = position_ms,
  }

  if context_uri then
    body['context_uri'] = context_uri
  end

  if offset then
    body['offset'] = {
      position = offset,
    }
  end

  logger.debug('Request body: %s', vim.json.encode(body))

  if check_scope(auth_info.scope, 'user-modify-playback-state') then
    check_session(auth_info)
    api.put(base_url .. '/me/player/play', {
      ['Content-Type'] = 'application/json',
    }, nil, body, auth_info.access_token, callback)
  else
    logger.error 'Unable to run API Request: Resume Track. - Permissions not available'
  end
end

return M
