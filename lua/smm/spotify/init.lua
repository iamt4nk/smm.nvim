local auth = require 'smm.spotify.auth'
local token = require 'smm.spotify.token'
local config = require 'smm.spotify.config'
local logger = require 'smm.utils.logger'
local requests = require 'smm.spotify.requests'

local M = {}

M.auth_info = nil

local function check_and_update_account_type()
  requests.get_user_profile(function(response_body, response_headers, status_code)
    if status_code == 200 and response_body and response_body.product then
      local actual_account_type = response_body.product -- 'free' or 'premium'

      local config_module = require 'smm.config'
      local current_config = config_module.get()

      if current_config.premium == true and actual_account_type == 'free' then
        -- Update the config
        current_config.premium = false

        -- Re-register commands with free account permissions
        vim.schedule(function()
          local commands = require 'smm.commands'
          commands.setup()

          -- Create window warning that account is free.
          local lines = {
            'FREE Spotify account detected!',
            '',
            'Your configuration does not specify premium = false but SMM detected that your account is free.',
            '',
            'You will be unable to use any commands that change playback in any way.',
            'To suppress this window please set the following in your configuration:',
            '{',
            '  premium = false',
            '}',
            '',
            'Press <Esc> or :q to close this message',
          }

          lines = require('smm.playback.interface.utils').pad_lines(lines, 2, 4, 2, 4)

          local width = 100
          local height = #lines

          local buf = vim.api.nvim_create_buf(false, true)
          vim.bo[buf].buftype = 'nofile'
          vim.bo[buf].bufhidden = 'wipe'
          vim.bo[buf].swapfile = false
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

          local ui = vim.api.nvim_list_uis()[1]
          local row = math.floor((ui.height - height) / 2)
          local col = math.floor((ui.width - width) / 2)

          local title = ' Spotify Free Account Warning '

          if require('smm.playback.interface.config').get().icons == true then
            title = '  ' .. title
          end

          local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
            style = 'minimal',
            border = 'rounded',
            title = title,
            title_pos = 'center',
          })

          vim.api.nvim_set_hl(0, 'SpotifyGreen', { fg = '#1ED760' })
          vim.wo[win].winhighlight = 'FloatTitle:SpotifyGreen,FloatBorder:SpotifyGreen'

          vim.keymap.set('n', '<ESC>', function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, { buffer = buf })
        end)
      end
    else
      logger.debug('Could not fetch user profile for account type detection. Status: %d, Error:\n%s', status_code, response_body)
    end
  end)
end

function M.authenticate()
  local refresh_token = token.load_refresh_token()

  if not refresh_token then
    logger.info 'No refresh token found - initiating OAuth Flow'
    M.auth_info = auth.initiate_oauth_flow()
  else
    M.auth_info = auth.refresh_access_token(refresh_token)
  end

  check_and_update_account_type()

  token.delete_refresh_token()
  token.save_refresh_token(M.auth_info.refresh_token)
end

---@param user_config SMM_SpotifyConfig
function M.setup(user_config)
  config.setup(user_config)

  --- Inject retry configurations into the requests module specifically
  requests.api_retry_max = config.get().api_retry_max
  requests.api_retry_backoff = config.get().api_retry_backoff

  logger.debug 'Initializing Spotify - Auth Module Config'
  auth.setup(user_config.auth)
end

return M
