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
---@return string code Verification Code
function M.create_server(port, state) end

return M
