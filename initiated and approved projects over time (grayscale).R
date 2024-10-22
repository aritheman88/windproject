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

# Read data from the 'projects' table
projects <- dbGetQuery(con, "SELECT * FROM projects")
print("Data read from database")

# Convert initiation_date and final_decision_date to Date format
projects$initiation_date <- as.Date(projects$initiation_date, format = "%Y-%m-%d")
projects$final_decision_date <- as.Date(projects$final_decision_date, format = "%Y-%m-%d")

# Filter for years between 2010 and 2023
projects_filtered <- projects %>%
  filter(!is.na(initiation_date) & format(initiation_date, "%Y") >= 2010 & format(initiation_date, "%Y") <= 2023)

# Extract the year from initiation_date
projects_filtered$year_Submitted <- format(projects_filtered$initiation_date, "%Y")

# Classify projects as Small or Large based on installed_capacity
projects_filtered$project_size <- ifelse(projects_filtered$installed_capacity < 20, "Small", "Large")

# Filter small and large projects separately
small_projects <- projects_filtered %>% filter(project_size == "Small")
large_projects <- projects_filtered %>% filter(project_size == "Large")

# Function to summarize and merge data for each project size
prepare_data <- function(data) {
  Submitted_by_year <- data %>%
    group_by(year_Submitted) %>%
    summarise(Submitted_count = n(), .groups = 'drop')
  
  approved_projects <- data %>%
    filter(project_status == "approved" & !is.na(final_decision_date))
  
  rejected_projects <- data %>%
    filter(project_status == "rejected" & !is.na(final_decision_date))
  
  approved_by_year <- approved_projects %>%
    group_by(year_final = format(final_decision_date, "%Y")) %>%
    summarise(approved_count = n(), .groups = 'drop')
  
  rejected_by_year <- rejected_projects %>%
    group_by(year_final = format(final_decision_date, "%Y")) %>%
    summarise(rejected_count = n(), .groups = 'drop')
  
  full_data <- full_join(Submitted_by_year, approved_by_year, by = c("year_Submitted" = "year_final"))
  full_data <- full_join(full_data, rejected_by_year, by = c("year_Submitted" = "year_final"))
  
  full_data %>%
    mutate(Submitted_count = ifelse(is.na(Submitted_count), 0, Submitted_count),
           approved_count = ifelse(is.na(approved_count), 0, approved_count),
           rejected_count = ifelse(is.na(rejected_count), 0, rejected_count))
}

# Prepare data for small and large projects
small_data <- prepare_data(small_projects)
large_data <- prepare_data(large_projects)

# Function to create a bar chart for a given dataset and title with smaller fonts
create_chart <- function(data, title) {
  ggplot(data, aes(x = year_Submitted)) +
    geom_bar(aes(y = Submitted_count, fill = "Submitted", pattern = "stripe"), 
             stat = "identity", position = position_dodge(width = 0.6), alpha = 0.8, width = 0.6) +
    geom_bar(aes(y = approved_count, fill = "Final Decision", pattern = "circle"), 
             stat = "identity", position = position_dodge(width = 0.6), alpha = 0.8, width = 0.6) +
    geom_bar(aes(y = -rejected_count, fill = "Final Decision", pattern = "crosshatch"), 
             stat = "identity", position = position_dodge(width = 0.6), alpha = 0.8, width = 0.6) +
    geom_hline(yintercept = 0, color = "black", size = 0.8) +
    scale_x_discrete(limits = as.character(2010:2023)) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +
    scale_fill_manual(values = c("Submitted" = "gray70", "Final Decision" = "gray30"),
                      breaks = c("Submitted", "Final Decision"),
                      labels = c("Submitted", "Final Decision")) +
    labs(title = title,
         x = "Year",
         y = "Number of Projects",
         fill = "Project Stage") +
    theme_minimal() +
    theme(
      text = element_text(size = 8), # Set smaller font size for all text
      legend.title = element_text(size = 8), 
      legend.text = element_text(size = 7),
      axis.title = element_text(size = 8),
      axis.text = element_text(size = 7),
      plot.title = element_text(size = 9),
      legend.position = "right", 
      panel.grid.major = element_blank(),  
      panel.grid.minor = element_blank()
    )
}

# Create the charts
small_projects_chart <- create_chart(small_data, "Small projects")
large_projects_chart <- create_chart(large_data, "Large projects")

# Print the charts one above the other
library(gridExtra)
grid.arrange(small_projects_chart, large_projects_chart, ncol = 1)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
