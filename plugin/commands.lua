vim.api.nvim_create_user_command('Spotify', function()
  local auth = require 'smm.auth.oauth'
  local controller = require 'smm.controller.controller'

  local auth_info

  if not controller.auth_info then
    local new_auth_info = auth.ensure_valid_token(auth_info)
    if new_auth_info then
      auth_info = new_auth_info
    else
      vim.notify('Unable to authenticate', vim.log.levels.ERROR)
      return
    end
  end

  if controller.playback_window_is_showing then
    controller.cleanup()
  else
    controller.start_playback(auth_info)
    controller.get_profile_type()
  end
end, {
  desc = 'Open spotify window',
})

vim.api.nvim_create_user_command('SpotifyPause', function()
  require('smm.controller.controller').pause_track()
end, { desc = 'Pauses the currently playing song' })

vim.api.nvim_create_user_command('SpotifyResume', function()
  require('smm.controller.controller').resume_track()
end, { desc = 'Resumes the currently playing song' })
