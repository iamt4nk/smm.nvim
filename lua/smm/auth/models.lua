---@alias SpotifyClient { client_id: string, callback_url: string, scope: string[] }
---@alias Auth_Info { access_token: string, token_type: string, expires_in: integer, refresh_token: string, scope: string }

local M = {}

---@type SpotifyClient
M.spotify = {
  client_id = 'c43057d088204249bca8d5bde4e93bd3',
  callback_url = 'https://127.0.0.1:8080/callback',
  scope = {
    'user-read-playback-state',
    'user-read-currently-playing',
    'user-modify-playback-state',
    'user-read-private',
  },
}

return M
