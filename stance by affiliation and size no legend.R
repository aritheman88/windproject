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

# Define the order of positions from Negative to Positive
position_levels <- c("Negative", "Reservations", "Neutral", "Positive")

# Function to calculate position percentages
calculate_position_percentages <- function(filtered_quotes) {
  position_counts <- filtered_quotes %>%
    group_by(affiliation, position) %>%
    summarise(count = n(), .groups = 'drop')
  
  position_percentages <- position_counts %>%
    group_by(affiliation) %>%
    mutate(percentage = count / sum(count) * 100)
  
  position_percentages$position <- factor(position_percentages$position, levels = rev(position_levels))
  
  return(position_percentages)
}

# Filter data for small projects (installed capacity < 20)
small_projects <- subset(projects, installed_capacity < 20)
filtered_quotes_small <- subset(all_quotes, project_code %in% small_projects$plan_number)
position_percentages_small <- calculate_position_percentages(filtered_quotes_small)
print("Small projects data filtered and percentages calculated")

# Filter data for large projects (installed capacity >= 20)
large_projects <- subset(projects, installed_capacity >= 20)
filtered_quotes_large <- subset(all_quotes, project_code %in% large_projects$plan_number)
position_percentages_large <- calculate_position_percentages(filtered_quotes_large)
print("Large projects data filtered and percentages calculated")

# Define the greyscale color scheme
position_colors <- c("Negative" = "black", "Reservations" = "darkgrey", "Neutral" = "grey", "Positive" = "lightgrey")

# Create the stacked percentage bar chart for small projects
p_small <- ggplot(position_percentages_small, aes(x = affiliation, y = percentage, fill = position)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = position_colors) +
  labs(x = NULL, y = "Percentage", title = "Small Projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(), # Remove x-axis text for the top plot
    axis.ticks.x = element_blank(), # Remove x-axis ticks for the top plot
    axis.text.y = element_text(size = 6), # Adjust size of y-axis text
    plot.title = element_text(hjust = 0.5),  # Center the title
    legend.position = "none"  # Remove legend
  )

# Create the stacked percentage bar chart for large projects
p_large <- ggplot(position_percentages_large, aes(x = affiliation, y = percentage, fill = position)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = position_colors) +
  labs(x = "Organizational affiliation", y = "Percentage", title = "Large Projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 6), # Rotate and adjust size of x-axis text
    axis.text.y = element_text(size = 6), # Adjust size of y-axis text
    plot.title = element_text(hjust = 0.5),  # Center the title
    legend.position = "none"  # Remove legend
  )

# Combine the two plots into one
library(gridExtra)
combined_plot <- grid.arrange(p_small, p_large, ncol = 1, heights = c(1, 1.5))

# Explicitly print the combined plot
print(combined_plot)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
