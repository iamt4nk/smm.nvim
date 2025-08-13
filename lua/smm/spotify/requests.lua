local api = require 'smm.utils.api_async'
local logger = require 'smm.utils.logger'
local utils = require 'smm.spotify.utils'
local config = require 'smm.spotify.config'

local M = {}

local base_url = 'https://api.spotify.com/v1'

---@type integer
M.api_retry_max = 0

---@type integer
M.api_retry_backoff = 0

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

---@param api_func function
---@param callback function
---@param retry_count? integer
local function retry(api_func, callback, retry_count)
  retry_count = retry_count or 1

  if retry_count > M.api_retry_max then
    logger.error('Max retries (%d) reached for API call', M.api_retry_max)
    return
  end

  logger.debug('API Attempt: %d/%d', retry_count, M.api_retry_max)

  vim.defer_fn(function()
    api_func(function(response_body, response_headers, status_code)
      callback(response_body, response_headers, status_code)
    end)
  end, M.api_retry_backoff)
end

---Generic API call wrapp[er that handles retry logic
---@param api_func function The API function to call
---@param callback function The callback to execute with results
---@param retry_override? boolean Whether to skip retries (default: false)
---@param retry_count? integer Current retry attempt (used internally)
local function make_api_call(api_func, callback, retry_override, retry_count)
  retry_override = retry_override == true
  retry_count = retry_count or 1

  api_func(function(response_body, response_headers, status_code)
    local should_retry = false

    if (status_code >= 500 and status_code < 600) or status_code == 429 then
      should_retry = true
    end

    if should_retry and not retry_override then
      if retry_count >= M.api_retry_max then
        logger.error('Max retries (%d) reached for API call', M.api_retry_max)
        callback(response_body, response_headers, status_code)
        return
      end

      logger.warn('API returned error (status %d). Retrying attempt %d/%d', status_code, retry_count + 1, M.api_retry_max)

      vim.defer_fn(function()
        make_api_call(api_func, callback, retry_override, retry_count + 1)
      end, M.api_retry_backoff)
    else
      -- If it succeeds or retries overridden, then continue
      callback(response_body, response_headers, status_code)
    end
  end)
end

---Gets user profile. Sends retry on server error by default unless overridden
---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
---@param retry_override? boolean
function M.get_user_profile(callback, retry_override)
  local auth_info = require('smm.spotify').auth_info
  check_session(auth_info)

  if not check_scope(auth_info.scope, 'user-read-private') then
    logger.error 'Unable to run API request: Get User Profile. - Permissions not available'
    return
  end

  local api_func = function(api_callback)
    api.get(base_url .. '/me', nil, nil, auth_info.access_token, api_callback)
  end

  make_api_call(api_func, callback, retry_override)
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
---@param retry_override? boolean
function M.get_playback_state(callback, retry_override)
  local auth_info = require('smm.spotify').auth_info
  check_session(auth_info)

  if not check_scope(auth_info.scope, 'user-read-playback-state') then
    logger.error 'Unable to run API request: Get User Playback State. - Permissions not available'
    return
  end

  local api_func = function(api_callback)
    api.get(base_url .. '/me/player', nil, nil, auth_info.access_token, api_callback)
  end

  make_api_call(api_func, callback, retry_override)
end

---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
---@param retry_override? boolean
function M.pause(callback, retry_override)
  local auth_info = require('smm.spotify').auth_info
  check_session(auth_info)

  if not check_scope(auth_info.scope, 'user-modify-playback-state') then
    logger.error 'Unable to run API Request: Pause Track. - Permissions not available'
    return
  end

  local api_func = function(api_callback)
    api.put(base_url .. '/me/player/pause', nil, nil, nil, auth_info.access_token, api_callback)
  end

  make_api_call(api_func, callback, retry_override)
end

---@param context_uri string?
---@param offset integer?
---@param position_ms integer
---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
---@param retry_override? boolean
function M.play(context_uri, offset, position_ms, callback, retry_override)
  local auth_info = require('smm.spotify').auth_info
  check_session(auth_info)

  local body = {
    position_ms = position_ms,
  }

  if context_uri and context_uri:match '^spotify:track' then
    body['uris'] = { context_uri }
  else
    body['context_uri'] = context_uri
  end

  if offset then
    body['offset'] = {
      position = offset,
    }
  end

  logger.debug('Request body: %s', vim.json.encode(body))

  if not check_scope(auth_info.scope, 'user-modify-playback-state') then
    logger.error 'Unable to run API Request: Play. - Permissions not available'
  end

  local api_func = function(api_callback)
    api.put(base_url .. '/me/player/play', {
      ['Content-Type'] = 'application/json',
    }, nil, body, auth_info.access_token, api_callback)
  end

  make_api_call(api_func, callback, retry_override)
end

---@param query string
---@param type string The type to search for { 'track', 'album', 'artist', 'playlist' }
---@param limit? integer Number of results to return (default: 20, max: 30)
---@param offset? integer The index of the first result to return (default: 0)
---@param callback fun(response_body: string|table, response_headers: table, status_code: integer)
---@param retry_override? boolean (Default: false)
function M.search(query, type, limit, offset, callback, retry_override)
  local auth_info = require('smm.spotify').auth_info
  check_session(auth_info)

  limit = limit or 20
  offset = offset or 0

  local query_params = {
    q = query,
    type = type,
    limit = limit,
    offset = offset,
  }

  local api_func = function(api_callback)
    api.get(base_url .. '/search', nil, query_params, auth_info.access_token, api_callback)
  end

  make_api_call(api_func, callback, retry_override)
end

return M
