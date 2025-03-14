local M = {}

---@class Timer
---@field current_pos integer The current position in milliseconds
---@field initial_pos integer Starting position when timer was last reset
---@field is_playing boolean Whether the timer is currently active
---@field is_updating boolean Whether or not to send updates to the control
---@field start_time integer When the timer was last started/reset
---@field last_sync_time integer When the timer was last synced
---@field timer uv_timer_t The underlying timer object
---@field on_sync function Callback for sync events
---@field on_update function Callback for update events

local UPDATE_INTERVAL = 100
local SYNC_INTERVAL = 5000

---@param opts? table
---@return Timer
function M.create_timer(opts)
  return {
    initial_pos = opts and opts.initial_pos or 0,
    current_pos = opts and opts.initial_pos or 0,
    is_playing = false,
    is_updating = false,
    start_time = vim.uv.now(),
    last_sync_time = vim.uv.now(),
    timer = vim.uv.new_timer(),
    on_sync = opts and opts.on_sync or nil,
    on_update = opts and opts.on_update or nil,
  }
end

---@param timer Timer
---@param should_force boolean? Force sync regardless of interval
local function attempt_sync(timer, should_force)
  local current_time = vim.uv.now()

  if should_force or (current_time - timer.last_sync_time) >= SYNC_INTERVAL then
    if timer.on_sync then
      timer.on_sync(function(playing)
        -- After sync completion, update our timestamps
        timer.start_time = current_time
        timer.last_sync_time = current_time
        timer.is_updating = playing
      end)
    end
  end
end

---@param timer Timer
function M.start(timer)
  if timer.is_playing then
    vim.notify('Timer is already running', vim.log.levels.INFO)
    return
  end

  timer.is_playing = true
  timer.start_time = vim.uv.now()

  timer.timer:start(
    0,
    UPDATE_INTERVAL,
    vim.schedule_wrap(function()
      if not timer.is_playing then
        return
      end

      -- Update Position
      if timer.is_updating then
        local current_time = vim.uv.now()
        local elapsed = current_time - timer.start_time
        timer.current_pos = timer.initial_pos + elapsed

        -- Call update callback if provided
        if timer.is_updating and timer.on_update then
          timer.on_update(timer.current_pos)
        end
      end

      --- Attempt sync if needed
      attempt_sync(timer)
    end)
  )
end

---@param timer Timer
function M.stop(timer)
  if not timer.is_playing then
    vim.notify('Timer is already stopped', vim.log.levels.INFO)
    return
  end

  timer.is_playing = false
  timer.is_updating = false
  timer.timer:stop()
end

---@param timer Timer
function M.pause(timer)
  if not timer.is_updating then
    vim.schedule(function()
      vim.notify('Timer is already paused', vim.log.levels.INFO)
    end)
  end

  timer.is_updating = false
end

---@param timer Timer
function M.resume(timer)
  if timer.is_updating then
    vim.notify('Timer is already running', vim.log.levels.INFO)
  end

  timer.is_updating = true
  timer.start_time = vim.uv.now()
  timer.initial_pos = timer.current_pos
end

---@param timer Timer
function M.reset(timer, new_position)
  timer.initial_pos = new_position or 0
  timer.current_pos = timer.initial_pos
  timer.start_time = vim.uv.now()
  timer.last_sync_time = timer.start_time
end

---@param timer Timer
function M.force_sync(timer)
  attempt_sync(timer, true)
end

---@param timer Timer
function M.cleanup(timer)
  if timer.timer then
    timer.timer:stop()
    timer.timer:close()
    timer.timer = nil
  end
  timer.is_playing = false
  timer.is_updating = false
end

return M
