local logger = require 'smm.utils.logger'

local function get_spotify_state_path()
  return vim.fn.stdpath 'state' .. '/spotify'
end

local M = {}

---@param refresh_token string
---@return boolean
function M.save_refresh_token(refresh_token)
  local spotify_dir = get_spotify_state_path()
  vim.fn.mkdir(spotify_dir, 'p')

  local refresh_token_path = spotify_dir .. '/refresh_token'
  local file = io.open(refresh_token_path, 'w')

  if not file then
    logger.error('Unable to open file: %s for reading', refresh_token_path)
    return false
  end

  file:write(refresh_token)
  file:close()
  return true
end

---@return string|nil
function M.load_refresh_token()
  local refresh_token_path = get_spotify_state_path() .. '/refresh_token'
  logger.debug('Refresh Token Path: %s', refresh_token_path)
  local file = io.open(refresh_token_path, 'r')
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

function M.delete_refresh_token()
  local refresh_token_path = get_spotify_state_path() .. '/refresh_token'
  os.remove(refresh_token_path)
end

---@return string
function M.get_spotify_state_path()
  return vim.fn.stdpath 'state' .. '/spotify'
end

return M
