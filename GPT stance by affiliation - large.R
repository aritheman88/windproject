# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
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

# Read data from the 'projects' and 'all_quotes' tables
projects <- dbGetQuery(con, "SELECT * FROM projects")
all_quotes <- dbGetQuery(con, "SELECT * FROM all_quotes")
print("Data read from database")

# Ensure 'affiliation', 'installed_capacity', and 'GPT_stance_detection' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$GPT_stance_detection <- as.factor(all_quotes$GPT_stance_detection)
print("Data formatted")

# Filter data for large projects (installed capacity >= 20 MW)
large_projects <- subset(projects, installed_capacity >= 20)
filtered_quotes <- subset(all_quotes, project_code %in% large_projects$plan_number)
print("Data filtered")

# Verify the filtered data
print("Filtered data verification:")
print(table(filtered_quotes$affiliation, filtered_quotes$GPT_stance_detection))

# Calculate the count of each GPT stance by affiliation
stance_counts <- filtered_quotes %>%
  group_by(affiliation, GPT_stance_detection) %>%
  summarise(count = n(), .groups = 'drop')

# Calculate the percentage of each stance within each affiliation
stance_percentages <- stance_counts %>%
  group_by(affiliation) %>%
  mutate(percentage = count / sum(count) * 100)

# Verify the stance percentages
print("Stance percentages verification:")
print(stance_percentages)

# Define the order of GPT stance from Strong Oppose to Strong Support
stance_levels <- c("Strong oppose", "Weak oppose", "Neutral", "Weak support", "Strong support")
stance_percentages$GPT_stance_detection <- factor(stance_percentages$GPT_stance_detection, levels = stance_levels)

# Define the red to green color scale
stance_colors <- c(
  "Strong oppose" = "#FFCCCC",  # Pale red
  "Weak oppose" = "#FF9999",    # Lighter red
  "Neutral" = "#D3D3D3",        # Pale gray
  "Weak support" = "#99FF99",   # Light green
  "Strong support" = "#66FF66"  # Pale green
)

# Reverse the factor levels to ensure the correct stacking order
stance_percentages$GPT_stance_detection <- factor(stance_percentages$GPT_stance_detection, levels = rev(stance_levels))

# Create the stacked percentage bar chart with the legend on the right
p_stacked <- ggplot(stance_percentages, aes(x = affiliation, y = percentage, fill = GPT_stance_detection)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = stance_colors) +
  labs(x = "Affiliation", y = "Percentage", fill = "Stance", title = "Share of Statements by GPT Stance Detection for large Projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8), # Rotate text and adjust size
    plot.title = element_text(hjust = 0.5),  # Center the title
    legend.position = "right"  # Move legend to the right
  )

# Explicitly print the plot
print(p_stacked)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
