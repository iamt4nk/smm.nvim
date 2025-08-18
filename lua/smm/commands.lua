local logger = require 'smm.utils.logger'

local M = {}

function M.setup()
  vim.api.nvim_create_user_command('Spotify', function(opts)
    local args = opts.fargs

    if #args == 0 then
      require('smm.playback').toggle_window()
    elseif args[1] == 'pause' then
      require('smm.playback').pause()
    elseif args[1] == 'resume' then
      require('smm.playback').resume()
    elseif args[1] == 'auth' then
      local auth_info = require('smm.spotify.auth').initiate_oauth_flow()
      require('smm.spotify').auth_info = auth_info

      local token = require 'smm.spotify.token'
      token.delete_refresh_token()
      token.save_refresh_token(auth_info.refresh_token)
    elseif args[1] == 'play' then
      local search_type = args[2]
      local query = table.concat(vim.list_slice(args, 3), ' ')

      if not search_type then
        logger.error 'Search type is required. Usage :Spotify play [song|album|artist|playlist] <query>'
        return
      end

      if not query or query == '' then
        logger.error 'Search query is required. Usage :Spotify play [song|album|artist|playlist] <query>'
        return
      end

      -- Validate search type
      local valid_types = { song = 'track', album = 'album', artist = 'artist', playlist = 'playlist' }
      local spotify_type = valid_types[search_type]

      if not spotify_type then
        logger.error('Invalid search type: %s. Valid types are: song, album, artist, playlist', search_type)
        return
      end

      ---@param result SMM_Artist|SMM_Album|SMM_Track|SMM_Playlist
      ---@param result_type SMM_MediaType
      local on_select = function(result, result_type)
        logger.info('Playing %s: %s', result_type:gsub('^%l', string.upper), result.name)
        require('smm.playback').play(result.uri)
      end

      require('smm.search.media').search(spotify_type, query, on_select)
    elseif args[1] == 'next' then
      require('smm.playback').next()
    elseif args[1] == 'prev' then
      require('smm.playback').previous()
    elseif args[1] == 'change_device' then
      require('smm.playback').transfer_playback()
    else
      logger.error 'Could not execute command. Usage: :Spotify [auth|pause|resume|play|change_device] [opts]'
    end
  end, {
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
end

return M
