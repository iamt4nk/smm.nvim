local M = {}

local LOG_LEVELS = {
  DEBUG = { level = 1, hl = 'Comment', prefix = '[DEBUG]' },
  INFO = { level = 2, hl = 'None', prefix = '[INFO]' },
  WARN = { level = 3, hl = 'WarningMsg', prefix = '[WARN]' },
  ERROR = { level = 4, hl = 'ErrorMsg', prefix = '[ERROR]' },
}

local debug_level = false
local log_file = ''
local enabled = true

-- Internal logging function
---@param level string
---@param message string
---@param ... any
local function log(level, message, ...)
  local log_config = LOG_LEVELS[level]
  if not log_config or not enabled then
    return
  end

  -- Always show INFO, ERROR, and WARN, only show DEBUG in debug mode
  local should_log = log_config.level > 1 or debug_level

  if not should_log then
    return
  end

  local formatted_msg = ''
  if ... then
    formatted_msg = string.format(message, ...)
  else
    formatted_msg = message
  end
  local full_message = string.format('%s smm.nvim %s', log_config.prefix, formatted_msg)

  if not log_file or log_file == '' then
    if level == 4 then
      error(full_message)
    end
    print(full_message)
  else
    local file = io.open(log_file, 'a+')
    if not file then
      error 'Failed to open log file'
    end
    file:write(full_message .. '\n')
    file:close()
  end
end

-- Public logging functions
---@param debug boolean
---@param file? string
function M.setup(debug, file)
  debug_level = (debug ~= false)
  log_file = file or ''
end

---@param message string
---@param ... any
function M.error(message, ...)
  log('ERROR', message, ...)
end

---@param message string
---@param ... any
function M.warn(message, ...)
  log('WARN', message, ...)
end

---@param message string
---@param ... any
function M.info(message, ...)
  log('INFO', message, ...)
end

---@param message string
---@param ... any
function M.debug(message, ...)
  log('DEBUG', message, ...)
end

return M
