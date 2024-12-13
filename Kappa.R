# Load necessary libraries
library(DBI)
library(RSQLite)
library(irr)  # For Cohen's Kappa

# Connect to the SQLite database
db_path <- "C:/Users/ariel/MyPythonScripts/wind/wind_project.db"
conn <- dbConnect(SQLite(), dbname = db_path)

# Query data from the database
query <- "SELECT position, GPT_2_prediction FROM all_quotes WHERE position IS NOT NULL AND GPT_2_prediction IS NOT NULL"
data <- dbGetQuery(conn, query)

# Ensure consistent capitalization
data$position <- tolower(data$position)
data$GPT_2_prediction <- tolower(data$GPT_2_prediction)

# Merge negative stances into a single category
merge_negatives <- function(x) {
  if (x %in% c("weak oppose", "strong oppose")) {
    return("oppose")
  } else {
    return(x)
  }
}

data$position <- sapply(data$position, merge_negatives)
data$GPT_2_prediction <- sapply(data$GPT_2_prediction, merge_negatives)

# Ensure categories match the new desired order
desired_order <- c("support", "neutral", "oppose")
data$position <- factor(data$position, levels = desired_order)
data$GPT_2_prediction <- factor(data$GPT_2_prediction, levels = desired_order)

# Calculate Cohen's Kappa
kappa_result <- kappa2(data[, c("position", "GPT_2_prediction")])

# Print the result
print("Cohen's Kappa:")
print(kappa_result)

# Close the database connection
dbDisconnect(conn)
