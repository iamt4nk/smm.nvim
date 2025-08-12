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
local Timer = {}
Timer.__index = Timer

---@param opts table
---@return SMM_PlaybackTimer
function Timer:new(opts)
  local instance = {
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

  setmetatable(instance, self)
  return instance
end

function Timer:start()
  self.timer:start(
    0,
    self.update_interval,
    vim.schedule_wrap(function()
      local override_sync = false
      if self.is_updating then
        self.current_pos = self.current_pos + self.update_interval
        if self.update then
          override_sync = self.update(self.current_pos)
        end
      end

      if not self.is_syncing then
        local current_time = vim.loop.now()
        if override_sync or (current_time - self.last_sync_time >= self.sync_interval) then
          if self.sync then
            self.is_syncing = true
            self.last_sync_time = current_time
            self.sync(function(sync_data)
              if sync_data then
                self.current_pos = sync_data.current_pos
                self.is_updating = sync_data.is_playing
                self.update(self.current_pos)
              else
                self:pause()
                self.update(nil)
              end
            end)
          end
          self.is_syncing = false
        end
      end
    end)
  )
  logger.debug('Started timer: %s', vim.inspect(self.timer))
end

function Timer:pause()
  self.is_updating = false
end

function Timer:resume()
  self.is_updating = true
end

function Timer:reset()
  self.current_pos = 0
end

function Timer:close()
  logger.debug 'Pausing timer'
  self:pause()
  logger.debug 'Resetting timer'
  self:reset()
  logger.debug 'Closing underlying timer object'
  self.timer:close()
  logger.debug('Closed timer: %s', vim.inspect(self.timer))
end

local M = {}

M.Timer = Timer

return M
