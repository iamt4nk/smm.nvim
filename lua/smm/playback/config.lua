local M = {}

local config = nil

function M.setup(user_config)
  config = user_config
end

function M.get()
  return config
end

return M
