local main_config = require 'smm.config'

local M = {}

local default_config = {
  enabled = true,
  some_setting = 'default_value',
}

local module_config = {}

function M.setup()
  -- Get module-specific config from mainconfig, merge with defaults
  local user_module_config = main_config.get().example_module or {}
  module_config = vim.tbl_deep_extend('force', default_config, user_module_config)
end

function M.get()
  return module_config
end

function M.get_value(key)
  return module_config[key]
end
