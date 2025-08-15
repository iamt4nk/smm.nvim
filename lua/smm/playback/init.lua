local config = require 'smm.playback.config'
local spotify = require 'smm.spotify'
local manager = require 'smm.playback.manager'
local interface = require 'smm.playback.interface'
local logger = require 'smm.utils.logger'

local M = {}

---Module setup function
---@param user_config table|nil
function M.setup(user_config)
  config.setup(user_config or {})

  if not config.get().enabled then
    logger.info 'Playback module not enabled. Skipping module registration'
    return
  end

  logger.debug 'Initializing playback interface'
  interface.setup(config.get().interface)
end

---Toggle the playback window on/off
function M.toggle_window()
  if interface.is_showing then
    logger.debug 'Hiding playback window'
    interface.remove_window()

    if manager.is_session_active() then
      logger.debug 'Stopping session playback'
      manager.stop_session()
    end
    return
  end

  -- Authenticate with Spotify before starting
  spotify.authenticate()

  logger.debug 'Showing playback window'
  interface.create_window()

  logger.debug 'Starting playback session'
  manager.start_session()
end

---Pause current playback
function M.pause()
  if not manager.is_session_active() then
    logger.error 'Playback session is not active. Unable to pause'
    return
  end

  manager.pause()
end

---Resume current playback at last position
function M.resume()
  if not manager.is_session_active() then
    logger.error 'Playback session is not active. Unable to resume'
    return
  end

  local playback_info = manager.get_playback_info()
  if playback_info and playback_info.playing then
    logger.info 'Track is already playing'
    return
  end

  --- Resume at current position (manager handles logic)
  manager.play()
end

---Play specific context
---@param context_uri string Spotify URI (track, album, playlist, artist)
---@param offset integer|nil Track offset for albums/playlists (default: 0)
---@param position_ms integer|nil Position to start playing from (default: 0)
function M.play(context_uri, offset, position_ms)
  if not manager.is_session_active() then
    logger.error 'Playback session not active. Unable to play'
    return
  end

  if context_uri:match '^spotify:artist' then
    offset = nil
  end

  manager.play(context_uri, offset, position_ms or 0)
end

---Force sync with Spotify servers
function M.sync()
  if not manager.is_session_active() then
    logger.error 'Playback session not active. Unable to sync'
    return
  end

  manager.sync()
end

---Skip to the next song
function M.next()
  if not manager.is_session_active() then
    logger.error 'Playback session not active. Unable to skip'
    return
  end

  manager.next()
end

---Skip to the previous song
function M.previous()
  if not manager.is_session_active() then
    logger.error 'Playback session not active. Unable to skip'
    return
  end

  manager.previous()
end

---Get current playback information (read-only)
---@return SMM_PlaybackInfo|nil
function M.get_playback_info()
  return manager.get_playback_info()
end

---Check if playback session is active
---@return boolean
function M.is_active()
  return manager.is_session_active()
end

return M
