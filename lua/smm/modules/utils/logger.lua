local config = require 'smm.config'

local M = {}

local LOG_LEVELS = {
  ERROR = { level = 1, hl = 'ErrorMsg', prefix = '[ERROR]' },
  WARN = { level = 2, hl = 'WarningMsg', prefix = '[WARN]' },
  INFO = { level = 3, hl = 'None', prefix = '[INFO]' },
  DEBUG = { level = 4, hl = 'Comment', prefix = '[DEBUG]' },
}

-- Internal logging function
local function log(level, message, ...)
  local log_config = LOG_LEVELS[level]
  if not log_config then
    return
  end

  -- Always show ERROR and WARN, only show INFO/DEBUG in debug mode
  local should_log = log_config.level <= 2 or config.get_value 'debug'

  if should_log then
    local formatted_msg = string.format(message, ...)
    local full_message = string.format('%s smm.nvim %s', log_config.prefix, formatted_msg)

    vim.schedule(function()
      vim.notify(full_message, vim.log.levels[level], { title = 'SMM.nvim' })
    end)
  end
end

-- Public logging functions

function M.error(message, ...)
  log('ERROR', message, ...)
end

function M.warn(message, ...)
  log('WARN', message, ...)
end

function M.info(message, ...)
  log('INFO', message, ...)
end

function M.debug(message, ...)
  log('DEBUG', message, ...)
end

return M
