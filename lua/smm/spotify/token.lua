local logger = require 'smm.utils.logger'
local crypto = require 'smm.utils.crypto'

local ENCRYPTED_PREFIX = 'encrypted:'

local function get_spotify_state_path()
  return vim.fn.stdpath 'state' .. '/spotify'
end

local M = {}

---@param refresh_token string
---@return boolean
function M.save_refresh_token(refresh_token)
  local spotify_dir = get_spotify_state_path()
  vim.fn.mkdir(spotify_dir, 'p')

  local key = crypto.derive_encryption_key()
  local ciphertext = crypto.encrypt_aes256(refresh_token, key)
  if not ciphertext then
    logger.error 'Failed to encrypt refresh token'
    return false
  end

  local refresh_token_path = spotify_dir .. '/refresh_token'
  local file = io.open(refresh_token_path, 'w')
  if not file then
    logger.error('Unable to open file: %s for writing', refresh_token_path)
    return false
  end

  file:write(ENCRYPTED_PREFIX .. ciphertext)
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

  local data = file:read '*all'
  file:close()

  if not data or #data == 0 then
    return nil
  end

  if data:sub(1, #ENCRYPTED_PREFIX) == ENCRYPTED_PREFIX then
    local ciphertext = data:sub(#ENCRYPTED_PREFIX + 1)
    local key = crypto.derive_encryption_key()
    local plaintext = crypto.decrypt_aes256(ciphertext, key)
    if not plaintext or #plaintext == 0 then
      logger.error 'Failed to decrypt refresh token'
      return nil
    end
    return plaintext
  end

  -- Legacy plaintext token: migrate to encrypted storage immediately.
  logger.info 'Migrating plaintext refresh token to encrypted storage'
  if M.save_refresh_token(data) then
    logger.info 'Refresh token migration complete'
  else
    logger.error 'Failed to migrate refresh token to encrypted storage'
  end
  return data
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
