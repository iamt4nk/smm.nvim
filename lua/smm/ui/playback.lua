local utils = require 'smm.ui.utils'

local M = {}

---@type integer|nil
local buf = nil

---@type integer|nil
M.win = nil

---@type WindowInfo|nil
M.info = nil

function M.show_window()
  local lines = { 'Loading Spotify playback information...' }
  M.update_window(lines)
end

--- Updates the window information
---@param playback_info WindowInfo|nil
function M.update_window_info(playback_info)
  local window_info = utils.format_playback_info(playback_info)
  M.update_window(window_info)
end

--- Sets the lines in the window
---@param lines table
function M.update_window(lines)
  vim.schedule(function()
    lines = utils.add_window_padding(lines, 1, 2, 1, 2)

    -- Setup window
    local width = 40
    local height = #lines

    local win_height = vim.o.lines
    local win_width = vim.o.columns

    -- Define a highlight group for the Spotify green border
    vim.api.nvim_set_hl(0, 'SpotifyGreen', { fg = '#1ED760' })

    local opts = {
      relative = 'editor',
      width = width,
      height = height,
      col = win_width - width - 2,
      row = win_height - height - 4,
      anchor = 'NW',
      style = 'minimal',
      border = 'rounded',
      title = ' Spotify ',
      title_pos = 'left',
    }

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].buftype = 'nofile'
      vim.bo[buf].bufhidden = 'hide'
      vim.bo[buf].swapfile = false
    end

    if not M.win or not vim.api.nvim_win_is_valid(M.win) then
      M.win = vim.api.nvim_open_win(buf, false, opts)
      -- Set window options
      vim.wo[M.win].winblend = 15
      vim.wo[M.win].wrap = false
    else
      vim.api.nvim_win_set_config(M.win, opts)
    end

    vim.api.nvim_win_set_option(M.win, 'winhighlight', 'FloatTitle:SpotifyGreen,FloatBorder:SpotifyGreen')

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
end

--- Stops the playback window and removes all underlying resources
function M.close_playback_window()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
  end

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
    buf = nil
  end
end

--- Cleanup
function M.cleanup()
  M.close_playback_window()
  M.info = nil
end

return M
