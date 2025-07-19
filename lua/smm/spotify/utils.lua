local M = {}

---@return string
function M.get_spotify_state_path()
  return vim.fn.stdpath 'state' .. '/spotify'
end

return M
