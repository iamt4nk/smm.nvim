local logger = require 'smm.modules.utils.logger'
local module_config = require 'smm.modules.example_module.config'
local commands = require 'smm.modules.example_module.commands'

local M = {}

function M.setup()
  logger.debug 'Setting up example_module'

  module_config.setup()

  commands.setup()

  logger.info 'Example module loaded successfully'
end

function M.do_something()
  logger.info 'Example module doing something!'
  return 'Hello from example module'
end

return M
