local M = {}

-- Get the path to store the token file
---@return string
local function get_token_path()
  local state_dir = vim.fn.stdpath 'state'
  local smm_dir = state_dir .. '/smm'

  -- Ensure the directory exists
  vim.fn.mkdir(smm_dir, 'p')

  return smm_dir .. '/refresh_token'
end

---@param refresh_token string
---@return boolean
function M.save_refresh_token(refresh_token)
  if not refresh_token then
    return false
  end

  local file = io.open(get_token_path(), 'w')
  if not file then
    vim.notify('Failed to save refresh token', vim.log.levels.ERROR)
    return false
  end

  file:write(refresh_token)
  file:close()
  return true
end

-- Load the refresh token from file
---@return string|nil
function M.load_refresh_token()
  local file = io.open(get_token_path(), 'r')
  if not file then
    return nil
  end

  local refresh_token = file:read '*all'
  file:close()

  if refresh_token and #refresh_token > 0 then
    return refresh_token
  end
  return nil
end

-- Clear the stored refresh token
---@return nil
function M.clear_refresh_token()
  local path = get_token_path()
  os.remove(path)
end

return M
