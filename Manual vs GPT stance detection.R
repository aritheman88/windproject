# Load necessary libraries
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(DBI)) install.packages("DBI")
library(DBI)
if (!require(RSQLite)) install.packages("RSQLite")
library(RSQLite)

# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Connect to the SQLite database
con <- dbConnect(RSQLite::SQLite(), "wind_project.db")
print("Database connected")

# Read data from the 'all_quotes' table
all_quotes <- dbGetQuery(con, "SELECT position, GPT_stance_detection FROM all_quotes WHERE position IS NOT NULL AND GPT_stance_detection IS NOT NULL")
print("Data read from database")

# Set the levels for the factors to control the order
all_quotes$position <- factor(all_quotes$position, levels = c("Negative", "Reservations", "Neutral", "Positive"))
all_quotes$GPT_stance_detection <- factor(all_quotes$GPT_stance_detection, levels = c("Strong support", "Weak support", "Neutral", "Weak oppose", "Strong oppose"))

# Create a contingency table with the specified order
contingency_table <- table(all_quotes$GPT_stance_detection, all_quotes$position)

# Display the contingency table
print("Contingency Table: GPT Stance Detection vs. Manual Stance Detection")
print(contingency_table)

# Optionally convert the table to a data frame for easier viewing and further analysis
contingency_df <- as.data.frame(contingency_table)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
