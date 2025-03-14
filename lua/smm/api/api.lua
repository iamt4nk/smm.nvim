local http = require 'smm.api.async'
local auth = require 'smm.auth.oauth'

local M = {}

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
---@return nil
function M.get_playback_state(auth_info, callback)
  if not auth_info or not auth_info.access_token or not auth_info.token_type then
    error 'You must supply an access_token and token type to run get_playback_state'
  end

  local headers = {
    ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
  }

  http.get('https://api.spotify.com/v1/me/player', headers, nil, function(response_body, response_headers, status_code)
    -- Handle 401 Unauthorized by refreshing the token
    if status_code == 401 and auth_info.refresh_token then
      auth_info = auth.refresh_access_token(auth_info.refresh_token)
      if not auth_info or not auth_info.access_token then
        callback(nil, nil, status_code)
        return
      end

      -- Retry with new token
      local new_headers = {
        ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
      }

      http.get('https://api.spotify.com/v1/me/player', new_headers, nil, callback)
      return
    end

    callback(response_body, response_headers, status_code)
  end)
end

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
---@return nil
function M.get_user_queue(auth_info, callback)
  if not auth_info or not auth_info.access_token or not auth_info.token_type then
    error 'You must supply an access_token and token type to run get_user_queue'
  end

  local headers = {
    ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
  }

  http.get('https://api.spotify.com/v1/me/player/queue', headers, nil, function(response_body, response_headers, status_code)
    -- Handle 401 Unauthorized by refreshing the token
    if status_code == 401 and auth_info.refresh_token then
      auth_info = auth.refresh_access_token(auth_info.refresh_token)
      if not auth_info or not auth_info.access_token then
        callback(nil, nil, 401)
        return
      end

      -- Retry with new token
      local new_headers = {
        ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
      }

      http.get('https://api.spotify.com/v1/me/player/queue', new_headers, nil, callback)
      return
    end

    callback(response_body, response_headers, status_code)
  end)
end

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
---@return nil
function M.pause_track(auth_info, callback)
  if not auth_info or not auth_info.access_token or not auth_info.token_type then
    error 'You must supply an access_token and token type to run pause_track'
  end

  local headers = {
    ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
  }

  http.put('https://api.spotify.com/v1/me/player/pause', headers, nil, function(response_body, response_headers, status_code)
    -- Handle 401 Unauthorized by refreshing the token
    if status_code == 401 and auth_info.refresh_token then
      auth_info = auth.refresh_access_token(auth_info.refresh_token)
      if not auth_info or not auth_info.access_token then
        callback(nil, nil, 401)
        return
      end

      -- Retry with new token
      local new_headers = {
        ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
      }
      http.put('https://api.spotify.com/v1/me/player/queue', new_headers, nil, callback)
      return
    end

    callback(response_body, response_headers, status_code)
  end)
end

---@param position_ms integer
---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
---@return nil
function M.resume_track(position_ms, auth_info, callback)
  if not auth_info or not auth_info.access_token or not auth_info.token_type then
    error 'You must supply an access_token and token type to run pause_track'
  end

  local headers = {
    ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
    ['Content-Type'] = 'application/json',
  }

  local body = { position_ms = position_ms }

  http.put('https://api.spotify.com/v1/me/player/play', body, headers, function(response_body, response_headers, status_code)
    -- Handle 401 Unauthorized by refreshing the token
    if status_code == 401 and auth_info.refresh_token then
      auth_info = auth.refresh_access_token(auth_info.refresh_token)
      if not auth_info or not auth_info.access_token then
        callback(nil, nil, 401)
        return
      end

      -- Retry with new token
      local new_headers = {
        ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
      }

      http.put('https://api.spotify.com/v1/me/player/queue', new_headers, nil, callback)
      return
    end
    callback(response_body, response_headers, status_code)
  end)
end

return M
