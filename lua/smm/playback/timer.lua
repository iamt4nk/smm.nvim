local logger = require 'smm.utils.logger'
local config = require 'smm.playback.config'

---@class SMM_PlaybackTimer
---@field current_pos integer The current position in milliseconds
---@field update_interval integer How often the timer should update
---@field is_updating boolean Whether or not the timer should send updates.
---@field update fun(current_pos: integer|nil) Where to send the updated timestamp
---@field sync_interval integer time in ms between each sync
---@field is_syncing boolean whether we are currently syncing. Important so we don't issue multiple syncs at once.
---@field sync fun(callback: fun(sync_data: SyncData)) Method to run, provided by the caller to sync with Spotify servers
---@field last_sync_time integer When the last sync time occurred
---@field next_sync_override integer In case a sync needs to occur sooner
---@field consecutive_failures integer For tracking consecutive failures
---@field backoff_multiplier integer Multiplier for backoff in case too many 500s
---@field timer uv_timer_t The underlying timer object

local M = {}

---@param opts table
---@return SMM_PlaybackTimer
function M.create_timer(opts)
  return {
    current_pos = 0,
    update_interval = config.get().timer_update_interval,
    is_updating = false,
    update = opts.update and opts.update or nil,
    sync_interval = config.get().timer_sync_interval,
    is_syncing = false,
    sync = opts.sync and opts.sync or nil,
    last_sync_time = 0,
    timer = vim.uv.new_timer(),
    next_sync_override = nil,
    consecutive_failures = 0,
    backoff_multiplier = 1,
  }
end

---@param timer SMM_PlaybackTimer
function M.start(timer)
  timer.timer:start(
    0,
    timer.update_interval,
    vim.schedule_wrap(function()
      local override_sync = false
      if timer.is_updating then
        timer.current_pos = timer.current_pos + timer.update_interval
        if timer.update then
          override_sync = timer.update(timer.current_pos)
        end
      end

      if not timer.is_syncing then
        local current_time = vim.loop.now()
        if override_sync or (current_time - timer.last_sync_time >= timer.sync_interval) then
          if timer.sync then
            timer.is_syncing = true
            timer.last_sync_time = current_time
            timer.sync(function(sync_data)
              if sync_data then
                timer.current_pos = sync_data.current_pos
                timer.is_updating = sync_data.is_playing
                timer.update(timer.current_pos)
              else
                M.pause(timer)
                timer.update(nil)
              end
            end)
          end
          timer.is_syncing = false
        end
      end
    end)
  )
  logger.debug('Started timer: %s', vim.inspect(timer.timer))
  logger.debug(debug.traceback())
end

---@param timer SMM_PlaybackTimer
function M.pause(timer)
  timer.is_updating = false
end

---@param timer SMM_PlaybackTimer
function M.resume(timer)
  timer.is_updating = true
end

---@param timer SMM_PlaybackTimer
function M.reset(timer)
  timer.current_pos = 0
end

---@param timer SMM_PlaybackTimer
function M.close(timer)
  logger.debug 'Pausing timer'
  M.pause(timer)
  logger.debug 'Resetting timer'
  M.reset(timer)
  logger.debug 'Closing underlying timer object'
  timer.timer:close()
  logger.debug('Closed timer: %s', vim.inspect(timer.timer))
end

return M
