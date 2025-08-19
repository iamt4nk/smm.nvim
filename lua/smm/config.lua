local logger = require 'smm.utils.logger'

---@alias SMM_Config { debug: boolean, file?: string, premium: boolean, playback: SMM_PlaybackConfig, spotify: SMM_SpotifyConfig }
local M = {}

local default_config = {
  premium = true,
  debug = false,
  file = '/home/klanum/smm_log.txt',

  playback = {
    enabled = true,
    timer_update_interval = 100,
    timer_sync_interval = 5000,
    interface = {
      playback_pos = 'BottomRight', ---@type SMM_PlaybackWindowPosition
      playback_width = 40,
      progress_bar_width = 35,
    },
  },

  spotify = {
    enabled = true,
    api_retry_max = 3,
    api_retry_backoff = 2000,
    auth = {
      enabled = true,
      client_id = 'c43057d088204249bca8d5bde4e93bd3',
      callback_url = 'http://127.0.0.1',
      callback_port = 8080,
    },
  },
}

local config = {}

---@param user_config SMM_Config
function M.setup(user_config)
  if user_config.debug == nil then
    user_config.debug = false
  end

  logger.debug('Default config: %s\n', vim.inspect(default_config))
  config = vim.tbl_deep_extend('force', default_config, user_config or {})
  logger.debug('Merged config: %s\n', vim.inspect(config))

  logger.setup((user_config and user_config.debug) or default_config.debug, user_config.file)
end

---@return SMM_Config
function M.get()
  return config
end

function M.get_value(key)
  return config[key]
end

---@param update table
function M.update_config(update)
  default_config = vim.tbl_deep_extend('force', default_config, update or {})
end

return M
