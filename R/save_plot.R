#' Save a plot to one or more file formats with overwrite safety
#'
#' Saves ggplot/patchwork objects, recorded base plots (`recordPlot()`), or plot-drawing
#' functions to disk. Supports multiple formats in a single call (e.g., `c("png", "svg")`)
#' and uses an overwrite-safe policy:
#' \itemize{
#'   \item Interactive sessions prompt to overwrite, rename existing, or skip.
#'   \item Non-interactive sessions optionally compare file hashes; if different, the
#'   existing file is renamed using its last-modified timestamp before writing the new file.
#' }
#'
#' For base R plots, you can pass an expression like `plot(x, y)` or pass a previously drawn
#' plot object (`p <- plot(x, y)` yields `NULL`) and the function will attempt to capture the
#' current device output via `recordPlot()`.
#'
#' @param plot A plot to save. Supported inputs:
#'   \itemize{
#'     \item A ggplot/patchwork object (anything inheriting from `"ggplot"`).
#'     \item A `"recordedplot"` object, typically produced by [grDevices::recordPlot()].
#'     \item A function with no arguments that draws a plot (useful for base graphics).
#'     \item A plotting expression (e.g., `plot(x, y)`) supplied directly to `plot`.
#'   }
#' @param name Character scalar. File name stem (no extension), e.g. `"my_plot"`.
#' @param format Character vector of output formats, e.g. `"png"` or `c("png", "svg")`.
#'   Leading dots are allowed (e.g. `".png"`).
#' @param target Character. Output folder relative to `getwd()` (default `"."`).
#' @param width,height Plot dimensions. Interpretation depends on the graphics device.
#' @param units Units for raster devices (e.g., `"in"`, `"px"`, `"cm"`).
#' @param dpi Resolution for raster formats (used for png/jpeg).
#' @param prompt Logical. If `TRUE`, prompt before overwriting when a file exists.
#'   Default is `interactive()`.
#' @param compare Logical. In non-interactive mode, if `TRUE`, compare MD5 hashes between
#'   the new and existing file; if identical, keep the original.
#' @param create_dir Logical. If `TRUE`, create the target directory if it does not exist.
#'
#' @return Invisibly returns a character vector of file paths written (or retained when
#'   identical under `compare = TRUE`).
#'
#' @examples
#' \dontrun{
#' # ggplot / patchwork
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' save_plot(p, name = "scatter", format = c("png", "svg"), target = "output/figures")
#'
#' # base plot via expression
#' save_plot(plot(mtcars$wt, mtcars$mpg), name = "base_scatter")
#'
#' # base plot already drawn (p is NULL)
#' p0 <- plot(mtcars$wt, mtcars$mpg)
#' save_plot(p0, name = "base_scatter2")
#'
#' # base plot via function
#' save_plot(function() plot(mtcars$wt, mtcars$mpg), name = "base_scatter3")
#' }
save_plot <- function(plot, name, format = "png", target = ".",
                      width = 7, height = 5, units = "in", dpi = 300,
                      prompt = interactive(),
                      compare = TRUE, create_dir = TRUE) {
  # Normalize arguments
  format <- tolower(format)
  format <- sub("^\\.", "", format)
  stopifnot(is.character(name), length(name) == 1, nzchar(name))
  stopifnot(is.character(format), length(format) >= 1)
  
  # Set target folder
  out_dir <- if (is.null(target) || target == "" || target == ".") {
    getwd()
  } else {
    file.path(getwd(), target)
  }
  if (!dir.exists(out_dir)) {
    if (create_dir) {
      dir.create(out_dir, recursive = TRUE)
    } else {
      stop("Target directory does not exist: ", out_dir)
    }
  }
  
  # Create a drawer
  expr <- substitute(plot)
  # If user passed a variable (like "p") or an object, evaluate it
  # Assume that if it's NULL the plot was just drawn and capture it
  if (!is.call(expr)) {
    obj <- eval(expr, parent.frame())
    
    if (is.null(obj)) {
      if (grDevices::dev.cur() == 1L) stop ("No active graphics device to capture from.")
      obj <- recordPlot() # Capture current plot before opening file device
    }
    
    plot_obj <- obj
    draw <- if (inherits(plot_obj, "ggplot")) {
      function() print(plot_obj)
    } else if (inherits(plot_obj, "recordedplot")) {
      function() replayPlot(plot_obj)
    } else if (is.function(plot_obj)) {
      plot_obj
    } else {
      stop("Unsupported plot type. Supply ggplot/recordedplot/function, or an expression like plot(x,y).")
    }
  } else {
    # Expression mode: evaluate the expression INSIDE the output device.
    draw <- function() {
      val <- eval(expr, parent.frame())
      
      if (inherits(val, "ggplot")) {
        print(val)
      } else if (inherits(val, "recordedplot")) {
        replayPlot(val)
      } else if (is.function(val)) {
        val()
      } else {
        # Most base plots: val is NULL because the expression drew the plot already.
        invisible(NULL)
      }
    }
  }
  
  # Helper for timestamps
  file_time_tag <- function(path, fmt = "%Y%m%d%H%M") {
    if (!file.exists(path)) return(format(Sys.time(), fmt))
    
    info <- file.info(path)
    
    if (!is.na(info$mtime)) {
      t <- info$mtime
    } else if (!is.na(info$ctime)) {
      t <- info$ctime
    } else {
      t <- Sys.time()
    }
    
    format(t, fmt)
  }
  
  # Helper to open a graphics device for the given format
  open_device <- function(fmt, filename) {
    fmt <- tolower(fmt)
    if (fmt == "png") {
      grDevices::png(filename, width = width, height = height, units = units, res = dpi)
    } else if (fmt %in% c("jpg", "jpeg")) {
      grDevices::jpeg(filename, width = width, height = height, units = units, res = dpi)
    } else if (fmt == "svg") {
      grDevices::svg(filename, width = width, height = height)
    } else if (fmt == "pdf") {
      grDevices::pdf(filename, width = width, height = height)
    } else {
      stop("Unsupported format: ", fmt)
    }
  }
  
  # Helper to render the plot to a file & close device
  render_to_file <- function(fmt, filename) {
    open_device(fmt, filename)
    on.exit(grDevices::dev.off(), add = TRUE)
    draw()
    invisible(filename)
  }
  
  # Helper to get name string
  md5 <- function(path) unname(tools::md5sum(path))
  
  # Helper to prompt for instructions if file exists
  interactive_choice <- function(path) {
    msg <- paste0("File exists:\n ", path, "\nChoose: [o]verwrite, [r]ename existing, [s]kip: ")
    ans <- tolower(trimws(readline(msg)))
    if (ans %in% c("o", "overwrite")) "overwrite"
    else if (ans %in% c("r", "rename")) "rename"
    else "skip"
  }
  
  # Main loop over formats
  saved_paths <- character(0)
  
  for (fmt in format) {
    final_path <- file.path(out_dir, paste0(name, ".", fmt))
    tmp_path <- tempfile(pattern = paste0(name, "_"), fileext = paste0(".", fmt))
    
    render_to_file(fmt, tmp_path)
    
    if (file.exists(final_path)) {
      if (prompt) {
        action <- interactive_choice(final_path)
        
        if (action == "skip") {
          unlink(tmp_path)
          next
        }
        
        if (action == "rename") {
          backup <- file.path(out_dir, paste0(name, "_", file_time_tag(final_path), ".", fmt))
          file.rename(final_path, backup)
        }
        # Overwrite just falls through
      } else {
        # non-interactive behavior
        if (compare) {
          # Note that this is a byte level compare and may differ due to metadata in some formats
          same <- identical(md5(tmp_path), md5(final_path))
          if (same) {
            unlink(tmp_path)
            saved_paths <- c(saved_paths, final_path)
            next
          }
        }
        backup <- file.path(out_dir, paste0(name, "_", file_time_tag(final_path), ".", fmt))
        file.rename(final_path, backup)
      }
    }
    
    file.rename(tmp_path, final_path)
    saved_paths <- c(saved_paths, final_path)
  }
  invisible(saved_paths)
}