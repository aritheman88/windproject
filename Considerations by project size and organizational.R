# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(tidyr)) install.packages("tidyr")
library(tidyr)
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

# Ensure 'affiliation' and 'installed_capacity' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
print("Data formatted")

# Define a function to calculate the percentage of Factors
calculate_Factor_percentages <- function(filtered_quotes) {
  Factor_counts <- filtered_quotes %>%
    group_by(affiliation) %>%
    summarise(
      Environmental = sum(Environmental, na.rm = TRUE),
      Planning = sum(Planning, na.rm = TRUE),
      Community_acceptance = sum(Community_acceptance, na.rm = TRUE),
      Finance = sum(Finance, na.rm = TRUE),
      Technical = sum(Technical, na.rm = TRUE)
    ) %>%
    mutate(
      Total = Environmental + Planning + Community_acceptance + Finance + Technical,
      Environmental = Environmental / Total * 100,
      Planning = Planning / Total * 100,
      Community_acceptance = Community_acceptance / Total * 100,
      Finance = Finance / Total * 100,
      Technical = Technical / Total * 100
    ) %>%
    select(-Total) %>%
    pivot_longer(cols = c(Environmental, Planning, Community_acceptance, Finance, Technical), 
                 names_to = "Factor", 
                 values_to = "Percentage")
  
  return(Factor_counts)
}

# Filter data for small projects (installed capacity < 20)
small_projects <- subset(projects, installed_capacity < 20)
filtered_quotes_small <- subset(all_quotes, project_code %in% small_projects$plan_number)
Factor_percentages_small <- calculate_Factor_percentages(filtered_quotes_small)
Factor_percentages_small$Project_Size <- "Small Projects"
print("Small projects data filtered and percentages calculated")

# Filter data for large projects (installed capacity >= 20)
large_projects <- subset(projects, installed_capacity >= 20)
filtered_quotes_large <- subset(all_quotes, project_code %in% large_projects$plan_number)
Factor_percentages_large <- calculate_Factor_percentages(filtered_quotes_large)
Factor_percentages_large$Project_Size <- "Large Projects"
print("Large projects data filtered and percentages calculated")

# Combine data for small and large projects
Factor_percentages <- rbind(Factor_percentages_small, Factor_percentages_large)

# Create the stacked percentage bar chart for Factors
p_Factors <- ggplot(Factor_percentages, aes(x = affiliation, y = Percentage, fill = Factor)) +
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~Project_Size) +
  scale_fill_manual(values = c("Environmental" = "darkgreen", "Planning" = "darkblue", 
                               "Community_acceptance" = "goldenrod", "Finance" = "darkred",
                               "Technical" = "purple")) +  # Add color for "Technical"
  labs(x = "Organizational affiliation", y = "Percentage", title = "Figure 6: Factors by project size and organizational affiliation") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 6), # Rotate and adjust size of x-axis text
    axis.text.y = element_text(size = 6), # Adjust size of y-axis text
    plot.title = element_text(hjust = 0.5),  # Center the title
    legend.position = "right"  # Place the legend on the right
  )

# Explicitly print the plot
print(p_Factors)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
