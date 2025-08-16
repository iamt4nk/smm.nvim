local logger = require 'smm.utils.logger'
local requests = require 'smm.spotify.requests'
local Device = require('smm.models.device').Device

local M = {}

---Parse search results and convert to model objects
---@param search_response table
---@return SMM_Device[]  -- Array of device objects
local function parse_search_results(search_response)
  local results = {}

  if not search_response then
    logger.debug 'No results found'
    return results
  end

  local devices = search_response['devices'] or {}

  for _, device in ipairs(devices) do
    table.insert(results, Device:new(device))
  end

  logger.debug('Parsed %d results for devices', #results)
  return results
end

---Format a result for display in Telescope
---@param result SMM_Device
---@return string display_text, string ordinal_text
local function format_result(result)
  local device_name = result:get_display_name()
  local type = result.type
  local active = result.is_active

  local display_text = string.format('%s - %s %s', device_name, type, active and tostring(active) or '')
  local ordinal_text = string.format('%s %s %s', device_name, type, active and tostring(active) or '')

  return display_text, ordinal_text
end

---Search for available devices
---@param callback fun(result_device: SMM_Device)
function M.search(callback)
  local has_telescope, _ = pcall(require, 'telescope')

  if not has_telescope then
    logger.error 'Telescope is required for search functionality. Please install nvim-telescope/telescope.nvim as a dependency'
    return
  end

  logger.debug 'Getting all devices'

  --Perform the search
  requests.get_available_devices(function(response_body, response_headers, status_code)
    if status_code ~= 200 then
      logger.error('Getting devices failed. Status: %d, Response: %s', status_code, vim.inspect(response_body))
      return
    end

    local results = parse_search_results(response_body)

    if #results == 0 then
      logger.info 'No devices found'
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
          prompt_title = string.format 'Available Spotify Devices',
          finder = finders.new_table {
            results = results,
            entry_maker = function(result)
              local display_text, ordinal_text = format_result(result)
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
              if selection and callback then
                callback(selection.value)
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
