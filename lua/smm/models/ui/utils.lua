local M = {}

---@param width integer
---@param height integer
---@param pos SMM_WindowPos
---@return table
function M.get_window_pos(width, height, pos)
  local win_height = vim.o.lines
  local win_width = vim.o.columns

  ---@type vim.api.keyset.win_config
  local win_opts = {}

  if pos == 'TopLeft' then
    win_opts['col'] = 2
    win_opts['row'] = 1
  elseif pos == 'TopRight' then
    win_opts['col'] = win_width - width - 2
    win_opts['row'] = 1
  elseif pos == 'BottomLeft' then
    win_opts['col'] = 2
    win_opts['row'] = win_height - height - 4
  elseif pos == 'BottomRight' then
    win_opts['col'] = win_width - width - 2
    win_opts['row'] = win_height - height - 4
  elseif pos == 'Center' then
    win_opts['col'] = math.floor((win_width - width) / 2)
    win_opts['row'] = math.floor((win_height - height) / 2)
  end

  return win_opts
end

---@param lines string[]
---@param top integer
---@param right integer
---@param bottom integer
---@param left integer
---@return string[]
function M.pad_lines(lines, top, right, bottom, left)
  local padded_lines = {}

  for _ = 1, top do
    table.insert(padded_lines, '')
  end

  for _, line in ipairs(lines) do
    table.insert(padded_lines, string.rep(' ', left) .. line .. string.rep(' ', right))
  end

  for _ = 1, bottom do
    table.insert(padded_lines, '')
  end

  return padded_lines
end

---@param width integer
---@param height integer
---@param title string
---@param position SMM_WindowPos
---@return vim.api.keyset.win_config
function M.create_opts(width, height, title, position)
  local pos = M.get_window_pos(width, height, position)

  ---@type vim.api.keyset.win_config
  local win_opts = {
    width = width,
    height = height,
    col = pos.col,
    row = pos.row,
    relative = 'editor',
    anchor = 'NW',
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'left',
  }

  return win_opts
end

return M
