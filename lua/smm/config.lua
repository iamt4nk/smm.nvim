local logger = require 'smm.utils.logger'

local M = {}

local default_config = {
  initialized = false,
  debug = true,
  -- file = '/home/klanum/smm_log.txt',

  example_module = {
    enabled = true,
    some_setting = 'default_value',
  },

  spotify = {
    enabled = true,
    auth = {
      enabled = true,
      client_id = 'c43057d088204249bca8d5bde4e93bd3',
      callback_url = 'http://127.0.0.1',
      callback_port = 8080,
      scope = {
        'user-read-playback-state',
        'user-read-currently-playing',
        'user-modify-playback-state',
        'user-read-private',
      },
    },
  },
}

local current_config = {}

function M.setup(user_config)
  logger.setup((user_config and user_config.debug and user_config) or default_config)

  logger.debug('Default config: %s\n', vim.inspect(default_config))
  current_config = vim.tbl_deep_extend('force', default_config, user_config or {})
  logger.debug('Merged config: %s\n', vim.inspect(current_config))

  logger.debug 'Initializing Spotify Module config'
  require('smm.spotify.config').setup(current_config.spotify)
  logger.debug 'Initializing example module config'
  require('smm.example_module.config').setup(current_config.example_module)
end

function M.get()
  return current_config
end

function M.get_value(key)
  return current_config[key]
end

return M
