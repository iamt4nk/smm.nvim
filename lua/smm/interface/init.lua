local config = require 'smm.interface.config'

local M = {}

function M.setup(user_config)
  config.setup(user_config or {})
end

return M
