local playback_utils = require 'smm.controller.playback_utils'
local timer = require 'smm.timer.timer'
local api = require 'smm.api.api'
local playback = require 'smm.ui.playback'

local M = {}

---@type Playback_Info|nil
M.playback_info = nil

---@type Auth_Info|nil
M.auth_info = nil

---@type Timer|nil
M.timer = nil

---@type boolean
M.playback_window_is_showing = false

---@type boolean
M.is_syncing_playback = false

---@param done_callback fun(playing: boolean) Callback to run when completes. Sends boolean on success status
local function handle_timer_sync(done_callback)
  if M.is_syncing_playback then
    done_callback(M.playback_info and M.playback_info.playing or false)
    return
  end

  M.sync_playback_data(function(is_playing)
    done_callback(is_playing)
  end)
end

---@param current_ms integer Current position in milliseconds
local function handle_timer_update(current_ms)
  if not M.playback_info then
    return
  end

  M.playback_info.current_ms = current_ms

  if current_ms >= M.playback_info.duration_ms then
    timer.force_sync(M.timer)
    return
  end

  vim.schedule(function()
    local window_lines = playback_utils.extract_playback_info(M.playback_info)
    playback.update_window(window_lines)
  end)
end

function M.setup_timer()
  M.timer = timer.create_timer {
    initial_pos = M.playback_info.current_ms,
    on_sync = function(done_callback)
      handle_timer_sync(done_callback)
    end,
    on_update = function(done_callback)
      handle_timer_update(done_callback)
    end,
  }

  timer.start(M.timer)

  if M.playback_info.playing then
    timer.resume(M.timer)
  else
    timer.pause(M.timer)
  end
end

---@param callback fun(bool) whether playback is currently running
function M.sync_playback_data(callback)
  M.is_syncing_playback = true

  api.get_playback_state(M.auth_info, function(playback_data, _, status_code)
    M.is_syncing_playback = false
    if status_code == 200 then
      local new_playback_info = playback_utils.extract_playback_info(playback_data)

      if new_playback_info then
        -- Track ID changed?
        local track_changed = not M.playback_info or M.playback_info.id ~= new_playback_info.id
        if track_changed then
          M.playback_info = new_playback_info
        end

        -- Reset timer with the correct position from the API
        if M.timer then
          timer.reset(M.timer, M.playback_info.current_ms)
        end
      end

      -- Update UI
      vim.schedule(function()
        playback.update_window_info(playback_data)
      end)
    end

    callback(M.playback_info and M.playback_info.playing or false)
  end)
end

--- @param auth_info Auth_Info
--- Creates the playback window, using the current playback_info state
function M.start_playback(auth_info)
  M.auth_info = auth_info

  playback.show_window()
  M.playback_window_is_showing = true

  M.is_syncing_playback = true
  playback_utils.fetch_initial_playback_data(auth_info, function(playback_data)
    M.playback_info = playback_data
    print(vim.inspect(playback_data))

    vim.schedule(function()
      playback.update_window_info(playback_data)
    end)

    M.setup_timer()
    M.is_syncing_playback = false
  end)
end

return M
