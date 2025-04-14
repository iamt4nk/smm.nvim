local has_plenary, curl = pcall(require, 'plenary.curl')

if not has_plenary then
  error 'Plenary.nvim is required for HTTP requests. Install it as a dependency with your plugin manager'
end

local utils = require 'smm.auth.utils'

---@alias Request_Info { base_url: string, endpoint: string, query_table: table|nil, body_table: table|nil, headers: table|nil }

local M = {}

---@param query_table table
---@return string
local function encode_query_params(query_table)
  if not query_table then
    return ''
  end

  local query_parts = {}
  for k, v in pairs(query_table) do
    table.insert(query_parts, k .. '=' .. vim.uri_encode(tostring(v)))
  end

  if #query_parts == 0 then
    return ''
  else
    return '?' .. table.concat(query_parts, '&')
  end
end

---@param response table The curl response
---@return table, table, integer
local function process_response(response)
  local response_body = response.body
  local response_status = response.status

  -- Process headers
  local response_headers = {}
  for _, header in ipairs(response.headers) do
    local key, value = header:match '([^:]+):%s*(.*)'
    if key and value then
      response_headers[key:lower()] = value:match '^%s*(.-)%s*$'
    end
  end

  -- Parse JSON if content type is application/json
  if response_body and response_body ~= '' and response_headers['content-type'] and response_headers['content-type']:match 'application/json' then
    local ok, parsed = pcall(vim.json.decode, response_body)
    if ok then
      response_body = parsed
    end
  end

  return response_body, response_headers, response_status
end

---@param request_info Request_Info
---@return table, table, integer
function M.send_get_request(request_info)
  local query = request_info['query_table'] and encode_query_params(request_info['query_table']) or ''
  local url = request_info['base_url'] .. '/' .. request_info['endpoint'] .. query
  local headers = request_info['headers'] or {}

  local response = curl.get(url, {
    headers = headers,
  })

  return process_response(response)
end

---@param request_info Request_Info
---@return table, table, integer
function M.send_post_form_request(request_info)
  local headers = request_info['headers'] or {}
  if not headers['Content-Type'] then
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
  end

  local body = ''
  if request_info['body_table'] then
    if headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body = utils.stringify_table_as_kv(request_info['body_table'])
    else
      body = utils.stringify_table_as_json(request_info['body_table'])
    end
  end

  local url = request_info['base_url'] .. '/' .. request_info['endpoint']

  local response = curl.post(url, {
    headers = headers,
    body = body,
  })

  return process_response(response)
end

---@param request_info Request_Info
---@return table, table, integer
function M.send_put_request(request_info)
  local query = request_info['query_table'] and encode_query_params(request_info['query_table']) or ''
  local url = request_info['base_url'] .. '/' .. request_info['endpoint'] .. query

  local headers = request_info['headers'] or {}
  if not headers['Content-Type'] then
    headers['Content-Type'] = 'application/json'
  end

  local body = ''
  if request_info['body_table'] then
    if headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body = utils.stringify_table_as_kv(request_info['body_table'])
    else
      body = utils.stringify_table_as_json(request_info['body_table'])
    end
  end

  local response = curl.put(url, {
    headers = headers,
    body = body,
  })

  return process_response(response)
end

return M
