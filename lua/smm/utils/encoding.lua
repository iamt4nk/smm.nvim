local logger = require 'smm.utils.logger'

local M = {}

---@param query_table table
---@return string
function M.encode_table_as_query(query_table)
  logger.debug 'Encoding table as query string'

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
    local query_string = table.concat(query_parts, '&')
    logger.debug('Finished encoding table as query string: %s', query_string)
    return query_string
  end
end

---@param json_table table
---@return string
function M.encode_table_as_json(json_table)
  local ok, json_string = pcall(vim.json.encode, json_table)
  if not ok then
    logger.error 'Unable to encode table as JSON'
  end

  return json_string
end

return M
