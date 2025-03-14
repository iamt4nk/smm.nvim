local socket = require 'socket'

local function get_server_ok_authenticated()
  return [[<h1>Authntication Successful</h1>
  <p>You can close this window.</p>]]
end

local function get_server_ok_not_authenticated()
  return [[<h1>Authorization Denied!</h1>
  <p>You will not be able to use SMM.</p>]]
end

local function get_server_bad_request_csrf()
  return [[<h1>Authentication Failed</h1>
  <p>Invalid state parameter. This could indicate a security issue</p>]]
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

<html>
<body>]] .. get_server_bad_request_csrf() .. [[
</body></html>]]

    client:send(response)
    client:close()
    server:close()
    error 'OAuth state mismatch - potential CSRF attack'
  end

  if error ~= nil then
    response = [[HTTP/1.1 200 OK
Content-Type: text/html

<html>
<body>]] .. get_server_ok_not_authenticated() .. [[
</body>
</html>]]
  else
    response = [[HTTP/1.1 200 OK
Content-Type: text/html

<html>
<body> ]] .. get_server_ok_authenticated() .. [[
</body>
</html>]]
  end

  client:send(response)
  client:close()
  server:close()

  return code
end

return M
