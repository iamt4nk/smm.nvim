local curl = require 'plenary.curl'
local encoding = require 'smm.utils.encoding'
local logger = require 'smm.utils.logger'

---@alias SMM_GetRequestSynchronous { base_url: string, endpoint: string, query: table|nil, headers: table|nil }
---@alias SMM_PutRequestSynchronous { base_url: string, endpoint: string, query: table|nil, body: table|nil, headers: table|nil }
---@alias SMM_PostRequestSynchronous { base_url: string, endpoint: string, query: table|nil, body: table|nil, headers: table|nil }

---@param response table The curl response
---@return table, table, integer
local function process_response(response)
  local response_body = response.body
  local response_status = response.status

  -- Process headers
  local response_headers = {}
  for _, header in ipairs(response.headers) do
    local key, value = header:match '([^:]+):%S*(.*)'
    if key and value then
      response_headers[key:lower()] = value:match '^%s*(.-)%s*$'
    end
  end

  -- Parse JSON if content type is application/json
  if response_headers['content-type'] and response_headers['content-type']:match 'application/json' and response_body and response_body ~= '' then
    local ok, parsed = pcall(vim.json.decode, response_body)
    if not ok then
      logger.error 'Unable to parse JSON response. Please check the received data'
    else
      response_body = parsed
    end
  end

  return response_body, response_headers, response_status
end

local M = {}

---@param request_info SMM_GetRequestSynchronous
---@return table, table, integer
function M.send_get_request(request_info)
  local query = request_info['query'] and encoding.encode_table_as_query(request_info['query'])
  local url = request_info['endpoint'] and request_info['base_url'] .. '/' .. request_info['endpoint'] or request_info['base_url']
  url = query and url .. '?' .. query or url
  local headers = request_info['headers'] or {}

  local response = curl.get(url, {
    headers = headers,
  })

  return process_response(response)
end

---@param request_info SMM_PutRequestSynchronous
---@return table, table, integer
function M.send_put_request(request_info)
  local query = request_info['query'] and encoding.encode_table_as_query(request_info['query']) or ''
  local url = request_info['base_url'] .. '/' .. request_info['endpoint'] .. '?' .. query

  local headers = request_info['headers'] or {}
  if not headers['Content-Type'] then
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
  end

  local body = ''
  if request_info['body'] then
    if headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body = encoding.encode_table_as_query(request_info['body'])
    elseif headers['Content-Type'] == 'application/json' then
      body = encoding.encode_table_as_json(request_info['body'])
    else
      logger.error 'Content type not implemented'
    end
  end

  local response = curl.put(url, {
    headers = headers,
    body = body,
  })

  return process_response(response)
end

---@param request_info SMM_PostRequestSynchronous
---@return table, table, integer
function M.send_post_request(request_info)
  local query = request_info['query'] and encoding.encode_table_as_query(request_info['query']) or ''
  local url = request_info['base_url'] .. '/' .. request_info['endpoint']
  url = (query ~= '') and (url .. '?' .. query) or url

  local headers = request_info['headers'] or {}
  if not headers['Content-Type'] then
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
  end

  local body = ''
  if request_info['body'] then
    if headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body = encoding.encode_table_as_query(request_info['body'])
    elseif headers['Content-Type'] == 'application/json' then
      body = encoding.encode_table_as_json(request_info['body'])
    else
      logger.error 'Content type not implemented'
    end
  end

  local response = curl.post(url, {
    headers = headers,
    body = body,
  })

  return process_response(response)
end

return M
