# Homework Template: Time Series Analysis (PDF)

This is a template for Time Series Analysis (CU Denver: MATH-5027), pre-configured to produce styled PDF documents. It uses renv to ensure that every assignment is fully reproducible with the correct R package versions.


## What's in This Template?

This repository contains several key configuration files that automate your setup process.

-   **`_quarto.yml`**: The main control panel for the Quarto project.
-   **`_PROJECT_README.md`**: A template that will become the `README.md` for your new homework repository.
-   **`R/initialize_project.R`**: An automation script that renames project files and replaces this instructional README with the project-specific one.
-   **`R/setup.R`**: The script where you load R packages and set global options.
-   **`docs/`**: A folder to store assignment instructions and other supplementary documents.
-   **`renv` files**: The core of the project's reproducibility (`renv.lock`, `.Rprofile`).

## Workflow for a New Assignment

### One-Time Setup

You need a GitHub Personal Access Token (PAT) so R can interact with your GitHub account.

1.  **Generate Token:** Run `usethis::create_github_token()`. Give it a name, check the `repo` scope, and **copy the token immediately**.
2.  **Store Token:** Run `gitcreds::gitcreds_set()` and paste the token when prompted.

### Creating a New Project

Follow these steps from your R console for each new assignment.

#### Step 1: Create the New Repository on GitHub
This command generates a new repository from this template. **Update the `name` and `description` each time.**

```r
library(gh)
new_repo_name <- "2025-mm-dd_tsa_homework-{num}"
new_repo_desc <- "Homework {num} for Time Series Analysis"

gh::gh(
  "POST /repos/EDukeChase/tsa-hw-template/generate", 
  name = new_repo_name,
  description = new_repo_desc
)
```

#### Step 2: Clone the New Repository to Your Computer

Use `usethis` to clone the new repo to your local machine.

```r
library(usethis)
create_from_github(
  repo = paste0("EDukeChase/", new_repo_name),
  destdir = "G:\\My Drive\\CU_Denver\\2025_3-Fall\\Time-Series_MATH-5027\\homework",
  open = TRUE
)
```

#### Step 3: Restore the R Environment

Once the new project opens, run this in the console to install all the necessary packages.

```r
renv::restore()
```

#### Step 4: Initialize the Project

Run this script to automatically rename files and clean up the READMEs.

```r
source("R/initialize_project.R")
```

#### Step 5: Restart the Project

You **must** restart the project to use the new `.Rproj` file.

1. Go to `File > Close Project`.

2. Go to `File > Open Project...` and select your newly names `.Rproj` file.

#### Step 6: Customize Your New README.md

This is the final step. The main `README.md` has been replaced with a generic template.

1. Open the new `README.md` file.

2. Fill in the placeholders like `{num}`, `2025-mm-dd`, etc.

3. **Commit and push** this change to your repository. This ensures your new project is self-documenting.