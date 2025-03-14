local M = {}

function M.open_browser(url)
  local platform = vim.loop.os_uname().sysname

  local uname = vim.fn.system 'uname -r'
  local is_wsl = uname:lower():match 'microsoft' ~= nil or uname:lower():match 'wsl' ~= nil

  if is_wsl then
    vim.fn.system { 'powershell.exe', '/c', 'start', url }
    return
  end

  if platform == 'Darwin' then
    vim.fn.system { 'open', url }
    return
  end

  if platform == 'Linux' then
    vim.fn.system { 'xdg-open', url }
    return
  end

  if platform == 'Windows' then
    vim.fn.system { 'cmd', '/c', 'start', url }
    return
  end
end

return M
