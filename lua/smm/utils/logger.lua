local M = {}

local LOG_LEVELS = {
  ERROR = { level = 1, hl = 'ErrorMsg', prefix = '[ERROR]' },
  WARN = { level = 2, hl = 'WarningMsg', prefix = '[WARN]' },
  INFO = { level = 3, hl = 'None', prefix = '[INFO]' },
  DEBUG = { level = 4, hl = 'Comment', prefix = '[DEBUG]' },
}

local debug_level = false

-- Internal logging function
local function log(level, message, ...)
  local log_config = LOG_LEVELS[level]
  if not log_config then
    return
  end

  -- Always show ERROR and WARN, only show INFO/DEBUG in debug mode
  local should_log = log_config.level <= 3 or debug_level

  if should_log then
    local formatted_msg = ''
    if ... then
      formatted_msg = string.format(message, ...)
    else
      formatted_msg = message
    end
    local full_message = string.format('%s smm.nvim %s', log_config.prefix, formatted_msg)

    vim.schedule(function()
      vim.notify(full_message, vim.log.levels[level], { title = 'SMM.nvim' })
    end)
  end
end

-- Public logging functions

---@param log_opts table
function M.setup(log_opts)
  if log_opts and log_opts.debug == true then
    debug_level = true
  end
end

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
