local playback_utils = require 'smm.controller.playback_utils'
local timer = require 'smm.timer.timer'
local api = require 'smm.api.api'
local playback = require 'smm.ui.playback'
local notification = require 'smm.ui.notification'

local M = {}

---@type Playback_Info|nil
M.playback_info = nil

---@type Auth_Info|nil
M.auth_info = nil

---@type SpotifyTimer|nil
M.timer = nil

---@type boolean
M.playback_window_is_showing = false

--- Local functions for timer object
--------------------------------------------------------------------------------

---@param callback fun(sync_data: SyncData|nil) call back to the timer with the appropriate data
local function handle_timer_sync(callback)
  api.get_playback_state(M.auth_info, function(playback_data, _, status_code)
    if status_code == 200 or status_code == 204 then
      local playback_info = playback_utils.extract_playback_info(playback_data)
      M.playback_info = playback_info

      if playback_info and playback_info.current_ms and playback_info.playing ~= nil then
        callback {
          current_pos = playback_info.current_ms,
          is_playing = playback_info.playing,
        }
      else
        callback(nil)
      end
    else
      vim.schedule(function()
        vim.notify('Error: getting playback state failed:\nStatus Code: ' .. status_code, vim.log.levels.ERROR)
        callback(nil)
      end)
    end
  end)
end

---@param current_ms integer|nil Current position in milliseconds
local function handle_timer_update(current_ms)
  if not current_ms then
    playback.update_window_info(nil)
    return
  end

  if not M.playback_info then
    return
  end

  M.playback_info.current_ms = current_ms

  vim.schedule(function()
    local playback_info = playback_utils.create_playback_data(M.playback_info)
    playback.update_window_info(playback_info)
  end)
end

local function handle_timer_pause()
  api.pause_track(M.auth_info, function(response_body, _, status_code)
    if status_code == 200 or status_code == 204 then
      timer.pause(M.timer)
    else
      vim.schedule(function()
        vim.notify('Error: unable to pause current track:\nStatus Code: ' .. status_code .. '\nError: ' .. response_body, vim.log.levels.ERROR)
      end)
    end
  end)
end

---@param position_ms integer|nil
local function handle_timer_resume(position_ms)
  if position_ms == nil then
    position_ms = 0
  end

  api.resume_track(position_ms, M.auth_info, function(response_body, _, status_code)
    if status_code == 200 or status_code == 204 then
      timer.resume(M.timer)
    else
      vim.schedule(function()
        vim.notify(
          'Error: unable to resume current track at position: ' .. position_ms .. '\nError: ' .. response_body .. '\nStatus code: ' .. status_code,
          vim.log.levels.ERROR
        )
      end)
    end
  end)
end

---@param callback fun(is_premium: boolean)
local function get_user_subscription_status(callback)
  api.get_user_profile(M.auth_info, function(response_body, _, status_code)
    if status_code == 200 or status_code == 204 then
      if response_body['product'] == 'premium' then
        callback(true)
        return
      else
        callback(false)
        return
      end
    else
      vim.schedule(function()
        vim.notify('Error: unable to get user profile. Error: ' .. response_body .. '\nStatus code: ' .. status_code, vim.log.levels.ERROR)
        callback(false)
      end)
    end
  end)
  callback(false)
end

--- End Local Functions
--------------------------------------------------------------------------------

function M.setup_timer()
  M.timer = timer.create_timer {
    current_pos = M.playback_info and M.playback_info.current_ms or 0,
    update_interval = 100,
    send_update = handle_timer_update,
    sync = handle_timer_sync,
  }

  timer.start(M.timer)

  if M.playback and M.playback_info.playing then
    timer.resume(M.timer)
  end
end

---@param auth_info Auth_Info
---Creates the playback window, using the current playback_info state
function M.start_playback(auth_info)
  M.auth_info = auth_info

  playback.show_window()
  M.playback_window_is_showing = true

  M.setup_timer()
end

---Hides window and stops playback
function M.cleanup()
  M.auth_info = nil
  playback.close_playback_window()
  playback.cleanup()
  timer.pause(M.timer)
  timer.close(M.timer)
end

---Pauses the currently playing track
function M.pause_track()
  handle_timer_pause()
end

--- Resumes the currently playing track
function M.resume_track()
  local current_pos = M.timer.current_pos

  handle_timer_resume(current_pos)
end

function M.get_profile_type()
  get_user_subscription_status(function(is_premium)
    vim.schedule(function()
      vim.notify(tostring(is_premium), vim.log.levels.INFO)
      if not is_premium then
        notification.show_free_user_notice {
          top = 1,
          bottom = 1,
          left = 3,
          right = 3,
        }
      end
    end)
  end)
end

return M
