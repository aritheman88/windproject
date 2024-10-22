# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(dplyr)) install.packages("dplyr")
if (!require(DBI)) install.packages("DBI")
if (!require(RSQLite)) install.packages("RSQLite")
if (!require(tidyr)) install.packages("tidyr")

library(ggplot2)
library(dplyr)
library(DBI)
library(RSQLite)
library(tidyr)

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

# Ensure 'affiliation', 'installed_capacity', 'sentiment', and 'position' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$sentiment <- as.numeric(all_quotes$sentiment)
all_quotes$position <- factor(all_quotes$position, levels = c("Positive", "Neutral", "Reservations", "Negative"))
print("Data formatted")

# Filter projects for 'approved' and 'rejected' statuses
filtered_projects <- subset(projects, project_status %in% c("approved", "rejected"))

# Convert project_status to binary
filtered_projects$project_status_binary <- ifelse(filtered_projects$project_status == "approved", 1, 0)

# Define common variables
desired_affiliations <- c("Planning bodies", "Locals", "Developers", "Environmental organizations", "Government")

# Aggregate sentiment by project and affiliation
aggregated_sentiment <- all_quotes %>%
  filter(affiliation %in% desired_affiliations) %>%
  group_by(project_code, affiliation) %>%
  summarise(average_sentiment = mean(sentiment, na.rm = TRUE)) %>%
  pivot_wider(names_from = affiliation, values_from = average_sentiment)

# Merge aggregated sentiment with project status
merged_data <- merge(filtered_projects, aggregated_sentiment, by.x = "plan_number", by.y = "project_code", all.x = TRUE)

# Replace NA values with 0 (assuming no sentiment information should be treated as neutral)
merged_data[is.na(merged_data)] <- 0

# Run the logistic regression model
model <- glm(project_status_binary ~ `Government` + `Planning bodies` + `Developers` + `Locals` + `Environmental organizations`, 
             data = merged_data, 
             family = binomial(link = "logit"))

# Print the summary of the model
summary(model)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
