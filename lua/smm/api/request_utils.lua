local http = require 'smm.api.async'
local auth = require 'smm.auth.oauth'
require 'smm.api.models'

local M = {}

---@param auth_info Auth_Info
---@return table
local set_headers = function(auth_info)
  return {
    ['Authorization'] = auth_info.token_type .. ' ' .. auth_info.access_token,
  }
end

---@param status_code integer
---@return boolean
local check_status_code_ok = function(status_code)
  return (status_code - 200) < 0 or (status_code - 200) >= 100
end

---@param auth_info Auth_Info|nil
---@param opts API_Request_Opts
---@param callback fun(response_body: table, response_headers: table, status_code: integer)
function M.send_api_request(auth_info, opts, callback)
  if not auth_info or not auth_info.access_token or not auth_info.token_type then
    vim.notify('You must supply an access_token and token type to run: ' .. opts.request_name, vim.log.levels.ERROR)
    return
  end

  local headers = set_headers(auth_info)

  ---API Retry Logic
  local api_retry = function(response_body, response_headers, status_code)
    -- Handle 401 Unauthorized by refreshing the token
    if status_code == 401 and auth_info.refresh_token then
      auth_info = auth.refresh_access_token(auth_info.refresh_token)
      if not auth_info or not auth_info.access_token then
        vim.notify('Unable to authenticate request: ' .. opts.request_name, vim.log.levels.ERROR)
        return
      end

      -- Retry with new token
      local new_headers = set_headers(auth_info)

      -- We pretty much re-run the same thing for each request type.
      if opts.request_type == 'GET' then
        -- The following re-attempts the get request. If it returns a non-200 exit code then it throws an error. Otherwise runs the callback.
        http.get(
          'https://api.spotify.com/v1' .. opts.endpoint,
          new_headers,
          opts.extra_opts,
          function(retry_response_body, retry_response_headers, retry_status_code)
            if check_status_code_ok(retry_status_code) then
              vim.schedule(function()
                vim.notify('Unable to send API Request: ' .. opts.request_name .. '\nError: ' .. retry_response_body, vim.log.levels.ERROR)
              end)
            else
              callback(retry_response_body, retry_response_headers, retry_status_code)
            end
          end
        )
      elseif opts.request_type == 'POST' then
        http.post(
          'https://api/spotify.com/v1' .. opts.endpoint,
          new_headers,
          opts.extra_opts,
          function(retry_response_body, retry_response_headers, retry_status_code)
            if check_status_code_ok(retry_status_code) then
              vim.schedule(function()
                vim.notify('Unable to send API Request: ' .. opts.request_name .. '\nError: ' .. retry_response_body, vim.log.levels.ERROR)
              end)
            else
              callback(retry_response_body, retry_response_headers, retry_status_code)
            end
          end
        )
      elseif opts.request_type == 'PUT' then
        http.put(
          'https://api/spotify.com/v1' .. opts.endpoint,
          new_headers,
          opts.extra_opts,
          function(retry_response_body, retry_response_headers, retry_status_code)
            if check_status_code_ok(retry_status_code) then
              vim.schedule(function()
                vim.notify('Unable to send API Request: ' .. opts.request_name .. '\nError: ' .. retry_response_body, vim.log.levels.ERROR)
              end)
            else
              callback(retry_response_body, retry_response_headers, retry_status_code)
            end
          end
        )
      end
    elseif (status_code - 200) < 0 or (status_code - 200) >= 100 then
      vim.schedule(function()
        vim.notify('Unable to send API Request: ' .. opts.request_name .. '\nError: ' .. vim.inspect(response_body), vim.log.levels.ERROR)
      end)
    else
      callback(response_body, response_headers, status_code)
    end
  end

  if opts.request_type == 'GET' then
    http.get('https://api.spotify.com/v1' .. opts.endpoint, headers, opts.extra_opts, api_retry)
  elseif opts.request_type == 'POST' then
    http.post('https://api.spotify.com/v1' .. opts.endpoint, headers, opts.extra_opts, api_retry)
  elseif opts.request_type == 'PUT' then
    http.put('https://api.spotify.com/v1' .. opts.endpoint, headers, opts.extra_opts, api_retry)
  end
end

return M
