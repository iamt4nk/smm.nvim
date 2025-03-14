vim.api.nvim_create_user_command('Spotify', function()
  local auth = require 'smm.auth.oauth'
  local playback = require 'smm.ui.playback'

  if playback.win == nil then
    local auth_info
    local new_auth_info = auth.ensure_valid_token(auth_info)
    if new_auth_info then
      auth_info = new_auth_info
      playback.show_window()
    else
      vim.notify('Unable to authenticate', vim.log.levels.ERROR)
    end
  else
    playback.cleanup()
  end
end, {
  desc = 'Open spotify window',
})

vim.api.nvim_create_user_command('SpotifyPause', function()
  require('smm.ui.old_playback').pause_track()
end, { desc = 'Pauses the currently playing song' })

vim.api.nvim_create_user_command('SpotifyResume', function()
  require('smm.ui.old_playback').resume_track()
end, { desc = 'Resumes the currently playing song' })
