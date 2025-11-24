# --- RStudio Shortcuts & Dev Dependencies ---
# Set custom keyboard shortcuts and keep dev packages tracked by renv.

library(styler)     # Code formatting
library(shrtcts)    # Keybinding management

#' Style Selection
#' @shortcut Ctrl+Alt+A
function() {
  styler::style_selection()
}