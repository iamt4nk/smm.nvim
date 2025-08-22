local logger = require 'smm.utils.logger'
local config = require 'smm.config'

---@alias SMM_WindowPos
--- | 'TopLeft'
--- | 'TopRight'
--- | 'BottomLeft'
--- | 'BottomRight'
--- | 'Center'

---@param lines string[]
---@param top integer
---@param right integer
---@param bottom integer
---@param left integer
---@return string[]
local function pad_lines(lines, top, right, bottom, left)
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

---@class SMM_UI_Window
---@field win integer
---@field buf integer
---@field win_opts vim.api.keyset.win_config
---@field title string
---@field lines string[]
---@field is_showing boolean
---@field width integer
---@field height integer
local Window = {}
Window.__index = Window

---@param title string
---@param lines string[]
---@param width integer
---@param height integer
---@param position SMM_WindowPos
function Window:new(title, lines, width, height, position)
  lines = pad_lines(lines, 1, 2, 1, 2)
  local buf = nil
  local win = nil

  if config.get().icons == true then
    title = '  ' .. title
  end

  ---@type vim.api.keyset.win_config
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    anchor = 'NW',
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'left',
  }

  self:set_window_pos(width, height, position)

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile = false
  end

  if not win or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_open_win(buf, false, win_opts)
    vim.wo[win].wrap = true
  else
    vim.api.nvim_win_set_config(win, win_opts)
  end

  vim.api.nvim_set_hl(0, 'SpotifyGreen', { fg = '#1ED760' })
  vim.wo[win].winhighlight = 'FloatTitle:SpotifyGreen,FloatBorder:SpotifyGreen'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local instance = {
    win = win,
    buf = buf,
    win_opts = win_opts,
    title = title,
    lines = lines,
    is_showing = true,
    width = width,
    height = height,
  }

  setmetatable(instance, Window)
  return instance
end

---@param width integer
---@param height integer
---@param pos SMM_WindowPos
function Window:set_window_pos(width, height, pos)
  local win_height = vim.o.lines
  local win_width = vim.o.columns

  if pos == 'TopLeft' then
    self.win_opts['col'] = 2
    self.win_opts['row'] = 1
  elseif pos == 'TopRight' then
    self.win_opts['col'] = win_width - width - 2
    self.win_opts['row'] = 1
  elseif pos == 'BottomLeft' then
    self.win_opts['col'] = 2
    self.win_opts['row'] = win_height - height - 4
  elseif pos == 'BottomRight' then
    self.win_opts['col'] = win_width - width - 2
    self.win_opts['row'] = win_height - height - 4
  elseif pos == 'Center' then
    self.win_opts['col'] = math.floor((win_width - width) / 2)
    self.win_opts['row'] = math.floor((win_height - height) / 2)
  end
end

---@param lines string[]
function Window:update_window(lines)
  if not self.win or not self.buf then
    logger.error 'Unable to update window - Does not exist'
    return
  end

  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
end

function Window:close()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    self.is_showing = false
    vim.api.nvim_win_close(self.win, true)
    self.win_opts = {}
    self.win = nil
  end

  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_delete(self.buf, { force = true })
    self.buf = nil
  end
end

local M = {}

M.Window = Window

return M
