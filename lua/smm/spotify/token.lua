local utils = require 'smm.spotify.utils'
local logger = require 'smm.utils.logger'

local M = {}

---@param refresh_token string
---@return boolean
function M.save_refresh_token(refresh_token)
  logger.info 'SMM: Saving refresh token to disk'
  local spotify_dir = utils.get_spotify_state_path()
  vim.fn.mkdir(spotify_dir, 'p')

  local refresh_token_path = spotify_dir .. '/refresh_token'
  local file = io.open(refresh_token_path, 'w')

  if not file then
    logger.error('Unable to open file: %s for reading', refresh_token_path)
  end

  file:write(refresh_token)
  file:close()
  return true
end

---@return string|nil
function M.load_refresh_token()
  local refresh_token_path = utils.get_spotify_state_path() .. '/refresh_token'
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
  local refresh_token_path = utils.get_spotify_state_path() .. '/refresh_token'
  os.remove(refresh_token_path)
end

return M
