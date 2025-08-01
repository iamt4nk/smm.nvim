local logger = require 'smm.utils.logger'
local M = {}

function M.open_browser(url)
  local escaped_url = vim.fn.shellescape(url)

  logger.debug 'Opening browser'
  local platform = vim.loop.os_uname().sysname
  logger.debug('Platform: %s', platform)

  local uname = vim.fn.system 'uname -r'
  logger.debug('Uname: %s', uname)
  local is_wsl = uname:lower():match 'microsoft' ~= nil or uname:lower():match 'wsl' ~= nil
  logger.debug('WSL: %s', tostring(is_wsl))

  if is_wsl then
    logger.debug 'Opening powershell process and spawning browser'
    vim.fn.system { 'powershell.exe', '/c', 'start', escaped_url }
    return
  end

  if platform == 'Darwin' then
    vim.fn.system { 'open', escaped_url }
    return
  end

  if platform == 'Linux' then
    vim.fn.system { 'xdg-open', escaped_url }
    return
  end

  if platform == 'Windows' then
    vim.fn.system { 'cmd', '/c', 'start', escaped_url }
    return
  end
end

return M
