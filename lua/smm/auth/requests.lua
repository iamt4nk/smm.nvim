local https = require 'ssl.https'
local ltn12 = require 'ltn12'
local utils = require 'smm.auth.utils'

---@alias Request_Info { base_url: string, endpoint: string, query_table: table|nil, body_table: table|nil, headers: table|nil }

local M = {}

---@param request_info Request_Info
---@return table, table, integer
function M.send_get_request(request_info)
  local query = nil
  query = request_info['query_table'] and vim.uri_encode(utils.stringify_table_as_kv(request_info['query_table']))

  local headers = request_info['headers'] or {}

  local response_body = {}

  local _, code, response_headers, _ = https.request {
    url = request_info['base_url'] .. '/' .. request_info['endpoint'] .. (query and ('?' .. query) or ''),
    headers = headers,
    method = 'GET',
    sink = ltn12.sink.table(response_body),
  }

  local response = nil
  if #response_body > 0 and response_headers['content-type'] == 'application/json' then
    local full_response = table.concat(response_body)
    response = vim.json.decode(full_response)
  end

  return response, response_headers, code
end

---@param request_info Request_Info
---@return table, table, integer
function M.send_post_form_request(request_info)
  local body = request_info['body_table'] and utils.stringify_table_as_kv(request_info['body_table'])
  local headers = request_info['headers'] and request_info['headers'] or {}

  if #headers == 0 then
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
  end

  if headers['Content-Length'] == nil then
    headers['Content-Length'] = #body
  end

  local response_body = {}

  local _, code, response_headers, _ = https.request {
    url = request_info['base_url'] .. '/' .. request_info['endpoint'],
    method = 'POST',
    headers = headers,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response_body),
  }

  local response = nil
  if #response_body > 0 then
    local full_response = table.concat(response_body)
    response = vim.json.decode(full_response)
  end

  return response, response_headers, code
end

---@param request_info Request_Info
---@return table, table, integer
function M.send_put_request(request_info)
  local query = request_info['query_table'] and utils.stringify_table_as_kv(request_info['query_table']) or nil
  local body = request_info['body_table'] and utils.stringify_table_as_json(request_info['body_table']) or nil
  local headers = request_info['headers'] and request_info['headers'] or {}

  if headers == {} then
    headers['Content-Type'] = 'application/json'
  end

  if not headers['Content-Length'] then
    headers['Content-Length'] = body and #body or 0
  end

  local response_body = {}

  local _, code, response_headers, _ = https.request {
    url = request_info['base_url'] .. '/' .. request_info['endpoint'] .. (query and ('?' .. query) or ''),
    headers = headers,
    method = 'PUT',
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response_body),
  }

  return response_body, response_headers, code
end

return M
