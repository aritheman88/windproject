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

# Ensure 'affiliation', 'project_status', and 'position' columns are properly formatted
query_result$affiliation <- as.factor(query_result$affiliation)
query_result$project_status <- as.factor(query_result$project_status)
query_result$position <- factor(query_result$position, levels = c("Negative", "Reservations", "Neutral", "Positive"))
print("Data formatted")

# Filter data for the specific affiliations and non-empty project_status
desired_affiliations <- c("Planning bodies", "Locals", "Developers", "Environmental organizations", "Government")
desired_statuses <- c("rejected", "approved")
filtered_data <- subset(query_result, affiliation %in% desired_affiliations & project_status %in% desired_statuses)
print("Data filtered")

# Calculate percentages for each combination of affiliation, project_status, and position
percentage_data <- filtered_data %>%
  group_by(affiliation, project_status, position) %>%
  summarise(count = n(), .groups = 'drop') %>%
  group_by(affiliation, project_status) %>%
  mutate(percentage = count / sum(count) * 100) %>%
  ungroup()
print("Percentages calculated")

# Create the stacked column plot with facets for project_status
p <- ggplot(percentage_data, aes(x = affiliation, y = percentage, fill = position)) +
  geom_bar(stat = "identity") +
  facet_grid(project_status ~ ., scales = "free_y") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  scale_fill_manual(values = c(
    "Positive" = "#90EE90",  # Light green
    "Neutral" = "#D3D3D3",   # Light gray
    "Reservations" = "#FFD700", # Light gold
    "Negative" = "#FFB6C1"  # Light pink
  )) +
  labs(x = "Affiliation", y = "Percentage", fill = "Position") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10), # Rotate text and adjust size
    strip.text.y = element_text(size = 10)  # Adjust size of strip text for facets
  )

# Explicitly print the plot
print(p)
