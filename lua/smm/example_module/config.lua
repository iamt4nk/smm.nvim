local M = {}

local default_config = {
  enabled = true,
  some_setting = 'default_value',
}

local module_config = {}

---@param opts table
function M.setup(opts)
  module_config = vim.tbl_deep_extend('force', default_config, opts)
end

function M.get()
  return module_config
end

function M.get_value(key)
  return module_config[key]
end

return M
