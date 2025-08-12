local logger = require 'smm.utils.logger'
local spotify = require 'smm.spotify'
local playback = require 'smm.playback'
local search = require 'smm.search'
local config = require 'smm.config'
local commands = require 'smm.commands'

local M = {}

function M.setup(user_config)
  config.setup(user_config or {})

  commands.setup()

  logger.debug 'Initializing Spotify Module'
  spotify.setup(config.get().spotify)

  logger.debug 'Initializing Playback Module'
  playback.setup(config.get().playback)

  logger.debug 'Initializing Search Module'
  search.setup()
end

return M
