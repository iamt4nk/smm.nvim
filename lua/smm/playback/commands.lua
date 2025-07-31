local logger = require 'smm.utils.logger'
local config = require 'smm.playback.config'

local M = {}

function M.setup()
  vim.api.nvim_create_user_command('Spotify', function(opts)
    local args = opts.fargs
    local playback = require 'smm.playback'

    if #args == 0 then
      playback.toggle_window()
    elseif args[1] == 'pause' then
      playback.pause()
    elseif args[1] == 'resume' then
      playback.resume()
    else
      logger.warn('Unknown Spotify command: %s', args[1])
      print 'Usage: :Spotify [pause|resume]'
    end
  end, {
    desc = 'Open the Spotify plugin and authenticate',
    nargs = '*',
    complete = function(ArgLead, CmdLine, CursorPos)
      return { 'pause', 'resume' }
    end,
  })
end

return M
