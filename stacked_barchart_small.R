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

# Ensure 'affiliation', 'installed_capacity', and 'position' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$position <- as.factor(all_quotes$position)
print("Data formatted")

# Filter data for small projects (installed capacity < 20)
small_projects <- subset(projects, installed_capacity < 20)
filtered_quotes <- subset(all_quotes, project_code %in% small_projects$plan_number)
print("Data filtered")

# Verify the filtered data
print("Filtered data verification:")
print(table(filtered_quotes$affiliation, filtered_quotes$position))

# Calculate the count of each position by affiliation
position_counts <- filtered_quotes %>%
  group_by(affiliation, position) %>%
  summarise(count = n(), .groups = 'drop')

# Calculate the percentage of each position within each affiliation
position_percentages <- position_counts %>%
  group_by(affiliation) %>%
  mutate(percentage = count / sum(count) * 100)

# Verify the position percentages
print("Position percentages verification:")
print(position_percentages)

# Define the order of positions from Negative to Positive
position_levels <- c("Negative", "Reservations", "Neutral", "Positive")
position_percentages$position <- factor(position_percentages$position, levels = position_levels)

# Define the greyscale color scheme
position_colors <- c("Negative" = "black", "Reservations" = "darkgrey", "Neutral" = "grey", "Positive" = "lightgrey")

# Reverse the factor levels to ensure the correct stacking order
position_percentages$position <- factor(position_percentages$position, levels = rev(position_levels))

# Create the stacked percentage bar chart
p_stacked <- ggplot(position_percentages, aes(x = affiliation, y = percentage, fill = position)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = position_colors) +
  labs(x = "Affiliation", y = "Percentage", fill = "Position", title = "Share of Statements by Position for Small Projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8), # Rotate text and adjust size
    plot.title = element_text(hjust = 0.5),  # Center the title
    legend.position = "bottom"
  )

# Explicitly print the plot
print(p_stacked)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
