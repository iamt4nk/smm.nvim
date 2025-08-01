local logger = require 'smm.utils.logger'

local M = {}

function M.setup()
  vim.api.nvim_create_user_command('Spotify', function(opts)
    local args = opts.fargs

    if #args == 0 then
      require('smm.playback').toggle_window()
    elseif args[1] == 'pause' then
      require('smm.playback').pause()
    elseif args[1] == 'resume' then
      require('smm.playback').resume()
    elseif args[1] == 'auth' then
      local auth_info = require('smm.spotify.auth').initiate_oauth_flow()
      require('smm.spotify').auth_info = auth_info

      local token = require 'smm.spotify.token'
      token.delete_refresh_token()
      token.save_refresh_token(auth_info.refresh_token)
    end
  end, {
    desc = 'Spotify related commands',
    nargs = '*',
    complete = function(ArgLead, CmdLine, CursorPos)
      return { 'auth', 'pause', 'resume' }
    end,
  })
end

return M
