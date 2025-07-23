local logger = require 'smm.utils.logger'
local spotify = require 'smm.spotify'
local interface = require 'smm.interface'
local config = require 'smm.config'

local M = {}

function M.setup(user_config)
  config.setup(user_config or {})

  logger.debug 'Initializing Spotify Module'
  spotify.setup(config.get().spotify)

  logger.debug 'Initializing Interface Module'
  interface.setup(config.get().interface)
end

return M
