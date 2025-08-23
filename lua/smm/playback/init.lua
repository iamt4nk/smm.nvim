local config = require 'smm.playback.config'
local spotify = require 'smm.spotify'
local manager = require 'smm.playback.manager'
local logger = require 'smm.utils.logger'
local utils = require 'smm.playback.utils'
local Window = require('smm.models.ui.interface').Window

local M = {}

---@type SMM_UI_Window
M.playback_window = nil

---@param playback_info
local function update_playback_window(playback_info)
  if M.playback_window then
    local lines = utils.format_playback_lines(playback_info)
    M.playback_window:update_window(lines)
  end
end

---Module setup function
---@param user_config table|nil
function M.setup(user_config)
  config.setup(user_config or {})
end

---Toggle the playback window on/off
function M.toggle_window()
  if M.playback_window and M.playback_window.is_showing then
    logger.debug 'Hiding playback window'
    M.playback_window:close()

    if manager.is_session_active() then
      logger.debug 'Stopping session playback'
      manager.stop_session()
    end
    return
  end

  -- Authenticate with Spotify before starting
  spotify.authenticate()

  logger.debug 'Showing playback window'

  local lines = { 'Loading Playback Information...' }
  local width = config.get().playback_width
  local height = #lines + 2
  local position = config.get().playback_pos

  M.playback_window = Window:new(' Spotify ', lines, width, height, position)

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

---Transfer playback to another device
function M.transfer_playback()
  if not manager.is_session_active() then
    logger.error 'Playback session not active. Unable to transfer session'
  end

  manager.transfer_playback()
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

M.update_playback_window = update_playback_window

return M
