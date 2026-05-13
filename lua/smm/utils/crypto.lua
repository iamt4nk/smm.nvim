local logger = require 'smm.utils.logger'

local M = {}

math.randomseed(os.time() + vim.loop.getpid())

local function get_machine_id()
  for _, path in ipairs { '/etc/machine-id', '/var/lib/dbus/machine-id' } do
    local f = io.open(path, 'r')
    if f then
      local id = f:read '*all'
      f:close()
      id = id:gsub('%s+', '')
      if #id > 0 then
        return id
      end
    end
  end
  if vim.uv.os_uname().sysname == 'Darwin' then
    local result = vim.fn.system 'ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null'
    local uuid = result:match '"IOPlatformUUID" = "([^"]+)"'
    if uuid then
      return uuid
    end
  end
  return vim.fn.sha256(vim.fn.expand '~' .. (vim.uv.os_uname().sysname or 'unknown'))
end

-- Returns a SHA-256 hex string derived from machine-specific data, used as AES-256 passphrase.
function M.derive_encryption_key()
  local machine_id = get_machine_id()
  local home = vim.fn.expand '~'
  return vim.fn.sha256('smm.nvim:v1:' .. machine_id .. ':' .. home)
end

local function write_restricted_temp(content, binary_mode)
  local path = vim.fn.tempname()
  -- Create the file with mode 600 before writing sensitive content
  vim.fn.system { 'install', '-m', '600', '/dev/null', path }
  local f = io.open(path, binary_mode and 'wb' or 'w')
  if not f then
    return nil
  end
  f:write(content)
  f:close()
  return path
end

---@param plaintext string
---@param key string hex-encoded 256-bit key from derive_encryption_key()
---@return string|nil base64-encoded ciphertext (salt+IV embedded by openssl)
function M.encrypt_aes256(plaintext, key)
  local input_path = write_restricted_temp(plaintext, true)
  if not input_path then
    logger.error 'encrypt_aes256: cannot create plaintext temp file'
    return nil
  end

  local key_path = write_restricted_temp(key, false)
  if not key_path then
    os.remove(input_path)
    logger.error 'encrypt_aes256: cannot create key temp file'
    return nil
  end

  local output_path = vim.fn.tempname()
  vim.fn.system {
    'openssl', 'enc', '-aes-256-cbc', '-pbkdf2',
    '-pass', 'file:' .. key_path,
    '-in', input_path,
    '-out', output_path,
    '-base64', '-A',
  }

  os.remove(input_path)
  os.remove(key_path)

  if vim.v.shell_error ~= 0 then
    logger.error 'encrypt_aes256: openssl encryption failed'
    os.remove(output_path)
    return nil
  end

  local out = io.open(output_path, 'r')
  os.remove(output_path)
  if not out then
    logger.error 'encrypt_aes256: cannot read encrypted output'
    return nil
  end

  local ciphertext = out:read '*all'
  out:close()
  return ciphertext:gsub('%s+', '')
end

---@param ciphertext string base64-encoded ciphertext produced by encrypt_aes256()
---@param key string hex-encoded 256-bit key from derive_encryption_key()
---@return string|nil plaintext
function M.decrypt_aes256(ciphertext, key)
  local input_path = write_restricted_temp(ciphertext, false)
  if not input_path then
    logger.error 'decrypt_aes256: cannot create ciphertext temp file'
    return nil
  end

  local key_path = write_restricted_temp(key, false)
  if not key_path then
    os.remove(input_path)
    logger.error 'decrypt_aes256: cannot create key temp file'
    return nil
  end

  local output_path = vim.fn.tempname()
  vim.fn.system {
    'openssl', 'enc', '-d', '-aes-256-cbc', '-pbkdf2',
    '-pass', 'file:' .. key_path,
    '-in', input_path,
    '-out', output_path,
    '-base64', '-A',
  }

  os.remove(input_path)
  os.remove(key_path)

  if vim.v.shell_error ~= 0 then
    logger.error 'decrypt_aes256: openssl decryption failed'
    os.remove(output_path)
    return nil
  end

  local out = io.open(output_path, 'rb')
  os.remove(output_path)
  if not out then
    logger.error 'decrypt_aes256: cannot read decrypted output'
    return nil
  end

  local plaintext = out:read '*all'
  out:close()
  return plaintext
end

---@param length integer
---@return string
function M.generate_random_string(length)
  local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local random_string = ''

  for _ = 1, length do
    local random_index = math.random(1, #charset)
    local character = string.sub(charset, random_index, random_index)
    random_string = random_string .. character
  end

  logger.debug('Random string generated: %s', random_string)

  return random_string
end

---@param data string
---@return string
function M.get_sha256_sum(data)
  logger.debug('Getting SHA256 hash of: %s', data)
  local hash_hex = vim.fn.sha256(data)

  -- Convert hex string to bytes
  local hash_bytes = {}
  for i = 1, #hash_hex, 2 do
    local byte = tonumber(hash_hex:sub(i, i + 1), 16)
    table.insert(hash_bytes, string.char(byte))
  end

  local hash_string = table.concat(hash_bytes)
  return hash_string
end

---@param data string
---@return string
function M.get_base64(data)
  local base64_data = vim.base64.encode(data)
  base64_data = string.gsub(base64_data, '%=', '')
  base64_data = string.gsub(base64_data, '%+', '-')
  base64_data = string.gsub(base64_data, '%/', '_')

  logger.debug('Base64 representation of data: %s', base64_data)
  return base64_data
end

return M
