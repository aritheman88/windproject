# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Read the CSV file into R
query_result <- read.csv("quotes_sentiment_status.csv")
print("CSV file read")

# Include the 'Hmisc' package for Spearman's rank correlation
library(Hmisc)

# Ensure the 'sentiment' column is numeric
query_result$sentiment <- as.numeric(as.character(query_result$sentiment))

# Create a binary variable for 'position' indicating whether it is 'Positive' or not
query_result$is_positive <- ifelse(query_result$position == "Positive", 1, 0)

# Remove rows with NA values in the 'sentiment' or 'is_positive' columns
query_result <- na.omit(query_result[, c("sentiment", "is_positive")])

# Calculate Spearman's rank correlation
correlation <- rcorr(query_result$sentiment, query_result$is_positive, type = "spearman")

# Print the correlation coefficient (rho) and p-value
cat("Spearman's rank correlation coefficient (rho): ", correlation$r[1,2])
cat("\nP-value: ", correlation$P[1,2])
