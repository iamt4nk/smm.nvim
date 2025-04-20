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
  return server_response('Authentication Successful!', 'You may now close this window')
end

local function get_server_ok_not_authenticated()
  return server_response('Authentication Denied!', 'You will not be able to use SMM')
end

local function get_server_bad_request_csrf()
  return server_response('Authentication Failed!', 'This could indicate a security issue')
end

local M = {}

function M.create_server(port, state)
  local server = assert(socket.bind('*', port))

  server:settimeout(60)

  local client = server:accept()

  local request = client:receive()

  local error = request:match 'error=([^%s&]+)'
  local code = request:match 'code=([^%s&]+)'
  local returned_state = request:match 'state=([^%s]+)'

  local response = ''

  if state ~= returned_state then
    response = [[HTTP/1.1 400 Bad Request 
Content-Type: text/html 

]] .. get_server_bad_request_csrf()

    client:send(response)
    client:close()
    server:close()
    error 'OAuth state mismatch - potential CSRF attack'
  end

  if error ~= nil then
    response = [[HTTP/1.1 200 OK
Content-Type: text/html

]] .. get_server_ok_not_authenticated()
  else
    response = [[HTTP/1.1 200 OK
Content-Type: text/html

]] .. get_server_ok_authenticated()
  end

  client:send(response)
  client:close()
  server:close()

  return code
end

return M
