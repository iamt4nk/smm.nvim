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

---@param search_type string
---@param query string
local function play(search_type, query)
  if not search_type then
    logger.error 'Search type is required. Usage :Spotify play [song|album|artist|playlist] <query>'
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

  ---@param result SMM_Artist|SMM_Album|SMM_Track|SMM_Playlist
  ---@param result_type SMM_MediaType
  local on_select = function(result, result_type)
    logger.info('Playing %s: %s', result_type:gsub('^%l', string.upper), result.name)
    require('smm.playback').play(result.uri)
  end

  require('smm.search.media').search(spotify_type, query, on_select)
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

--- End local functions

---@param opts table
local function setup_premium(opts)
  local args = opts.fargs

  if #args == 0 then
    toggle_window()
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
  elseif args[1] == 'next' then
    next()
  elseif args[1] == 'prev' then
    prev()
  elseif args[1] == 'change_device' then
    change_device()
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
      logger.error 'Could not execute command. Usage: :Spotify repeat [track|off]'
    end
  else
    logger.error 'Could not execute command. Usage: :Spotify [auth|pause|resume|play|next|prev|change_device] [opts]'
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
    logger.error 'Could not execute command. Usage: :Spotify [auth]'
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
          return { 'auth', 'pause', 'resume', 'play', 'change_device' }
        elseif #args == 3 and args[2] == 'search' then
          return { 'song', 'album', 'artist', 'playlist' }
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
