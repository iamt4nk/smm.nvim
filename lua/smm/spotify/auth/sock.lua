local config = require 'smm.config'
local logger = require 'smm.utils.logger'
local socket = require 'socket'

---@param title string
---@param desc string
---@return string
local function server_response(title, desc)
  return [[<!DOCTYPE>
    <html>
      <head>
        <title>]] .. title .. [[</title>
        <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
      </head>

      <body class="bg-black font-sans subpixel-antialiased">
        <div class="flex h-screen items-center justify-center">
          <div class="border-white border p-18 shadow-md shadow-gray-500 bg-[121212]">
            <h1 class="text-3xl font-bold text-white mb-5">
              ]] .. title .. [[
            </h1>
            <p class="text-white mb-5">
              ]] .. desc .. [[
            </p>
            <button onclick="window.close()" class="w-full h-10 text-[121212] bg-[1ED760] hover:bg-[3BE477] font-bold px-4 rounded-full text-center transition duration-200">
              Close Window
            </button>
          </div>
        </div>
      </body>
    </html>]]
end

local function get_server_ok_authenticated()
  logger.debug 'Authentication Successful'
  return server_response('Authentication Successful!', 'You may now close this window')
end

local function get_server_ok_not_authenticated()
  logger.debug 'Authentication Denied'
  return server_response('Authentication Denied!', 'You will not be able to use SMM')
end

local function get_server_bad_request_csrf()
  logger.debug 'Authentication Failed. Possible security issue'
  return server_response('Authentication Failed', 'This could indicate a security issue')
end

local M = {}

---@param port integer
---@param state string
---@param callback function Function to call with the result (success, code_or_error)
function M.start_server(port, state, callback)
  logger.debug('Starting HTTP server on port %d using vim.loop', port)

  local server = vim.loop.new_tcp()
  local timeout_duration = config.get_value 'debug' == true and 60000 or 600000

  -- Set up timeout
  local timeout_timer = vim.loop.new_timer()
  timeout_timer:start(timeout_duration, 0, function()
    logger.debug 'Server timeout reached'
    server:close()
    callback(false, 'Authentication timeout')
  end)

  server:bind('127.0.0.1', port)

  server:listen(128, function(err)
    if err then
      timeout_timer:close()
      logger.error('Server listen error: %s', err)
    end

    local client = vim.loop.new_tcp()
    server:accept(client)

    -- Read the HTTP request
    client:read_start(function(read_err, data)
      if read_err then
        client:close()
        logger.error('Client read error: %s', read_err)
      end

      if data then
        logger.debug('Received request data: %s', data)

        -- Parse the HTTP request
        local request_line = data:match 'GET ([^\r\n]+)'
        if not request_line then
          client:close()
          return
        end

        logger.debug('Request line: %s', request_line)

        -- Extract query parameters
        local error_param = request_line:match 'error=([^%s&]+)'
        local code = request_line:match 'code=([^%s&]+)'
        local returned_state = request_line:match 'state=([^%s&]+)'

        -- Validate state
        logger.debug(returned_state)
        if state ~= returned_state then
          local response = string.format(
            [[HTTP/1.1 400 Bad Request
Content-Type: text/html
Content-Length: %d

%s]],
            #get_server_bad_request_csrf(),
            get_server_bad_request_csrf()
          )

          client:write(response)
          client:close()
          server:close()
          timeout_timer:close()
          callback(false, 'OAuth state mismatch - potential CSRF attack')
          return
        end

        -- Prepare response
        local response_body
        local status_code

        if error_param then
          response_body = get_server_ok_not_authenticated()
          status_code = '200 OK'
        else
          response_body = get_server_ok_authenticated()
          status_code = '200 OK'
        end

        local response = string.format(
          [[HTTP/1.1 %s
Content-Type: text/html
Content-Length: %d

%s]],
          status_code,
          #response_body,
          response_body
        )

        client:write(response, function()
          client:close()
          server:close()
          timeout_timer:close()

          if error_param then
            callback(false, 'Authentication denied by user')
          else
            callback(true, code)
          end
        end)
      end
    end)
  end)

  logger.debug 'TCP server created and listening'
end

-- ---@param port integer
-- ---@param state string
-- ---@param callback fun(success: boolean, response: string)
-- ---@return string code Verification Code
-- function M.start_server(port, state, callback)
--   logger.debug('Starting HTTP server on port %d', port)
--
--   local server = assert(socket.bind('*', port))
--   logger.debug 'Server started'
--
--   logger.debug 'Setting server timeout'
--   server:settimeout(0)
--
--   local timeout_duration = config.get_value 'debug' == true and 60000 or 300000 --milliseconds
--   local start_time = vim.loop.now()
--
--   logger.debug 'Server timeout set'
--
--   logger.debug 'Accepting requests to server'
--   local timer = vim.loop.new_timer()
--   timer:start(
--     100,
--     100,
--     vim.schedule_wrap(function()
--       local current_time = vim.loop.now()
--
--       if current_time - start_time > timeout_duration then
--         timer:stop()
--         timer:close()
--         server:close()
--         callback(false, 'Authentication timeout')
--         return
--       end
--
--       -- Try to accept a connection (non-blocking)
--       local client, err = server:accept()
--       if client then
--         timer:stop()
--         timer:close()
--
--         local request = client:receive()
--         logger.debug 'Received request'
--
--         local error = request:match 'error=([^%s&]+)'
--         local code = request:match 'code=([^%s&]+)'
--         local returned_state = request:match 'state=([^%s]+)'
--
--         local response = ''
--
--         if state ~= returned_state then
--           response = [[HTTP/1.2 400 Bad Request
--           Content-Type: text/html
--
--           ]] .. get_server_bad_request_csrf()
--
--           client:send(response)
--           client:close()
--           server:close()
--           callback(false, 'OAuth state mismatch - potential CSRF attack')
--           return
--         end
--
--         if error ~= nil then
--           response = [[HTTP/1.2 200 OK
--           Content-Type: text/html
--
--           ]] .. get_server_ok_not_authenticated()
--           client:send(response)
--           client:close()
--           server:close()
--           callback(false, 'Authentication denied by user')
--           return
--         else
--           response = [[HTTP/1.2 200 OK
--           Content-Type: text/html
--
--           ]] .. get_server_ok_authenticated()
--           client:send(response)
--           client:close()
--           server:close()
--           callback(true, code)
--         end
--       elseif err ~= 'timeout' then
--         timer:stop()
--         timer:close()
--         server:close()
--         callback(false, 'Server Error: ' .. tostring(err))
--       end
--     end)
--   )
-- end

return M
