# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)

# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Read the CSV file into R
query_result <- read.csv("quotes_sentiment_status.csv")
print("CSV file read")

# Check the structure of the data
str(query_result)
head(query_result)

# Ensure 'affiliation', 'sentiment', and 'project_status' columns are properly formatted
query_result$affiliation <- as.factor(query_result$affiliation)
query_result$sentiment <- as.numeric(query_result$sentiment)
query_result$project_status <- as.factor(query_result$project_status)
print("Data formatted")

# Print unique values in 'project_status' to debug filtering step
print(unique(query_result$project_status))

# Filter data for the specific affiliations and project statuses
desired_affiliations <- c("Planning bodies", "Locals", "Developers", "Environmental organizations", "Government")
desired_statuses <- c("approved", "rejected")
filtered_data <- subset(query_result, affiliation %in% desired_affiliations & project_status %in% desired_statuses)
print("Data filtered")

# Verify the filtered data
print(unique(filtered_data$project_status))
print(table(filtered_data$project_status))
str(filtered_data)
head(filtered_data)

# Create the box plot
p <- ggplot(filtered_data, aes(x = affiliation, y = sentiment, fill = project_status)) +
  geom_boxplot() +
  #geom_jitter(width = 0.2, aes(color = project_status), alpha = 0.5, size = 0.5) +
  scale_y_continuous(limits = c(-1, 1)) +
  scale_fill_manual(values = c("approved" = "lightgreen", "rejected" = "lightcoral")) +
  scale_color_manual(values = c("approved" = "darkgreen", "rejected" = "darkred")) +
  labs(x = "Affiliation", y = "Sentiment", fill = "Project Status", color = "Project Status") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10) # Rotate text and adjust size
  )

# Explicitly print the plot
print(p)
