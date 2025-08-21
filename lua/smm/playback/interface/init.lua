local logger = require 'smm.utils.logger'
local config = require 'smm.playback.interface.config'
local utils = require 'smm.playback.interface.utils'

local M = {}

-- Local variables
---@type integer
local PLAYBACK_WIDTH

---@type string
local PLAYBACK_POS

-- Setup function for configuration

function M.setup(user_config)
  config.setup(user_config or {})

  PLAYBACK_WIDTH = config.get().playback_width
  PLAYBACK_POS = config.get().playback_pos
end

-------------------------------------

---@type boolean
M.is_showing = false

---@type integer|nil
local buf = nil

---@type vim.api.keyset.win_config
local win_opts = {}

---@type integer|nil
local win = nil

---@param width integer
---@param height integer
local function set_window_pos(width, height)
  local win_height = vim.o.lines
  local win_width = vim.o.columns
  local win_pos = PLAYBACK_POS

  if win_pos == 'TopLeft' then
    win_opts['col'] = 2
    win_opts['row'] = 1
  elseif win_pos == 'TopRight' then
    win_opts['col'] = win_width - width - 2
    win_opts['row'] = 1
  elseif win_pos == 'BottomLeft' then
    win_opts['col'] = 2
    win_opts['row'] = win_height - height - 4
  elseif win_pos == 'BottomRight' then
    win_opts['col'] = win_width - width - 2
    win_opts['row'] = win_height - height - 4
  end
end

function M.create_window()
  vim.schedule(function()
    local lines = { 'Loading Spotify Information...' }
    lines = utils.pad_lines(lines, 1, 2, 1, 2)

    local width = 40
    local height = #lines

    local title = ' Spotify '

    if config.get().icons == true then
      title = '  ' .. title
    end

    win_opts = {
      relative = 'editor',
      width = width,
      height = height,
      anchor = 'NW',
      style = 'minimal',
      border = 'rounded',
      title = title,
      title_pos = 'left',
    }

    set_window_pos(width, height)

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].buftype = 'nofile'
      vim.bo[buf].bufhidden = 'hide'
      vim.bo[buf].swapfile = false
    end

    if not win or not vim.api.nvim_win_is_valid(win) then
      M.is_showing = true
      win = vim.api.nvim_open_win(buf, false, win_opts)

      vim.wo[win].wrap = false
    else
      vim.api.nvim_win_set_config(win, win_opts)
    end

    vim.api.nvim_set_hl(0, 'SpotifyGreen', { fg = '#1ED760' })
    vim.wo[win].winhighlight = 'FloatTitle:SpotifyGreen,FloatBorder:SpotifyGreen'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

---@param playback_info SMM_PlaybackInfo|nil
function M.update_window(playback_info)
  vim.schedule(function()
    if not win or not buf then
      logger.error 'Unable to update playback window - Does not exist'
      return
    end
    local lines = utils.format_playback_lines(playback_info)

    local width = PLAYBACK_WIDTH
    local height = #lines

    win_opts['width'] = width
    win_opts['height'] = height

    set_window_pos(width, height)

    vim.api.nvim_win_set_config(win, win_opts)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

function M.remove_window()
  if win and vim.api.nvim_win_is_valid(win) then
    M.is_showing = false
    vim.api.nvim_win_close(win, true)
    win_opts = {}
    win = nil
  end

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
    buf = nil
  end
end

return M
