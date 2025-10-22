local logger = require 'smm.utils.logger'
local config = require 'smm.config'

local M = {}

--- Local functions that interact with the app
local function toggle_window()
  require('smm.playback').toggle_window()
end

local function pause()
  require('smm.playback').pause()
end

local function resume()
  require('smm.playback').resume()
end

local function auth()
  local auth_info = require('smm.spotify.auth').initiate_oauth_flow()
  require('smm.spotify').auth_info = auth_info

  local token = require 'smm.spotify.token'
  token.delete_refresh_token()
  token.save_refresh_token(auth_info.refresh_token)
end

---@return string
local function get_usage()
  return [[
    Usage: `:Spotify (command) [options]
    
    Commands:
      help - displays this usage message
      auth - Re-initiate a new authorization flow. Can be used for switching accounts or getting a new authorization token
      pause - Pause the current song
      resume - resume the current song from the current position
      play [ song | album | artist | playlist | liked ] - Plays the given context
      next - skips to the next song in the given context
      prev - skips to the previous song in the given context
      select device - opens a menu to select which device to play on. Can be run to start a playback session.
      like_song - adds the current song to liked songs
      unlike_song - removes the current song from liked songs
  ]]
end

---@param search_type string
---@param query string
local function play(search_type, query)
  if not search_type then
    logger.error 'Search type is required. Usage `:Spotify play [song|album|artist|playlist] <query>` or,\n`:Spotify play liked'
    return
  end

  if search_type == 'liked' then
    require('smm.playback').play('spotify:collection:tracks', 0, 0)
    return
  end

  -- Validate search type
  local valid_types = { song = 'track', album = 'album', artist = 'artist', playlist = 'playlist' }
  local spotify_type = valid_types[search_type]

  if not spotify_type then
    logger.error('Invalid search type: %s. Valid types are: song, album, artist, playlist', search_type)
    return
  end

  if not query or query == '' then
    logger.error 'Search query is required. Usage :Spotify play [song|album|artist|playlist] <query>'
    return
  end

  require('smm.playback').media_search(spotify_type, query)
end

local function next()
  require('smm.playback').next()
end

local function prev()
  require('smm.playback').previous()
end

local function change_device()
  require('smm.playback').transfer_playback()
end

local function shuffle()
  require('smm.playback').change_shuffle_state()
end

---@param state 'off' | 'track' | 'context'
local function change_repeat_state(state)
  require('smm.playback').change_repeat_state(state)
end

local function like_current_song()
  require('smm.playback').like_current_song()
end

local function unlike_current_song()
  require('smm.playback').unlike_current_song()
end

--- End local functions

---@param opts table
local function setup_premium(opts)
  local args = opts.fargs

  if #args == 0 then
    toggle_window()
  elseif args[1] == 'help' then
    logger.info(get_usage())
  elseif args[1] == 'pause' then
    pause()
  elseif args[1] == 'resume' then
    resume()
  elseif args[1] == 'auth' then
    auth()
  elseif args[1] == 'play' then
    local search_type = args[2]
    local query = table.concat(vim.list_slice(args, 3), ' ')

    play(search_type, query)
  elseif args[1] == 'like_song' then
    like_current_song()
  elseif args[1] == 'unlike_song' then
    unlike_current_song()
  elseif args[1] == 'next' then
    next()
  elseif args[1] == 'prev' then
    prev()
  elseif args[1] == 'select' then
    if #args == 2 and args[2] == 'device' then
      change_device()
    else
      logger.error 'Could not execute command. Usage: `:Spotify select device`'
    end
  elseif args[1] == 'shuffle' then
    shuffle()
  elseif args[1] == 'repeat' then
    if #args == 1 then
      change_repeat_state 'context'
    elseif args[2] == 'track' then
      change_repeat_state 'track'
    elseif args[2] == 'off' then
      change_repeat_state 'off'
    else
      logger.error 'Could not execute command. Usage: :Spotify repeat `[track|off]`'
    end
  else
    logger.error('Could not execute command.' .. get_usage())
  end
end

---@param opts table
local function setup_free(opts)
  local args = opts.fargs

  if #args == 0 then
    toggle_window()
  elseif args[1] == 'auth' then
    auth()
  else
    logger.error 'Could not execute command. Usage: `:Spotify [auth]`'
  end
end

function M.setup()
  if config.get().premium then
    vim.api.nvim_create_user_command('Spotify', setup_premium, {
      desc = 'Spotify related commands',
      nargs = '*',
      complete = function(ArgLead, CmdLine, CursorPos)
        local args = vim.split(CmdLine, '%s+')

        if #args == 2 then
          return { 'auth', 'pause', 'resume', 'play', 'next', 'prev', 'select', 'like_song', 'unlike_song' }
        elseif #args == 3 then
          if args[2] == 'play' then
            return { 'song', 'album', 'artist', 'playlist', 'liked' }
          elseif args[2] == 'select' then
            return { 'device' }
          end
        end
        return {}
      end,
    })
  else
    vim.api.nvim_create_user_command('Spotify', setup_free, {
      desc = 'Spotify (free account) commands',
      nargs = '*',
    })
  end
end

return M
