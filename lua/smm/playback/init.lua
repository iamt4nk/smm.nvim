local config = require 'smm.playback.config'

local api = require 'smm.spotify.requests'
local playback_timer = require 'smm.playback.timer'
local utils = require 'smm.playback.utils'
local logger = require 'smm.utils.logger'
local interface = require 'smm.playback.interface'

---@type SMM_PlaybackInfo|nil
local playback_info = nil

---@type SMM_PlaybackTimer|nil
local timer = nil

local M = {}

--- Local functions for handling playback actions

----@param callback fun(sync_data: SMM_SyncData|nil) callback to the timer with the appropriate data
local function handle_timer_sync(callback)
  api.get_playback_state(function(playback_response, playback_headers, status_code)
    if status_code == 200 or status_code == 204 then
      logger.debug('Playback Response:\n%s', vim.inspect(playback_response))
      logger.debug('Playback Response headers:\n%s', vim.inspect(playback_headers))

      playback_info = utils.get_playbackinfo(playback_response)

      if (playback_info and playback_info.current_ms and playback_info.playing ~= nil) and playback_info ~= '' then
        logger.debug('Calling back: %s %s', playback_info.current_ms, playback_info.playing)
        callback {
          current_pos = playback_info.current_ms,
          is_playing = playback_info.playing,
        }
      else
        logger.debug 'Callback: nil'
        callback(nil)
      end
    else
      logger.error('Getting playback state failed:\nStatus Code: %s\nError: %s', status_code, playback_response)
    end
  end)
end

---@param current_ms integer|nil Current position in milliseconds
local function handle_timer_update(current_ms)
  if not playback_info or not current_ms then
    interface.update_window(nil)
    return
  end

  playback_info.current_ms = current_ms
  interface.update_window(playback_info)
end

local function handle_timer_pause()
  api.pause_track(function(pause_response, pause_headers, status_code)
    if status_code == 200 or status_code == 204 then
      playback_timer.pause(timer)
    else
      logger.error('Unable to pause current track:\nStatus Code: %s\nError: %s', status_code, vim.inspect(pause_response))
    end
  end)
end

---@param position_ms integer|nil
local function handle_timer_resume(position_ms)
  if not position_ms then
    position_ms = 0
  end

  api.resume_track(nil, nil, position_ms, function(resume_response, resume_headers, status_code)
    if status_code == 200 or status_code == 204 then
      playback_timer.resume(timer)
    else
      logger.error('Unable to resume current track:\nStatus Code: %s\nError: %s', status_code, vim.inspect(resume_response))
    end
  end)
end

local function start_timer()
  timer = playback_timer.create_timer {
    update = handle_timer_update,
    sync = handle_timer_sync,
  }

  playback_timer.start(timer)
end

---Module setup function
function M.setup(user_config)
  config.setup(user_config or {})

  if not config.get().enabled then
    logger.info 'Playback module not enabled. Skipping module registration'
    return
  end

  logger.debug 'Initializing playback interface'
  interface.setup(config.get().interface)
end

---Functions to interface with

function M.toggle_window()
  if interface.is_showing then
    logger.debug 'Removing window'
    interface.remove_window()
    if timer then
      logger.debug 'Removing timer'
      playback_timer.close(timer)
    end

    interface.is_showing = false
    return
  end

  logger.debug 'Showing window'
  interface.create_window()
  start_timer()
  interface.is_showing = true
end

function M.pause()
  if not playback_info then
    logger.error 'Playback has not started. Unable to pause'
    return
  end

  if playback_info and not playback_info.playing then
    logger.info 'Track already paused'
    return
  end

  handle_timer_pause()
end

function M.resume()
  if not playback_info then
    logger.error 'Playback has not started. Unable to resume.'
    return
  end

  if playback_info and playback_info.playing then
    logger.info 'Track is already playing'
    return
  end

  if not playback_info.current_ms then
    playback_info.current_ms = 0
  end

  handle_timer_resume(playback_info.current_ms)
end

return M
