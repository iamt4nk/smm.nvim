-- Prevent the plugin from loading twice
if vim.g.loaded_smm then
  return
end
vim.g.loaded_smm = 1

--- Only load if Neovim version is compatible
if vim.fn.has 'nvim-0.8' == 0 then
  error 'SMM.nvim requires Neovim 0.8+'
end

require('smm').setup()
