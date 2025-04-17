local utils = require 'smm.ui.utils'

local M = {}

---@type integer|nil
local buf = nil

---@type integer|nil
local win = nil

--- Shows a centered notification window with a message
---@param title string Window title
---@param lines table List of lines to display
---@param opts table|nil Optional Configuration parameters
function M.show(title, lines, opts)
  opts = opts or {}

  vim.schedule(function()
    --- Calculate window dimensions
    local width = opts.width or 60
    local height = #lines

    --- Calculate center position
    local win_height = vim.o.lines
    local win_width = vim.o.columns
    local row = math.floor((win_height - height) / 2) - 2
    local col = math.floor((win_width - width) / 2)

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].buftype = 'nofile'
      vim.bo[buf].bufhidden = 'wipe'
      vim.bo[buf].swapfile = false
      vim.bo[buf].modifiable = false
    end

    -- Set up window options
    local window_opts = {
      relative = 'editor',
      width = width,
      height = height,
      col = col,
      row = row,
      anchor = 'NW',
      style = 'minimal',
      border = 'rounded',
      title = title and (' ' .. title .. ' ') or nil,
      title_pos = 'center',
    }

    -- Create window if not exist
    vim.bo[buf].modifiable = true
    if not win or not vim.api.nvim_win_is_valid(win) then
      win = vim.api.nvim_open_win(buf, true, window_opts)

      -- Set window options
      vim.wo[win].winblend = opts.winblend or 0
      vim.wo[win].wrap = true
      vim.wo[win].cursorline = false

      -- Add keymaps to close notification
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua require("smm.ui.notification").close()<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':lua require("smm.ui.notification").close()<CR>', { noremap = true, silent = true })
    end

    -- Add lines to buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.bo[buf].modifiable = false
  end)
end

--- Closes notification window
function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
  end

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
    buf = nil
  end
end

--- Shows notification that certain features are disabled for free users
---@param padding table|nil Optional table to specify padding
---@param callback function|nil Optional callback function to execute when notification is closed
function M.show_free_user_notice(padding, callback)
  local lines = {
    'Free Spotify Account Detected',
    '',
    'Due to Spotify API limitations, free accounts cannot:',
    '',
    '• Start or stop track playback',
    '• Skip to the next/previous track',
    '• Seek to a position in a track',
    '• Modify the queue',
    '',
    'Track information display will still work normally.',
    '',
    'To use these features, please upgrade to Spotify Premium.',
  }

  if padding then
    lines = utils.add_window_padding(lines, padding.top, padding.right, padding.bottom, padding.left)
  end

  if callback then
    local augroup = vim.api.nvim_create_augroup('SMMNotificationCallback', { clear = true })
    vim.api.nvim_create_autocmd('BufWinLeave', {
      group = augroup,
      buffer = buf,
      callback = function()
        callback()
        vim.api.nvim_del_augroup_by_id(augroup)
      end,
      once = true,
    })
  end

  M.show('Spotify Music Manager', lines, nil)
end

return M
