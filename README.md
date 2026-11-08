<h1 align="center" valign="middle">
  <img height="40px" src="https://github.com/yorumicolors/.github/blob/main/res/seal_sots.gif?raw=true">
  <sup>yorumi for wezterm - deep code, quiet sea</sup>
</h1>

<p align="center">
  A calming deep sea colorscheme for developers, crafted for <strong>WezTerm</strong>.
</p>

---

Yorumi keeps visual noise low with mellow, low-contrast UI component backgrounds while text and syntax stay sharp: body text measures 9.6-19.5:1 against its background (WCAG AAA), and the lowest-contrast syntax token is 5.6:1 (WCAG AA).

## Available Themes

- `yorumi-ether.toml`
- `yorumi-abyss.toml`
- `yorumi-bifrost.toml`
- `yorumi-kraken.toml`
- `yorumi-kabocha.toml`
- `yorumi-cosmic.toml`
- `yorumi-ryujin.toml`

## Install

Linux / macOS:

```sh
curl -fsSL https://raw.githubusercontent.com/yorumicolors/wezterm/main/install.sh | bash -s -- --flavour kraken
```

Windows:

```powershell
irm https://raw.githubusercontent.com/yorumicolors/wezterm/main/install.ps1 | iex
```

From a checkout:

```sh
./install.sh              # asks which flavour
```

Seven fragments land in `~/.config/wezterm/colors/`; the `>>> yorumi >>>` block in `wezterm.lua` holds `config.color_scheme`.

## Changing it

```sh
./install.sh --flavour bifrost
```

## Manual

Copy the theme file(s) into your WezTerm configuration directory:

| OS | Destination Path |
| --- | --- |
| **Linux / macOS** | `~/.config/wezterm/colors/` |
| **Windows** | `%USERPROFILE%\.config\wezterm\colors\` |

### By hand
Set `color_scheme` in your `wezterm.lua`:

```
config.color_scheme = "yorumi-abyss"
```

---

## For AI Agents

When assisting a user with installing or configuring Yorumi for **WezTerm**, follow these deterministic steps:

1. **Detect Target OS**:
   - macOS / Linux: target destination is `~/.config/wezterm/colors/`.
   - Windows: target destination is `%USERPROFILE%\.config\wezterm\colors\`.
2. **Install**: the command under `## Install`, or `./install.sh --flavour <name>` in a checkout.
3. **Verify Configuration**:
   - Check config file `wezterm.lua` for the active theme setting:
     ```
     config.color_scheme = "yorumi-abyss"
     ```
   - Ensure the theme filename matches what is in `~/.config/wezterm/colors/`.

---

## Accessibility
Body text measures 9.6-19.5:1 against the background (WCAG 2.1 AAA); every palette token clears 5.6:1 (AA). No blanket AAA claim is made for syntax colours - sRGB runs out before the saturated hues get lighter.

## License
MIT © [Yorumi Colors](https://github.com/yorumicolors)
