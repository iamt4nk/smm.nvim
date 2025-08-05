local M = {}

---@return string
function M.get_spotify_state_path()
  return vim.fn.stdpath 'state' .. '/spotify'
end

---@param ms integer milliseconds to wait
---@param callback function Function to call after the delay
function M.sleep_async(ms, callback)
  vim.defer_fn(callback, ms)
end

return M
