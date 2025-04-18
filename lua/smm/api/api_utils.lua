local M = {}

---@param query_table table
---@return string
function M.encode_query_params(query_table)
  if not query_table then
    return ''
  end

  local query_parts = {}
  for k, v in pairs(query_table) do
    table.insert(query_parts, k .. '=' .. vim.uri_encode(tostring(v)))
  end

  if #query_parts == 0 then
    return ''
  else
    return '?' .. table.concat(query_parts, '&')
  end
end

function M.stringify_table_as_kv(query_table)
  local query_string = ''
  for key, value in pairs(query_table) do
    if #query_string > 0 then
      query_string = query_string .. '&'
    end
    query_string = query_string .. key .. '=' .. value
  end
  return query_string
end

function M.stringify_table_as_json(json_table)
  local json_string = vim.json.encode(json_table)
  return json_string
end

function M.generate_random_string(length)
  local character_set = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local random_string = ''
  for _ = 1, length do
    local random_index = math.random(1, #character_set)
    local character = string.sub(character_set, random_index, random_index)
    random_string = random_string .. character
  end
  return random_string
end

function M.get_sha256_sum_base64(data)
  local hash_hex = vim.fn.sha256(data)

  -- Convert hex string to bytes
  local hash_bytes = {}
  for i = 1, #hash_hex, 2 do
    local byte = tonumber(hash_hex:sub(i, i + 1), 16)
    table.insert(hash_bytes, string.char(byte))
  end
  local raw_bytes = table.concat(hash_bytes)

  local base64_data = vim.base64.encode(raw_bytes)
  base64_data = string.gsub(base64_data, '%=', '')
  base64_data = string.gsub(base64_data, '%+', '-')
  base64_data = string.gsub(base64_data, '%/', '_')
  return base64_data
end

return M
