#' Export controls for Quarto-driven workflows
#'
#' Provides a simple "mode"-based interface (e.g., \code{mode = "analysis"})
#' to control exporting figures and tables during Quarto renders.
#'
#' This module is intended to be sourced from your Quarto setup chunk and used
#' to configure defaults for \code{save_plot()} (figures) and \code{saveRDS()}
#' (tables / objects).
#'
#' @details
#' Typical usage (in your Quarto setup chunk):
#'
#' \preformatted{
#' source("R/export_controls.R")
#' source("R/save_plot.R")
#'
#' ctrl <- export_controls(mode = "analysis")
#'
#' # Wrap save_plot() so you don't need to pass prompt/overwrite/backup/compare every time
#' save_plot <- apply_save_plot_defaults(
#'   save_plot,
#'   ctrl,
#'   default_target = "output/figures",
#'   default_format = c("png", "svg")
#' )
#' }
#'
#' \strong{How the flags map to \code{save_plot()}}:
#' When an output file already exists and \code{prompt = FALSE} (typical during full renders),
#' \code{save_plot()} behaves as follows:
#' \itemize{
#'   \item If \code{compare = TRUE} and the new output is byte-identical (MD5 matches):
#'         the temp file is discarded and the existing file is kept (no change).
#'   \item If the file differs:
#'     \itemize{
#'       \item If \code{overwrite = TRUE}: the existing file is removed and replaced in-place.
#'       \item Else if \code{backup = TRUE}: the existing file is renamed with a timestamp suffix,
#'             and the new file is written to the original name.
#'       \item Else (\code{overwrite = FALSE} and \code{backup = FALSE}): the new output is discarded
#'             and the existing file is kept (i.e., "skip if exists").
#'     }
#' }
#'
#' \strong{Modes (presets)}:
#' These are convenience presets for the above flags. The short summary below assumes
#' a file already exists at the target path.
#'
#' \describe{
#'   \item{analysis}{
#'     No exporting. \code{ctrl$outputs = FALSE}. You typically still draw plots/tables in the
#'     rendered document, but you do not write artifacts to \code{output/figures} or \code{output/tables}.
#'   }
#'
#'   \item{export_overwrite}{
#'     Export artifacts and overwrite in place (no backups).
#'     \itemize{
#'       \item If file exists: always replace it (typically with \code{compare = FALSE} for speed).
#'       \item Best for: "regenerate everything deterministically" runs.
#'     }
#'   }
#'
#'   \item{export_backup}{
#'     Export artifacts; keep timestamped backups for changed files.
#'     \itemize{
#'       \item If file exists and differs: rename old file to \code{name_YYYYMMDDHHMM.ext}, then write new.
#'       \item If file exists and identical (MD5 matches): do nothing.
#'       \item Best for: safe iteration when you want an automatic version trail.
#'     }
#'   }
#'
#'   \item{export_new_only}{
#'     Export only when missing (skip-if-exists behavior).
#'     \itemize{
#'       \item If file does not exist: write it.
#'       \item If file exists and identical: do nothing.
#'       \item If file exists and differs: do nothing (keeps the existing file).
#'       \item Best for: "populate an empty artifacts folder once" or when you never want to touch
#'             already-exported files.
#'     }
#'   }
#'
#'   \item{interactive}{
#'     Export artifacts, but ask what to do on conflicts (overwrite/rename/skip).
#'     \itemize{
#'       \item Intended for manual, interactive use (running chunks at the console).
#'       \item Note: during full Quarto render in RStudio, \code{interactive()} is usually FALSE,
#'             so prompting is generally not desirable unless you explicitly force it.
#'     }
#'   }
#' }
#'
#' \strong{Optional Quarto YAML params (overrides)}:
#' If \code{prefer = "params"} (default), any non-NULL YAML param overrides the mode preset:
#'
#' \preformatted{
#' params:
#'   export_mode: export_backup
#'   save_outputs: true
#'   save_prompt: false
#'   save_overwrite: false
#'   save_backup: true
#'   save_compare: true
#' }
#'
#' This lets you keep a stable \code{export_mode} while occasionally tweaking one behavior
#' (e.g., turning MD5 comparison on/off).
#'
#' \strong{Creating custom modes}:
#' There are two common patterns.
#'
#' \emph{A) Add a new preset inside \code{export_controls()}} (edit this file):
#' Add an entry to the internal \code{presets} list, e.g.:
#' \preformatted{
#' presets$export_backup_no_md5 <- list(
#'   outputs = TRUE,
#'   prompt = FALSE,
#'   overwrite = FALSE,
#'   backup = TRUE,
#'   compare = FALSE   # faster, but will back up + rewrite even if content didn't change
#' )
#' }
#' Then call \code{export_controls(mode = "export_backup_no_md5")}.
#'
#' \emph{B) Post-process a control list without editing this file}:
#' In your setup chunk:
#' \preformatted{
#' ctrl <- export_controls(mode = "export_backup")
#' ctrl$compare <- FALSE     # custom tweak
#' ctrl$mode <- "export_backup_no_md5"
#' }
#' This is useful for one-off experimentation or project-specific tweaks.
#'
#' @param mode Character scalar. One of:
#'   \code{"analysis"}, \code{"export_overwrite"}, \code{"export_backup"},
#'   \code{"export_new_only"}, \code{"interactive"}.
#'   If \code{mode = NULL}, the function will use \code{params$export_mode} if present,
#'   otherwise defaults to \code{"analysis"}.
#' @param params Optional named list (Quarto's \code{params}). If NULL, attempts to find
#'   \code{params} in the calling environment.
#' @param prefer Character scalar: \code{"params"} (default) or \code{"mode"}.
#'   If \code{"params"}, any non-NULL YAML param overrides the mode preset.
#'   If \code{"mode"}, the preset wins (params ignored except \code{export_mode} when mode=NULL).
#'
#' @return A list with fields:
#'   \itemize{
#'     \item \code{mode} mode used
#'     \item \code{outputs} logical; whether you intend to write artifacts at all
#'     \item \code{prompt} logical; whether to prompt on conflicts
#'     \item \code{overwrite} logical; overwrite existing outputs in-place
#'     \item \code{backup} logical; rename existing outputs to timestamped backups
#'     \item \code{compare} logical; MD5 compare to skip identical writes
#'   }
export_controls <- function(mode = NULL, params = NULL, prefer = c("params", "mode")) {
  prefer <- match.arg(prefer)
  
  # Retrieve Quarto params if not explicitly passed
  if (is.null(params)) {
    if (exists("params", inherits = TRUE)) {
      params <- get("params", inherits = TRUE)
    } else {
      params <- list()
    }
  }
  
  # Mode can be supplied via YAML param export_mode
  if (is.null(mode)) {
    mode <- params[["export_mode"]]
    if (is.null(mode)) mode <- "analysis"
  }
  
  presets <- list(
    analysis = list(
      outputs = FALSE,
      prompt = NULL,        # NULL -> use interactive()
      overwrite = FALSE,
      backup = TRUE,
      compare = TRUE
    ),
    export_overwrite = list(
      outputs = TRUE,
      prompt = FALSE,
      overwrite = TRUE,
      backup = FALSE,
      compare = FALSE
    ),
    export_backup = list(
      outputs = TRUE,
      prompt = FALSE,
      overwrite = FALSE,
      backup = TRUE,
      compare = TRUE
    ),
    export_new_only = list(
      outputs = TRUE,
      prompt = FALSE,
      overwrite = FALSE,
      backup = FALSE,
      compare = TRUE
    ),
    interactive = list(
      outputs = TRUE,
      prompt = TRUE,
      overwrite = FALSE,
      backup = TRUE,
      compare = TRUE
    )
  )
  
  if (!mode %in% names(presets)) {
    stop("Unknown export mode: ", mode, "\nValid modes: ", paste(names(presets), collapse = ", "))
  }
  
  ctrl <- presets[[mode]]
  
  # Optionally override with YAML params
  if (identical(prefer, "params")) {
    override_if_set <- function(name, current) {
      val <- params[[name]]
      if (is.null(val)) current else val
    }
    
    ctrl$outputs   <- override_if_set("save_outputs",   ctrl$outputs)
    ctrl$prompt    <- override_if_set("save_prompt",    ctrl$prompt)
    ctrl$overwrite <- override_if_set("save_overwrite", ctrl$overwrite)
    ctrl$backup    <- override_if_set("save_backup",    ctrl$backup)
    ctrl$compare   <- override_if_set("save_compare",   ctrl$compare)
  }
  
  # Resolve prompt NULL -> interactive()
  prompt_val <- ctrl$prompt
  ctrl$prompt <- if (is.null(prompt_val)) interactive() else isTRUE(prompt_val)
  
  # Coerce clean logicals
  ctrl$outputs   <- isTRUE(ctrl$outputs)
  ctrl$overwrite <- isTRUE(ctrl$overwrite)
  ctrl$backup    <- isTRUE(ctrl$backup)
  ctrl$compare   <- isTRUE(ctrl$compare)
  
  ctrl$mode <- mode
  ctrl
}

#' Wrap save_plot() with default export policy + destination
#'
#' Returns a function with the usual signature \code{(plot, name, format, target, ...)}.
#' The wrapper supplies default values for \code{prompt}, \code{overwrite}, \code{backup},
#' and \code{compare} from \code{ctrl}, as well as project defaults for \code{target} and
#' \code{format}.
#'
#' Importantly, any of \code{prompt/overwrite/backup/compare} that you pass explicitly in
#' \code{...} will override the defaults from \code{ctrl}. This makes it safe to use a
#' project-wide export mode (e.g., \code{"export_new_only"}) while still forcing a one-off
#' overwrite or backup behavior in a specific chunk.
#'
#' @param save_plot_fun A save_plot-like function.
#' @param ctrl Controls from [export_controls()].
#' @param default_target Default output folder.
#' @param default_format Default format vector (e.g., \code{c("png","svg")}).
#'
#' @return A wrapped \code{save_plot} function with the same calling convention.
apply_save_plot_defaults <- function(save_plot_fun, ctrl,
                                     default_target = "output/figures",
                                     default_format = "png") {
  force(save_plot_fun); force(ctrl); force(default_target); force(default_format)
  
  function(plot, name,
           format = default_format,
           target = default_target,
           ...) {
    
    dots <- list(...)
    
    # Only set defaults if the caller didn't supply them
    if (!"prompt"    %in% names(dots)) dots$prompt    <- ctrl$prompt
    if (!"overwrite" %in% names(dots)) dots$overwrite <- ctrl$overwrite
    if (!"backup"    %in% names(dots)) dots$backup    <- ctrl$backup
    if (!"compare"   %in% names(dots)) dots$compare   <- ctrl$compare
    
    do.call(
      save_plot_fun,
      c(list(plot = plot, name = name, format = format, target = target), dots)
    )
  }
}

#' Conditionally save an R object to disk (tables, models, etc.)
#'
#' Uses \code{ctrl$outputs} as the single switch for whether to write artifacts.
#'
#' @param object Any R object.
#' @param path File path (including extension).
#' @param ctrl Controls from [export_controls()].
#' @param ... Passed to [base::saveRDS()].
#'
#' @return Invisibly returns the path if written; otherwise NULL.
save_rds_if <- function(object, path, ctrl, ...) {
  if (!isTRUE(ctrl$outputs)) return(invisible(NULL))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(object, file = path, ...)
  invisible(path)
}
