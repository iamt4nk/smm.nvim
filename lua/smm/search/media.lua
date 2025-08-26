local logger = require 'smm.utils.logger'
local requests = require 'smm.spotify.requests'
local Track = require('smm.models.track').Track
local Album = require('smm.models.album').Album
local Artist = require('smm.models.artist').Artist
local Playlist = require('smm.models.playlist').Playlist

local M = {}

---Parse search results and convert to model objects
---@param search_response table
---@param search_type string
---@return table[] -- Array of model objects
function M.parse_search_results(search_response, search_type)
  local results = {}

  if not search_response or not search_response[search_type .. 's'] then
    logger.debug('No results found for search type: %s', search_type)
    return results
  end

  local items = search_response[search_type .. 's'].items or {}

  for _, item in ipairs(items) do
    if item == vim.NIL then
      goto continue
    end
    if search_type == 'track' then
      local artists = {}
      for _, artist_data in ipairs(item.artists or {}) do
        table.insert(artists, Artist:new(artist_data))
      end

      local album = Album:new(item.album)

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
    ::continue::
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

---Search for different types of media
---@param search_results table[]
---@param search_type string
---@param callback fun(result: SMM_Track|SMM_Album|SMM_Artist|SMM_Playlist, search_type: SMM_MediaType) Callback for when user selects result
function M.show_results_window(search_results, search_type, callback)
  -- Create Telescope picker
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local title = string.format(' Spotify %s Search: %s', search_type:gsub('^%l', string.upper), query)

  if require('smm.config').get().icons == true then
    title = '  ' .. title
  end

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table {
        results = search_results,
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
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and callback then
            callback(selection.value, search_type)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
