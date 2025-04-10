local has_plenary, curl = pcall(require, 'plenary.curl')

if not has_plenary then
  error 'Plenary.nvim is required for async HTTP. Install it as a dependency with your plugin manager'
end

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

--- Make a GET Request
---@param url string The base URL
---@param headers table|nil Optional headers
---@param query_table table|nil Optional query parameters
---@param callback function(response_body, response_headers, status_code) Callback Function
function M.get(url, headers, query_table, callback)
  local query = query_table and encode_query_params(query_table)

  curl.get(query and (url .. query) or url, {
    headers = headers or {},
    callback = function(response)
      -- Extract parts
      local response_body = response.body
      local response_headers = response.headers
      local response_status = response.status

      -- We need to convert the resulting response_headers to a k:v table as opposed to a list
      local table_response_headers = {}
      for _, value in ipairs(response_headers) do
        local k, v = value:match '([^:]+):%s*(.*)'

        if k and v then
          k = k:match '^%s*(.-)%s*$'
          table_response_headers[k] = v
        end
      end

      -- Try to parse JSON if possible
      if
        response_body
        and response_body ~= ''
        and table_response_headers
        and table_response_headers['content-type']
        and table_response_headers['content-type']:match 'application/json'
      then
        local ok, parsed = pcall(vim.json.decode, response_body)
        if ok then
          response_body = parsed
        end
      end

      callback(response_body, table_response_headers, response_status)
    end,
  })
end

--- Make a POST request
---@param url string The base URL
---@param body table|string Request body (will be encoded as JSON if table)
---@param headers table|nil Optional headers
---@param callback function(response_body, response_headers, status_code) Callback function
function M.post(url, body, headers, callback)
  local request_headers = headers or {}
  local body_data = body

  -- Handle body encoding based on content type
  if type(body) == 'table' then
    if request_headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      local form_parts = {}
      for k, v in pairs(body) do
        table.insert(form_parts, k .. '=' .. vim.uri_encode(tostring(v)))
      end
      body_data = table.concat(form_parts, '&')
    else
      -- Default to JSON
      request_headers['Content-Type'] = request_headers['Content-Type'] or 'application/json'
      body_data = vim.json.encode(body)
    end
  end

  curl.post(url, {
    headers = request_headers,
    body = body_data,
    callback = function(response)
      local response_body = response.body
      local response_headers = response.headers
      local response_status = response.status

      -- Try to parse JSON if possible
      if response_body and response_body ~= '' and headers and headers['Content-Type'] and headers['Content-Type']:match 'application/json' then
        local ok, parsed = pcall(vim.json.decode, body)
        if ok then
          response_body = parsed
        end
      end

      callback(response_body, response_headers, response_status)
    end,
  })
end

--- Make a PUT request
---@param url string The base URL
---@param body table|string|nil Request body (will be encoded as JSON if table)
---@param headers table|nil Optional headers
---@param callback function(response_body, response_headers, status_code) Callback function
function M.put(url, body, headers, callback)
  local request_headers = headers or {}
  local body_data = body

  -- Handle body encoding based on content type
  if type(body) == 'table' then
    if request_headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      local form_parts = {}
      for k, v in pairs(body) do
        table.insert(form_parts, k .. '=' .. vim.uri_encode(tostring(v)))
      end
      body_data = table.concat(form_parts, '&')
    else
      -- Default to JSON
      request_headers['Content-Type'] = request_headers['Content-Type'] or 'application/json'
      body_data = vim.json.encode(body)
    end
  end

  curl.put(url, {
    headers = request_headers,
    body = body_data,
    callback = function(response)
      local response_body = response.body
      local response_headers = response.headers
      local response_status = response.status

      -- Try to parse JSON if possible
      if response_body and response_body ~= '' and headers and headers['Content-Type'] and headers['Content-Type']:match 'application/json' then
        local ok, parsed = pcall(vim.json.decode, body)
        if ok then
          response_body = parsed
        end
      end

      callback(response_body, response_headers, response_status)
    end,
  })
end

return M
