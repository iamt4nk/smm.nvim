local logger = require 'smm.utils.logger'
local config = require 'smm.config'
local utils = require 'smm.models.ui.utils'

---@alias SMM_WindowPos
--- | 'TopLeft'
--- | 'TopRight'
--- | 'BottomLeft'
--- | 'BottomRight'
--- | 'Center'

---@class SMM_UI_Window
---@field win integer
---@field buf integer
---@field win_opts vim.api.keyset.win_config
---@field win_pos SMM_WindowPos
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
  logger.info 'Creating new window'

  local instance = {}

  setmetatable(instance, Window)

  title = instance:__create_title(title)

  local opts = utils.create_opts(width, height, title, position)

  local buf = Window:__create_buffer()
  local win = Window:__create_window(buf, opts)

  lines = utils.pad_lines(lines, 1, 2, 1, 2)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  instance = {
    win = win,
    buf = buf,
    win_opts = opts,
    win_pos = position,
    title = title,
    lines = lines,
    is_showing = true,
    width = width,
    height = height,
  }

  setmetatable(instance, Window)
  return instance
end

---@param title string
function Window:__create_title(title)
  if config.get().icons == true then
    title = '  ' .. title
  end
  return title
end

---@return integer
function Window:__create_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false

  return buf
end

---@param buf integer
---@param opts vim.api.keyset.win_config
---@return integer
function Window:__create_window(buf, opts)
  local win = vim.api.nvim_open_win(buf, false, opts)
  vim.wo[win].wrap = true

  vim.api.nvim_set_hl(0, 'SpotifyGreen', { fg = '#1ED760' })
  vim.wo[win].winhighlight = 'FloatTitle:SpotifyGreen,FloatBorder:SpotifyGreen'

  return win
end

---@param opts vim.api.keyset.win_config
function Window:__set_opts(opts)
  self.win_opts = vim.tbl_deep_extend('force', self.win_opts, opts)
end

---@param lines string[]
function Window:update_window(lines)
  if not self.win or not self.buf then
    logger.error 'Unable to update window - Does not exist'
    return
  end

  local height = #lines + 2

  lines = utils.pad_lines(lines, 1, 2, 1, 2)

  self.win_opts['height'] = height

  self:__set_opts(utils.get_window_pos(self.width, height, self.win_pos))

  vim.api.nvim_win_set_config(self.win, self.win_opts)
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
