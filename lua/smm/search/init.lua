local logger = require 'smm.utils.logger'
local spotify = require 'smm.spotify'
local requests = require 'smm.spotify.requests'
local Track = require('smm.playback.models.track').Track
local Album = require('smm.playback.models.album').Album
local Artist = require('smm.playback.models.artist').Artist
local Playlist = require('smm.playback.models.playlist').Playlist

local M = {}

---Parse search resulsts and convert to model objects
---@param search_response table
---@param search_type string
---@param table[] Array of model objects
local function parse_search_results(search_response, search_type)
  local results = {}

  if not search_response or not search_response[search_type .. 's'] then
    logger.debug('No results found for search type: %s', search_type)
    return results
  end

  local items = search_response[search_type .. 's'].items or {}

  for _, item in ipairs(items) do
    if search_type == 'track' then
      local artists = {}
      for _, artist_data in ipairs(item.artists or {}) do
        table.insert(artists, Artist:new(artist_data))
      end

      local album = nil
      if item.album then
        album = Album:new(item.album)
      end

      local track = Track:new(item)
      track.artists = artists
      track.album = album

      table.insert(results, track)
    elseif search_type == 'album' then
      local album = Album:new(item)
      table.insert(results, album)
    elseif search_type == 'artist' then
      local artist = Artist:new(item)
      table.insert(results, artist)
    elseif search_type == 'playlist' then
      local playlist = Playlist:new(item)
      table.insert(results, playlist)
    end
  end

  logger.debug('Parsed %d results for search type: %s', #results, search_type)
  return results
end

---Format a result for display in Telescope
---@param result SMM_Track|SMM_Album|SMM_Artist|SMM_Playlist
---@param search_type string
---@return string display_text, string ordinal_text
local function format_result(result, search_type)
  local display_text = ''
  local ordinal_text = ''

  if search_type == 'track' then
    ---@cast result SMM_Track
    local artist_name = result:get_primary_artist()
    local album_name = result.album and result.album.name or 'Unknown Album'
    display_text = string.format('%s - %s (%s)', result.name, artist_name, album_name)
    ordinal_text = string.format('%s %s %s', result.name, artist_name, album_name)
  elseif search_type == 'album' then
    ---@cast result SMM_Album
    local artist_name = result:get_primary_artist()
    display_text = string.format('%s - %s (%s)', result.name, artist_name, result:get_release_year())
    ordinal_text = string.format('%s %s', result.name, artist_name)
  elseif search_type == 'artist' then
    ---@cast result SMM_Artist
    local followers = result:get_formatted_followers()
    display_text = string.format('%s (Followers: %s)', result.name, followers)
    ordinal_text = result.name
  elseif search_type == 'playlist' then
    ---@cast result SMM_Playlist
    local owner = result:get_owner_name()
    local track_count = result:get_track_count()
    display_text = string.format('%s by %s (%d tracks)', result.name, owner, track_count)
    ordinal_text = string.format('%s %s', result.name, owner)
  end

  return display_text, ordinal_text
end

---Play the selected result
---@param result SMM_Track|SMM_Album|SMM_Artist|SMM_Playlist
---@param search_type string
local function play_result(result, search_type)
  logger.info('Playing %s: %s', search_type:gsub('^%l', string.upper), result.name)
  requests.play(result.uri, nil, 0, function(response_body, response_headers, status_code)
    if status_code == 200 or status_code == 204 then
      logger.debug('Successfully started playing %s: %s', search_type, result.name)
    else
      logger.error('Failed to play %s. Status: %d, Response: %s', search_type, status_code, vim.inspect(response_body))
    end
  end)
end

--Setup function
function M.setup()
  -- Currently no configuration needed for search module
  -- This is here for consistency and future extensibility
  logger.debug 'Search module initialized'
end

---Main search function that integrates with Telescope
---@param search_type string The type to search for { 'track', 'album', 'artist', 'playlist' }
---@param query string The search query
function M.search(search_type, query)
  -- Check if telescope is available
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    logger.error 'Telescope is required for search functionality. Please install telescope.nvim'
    return
  end

  if not spotify.auth_info then
    logger.info 'Authenticating with Spotify...'
    spotify.authenticate()
  end

  logger.debug('Searching for %s: "%s"', search_type, query)

  -- Perform the search
  requests.search(query, search_type, 20, 0, function(response_body, response_headers, status_code)
    if status_code ~= 200 then
      logger.error('Search failed. Status: %d, Response: %s', status_code, vim.inspect(response_body))
      return
    end

    local results = parse_search_results(response_body, search_type)

    if #results == 0 then
      logger.info('No %ss found for query: "%s"', search_type, query)
      return
    end

    -- Create Telescope picker
    local pickers = require 'telescope.pickers'
    local finders = require 'telescope.finders'
    local conf = require('telescope.config').values
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    vim.schedule(function()
      pickers
        .new({}, {
          prompt_title = string.format('Spotify %s Search: %s', search_type:gsub('^%l', string.upper), query),
          finder = finders.new_table {
            results = results,
            entry_maker = function(result)
              local display_text, ordinal_text = format_result(result, search_type)
              return {
                value = result,
                display = display_text,
                ordinal = ordinal_text,
              }
            end,
          },
          sorter = conf.generic_sorter {},
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                play_result(selection.value, search_type)
              end
            end)
            return true
          end,
        })
        :find()
    end)
  end)
end

return M
