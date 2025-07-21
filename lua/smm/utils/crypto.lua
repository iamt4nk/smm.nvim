local logger = require 'smm.utils.logger'

local M = {}

math.randomseed(os.time() + vim.loop.getpid())

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
