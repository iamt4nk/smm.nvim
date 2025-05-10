local has_plenary, curl = pcall(require, 'plenary.curl')
local utils = require 'smm.api.utils'

if not has_plenary then
  error 'Plenary.nvim is required for HTTP requests. Install it as a dependency with your plugin manager'
end

---@param status_code integer
---@return boolean
local check_status_code_ok = function(status_code)
  return (status_code - 200) >= 0 and (status_code - 200) < 100
end

local M = {}

---Make a GET Request
---@param opts Get_Request
---@return string, table, integer
function M.get(opts)
  local request_headers = opts.headers or {}
  local query = utils.encode_table_as_query(opts.query)

  print 'Sending GET Request'
  local resp = curl.get(query and (opts.url .. '?' .. query) or opts.url, {
    headers = request_headers,
  })

  local response_body = resp.body
  local response_headers = resp.headers
  local response_status = resp.status

  --- Convert resulting response headers to a k:v table
  local table_response_headers = utils.convert_headers_list_to_map(response_headers)

  -- Try to parse JSON if possible
  if
    response_body
    and response_body ~= ''
    and response_headers
    and response_headers['content-type']
    and response_headers['content-type']:match 'application/json'
  then
    local ok, parsed = pcall(utils.encode_table_as_json, response_body)
    if ok then
      response_body = parsed
    end
  end

  return response_body, response_headers, response_status
end

---Make a POST Request
---@param opts Post_Request
---@return string, table, integer
function M.post(opts)
  local request_headers = opts.headers or {}
  local body_data = opts.body
  local query = opts.query and utils.encode_table_as_query(opts.query)

  -- Handle body encoding based on content type
  if type(body_data) == 'table' then
    if request_headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body_data = utils.encode_table_as_query(body_data)
    else
      -- Default to JSON
      request_headers['Content-Type'] = 'application/json'
      body_data = utils.encode_table_as_json(body_data)
    end
  end

  local resp = curl.post(query and (opts.url .. '?' .. query) or opts.url, {
    headers = request_headers,
    body = body_data,
  })

  local response_body = resp.body
  local response_headers = resp.headers
  local response_status = resp.status

  --- Convert resulting response headers to a k:v table
  local table_response_headers = utils.convert_headers_list_to_map(response_headers)

  -- Try to parse JSON if possible
  if
    response_body
    and response_body ~= ''
    and response_headers
    and response_headers['content-type']
    and response_headers['content-type']:match 'application/json'
  then
    local ok, parsed = pcall(utils.encode_table_as_json, response_body)
    if ok then
      response_body = parsed
    end
  end

  return response_body, table_response_headers, response_status
end

---Make a POST Request
---@param opts Put_Request
---@return string, table, integer
function M.put(opts)
  local request_headers = opts.headers or {}
  local body_data = opts.body
  local query = opts.query and utils.encode_table_as_query(opts.query)

  -- Handle body encoding based on content type
  if type(body_data) == 'table' then
    if request_headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body_data = utils.encode_table_as_query(body_data)
    else
      -- Default to JSON
      request_headers['Content-Type'] = 'application/json'
      body_data = utils.encode_table_as_json(body_data)
    end
  end

  local resp = curl.post(query and (opts.url .. '?' .. query) or opts.url, {
    headers = request_headers,
    body = body_data,
  })

  local response_body = resp.body
  local response_headers = resp.headers
  local response_status = resp.status

  --- Convert resulting response headers to a k:v table
  local table_response_headers = utils.convert_headers_list_to_map(response_headers)

  -- Try to parse JSON if possible
  if
    response_body
    and response_body ~= ''
    and response_headers
    and response_headers['content-type']
    and response_headers['content-type']:match 'application/json'
  then
    local ok, parsed = pcall(utils.encode_table_as_json, response_body)
    if ok then
      response_body = parsed
    end
  end

  return response_body, table_response_headers, response_status
end

return M
