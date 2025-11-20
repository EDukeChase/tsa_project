#' Initialize New Project from Template
#'
#' @description
#' This script automates the setup of a new project from the template. It renames generic files
#' to match the repository name and replaces the template README with the
#' project-specific version.
#'
#' @details
#' Actions:
#'   1. Detects the new project's directory name.
#'   2. Renames the generic `.Rproj` and `.qmd` files.
#'   3. Replaces the main `README.md` with the project-specific template.
#'   4. Deletes the now-unneeded project README template.
#'
#' @return This function is called for its side effects and does not return a value.
#'
initialize_project <- function() {
  
  project_dir <- here::here()
  new_name <- basename(project_dir)
  
  message("New project name detected: '", new_name, "'")
  
  # --- 1. Rename the .Rproj file) ---
  old_rproj <- list.files(path = project_dir, pattern = "\\.Rproj$", full.names = TRUE)
  
  if (length(old_rproj) == 1) {
    new_rproj_path <- here::here(paste0(new_name, ".Rproj"))
    file.rename(from = old_rproj, to = new_rproj_path)
    message("Renamed '", basename(old_rproj), "' to '", basename(new_rproj_path), "'")
  } else {
    warning("Found ", length(old_rproj), " .Rproj files. Expected 1. Skipping rename.")
  }
  
  # --- 2. Rename the starter .qmd file ---
  old_qmd <- list.files(path = project_dir, pattern = "\\.qmd$", full.names = TRUE)
  
  if (length(old_qmd) == 1) {
    new_qmd_path <- here::here(paste0(new_name, ".qmd"))
    file.rename(from = old_qmd, to = new_qmd_path)
    message("Renamed '", basename(old_qmd), "' to '", basename(new_qmd_path), "'")
  } else {
    warning("Found ", length(old_qmd), " .qmd files. Expected 1. Skipping rename.")
  }
  
  # --- 3. Overwrite the main README.md ---
  project_readme_template <- here::here("_PROJECT_README.md")
  main_readme_path <- here::here("README.md")
  
  if (file.exists(project_readme_template)) {
    # Overwrite the main README with the project-specific one
    file.copy(from = project_readme_template, to = main_readme_path, overwrite = TRUE)
    message("Replaced README.md with project-specific version.")
    
    # Remove the template file
    file.remove(project_readme_template)
    message("Removed temporary file: '_PROJECT_README.md'")
  } else {
    warning("'_PROJECT_README.md' not found. Skipping README update.")
  }
  
  # --- 4. Final instruction ---
  message("\nIMPORTANT: Project initialization complete. Please close and reopen this project.")
  message("Use 'File > Open Project...' and select the new '", new_name, ".Rproj' file.")
  
}

# Automatically run the function when the script is sourced
initialize_project()