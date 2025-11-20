# Data Folder

Place all raw data files for the assignment in this directory. For time series analysis, this will typically include files like:

-   `.csv` or `.xlsx` tables containing time series data.
-   `.rds` or `.rda` files for pre-processed R objects.

**Best Practice:** The files in this folder should be treated as **read-only**. Your analysis scripts should read data from here but should never save modified files back into this directory.