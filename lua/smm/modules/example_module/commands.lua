local logger = require 'smm.modules.utils.logger'
local module_config = require 'smm.modules.example_module.config'

local M = {}

function M.setup()
  if not module_config.get_value 'enabled' then
    logger.debug 'Example module disabled, skipping command registration'
    return
  end

  -- Create module-specific commands
  vim.api.nvim_create_user_command('ExampleModuleTest', function()
    local example_module = require 'your-plugin-name.modules.example_module'
    local result = example_module.do_something()
    logger.info('Command result: %s', result)
  end, {
    desc = 'Test command for example module',
  })

  logger.debug 'Example module commands registered'
end
