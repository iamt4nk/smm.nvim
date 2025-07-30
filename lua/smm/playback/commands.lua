local logger = require 'smm.utils.logger'
local config = require 'smm.playback.config'

local M = {}

function M.setup()
  local playback = require 'smm.playback'

  if not config.get().enabled then
    logger.debug 'Playback module disabled, skipping command registration'
    return
  end

  vim.api.nvim_create_user_command('Spotify', function()
    playback.toggle_window()
    playback.start_timer()
  end, { desc = 'Open the Spotify plugin and authenticate' })
end

return M
