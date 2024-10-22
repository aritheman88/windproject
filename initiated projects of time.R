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

# Convert initiation_date to Date format
projects$initiation_date <- as.Date(projects$initiation_date, format = "%Y-%m-%d")

# Filter for years between 2010 and 2023
projects_filtered <- projects %>%
  filter(!is.na(initiation_date) & format(initiation_date, "%Y") >= 2010 & format(initiation_date, "%Y") <= 2023)

# Extract the year from initiation_date
projects_filtered$year_initiated <- format(projects_filtered$initiation_date, "%Y")

# Classify projects as Small or Large based on installed_capacity
projects_filtered$project_size <- ifelse(projects_filtered$installed_capacity < 20, "Small", "Large")

# Count the number of small and large projects initiated each year
projects_by_year_size <- projects_filtered %>%
  group_by(year_initiated, project_size) %>%
  summarise(count = n(), .groups = 'drop')

# Create the bar chart, with fill to differentiate Small and Large projects
p_bar <- ggplot(projects_by_year_size, aes(x = year_initiated, y = count, fill = project_size)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_x_discrete(limits = as.character(2010:2023)) +  # Ensure all years are shown on X-axis
  labs(title = "Number of Projects Initiated (2010-2023)",
       x = "Year",
       y = "Number of Projects",
       fill = "Project Size") +
  scale_fill_manual(values = c("Small" = "steelblue", "Large" = "orange")) +  # Color for Small and Large projects
  theme_minimal()

# Explicitly print the plot
print(p_bar)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
