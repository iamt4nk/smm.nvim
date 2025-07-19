local M = {}

local LOG_LEVELS = {
  ERROR = { level = 1, hl = 'ErrorMsg', prefix = '[ERROR]' },
  WARN = { level = 2, hl = 'WarningMsg', prefix = '[WARN]' },
  INFO = { level = 3, hl = 'None', prefix = '[INFO]' },
  DEBUG = { level = 4, hl = 'Comment', prefix = '[DEBUG]' },
}

local debug_level = false
local log_file = ''
local enabled = true

-- Internal logging function
---@param level integer
---@param message string
---@param ... any
local function log(level, message, ...)
  local log_config = LOG_LEVELS[level]
  if not log_config or not enabled then
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

    if not log_file or log_file == '' then
      if level == 1 then
        error(full_message)
      end
      vim.schedule(function()
        vim.notify(full_message, vim.log.levels[level], { title = 'SMM.nvim' })
      end)
    else
      local file = io.open(log_file, 'a+')
      if not file then
        error 'Failed to open log file'
      end
      file:write(full_message .. '\n')
      file:close()
    end
  end
end

-- Public logging functions

---@param log_opts table
function M.setup(log_opts)
  if log_opts and log_opts.debug == true then
    debug_level = true
  end

  if log_opts and log_opts.file ~= '' then
    log_file = log_opts.file
  end
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
