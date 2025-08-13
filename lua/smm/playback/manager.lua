local Timer = require('smm.playback.timer').Timer
local handlers = require 'smm.playback.handlers'
local interface = require 'smm.playback.interface'
local logger = require 'smm.utils.logger'

local M = {}

---@type SMM_PlaybackInfo|nil
local playback_info = nil

---@type SMM_PlaybackTimer|nil
local timer = nil

---@type function|nil
local sync_handler = nil

---@type function|nil
local update_handler = nil

---@type function|nil
local pause_handler = nil

---@type function|nil
local play_handler = nil

---Updates playback_info with partial data
---@param updates table Partial updates to apply to playback_info
local function update_playback_info(updates)
  if not playback_info then
    return
  end

  for key, value in pairs(updates) do
    playback_info[key] = value
  end
end

---Gets current playback info
---@return SMM_PlaybackInfo|nil
local function get_playback_info()
  return playback_info
end

---Gets current timer
---@return SMM_PlaybackTimer|nil
local function get_timer()
  return timer
end

---Handles interface updates
---@param updated_playback_info SMM_PlaybackInfo|nil
local function on_interface_update(updated_playback_info)
  interface.update_window(updated_playback_info)
end

---Handles playback info updates from sync handler
---@param updated_playback_info SMM_PlaybackInfo|nil
---@param status_code integer
local function on_playback_update(updated_playback_info, status_code)
  playback_info = updated_playback_info
  logger.debug('Manager received playback update: %s - Status Code: %d', updated_playback_info and vim.inspect(updated_playback_info) or nil, status_code)
end

---Initializes all handlers with their dependencies
local function initialize_handlers()
  sync_handler = handlers.create_sync_handler(on_playback_update)
  update_handler = handlers.create_update_handler(get_playback_info, on_interface_update)
  pause_handler = handlers.create_pause_handler(get_timer, update_playback_info)
  play_handler = handlers.create_play_handler(get_timer, update_playback_info)
end

---Starts the timer and playback session
function M.start_session()
  if timer then
    logger.warn 'Playback session already running'
    return
  end

  initialize_handlers()

  timer = Timer:new {
    update = update_handler,
    sync = sync_handler,
  }

  timer:start()
  logger.debug 'Playback session started'
end

---Stops the timer and cleans up
function M.stop_session()
  if timer then
    timer:close()
    timer = nil
    logger.debug 'Playback session stopped'
  end

  playback_info = nil
  sync_handler = nil
  update_handler = nil
  pause_handler = nil
  play_handler = nil
end

---Checks if session is running
---@return boolean
function M.is_session_active()
  return timer ~= nil
end

---Gets current playback info (read-only)
---@return SMM_PlaybackInfo|nil
function M.get_playback_info()
  return playback_info
end

function M.pause()
  if not playback_info then
    logger.error 'Playback has not started. Unable to pause'
    return
  end

  if not playback_info.playing then
    logger.info 'Track already paused'
    return
  end

  if pause_handler then
    pause_handler()
  end
end

---Resume/play track
---@param context_uri string|nil
---@param offset integer|nil
---@param position_ms integer|nil
function M.play(context_uri, offset, position_ms)
  if not context_uri and not position_ms and playback_info then
    position_ms = playback_info.progress_ms or 0
  end

  if play_handler then
    play_handler(context_uri, offset, position_ms)
  end
end

---Force a sync with Spotify
function M.sync()
  if not timer then
    logger.error 'Playback session not active. Unable to sync'
  end

  logger.debug 'Syncing'
  if sync_handler then
    sync_handler(function(sync_data)
      if sync_data then
        timer.current_pos = sync_data.current_pos
        timer.is_updating = sync_data.is_playing
        timer.update(timer.current_pos)
      else
        timer:pause()
        timer.update(nil)
      end
    end)
  end
end

return M
