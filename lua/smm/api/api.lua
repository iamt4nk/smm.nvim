local utils = require 'smm.api.request_utils'

local M = {}

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
function M.get_playback_state(auth_info, callback)
  utils.send_api_request(auth_info, {
    request_name = 'Get Playback State',
    request_type = 'GET',
    endpoint = '/me/player',
    extra_opts = nil,
  }, callback)
end

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
function M.get_user_queue(auth_info, callback)
  utils.send_api_request(auth_info, {
    request_name = 'Get User Queue',
    request_type = 'GET',
    endpoint = '/me/player/queue',
    extra_opts = nil,
  }, callback)
end

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
function M.pause_track(auth_info, callback)
  utils.send_api_request(auth_info, {
    request_name = 'Pause Track',
    request_type = 'PUT',
    endpoint = '/me/player/pause',
    extra_opts = nil,
  }, callback)
end

---@param position_ms integer
---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
---@return nil
function M.resume_track(position_ms, auth_info, callback)
  local body = { position_ms = position_ms }
  utils.send_api_request(auth_info, {
    request_name = 'Resume Track',
    request_type = 'PUT',
    endpoint = '/me/player/play',
    extra_opts = body,
  }, callback)
end

---@param auth_info Auth_Info|nil
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
function M.get_user_profile(auth_info, callback)
  utils.send_api_request(auth_info, {
    request_name = 'Get User Profile',
    request_type = 'GET',
    endpoint = '/me',
    extra_opts = nil,
  }, callback)
end

return M
