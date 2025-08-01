local M = {}

---@alias SMM_SpotifyAuthConfig { enabled: boolean, client_id: string, callback_url: string, callback_port: integer, premium: string, scope: string[]}

---@type SMM_SpotifyAuthConfig
local config = {}

---@param user_config SMM_SpotifyAuthConfig
function M.setup(user_config)
  config = user_config
  if config.premium then
    config.scope = {
      'user-read-playback-state',
      'user-read-currently-playing',
      'user-modify-playback-state',
      'user-read-private',
    }
  else
    config.scope = {
      'user-read-playback-state',
      'user-read-private',
    }
  end
end

---@return SMM_SpotifyAuthConfig
function M.get()
  return config
end

function M.get_value(key)
  return config[key]
end

return M
