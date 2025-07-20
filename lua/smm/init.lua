local M = {}

local config = require 'smm.config'

function M.setup(user_config)
  config.setup(user_config or {})
end

return M
