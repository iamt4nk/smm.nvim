local M = {}

-- Registry to track loaded modules

M.loaded_modules = {}

function M.register_module(name, module_config)
  M.loaded_modules[name] = module_config
  return module_config
end

function M.get_module(name)
  return M.loaded_modules[name]
end

-- Explicitly require modules here os they get registered
require 'smm.modules.example_module'

function M.load_all()
  for name, module in pairs(M.loaded_modules) do
    if module.setup then
      module.setup()
    end
  end
end

return M
