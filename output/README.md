# Output Folder

This folder is the designated location for all generated files from your analysis. This includes:

-   The final rendered **PDF document**.
-   Saved plots (`.png`, `.jpeg`, etc.).
-   Processed data tables (`.csv`) or model objects (`.rds`).
-   Cached analysis results (`.rds`) from the `cache_computation()` function.

**Important:** This entire folder (except for this README) is listed in the `.gitignore` file. Its contents are not and should not be tracked by Git. All files here should be reproducible by running the code in the main `.qmd` document.