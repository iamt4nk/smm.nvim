local logger = require 'smm.utils.logger'

local M = {}

---@param path string
---@param data string
---@return boolean
function M.write_data(path, data)
  local file = io.open(get_token_path(), 'w')
  if not file then
    logger.debug('Failed to open %s to save data.', path)
    return false
  end

  file:write(data)
  file:close()
  return true
end

---@param path string
---@return string|nil
function M.read_data(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end

  local data = file:read '*all'
  file:close()

  if data and #data > 0 then
    return data
  end
  return nil
end

---@param

return M
