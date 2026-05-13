local config = require 'smm.playback.config'
local spotify = require 'smm.spotify'
local manager = require 'smm.playback.manager'
local logger = require 'smm.utils.logger'
local utils = require 'smm.playback.utils'
local Window = require('smm.models.ui.interface').Window

local M = {}

---@type SMM_UI_Window
M.playback_window = nil

local ns_id = vim.api.nvim_create_namespace 'smm_track_link'

-- Line positions in the padded buffer (0-indexed):
-- 0=top_pad, 1=artist, 2=album, 3=track
local ARTIST_LINE = 1
local ALBUM_LINE = 2
local TRACK_LINE = 3
local LEFT_PAD = 2

local last_track_id = nil
local cached_links = nil

-- Reads buffer line to compute extmark positions, sets the extmark, and returns
-- the { line_nr, col_start, col_end, url } entry for later re-application.
local function set_link(buf, line_nr, url)
  local line = vim.api.nvim_buf_get_lines(buf, line_nr, line_nr + 1, false)[1] or ''
  local name_start = select(2, line:find(': ', 1, true)) or LEFT_PAD
  local end_col = #line:match('^(.-)%s*$')
  vim.api.nvim_buf_set_extmark(buf, ns_id, line_nr, name_start, {
    end_row = line_nr,
    end_col = end_col,
    hl_group = 'SMMTrackLink',
    url = url,
  })
  return { line_nr, name_start, end_col, url }
end

-- Re-applies cached link positions without reading from the buffer.
-- Called every tick after nvim_buf_set_lines destroys extmarks.
local function apply_cached_links(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  if not cached_links then return end
  for _, link in ipairs(cached_links) do
    vim.api.nvim_buf_set_extmark(buf, ns_id, link[1], link[2], {
      end_row = link[1],
      end_col = link[3],
      hl_group = 'SMMTrackLink',
      url = link[4],
    })
  end
end

---@param buf integer
---@param playback_info SMM_PlaybackInfo|nil
local function setup_track_link(buf, playback_info)
  cached_links = nil
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  if not playback_info or not playback_info.track then
    return
  end

  local track = playback_info.track
  cached_links = {}

  local artist_url = track.artists[1] and track.artists[1]:get_spotify_url() or ''
  if artist_url ~= '' then
    table.insert(cached_links, set_link(buf, ARTIST_LINE, artist_url))
  end

  local album_url = track.album and track.album:get_spotify_url() or ''
  if album_url ~= '' then
    table.insert(cached_links, set_link(buf, ALBUM_LINE, album_url))
  end

  local track_url = track:get_spotify_url()
  if track_url ~= '' then
    table.insert(cached_links, set_link(buf, TRACK_LINE, track_url))
  end
end

---@param playback_info SMM_PlaybackInfo
function M.update_playback_window(playback_info)
  if M.playback_window then
    local lines = utils.format_playback_lines(playback_info)
    M.playback_window:update_window(lines)
    if config.get().song_links then
      local current_track_id = playback_info and playback_info.track and playback_info.track.id
      if current_track_id ~= last_track_id then
        last_track_id = current_track_id
        setup_track_link(M.playback_window.buf, playback_info)
      else
        apply_cached_links(M.playback_window.buf)
      end
    end

    if playback_info then
      local title = ' Spotify '
      if playback_info.shuffle_state == true then
        title = title .. '- S '
      end

      logger.debug('"%s"', playback_info.repeat_state)
      if playback_info.repeat_state == 'context' then
        title = title .. '- R '
      elseif playback_info.repeat_state == 'track' then
        title = title .. '- RT '
      end

      logger.debug('"%s"', title)

      M.playback_window:__set_opts {
        title = M.playback_window:__create_title(title),
      }
    end
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
    last_track_id = nil
    cached_links = nil

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
  local title = ' Spotify '

  M.playback_window = Window:new(title, lines, width, height, position)
  vim.api.nvim_set_hl(0, 'SMMTrackLink', { fg = '#1ED760', underdotted = true })

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

---Change shuffle state
function M.change_shuffle_state()
  if not manager.is_session_active() then
    logger.error 'Playback session is not active. Unable to change shuffle state'
    return
  end

  manager.change_shuffle_state()
end

---Change repeat state
---@param state 'off' | 'track' | 'context'
function M.change_repeat_state(state)
  if not manager.is_session_active() then
    logger.error 'Playback session is not active. Unable to change repeat state'
    return
  end

  manager.change_repeat_state(state)
end

---Search for and play media
function M.media_search(search_type, query)
  if not manager.is_session_active() then
    logger.error 'Playback session is not active. Please start a session before controlling from SMM.nvim'
    return
  end

  manager.search_media(query, search_type)
end

---like the current song
function M.like_current_song()
  if not manager.is_session_active() then
    logger.error 'Unable to like current song. There is no session active'
    return
  end

  manager.add_song_to_liked_songs()
end

---unlike the current song
function M.unlike_current_song()
  if not manager.is_session_active() then
    logger.error 'Unable to like current song. There is no session active'
    return
  end

  manager.remove_song_from_liked_songs()
end

return M
