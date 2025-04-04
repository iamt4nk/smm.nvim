local M = {}

----------------------------------------------------------------
---The rationale behind this module is that we need some timer
---that does not get stopped while the plugin is running. This timer
---helps with multiple use cases:
---1. Keeping track of song timestamp
---2. Keeps in sync from the spotify servers
---3. Due to the timer being able to be controlled from another spotify source,
---   this timer needs to be running all the time, and then only update if is_updating = true.
---   This is because Spotify Web API has no ability to register a webhook, therefore,
---   we need to query the API every X seconds.
----------------------------------------------------------------

---@alias SyncData { is_playing: boolean, current_pos: integer }

---@class SpotifyTimer
---@field current_pos integer The current position in milliseconds
---@field update_interval integer How often the timer should update
---@field is_updating boolean Whether or not the timer should send updates.
---@field send_update fun(current_pos: integer) Where to send the updated timestamp
---@field sync_interval integer time in ms between each sync
---@field is_syncing boolean whether we are currently syncing. Important so we don't issue multiple syncs at once.
---@field sync fun(callback: fun(sync_data: SyncData)) Method to run, provided by the caller to sync with Spotify servers
---@field last_sync_time integer When the last sync time occurred
---@field timer uv_timer_t The underlying timer object

---@param opts table
---@return SpotifyTimer
function M.create_timer(opts)
  return {
    current_pos = opts.current_pos and opts.current_pos or 0,
    update_interval = opts.update_interval and opts.update_interval or 1000,
    is_updating = false,
    send_update = opts.send_update and opts.send_update or nil,
    sync_interval = opts.sync_interval and opts.sync_interval or 5000,
    is_syncing = false,
    sync = opts.sync and opts.sync or nil,
    last_sync_time = 0,
    timer = vim.uv.new_timer(),
  }
end

---@param timer SpotifyTimer
function M.start(timer)
  timer.timer:start(
    0,
    timer.update_interval,
    vim.schedule_wrap(function()
      if not timer.is_syncing then
        local current_time = vim.loop.now()
        if current_time - timer.last_sync_time >= timer.sync_interval then
          if timer.sync then
            timer.is_syncing = true
            timer.last_sync_time = current_time
            timer.sync(function(sync_data)
              if sync_data then
                timer.current_pos = sync_data.current_pos
                timer.is_updating = sync_data.is_playing
              else
                M.pause(timer)
              end
            end)
          end
          timer.is_syncing = false
        end
      end

      if timer.is_updating then
        timer.current_pos = timer.current_pos + timer.update_interval
        if timer.send_update then
          timer.send_update(timer.current_pos)
        end
      end
    end)
  )
end

---@param timer SpotifyTimer
function M.pause(timer)
  timer.is_updating = false
end

---@param timer SpotifyTimer
function M.resume(timer)
  timer.is_updating = true
end

---@param timer SpotifyTimer
function M.reset(timer)
  timer.current_pos = 0
end

---@param timer SpotifyTimer
function M.close(timer)
  M.pause(timer)
  M.reset(timer)
  timer.timer:close()
end

return M
