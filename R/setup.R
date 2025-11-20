# --- Core Packages ---
library(here)               # For robust file paths
library(tidyverse)          # For data manipulation and plotting (ggplot2, dplyr, etc.)

# --- Quarto & Caching Packages ---
library(digest)             # Creates hashes for caching function.
library(future)             # Parallel processing
library(knitr)              # Used for running R code in Quarto

# --- Visualization Packages ---
library(RColorBrewer)       # Color palettes to enable color-blind friendliness

# --- Homework specific packages ---

# --- Set seed for reproducibility ---
set.seed(5027)

# --- Set global chunk options ---
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.width = 8,
  fig.asp = 0.618,
  fig.align = 'center',
  comment = "#>"
)

# --- Set plot options ---
theme_set(theme_bw(base_size = 12))
options(
  ggplot2.discrete.colour = RColorBrewer::brewer.pal(3, "Dark2"),
  ggplot2.discrete.fill = RColorBrewer::brewer.pal(3, "Dark2"),
  ggplot2.continuous.colour = "viridis",
  ggplot2.continuous.fill = "viridis"
)

# --- Custom Functions ---

#' Cache a Computation and Optionally Run in Parallel
#'
#' @description
#' This function provides a smart caching mechanism with optional on-demand
#' parallel processing. It evaluates an R expression and saves the result.
#' On subsequent runs, if the code has not changed, it loads the result
#' directly from the cache. If the code needs to be re-run, it can optionally
#' set up a parallel backend to speed up the computation, and will automatically
#' shut it down afterward.
#'
#' @param code {expression} The R code to be executed and cached. Enclose in `{}`.
#' @param cache_filename {character} A unique filename for the cache file (e.g.,
#'   "my_analysis_cache.rds"). Saved in the `output/` directory.
#' @param parallel {logical} If `TRUE` (the default), sets up a `future`
#'   multisession plan before running the code and restores the sequential plan
#'   afterward. If `FALSE`, runs the code sequentially.
#'
#' @return The result of the evaluated `code` expression.
#'
#' @importFrom digest digest
#' @importFrom future plan nbrOfWorkers multisession sequential
#' @importFrom parallel detectCores
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # --- How to use the function in your .qmd file ---
#'
#' # Run a long computation using parallel processing (the default)
#' result1 <- cache_computation({
#'   Sys.sleep(5) # Represents a slow, parallelizable task
#'   1:100
#' }, cache_filename = "parallel_result.rds")
#'
#' # Run a computation sequentially
#' result2 <- cache_computation({
#'   Sys.sleep(2) # A task that doesn't need parallel overhead
#'   "done"
#' }, cache_filename = "sequential_result.rds", parallel = FALSE)
#' }
cache_computation <- function(code, cache_filename, parallel = TRUE) {
  
  # Create a unique hash of the code expression
  code_expr <- substitute(code)
  current_hash <- digest::digest(code_expr)
  
  # Define the full path to the cache file
  cache_path <- here::here("output", cache_filename)
  
  # Check if a cache file exists and if the hash matches
  if (file.exists(cache_path)) {
    cached_data <- readRDS(cache_path)
    if (identical(cached_data$hash, current_hash)) {
      message("Cache hit: Loading '", cache_filename, "' from cache.")
      return(cached_data$result)
    } else {
      message("Code has changed. Re-running computation.")
    }
  } else {
    message("No cache found. Running computation.")
  }
  
  # If we get here, we need to run the code.
  # Check if parallel execution is requested.
  if (parallel) {
    # --- Set up parallel plan ---
    n_cores <- parallel::detectCores() - 1
    future::plan(future::multisession, workers = n_cores)
    message(paste("Parallel plan activated with", future::nbrOfWorkers(), "workers."))
    
    # IMPORTANT: Ensure the sequential plan is restored when the function exits,
    # even if there's an error.
    on.exit({
      future::plan(future::sequential)
      message("Parallel plan shut down. Restored sequential plan.")
    }, add = TRUE)
    
    # Evaluate the user's code in the parallel context
    result <- eval(code_expr, envir = parent.frame())
    
  } else {
    # Run the code sequentially
    result <- eval(code_expr, envir = parent.frame())
  }
  
  # Save the result AND the hash to the cache file
  data_to_cache <- list(result = result, hash = current_hash)
  saveRDS(data_to_cache, file = cache_path)
  
  return(result)
}