vim.api.nvim_create_user_command('Spotify', function()
  local auth = require 'smm.auth.oauth'
  local controller = require 'smm.controller.controller'
  vim.notify('Imported dependencies', vim.log.levels.INFO)

  if not controller.auth_info then
    local auth_info
    local new_auth_info = auth.ensure_valid_token(auth_info)
    vim.notify('got valid auth token', vim.log.levels.INFO)
    if new_auth_info then
      auth_info = new_auth_info
      vim.notify('starting playback', vim.log.levels.INFO)
      controller.start_playback(auth_info)
      require('smm.controller.controller').get_profile_type()
      vim.notify('received profile type', vim.log.levels.INFO)
    else
      vim.notify('Unable to authenticate', vim.log.levels.ERROR)
    end
  else
    controller.cleanup()
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
