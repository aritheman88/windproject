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
projects_filtered$year_initiated <- format(projects_filtered$initiation_date, "%Y")

# Classify projects as Small or Large based on installed_capacity
projects_filtered$project_size <- ifelse(projects_filtered$installed_capacity < 20, "Small", "Large")

# Count the number of initiated small and large projects each year
initiated_by_year_size <- projects_filtered %>%
  group_by(year_initiated, project_size) %>%
  summarise(initiated_count = n(), .groups = 'drop')

# Filter for approved projects based on final_decision_date and project_status
approved_projects <- projects %>%
  filter(project_status == "approved" & !is.na(final_decision_date) & format(final_decision_date, "%Y") >= 2010 & format(final_decision_date, "%Y") <= 2023)

# Extract the year from final_decision_date
approved_projects$year_approved <- format(approved_projects$final_decision_date, "%Y")

# Classify approved projects as Small or Large based on installed_capacity
approved_projects$project_size <- ifelse(approved_projects$installed_capacity < 20, "Small", "Large")

# Count the number of approved small and large projects each year
approved_by_year_size <- approved_projects %>%
  group_by(year_approved, project_size) %>%
  summarise(approved_count = n(), .groups = 'drop')

# Merge initiated and approved counts by year and size
full_data <- full_join(initiated_by_year_size, approved_by_year_size, by = c("year_initiated" = "year_approved", "project_size"))

# Replace NAs with 0 for initiated_count and approved_count
full_data <- full_data %>%
  mutate(initiated_count = ifelse(is.na(initiated_count), 0, initiated_count),
         approved_count = ifelse(is.na(approved_count), 0, approved_count))

# Create the bar chart with transparency for initiated projects and solid for approved projects
p_bar <- ggplot(full_data, aes(x = year_initiated)) +
  # Transparent bars for initiated projects
  geom_bar(aes(y = initiated_count, fill = paste("Initiated", project_size)), stat = "identity", position = position_dodge(width = 0.6), alpha = 0.5, width = 0.6) +
  # Solid bars for approved projects
  geom_bar(aes(y = approved_count, fill = paste("Approved", project_size)), stat = "identity", position = position_dodge(width = 0.6), alpha = 1, width = 0.6) +
  scale_x_discrete(limits = as.character(2010:2023)) +  # Ensure all years are shown on X-axis
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +  # Ensure Y-axis labels are whole numbers
  scale_fill_manual(values = c("Approved Large" = "orange", "Initiated Large" = "orange", 
                               "Approved Small" = "blue", "Initiated Small" = "blue"),
                    breaks = c("Approved Large", "Initiated Large", "Approved Small", "Initiated Small"),
                    labels = c("Large - approved", "Large - initiated", "Small - approved", "Small - initiated")) +  # Legend order and labels
  labs(title = "Number of projects initiated and approved (2010-2023)",
       x = "Year",
       y = "Number of Projects",
       fill = "Project Status") +
  theme_minimal() +
  theme(
    legend.title = element_text(size = 10), 
    legend.position = "right", 
    panel.grid.major = element_blank(),  # Remove major grid
    panel.grid.minor = element_blank()   # Remove minor grid
  )

# Explicitly print the plot
print(p_bar)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
