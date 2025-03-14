local utils = require 'smm.controller.utils'
local timer = require 'smm.timer.timer'
local api = require 'smm.api.api'
local playback = require 'smm.ui.playback'

local M = {}

---@type Playback_Info|nil
M.playback_info = nil

---@type Auth_Info|nil
M.auth_info = nil

---@type Timer|nil
M.timer = nil

---@type boolean
M.is_syncing_playback = false

--- @param auth_info Auth_Info
--- Creates the playback window, using the current playback_info state
function M.start_playback(auth_info) end

function M.stop_playback() end

local function fetch_playback_data()
  M.is_syncing_playback = true
  api.get_playback_state(M.auth_info, function(playback_data, _, status_code)
    local playback_info = utils.create_playback_data(playback_data)

    if status_code ~= 200 or not playback_info then
      vim.schedule(function()
        local lines = { 'No track currently playing' }
        playback.update_window(lines)
      end)
      M.is_syncing = false
      return
    end
    M.is_syncing_playback = false
  end)
end

-- Setup the timer for UI updates and periodic sync
-- function M.setup_timer()
--   -- Create timer with the current playback position
--   M.timer = timer.create_timer {
--     initial_pos = M.playback_info and M.playback_info.current_ms or 0,
--     on_sync = function(done_callback)
--       -- Skip if already syncing
--       if M.is_syncing then
--         done_callback(M.playback_info and M.playback_info.playing or false)
--         return
--       end
--
--       M.is_syncing = true
--
--       -- We'll track when both operations are done
--       local pending_operations = 2
--       local function complete_operation()
--         pending_operations = pending_operations - 1
--         if pending_operations <= 0 then
--           M.is_syncing = false
--           done_callback(M.playback_info and M.playback_info.playing or false)
--         end
--       end
--
--       -- Sync playback info
--       api.get_playback_state(M.auth_info, function(playback_data, _, status_code)
--         if status_code == 200 and playback_data and playback_data.item then
--           local new_playback_info = {
--             id = playback_data.item.id,
--             artist = playback_data.item.artists[1].name,
--             track = playback_data.item.name,
--             duration_ms = playback_data.item.duration_ms,
--             current_ms = playback_data.progress_ms,
--             playing = playback_data.is_playing,
--           }
--
--           -- Track ID changed?
--           local track_changed = not M.playback_info or M.playback_info.id ~= new_playback_info.id
--           M.playback_info = new_playback_info
--
--           -- Reset timer with the correct position from the API
--           timer.reset(M.timer, M.playback_info.current_ms)
--         end
--         complete_operation()
--       end)
--
--       -- Sync queue info
--       api.get_user_queue(M.auth_info, function(queue_data, _, queue_status_code)
--         if queue_status_code == 200 and queue_data and queue_data.queue then
--           M.queue_info = {}
--           for _, v in ipairs(queue_data.queue) do
--             table.insert(M.queue_info, {
--               id = v.id,
--               artist = v.artists[1].name,
--               track = v.name,
--               duration_ms = v.duration_ms,
--             })
--           end
--         end
--         complete_operation()
--       end)
--     end,
--
--     on_update = function(current_ms)
--       if not M.playback_info then
--         return
--       end
--
--       -- Update current position
--       M.playback_info.current_ms = current_ms
--
--       -- Force sync if we've reached the end of the track
--       if current_ms >= M.playback_info.duration_ms then
--         timer.force_sync(M.timer)
--         return
--       end
--
--       -- Update UI
--       vim.schedule(function()
--         if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
--           local updated_text = utils.format_playback_info(M.playback_info)
--
--           -- Adjust window height if needed
--           if M.win and vim.api.nvim_win_is_valid(M.win) then
--             local config = vim.api.nvim_win_get_config(M.win)
--             if config.height ~= #updated_text then
--               config.height = #updated_text
--               vim.api.nvim_win_set_config(M.win, config)
--             end
--           end
--
--           -- Only update if the content has changed (prevents flickering)
--           local current_lines = vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)
--           local needs_update = #current_lines ~= #updated_text
--
--           if not needs_update then
--             for i, line in ipairs(current_lines) do
--               if line ~= updated_text[i] then
--                 needs_update = true
--                 break
--               end
--             end
--           end
--
--           if needs_update then
--             vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, updated_text)
--           end
--         else
--           M.cleanup()
--         end
--       end)
--     end,
--   }
--
--   -- We start the timer and begin updating if the track is playing
--   timer.start(M.timer)
--   if M.playback_info and M.playback_info.playing then
--     timer.resume(M.timer)
--   else
--     timer.pause(M.timer)
--   end
-- end
--
-- function M.pause_track()
--   if not M.auth_info then
--     vim.notify('No authentication information available', vim.log.levels.ERROR)
--     return
--   end
--
--   timer.pause(M.timer)
--   if M.playback_info then
--     M.playback_info.playing = false
--   end
--
--   api.pause_track_async(M.auth_info, function(response_body, response_headers, code)
--     if code ~= 200 then
--       vim.notify('Failed to pause track: ' .. (code or 'unknown error'), vim.log.levels.ERROR)
--       timer.start(M.timer)
--     end
--   end)
-- end
--
-- --- Stops the playback window and removes all underlying resources
-- function M.close_playback_window()
--   if M.win and vim.api.nvim_win_is_valid(M.win) then
--     vim.api.nvim_win_close(M.win, true)
--     M.win = nil
--   end
--
--   if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
--     vim.api.nvim_buf_delete(M.buf, { force = true })
--     M.buf = nil
--   end
--
--   if M.update_timer then
--     M.stop_window_updates()
--   end
-- end
--
-- -- Clean up all resources
-- function M.cleanup()
--   if M.timer then
--     timer.cleanup(M.timer)
--     M.timer = nil
--   end
--   M.close_playback_window()
--   M.playback_info = nil
--   M.queue_info = nil
--   M.is_syncing = false
-- end
--
return M
