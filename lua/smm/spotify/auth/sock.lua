local config = require 'smm.config'
local logger = require 'smm.utils.logger'

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

---@return string
local function get_server_ok_authenticated()
  logger.debug 'Authentication Successful'
  return server_response('Authentication Successful!', 'You may now close this window')
end

---@return string
local function get_server_ok_not_authenticated()
  logger.debug 'Authentication Denied'
  return server_response('Authentication Denied!', 'You will not be able to use SMM')
end

---@return string
local function get_server_bad_request_csrf()
  logger.debug 'Authentication Failed. Possible security issue'
  return server_response('Authentication Failed', 'This could indicate a security issue')
end

local M = {}

---@param port integer
---@param state string
---@return string oauth_code Verification Code
function M.start_server(port, state)
  logger.debug('Starting HTTP server on port %d', port)

  local server = vim.uv.new_tcp()
  logger.debug 'Server started'

  server:bind('127.0.0.1', port)

  local oauth_code = nil
  local received = false

  server:listen(128, function(err)
    if err then
      logger.error('Listen error: %s', err)
      return
    end

    local client = vim.uv.new_tcp()
    server:accept(client)

    client:read_start(function(err, data)
      if err then
        logger.error('Read error: %s', err)
        return
      end

      if data and not received then
        received = true

        -- Parse the HTTP request
        local request = data
        local error = request:match 'error=([^%s&]+)'
        oauth_code = request:match 'code=([^%s&]+)'
        local returned_state = request:match 'state=([^%s]+)'

        local response = ''

        if state ~= returned_state then
          response = string.format(
            [[HTTP/1.2 400 Bad Request
Content-Type: text/html

%s]],
            get_server_bad_request_csrf()
          )

          client:send(response)
          client:close()
          server:close()
          logger.error 'CSRF state mismatch - this could indicate a security issue'
        end

        if error ~= nil then
          response = string.format(
            [[HTTP/1.2 200 OK
Content-Type: text/html

%s]],
            get_server_ok_not_authenticated()
          )
          client:send(response)
          client:close()
          server:close()
          logger.error 'Authentication denied - plugin not loaded'
        else
          response = string.format(
            [[HTTP/1.2 200 OK
Content-Type: text/html

%s]],
            get_server_ok_authenticated()
          )
          client:send(response)
          client:close()
          server:close()
        end
      end
    end)
  end)

  -- Wait for the response (with timeout)
  vim.wait(60000, function()
    return oauth_code ~= nil
  end, 250)

  if oauth_code == nil then
    logger.error 'Unable to authenticate. Server timed out'
    return
  end

  return oauth_code
end

return M
