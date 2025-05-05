local has_plenary, curl = pcall(require, 'plenary.curl')
local utils = require 'smm.api.utils'
require 'smm.api.models'

if not has_plenary then
  error 'Plenary.nvim is required for async HTTP. Install it as a dependency with your plugin manager'
end

---@param status_code integer
---@return boolean
local check_status_code_ok = function(status_code)
  return (status_code - 200) >= 0 and (status_code - 200) < 100
end

local M = {}

---Make a GET Request
---@param opts Get_Request
---@param callback function(response_body, response_headers, status_code) Callback Function
function M.get(opts, callback)
  local query = utils.encode_table_as_query(opts.query)

  print 'Sending GET Request'
  curl.get(query and (opts.url .. '?' .. query) or opts.url, {
    headers = opts.headers or {},
    callback = function(response)
      -- Extract parts
      local response_body = response.body
      local response_headers = response.headers
      local response_status = response.status

      -- We need to convert the resulting response_headers to a k:v table as opposed to a list
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

      callback(response_body, table_response_headers, response_status)
    end,
  })
end

---Make a POST Request
---@param opts Post_Request
---@param callback function(response_body, response_headers, status_code) Callback function
function M.post(opts, callback)
  local request_headers = opts.headers or {}
  local body_data = opts.body
  local query = opts.query and utils.encode_table_as_query(opts.query)

  -- Handle body encoding based on content type
  if type(body_data) == 'table' then
    if request_headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body_data = utils.encode_table_as_query(body_data)
    else
      -- Default to JSON
      request_headers['Content-Type'] = request_headers['Content-Type'] or 'application/json'
      body_data = utils.encode_table_as_json(body_data)
    end
  end

  curl.post(query and (opts.url .. '?' .. query) or opts.url, {
    headers = request_headers,
    body = body_data,
    callback = function(response)
      local response_body = response.body
      local response_headers = response.headers
      local response_status = response.status

      -- We need to convert the resulting response_headers to a k:v table as opposed to a list
      local table_response_headers = utils.convert_headers_list_to_map(response_headers)

      -- Try to parse JSON if possible
      if
        response_body
        and response_body ~= ''
        and table_response_headers
        and table_response_headers['content-type']
        and table_response_headers['content-type']:match 'application/json'
      then
        local ok, parsed = pcall(utils.encode_table_as_json, response_body)
        if ok then
          response_body = parsed
        end
      end

      callback(response_body, table_response_headers, response_status)
    end,
  })
end

--- Make a PUT request
---@param opts Put_Request
---@param callback function(response_body, response_headers, status_code) Callback function
function M.put(opts, callback)
  local request_headers = opts.headers or {}
  local body_data = opts.body
  local query = opts.query and utils.encode_table_as_query(opts.query)

  -- Handle body encoding based on content type
  if type(body_data) == 'table' then
    if request_headers['Content-Type'] == 'application/x-www-form-urlencoded' then
      body_data = utils.encode_table_as_query(body_data)
    else
      -- Default to JSON
      request_headers['Content-Type'] = request_headers['Content-Type'] or 'application/json'
      body_data = utils.encode_table_as_json(body_data)
    end
  end

  curl.put(opts.query and (opts.url .. '?' .. query) or opts.url, {
    headers = request_headers,
    body = body_data,
    callback = function(response)
      local response_body = response.body
      local response_headers = response.headers
      local response_status = response.status

      -- We need to convert the resulting response_headers to a k:v table as opposed to a list
      local table_response_headers = utils.convert_headers_list_to_map(response_headers)

      -- Try to parse JSON if possible
      if
        response_body
        and response_body ~= ''
        and table_response_headers
        and table_response_headers['content-type']
        and table_response_headers['content-type']:match 'application/json'
      then
        local ok, parsed = pcall(utils.encode_table_as_json, response_body)
        if ok then
          response_body = parsed
        end
      end

      callback(response_body, table_response_headers, response_status)
    end,
  })
end

---Retry a request
---@param opts Retry_Opts
function M.retry(opts)
  local retry_callback = function(response_body, response_headers, status_code)
    if check_status_code_ok(status_code) then
      vim.schedule(function()
        vim.notify('Unable to send API request: ' .. opts.request_opts.request_name .. '\nError: ' .. response_body, vim.log.levels.ERROR)
      end)
    else
      opts.callback(response_body, response_headers, status_code)
    end
  end

  if opts.request_type == 'GET' then
    M.get({ opts.request_opts.url, opts.request_opts.headers, opts.request_opts.query }, retry_callback)
  elseif opts.request_type == 'POST' then
    M.post({ opts.request_opts.url, opts.request_opts.headers, opts.request_opts.query, opts.request_opts.body }, retry_callback)
  elseif opts.request_type == 'PUT' then
    M.put({ opts.request_opts.url, opts.request_opts.headers, opts.request_opts.query, opts.request_opts.body }, retry_callback)
  end
end

return M
