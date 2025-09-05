local Timer = require('smm.playback.timer').Timer
local handlers = require 'smm.playback.handlers'
local logger = require 'smm.utils.logger'

---@alias SMM_PlaybackInfo { id: string, device_id?: string, context_uri: string, context_type?: string, context_offset?: integer, playlist?: SMM_Playlist, track: SMM_Track, is_advertisement: boolean, playing: boolean,  progress_ms: integer, shuffle_state: boolean, repeat_state: string }

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

---@type function|nil
local next_handler = nil

---@type function|nil
local previous_handler = nil

---@type function|nil
local transfer_playback_handler = nil

---@type function|nil
local shuffle_handler = nil

---@type function|nil
local repeat_handler = nil

---@type function|nil
local media_search_handler = nil

---@type function|nil
local device_search_handler = nil

---@type function|nil
local like_song_handler = nil

---@type function|nil
local unlike_song_handler = nil

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
  vim.schedule(function()
    local playback = require 'smm.playback'
    playback.update_playback_window(updated_playback_info)
  end)
end

---Handles playback info updates from sync handler
---@param updated_playback_info SMM_PlaybackInfo|nil
---@param status_code integer
local function on_playback_update(updated_playback_info, status_code)
  playback_info = updated_playback_info
  logger.debug('Manager received playback update: %s - Status Code: %d', updated_playback_info and vim.inspect(updated_playback_info) or nil, status_code)
end

---Handles playing media
---@param result SMM_Artist|SMM_Album|SMM_Track|SMM_Playlist
---@param result_type SMM_MediaType
local on_select_media = function(result, result_type)
  logger.info('Playing %s: %s', result_type:gsub('^%l', string.upper), result.name)
  require('smm.playback').play(result.uri)
end

---Handles transferring device playback
---@param result SMM_Device
local on_select_device = function(result)
  logger.info('Switching device playback to: %s', result.name)
  if transfer_playback_handler then
    transfer_playback_handler(result)
  end
end

---Initializes all handlers with their dependencies
local function initialize_handlers()
  sync_handler = handlers.create_sync_handler(on_playback_update)
  update_handler = handlers.create_update_handler(get_playback_info, on_interface_update)
  pause_handler = handlers.create_pause_handler(get_timer, update_playback_info)
  next_handler = handlers.create_next_handler()
  previous_handler = handlers.create_previous_handler()
  shuffle_handler = handlers.create_shuffle_handler(update_playback_info)
  repeat_handler = handlers.create_repeat_handler(update_playback_info)
  play_handler = handlers.create_play_handler(get_timer, update_playback_info)
  media_search_handler = handlers.create_media_search_handler(on_select_media)
  transfer_playback_handler = handlers.create_transfer_playback_handler(update_playback_info)
  device_search_handler = handlers.create_device_search_handler(on_select_device)
  like_song_handler = handlers.create_add_liked_song_handler()
  unlike_song_handler = handlers.create_delete_liked_song_handler()
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
    vim.defer_fn(M.sync, 500)
  end
end

---Skip to next track
function M.next()
  if next_handler then
    next_handler()
    vim.defer_fn(M.sync, 500)
  end
end

---Skip to previous track
function M.previous()
  if previous_handler then
    previous_handler()
    vim.defer_fn(M.sync, 500)
  end
end

---Searches for a device and then transfers playback to that device
function M.transfer_playback()
  if device_search_handler then
    device_search_handler()
  end
end

--- Force a sync with Spotify
--- Call this with a `vim.defer_fn(sync, 500)` to delay it right after an action occurs.
function M.sync()
  if not timer then
    logger.error 'Playback session not active. Unable to sync'
    return
  end

  logger.debug 'Syncing'
  if sync_handler then
    sync_handler(function(sync_data)
      logger.debug('[TIMER] Sync callback received - has_data: %s', tostring(sync_data ~= nil))
      if sync_data then
        timer.current_pos = sync_data.current_pos
        timer.is_updating = sync_data.is_playing
        logger.debug('[TIMER] Sync updated - pos: %d, playing: %s', sync_data.current_pos, tostring(sync_data.is_playing))
        timer.update(timer.current_pos)
      else
        logger.debug '[TIMER] Sync returned nil, pausing timer'
        timer:pause()
        timer.update(nil)
      end
    end)
  end
end

---Change the shuffle state
function M.change_shuffle_state()
  local current_shuffle_state

  if playback_info then
    current_shuffle_state = playback_info.shuffle_state
  end

  if shuffle_handler then
    shuffle_handler(not current_shuffle_state)
  end
end

--- Change the repeat state
---@param state 'off' | 'track' | 'context'
function M.change_repeat_state(state)
  if repeat_handler then
    repeat_handler(state)
  end
end

--- Search for media and play it
---@param query string
---@param search_type string
function M.search_media(query, search_type)
  if media_search_handler then
    media_search_handler(search_type, query)
  end
end

--- Search for a device and transfer playback to it
function M.search_device()
  if device_search_handler then
    device_search_handler()
  end
end

--- Add the current song to liked songs
function M.add_song_to_liked_songs()
  if like_song_handler then
    current_id = playback_info.track.id
    like_song_handler(current_id)
  end
end

--- Remove the current song from liked songs
function M.remove_song_from_liked_songs()
  if unlike_song_handler then
    current_id = playback_info.track.id
    unlike_song_handler(current_id)
  end
end

return M
