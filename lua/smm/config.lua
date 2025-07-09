local M = {}

local default_config = {
  initialized = false,
  debug = true,

  example_module = {
    enabled = true,
    some_setting = 'default_value',
  },
}

local current_config = {}

function M.setup(user_config)
  current_config = vim.tbl_deep_extend('force', default_config, user_config or {})
end

function M.get()
  return current_config
end

function M.get_value(key)
  return current_config[key]
end

return M
