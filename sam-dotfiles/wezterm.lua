local wezterm = require 'wezterm';
return {
  use_ime = true,
  show_update_window = false,
  scrollback_lines = 10000,
  adjust_window_size_when_changing_font_size = false,
  check_for_updates = true,
  automatically_reload_config = true,
  audible_bell = "Disabled",
  font_size = 14,
  color_scheme = "Gruvbox dark, medium (base16)",
  hide_tab_bar_if_only_one_tab = true,
  font = wezterm.font_with_fallback({
    "Fira Code",
    "JetBrains Mono",
    "PowerlineExtraSymbols",
    "Noto Color Emoji",
    "Cousine for Powerline",
  }),
  colors = {
    visual_bell = "#ff0000"
  },
  visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = "CursorColor",
  },
}
