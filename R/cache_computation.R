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
cache_computation <- function(code, cache_filename, deps = NULL, parallel = TRUE) {
  
  # Hash the expression and any declared dependencies
  code_expr <- substitute(code)
  current_hash <- digest::digest(list(code_expr, deps))
  
  # Define the full path to the cache file
  cache_path <- here::here("output", cache_filename)
  dir.create(dirname(cache_path), showWarnings = FALSE, recursive = TRUE)
  
  # Check if a cache file exists and if the hash matches
  if (file.exists(cache_path)) {
    cached_data <- readRDS(cache_path)
    if (identical(cached_data$hash, current_hash)) {
      message("Cache hit: Loading '", cache_filename, "' from cache.")
      return(cached_data$result)
    } else {
      message("Code/deps changed. Re-running computation.")
    }
  } else {
    message("No cache found. Running computation.")
  }
  
  # Check if parallel execution is requested.
  if (parallel) {
    old_plan <- future::plan()
    on.exit(future::plan(old_plan), add = TRUE)
    
    # --- Set up parallel plan ---
    n_avail  <- future::availableCores()
    workers  <- min(8L, max(1L, n_avail - 1L))
    future::plan(future::multisession, workers = workers)
    message("Parallel plan activated with ", workers, " workers (available cores: ", n_avail, ").")
  }
  
  # Save the result and the hash to the cache file
  result <- eval(code_expr, envir = parent.frame())
  saveRDS(list(result = result, hash = current_hash), cache_path)
  
  return(result)
}