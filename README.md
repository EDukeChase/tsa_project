# Homework {num}: Time Series Analysis (Subject)

This repository contains the complete analysis for Homework {num} of Time Series Analysis (MATH-5027). {Brief description of homework subject}.

- **Author**: E. Duke Chase
- **Course**: MATH-5027, Time Series Analysis
- **Due Date**: 2025-mm-dd

## Repository Contents

This project is a reproducible R environment using `renv` and Quarto.

- `2025-mm-dd_tsa_homework-{num}.qmd`: The main Quarto document containing all code, analysis, and interpretation.
- `R/setup.R`: The R script that loads packages and sets global options.
- `_quarto.yml`: The project configuration file, which sets the HTML theme and other rendering options.
- `data/`: Contains raw data files used in the analysis. The contents of this folder are ignored by git.
- `output/`: Contains the rendered PDF document and other saved results like cached computations or plots. The contents of this folder are ignored by git.
- `renv.lock` / `.Rprofile`: Files that ensure the R environment is fully reproducible.

## How to Reproduce the Analysis

1.  **Clone the Repository**: `git clone <repository-url>`
2.  **Open the Project**: Open the `.Rproj` file in RStudio.
3.  **Restore the Environment**: Run `renv::restore()` in the R console to install the exact package versions used.
4.  **Render the Document**: Open the `.qmd` file and click **Render**, or run `quarto::quarto_render()` in the console. The final PDF will be generated in the `output/` folder.