# Yorumi Themes for WezTerm

| ![image](https://github.com/user-attachments/assets/5aad817e-09f7-44e9-a3c8-69fcd7b261cc) | ![image](https://github.com/user-attachments/assets/72c68113-6bda-444b-a833-2cb56ec5c2ba) |
| --- | --- |
| yorumi abyss | yorumi mist |
| ![image](https://github.com/user-attachments/assets/e668a132-b6a0-4074-864a-1750875de1b6) | ![image](https://github.com/user-attachments/assets/8423b05f-aad7-44d5-a3ec-e4101cf24a5b) |
| yorumi shade | yorumi kraken |


### Installation

Download the themes into your colors directory. This is normally `~/.config/wezterm/colors` directory on a POSIX system.
```bash
curl -L -o /tmp/yorumi-abyss https://raw.githubusercontent.com/yorumicolors/wezterm/refs/heads/main/yorumi-abyss.toml
curl -L -o /tmp/yorumi-mist https://raw.githubusercontent.com/yorumicolors/wezterm/refs/heads/main/yorumi-mist.toml
curl -L -o /tmp/yorumi-shade https://raw.githubusercontent.com/yorumicolors/wezterm/refs/heads/main/yorumi-shade.toml
curl -L -o /tmp/yorumi-kraken https://raw.githubusercontent.com/yorumicolors/wezterm/refs/heads/main/yorumi-kraken.toml
mkdir -p $HOME/.config/wezterm/themes
mv /tmp/yorumi-{abyss,mist,shade,kraken} $HOME/.config/wezterm/colors
```

You can then simply set the colorscheme on your `.wezterm.lua` as
```lua
local wezterm = require('wezterm')
local config = wezterm.config_builder()
-- ... 

-- Optionally: config.color_scheme_dirs = { '/.../.config/wezterm/colors/' }
config.color_scheme = 'Yorumi Mist' -- Options: Yorumi-[Mist|Abyss|Kraken|Shade]

-- ...
```

