# Spotify Music Manager - Neovim

> [!WARNING]  
> This plugin is currently in beta, of which there are limited spots. To sign up for the beta program, sign up [here](https://www.surveymonkey.com/r/FQSSS57).  

> [!CAUTION]  
> Currently the Spotify API does not allow free users to make any changes to playback. If you are a free user. Then please note you will still be able to view playback. But you will be unable to make any playback changes directly via the app. Unfortunately, there is nothing we can do about that.

SMM.nvim is a simple, minimal implementation for Spotify that allows users (currently) to view and control their current Spotify playback.

_**NOTE**_: This plugin does NOT stream any music itself, but rather it controls the current spotify player (regardless of device).

![SMM Demo](./assets/smm_demo.gif)

Installation:
- Use the following to install this plugin:  
LazyVim:  
```lua
{
    'iamt4nk/smm.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim'
    },
   config = {
      playback = {
         timer_update_interval = 100,     -- How often the timer itself is  updated
         timer_sync_interval = 5000,      -- How often sync requests are sent to the server.
         interface = {
            playback_pos = 'BottomRight', -- Options { 'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight' }
            playback_width = 40,          -- Width of the playback window
            progress_bar_width = 35,      -- Width of the progress bar
         },
      },

      spotify = {
         auth = {
            premium = true,
         },
      },
   },
},
```
(Feel free to add a PR with instructions to install for your package manager.)
  
> [!WARNING]  
> The configuration above are the defaults. Feel free to change any of these how you see fit. Do __*NOT*__ change any other configurations in the auth section you may find. They need to remain exactly how they see fit.

_**NOTE**_: Use the "nightly" branch for regular, untested updates.


### Execution
To run this plugin for the first time run the command:
```
:Spotify auth
```

This will initiate an OAuth procedure, which, once completed will store a refresh token in your `$HOME/.local/state/nvim/spotify` directory, as well as store an api access token in memory.

Afterwards you can run:
```
:Spotify
```

This will create a playback window, and start sending API requests to Spotify servers to start showing the track you are currently playing.  

**NOTE**: Spotify Apps that use the [Spotify Web API](https://developer.spotify.com/documentation/web-api) do not allow you to specify a webhook. This pretty much means that the only thing we can do on the plugin is send requests every so often to sync with the servers.

To stop the playback, simply run the same command.

### Other Commands
There are a few other commands you can currently run if you are a Spotify Premium User:
- `:Spotify pause`: Pauses current song
- `:Spotify resume`: Resumes current song
