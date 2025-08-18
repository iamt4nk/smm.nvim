local logger = require 'smm.utils.logger'

local M = {}

--Setup function
function M.setup()
  -- Currently no configuration needed for search module
  -- This is here for consistency and future extensibility
  logger.debug 'Search module initialized'
end

return M
