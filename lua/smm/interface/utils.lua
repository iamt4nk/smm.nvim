local M = {}

---@param lines string[]
---@param top integer
---@param right integer
---@param bottom integer
---@param left integer
---@return string[]
function M.pad_lines(lines, top, right, bottom, left)
  local padded_lines = {}

  for _ = 1, top do
    padded_lines:insert ''
  end

  for _, line in ipairs(lines) do
    padded_lines:insert(string.rep(' ', left) .. line .. string.rep(' ', right))
  end

  for _ = 1, bottom do
    padded_lines:insert ''
  end

  return padded_lines
end

---@param ms integer
---@return string
function M.convert_ms_to_timestamp(ms)
  local total_seconds = math.floor(ms / 1000)
  local minutes = math.floor(total_seconds / 60)
  local seconds = total_seconds % 60
  return string.format('%d:%02d', minutes, seconds)
end

return M
