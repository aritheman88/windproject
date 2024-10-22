# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(reshape2)) install.packages("reshape2")
library(reshape2)
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

# Ensure 'affiliation', 'installed_capacity', 'position', and 'project_status' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$position <- as.factor(all_quotes$position)
projects$project_status <- as.factor(projects$project_status)
print("Data formatted")

# Map 'position' values to numeric
position_mapping <- c("Positive" = 3, "Neutral" = 2, "Reservations" = 1, "Negative" = 0)
all_quotes$position_numeric <- as.numeric(sapply(all_quotes$position, function(x) position_mapping[x]))

# Verify the mapping
print("Position mapping verification:")
print(table(all_quotes$position, all_quotes$position_numeric))

# Filter data for approved and rejected projects
approved_projects <- subset(projects, project_status == 'approved')
rejected_projects <- subset(projects, project_status == 'rejected')

filtered_quotes_approved <- subset(all_quotes, project_code %in% approved_projects$plan_number)
filtered_quotes_rejected <- subset(all_quotes, project_code %in% rejected_projects$plan_number)

# Add a column to distinguish between approved and rejected projects
filtered_quotes_approved$project_status <- "Approved"
filtered_quotes_rejected$project_status <- "Rejected"

# Combine the datasets
combined_quotes <- rbind(filtered_quotes_approved, filtered_quotes_rejected)

# Verify the combined data
print("Combined data verification:")
print(head(combined_quotes))

# Calculate the count of each position by affiliation and project_status
position_counts <- combined_quotes %>%
  group_by(affiliation, project_status, position) %>%
  summarise(count = n(), .groups = 'drop')

# Calculate the percentage of each position within each affiliation and project_status
position_percentages <- position_counts %>%
  group_by(affiliation, project_status) %>%
  mutate(percentage = count / sum(count) * 100)

# Verify the position percentages
print("Position percentages verification:")
print(position_percentages)

# Define the order of positions from Negative to Positive
position_levels <- c("Negative", "Reservations", "Neutral", "Positive")
position_percentages$position <- factor(position_percentages$position, levels = rev(position_levels))

# Define the greyscale color scheme
position_colors <- c("Negative" = "black", "Reservations" = "darkgrey", "Neutral" = "grey", "Positive" = "lightgrey")

# Reverse the factor levels for project_status to ensure the correct stacking order
position_percentages$project_status <- factor(position_percentages$project_status, levels = c("Rejected", "Approved"))

# Create the stacked percentage bar chart
p_stacked <- ggplot(position_percentages, aes(x = affiliation, y = percentage, fill = position)) +
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~project_status, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = position_colors) +
  labs(x = "Affiliation", y = "Percentage", fill = "Position") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 6), # Rotate and adjust size of x-axis text
    axis.text.y = element_text(size = 8), # Adjust size of y-axis text
    strip.text = element_text(size = 14), # Make facet titles larger
    legend.position = "right" # Place legend on the side
  )

# Explicitly print the plot
print(p_stacked)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
