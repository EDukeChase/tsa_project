# --- Core Packages ---
library(here)               # For robust file paths
library(tidyverse)          # For data manipulation and plotting (ggplot2, dplyr, etc.)

# --- Quarto & Caching Packages ---
library(digest)             # Creates hashes for caching function.
library(future)             # Parallel processing
library(knitr)              # Used for running R code in Quarto

# --- Visualization Packages ---
library(RColorBrewer)       # Color palettes to enable color-blind friendliness


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