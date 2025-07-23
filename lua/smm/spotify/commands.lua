local logger = require 'smm.utils.logger'
local config = require 'smm.spotify.config'
local auth = require 'smm.spotify.auth'

local M = {}

function M.setup()
  if not config.get().enabled then
    logger.debug 'Spotify module disabled, skipping command registration'
    return
  end

  vim.api.nvim_create_user_command('Spotify', function()
    local playback = require 'smm.interface.playback'

    local playback_showing = playback.is_showing

    if not playback_showing then
      if not auth.auth_info then
        require('smm.spotify').auth()
      end
      playback.create_window()
      return
    end

    playback.remove_window()
  end, { desc = 'Open the Spotify plugin and authenticate' })
end

return M
