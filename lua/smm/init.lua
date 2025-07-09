local M = {}

local config = require 'smm.config'
local modules = require 'smm.modules'

function M.setup(user_config)
  config.setup(user_config or {})

  modules.load_all()

  config.get().initialized = true
end

M.modules = modules

return M
