-- Prevent the plugin from loading twice
if vim.g.loaded_smm then
  return
end
vim.g.loaded_smm = 1

--- Only load if Neovim version is compatible
if vim.fn.has 'nvim-0.8' == 0 then
  error 'SMM.nvim requires Neovim 0.8+'
end

-- Create the main user command for your plugin
vim.api.nvim_create_user_command('Spotify', function(opts)
  -- Lazy load the plugin only when the command is first used
  local plugin = require 'smm'

  if not require('smm.config').get().initialized then
    plugin.setup()
  end
end, {
  desc = 'Main command for SMM.nvim',
  nargs = '*',
  complete = function(arg_elad, cmd_line, cursor_pos)
    return {}
  end,
})
