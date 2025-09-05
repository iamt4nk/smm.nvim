local curl = require 'plenary.curl'
local encoding = require 'smm.utils.encoding'
local logger = require 'smm.utils.logger'

local M = {}

---@param headers table?
---@return table
local function prepare_headers(headers, access_token)
  if not headers then
    headers = {}
  end
  headers['Authorization'] = 'Bearer ' .. access_token
  return headers
end

---@param response table
---@return table|string, table, integer
local function process_response(response)
  -- logger.debug(vim.inspect(response))

  -- Extract parts of response
  local response_body = response.body
  local response_headers_array = response.headers
  local response_status = response.status

  -- We need to convert the resulting response_headers to a k:v table as opposed to a list
  local response_headers = {}
  for _, value in ipairs(response_headers_array) do
    local k, v = value:match '([^:]+):%s*(.*)'

    if k and v then
      k = k:match '^%s*(.-)%s*$'
      response_headers[k] = v
    end
  end

  -- Try to parse JSON if possible
  if
    response_body
    and response_body ~= ''
    and response_headers
    and response_headers['content-type']
    and response_headers['content-type']:match 'application/json'
  then
    local ok, parsed = pcall(vim.json.decode, response_body)
    if ok then
      response_body = parsed
    end
    response_body = parsed
  end
  return response_body, response_headers, response_status
end

---Make a GET Request
---@param url string The base URL
---@param headers table? Optional headers
---@param query table?
---@param access_token string
---@param callback fun(response_body: table|string, response_headers: table, status_code: integer) Callback Function
function M.get(url, headers, query, access_token, callback)
  local query_string = query and encoding.encode_table_as_query(query)
  headers = prepare_headers(headers, access_token)

  -- logger.debug('Sending GET request: %s\nQuery: %s\nHeaders: %s', url, vim.inspect(query), vim.inspect(headers))

  curl.get(query_string and (url .. '?' .. query_string) or url, {
    headers = headers,
    callback = function(response)
      callback(process_response(response))
    end,
  })
end

---Make a POST Request
---@param url string The base URL
---@param headers table? Optional headers
---@param query table? Optional Query
---@param body table|string Required Body (will be encoded as JSON if Content-Type not specified)
---@param access_token string
---@param callback fun(response_body: table|string, response_headers: table, status_code: integer) Callback Function
function M.post(url, headers, query, body, access_token, callback)
  local query_string = query and encoding.encode_table_as_query(query)
  local body_data = ''

  headers = prepare_headers(headers, access_token)

  if body then
    if type(body) == 'table' then
      if headers['Content-Type'] and headers['Content-Type']:match 'application%/x-www-form-urlencoded' then
        body_data = encoding.encode_table_as_query(body)
      else
        -- We default to JSON
        headers = {
          ['Content-Type'] = 'application/json',
        }
        body_data = encoding.encode_table_as_json(body)
      end
    else
      body_data = body
    end
  end

  -- logger.debug('Sending POST request: %s\nQuery: %s\nHeaders: %s\nBody: %s', url, vim.inspect(query), vim.inspect(headers), vim.inspect(body))

  curl.post(query_string and (url .. '?' .. query_string) or url, {
    headers = headers or {},
    body = body_data,
    callback = function(response)
      callback(process_response(response))
    end,
  })
end

--- Make a PUT Request
---@param url string The base URL
---@param headers table? Optional Headers
---@param query table? Optional Query
---@param body table|string? Request body (will be encoded as JSON if Content-Type not specified)
---@param access_token string Authorization Access Token
---@param callback fun(response_body: table|string, response_headers: table, status_code: integer) Callback Function
function M.put(url, headers, query, body, access_token, callback)
  local query_string = query and encoding.encode_table_as_query(query)
  local body_data = ''

  headers = prepare_headers(headers, access_token)

  if body then
    if type(body) == 'table' then
      if headers['Content-Type'] and headers['Content-Type']:match 'application%/x-www-form-urlencoded' then
        body_data = encoding.encode_table_as_query(body)
      else
        -- We default to JSON
        headers['Content-Type'] = 'application/json'
        body_data = encoding.encode_table_as_json(body)
      end
    else
      body_data = body
    end
  end

  -- logger.debug('Sending PUT request: %s\nQuery: %s\nHeaders: %s\n Body: %s', url, vim.inspect(query), vim.inspect(headers), body_data)

  curl.put(query_string and (url .. '?' .. query_string) or url, {
    headers = headers or {},
    body = body_data,
    callback = function(response)
      callback(process_response(response))
    end,
  })
end

--- Make a DELETE Request
---@param url string The base URL
---@param headers table? Optional Headers
---@param query table? Optional Query
---@param body table|string? Request body (will be encoded as JSON if Content-Type not specified)
---@param access_token string Authorization Access Token
---@param callback fun(response_body: table|string, response_headers: table, status_code: integer) Callback Function
function M.delete(url, headers, query, body, access_token, callback)
  local query_string = query and encoding.encode_table_as_query(query)
  local body_data = ''

  headers = prepare_headers(headers, access_token)

  if body then
    if type(body) == 'table' then
      if headers['Content-Type'] and headers['Content-Type']:match 'application%/x-www-form-urlencoded' then
        body_data = encoding.encode_table_as_query(body)
      else
        -- We default to JSON
        headers['Content-Type'] = 'application/json'
        body_data = encoding.encode_table_as_json(body)
      end
    else
      body_data = body
    end
  end

  -- logger.debug('Sending DELETE request: %s\nQuery: %s\nHeaders: %s\n Body: %s', url, vim.inspect(query), vim.inspect(headers), body_data)

  curl.delete(query_string and (url .. '?' .. query_string) or url, {
    headers = headers or {},
    body = body_data,
    callback = function(response)
      callback(process_response(response))
    end,
  })
end

return M
