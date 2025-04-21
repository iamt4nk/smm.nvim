# Spotify Music Manager - Neovim

> [!Warning] 
> This plugin is currently in beta, of which there are limited spots. To sign up for the beta program, sign up [here](https://www.surveymonkey.com/r/FQSSS57).  

> [!CAUTION]
> Currently the Spotify API does not allow free users to make any changes to playback. If you are a free user. Then please note you will still be able to view playback. But you will be unable to make any playback changes directly via the app. Unfortunately, there is nothing we can do about that.

SMM.nvim is a simple, minimal implementation for Spotify that allows users (currently) to view and control their current Spotify playback.

_**NOTE**_: This plugin does NOT stream any mu,sic itself, but rather it controls the current spotify player (regardless of device).

Installation:
- Use the following to install this plugin:  
LazyVim:  
```lua
{
    'iamt4nk/smm.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim'
    },
},
```
(Feel free to add a PR with instructions to install for your package manager.)

_**NOTE**_: Use the "nightly" branch for regular, untested updates.


### Execution
To run this plugin simply just type:
```
:Spotify
```

This will initiate a few different procedures.  
1. First time running it will start an OAuth flow and direct you through the process of logging in and authorizing the app.  
   **NOTE**: Once successfully completed this will store a refresh token in your `$HOME/.local/state/nvim/smm` directory. If this is deleted then authentication will need to be re-completed.  
1. Generate an authentication token.
1. Start a timer that sends API requests to Spotify servers.  
   **NOTE 2**: Spotify Apps that use the [Spotify Web API](https://developer.spotify.com/documentation/web-api) do not allow you to specify a webhook. This pretty much means that the only thing we can do on the plugin is send requests every so often to sync with the servers.

To stop the playback, simply run the same command.

### Other Commands
There are a few other commands you can currently run if you are a Spotify Premium User:
- `:SpotifyPause`: Pauses current Spotify Playback
- `:SpotifyResume`: Resumes current Spotify Playback
