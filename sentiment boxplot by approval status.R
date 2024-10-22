# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(dplyr)) install.packages("dplyr")
if (!require(DBI)) install.packages("DBI")
if (!require(RSQLite)) install.packages("RSQLite")

library(ggplot2)
library(dplyr)
library(DBI)
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

# Ensure 'affiliation', 'installed_capacity', and 'sentiment' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$sentiment <- as.numeric(all_quotes$sentiment)
print("Data formatted")

# Filter projects for 'approved' and 'rejected' statuses
filtered_projects <- subset(projects, project_status %in% c("approved", "rejected"))

# Define common variables
desired_affiliations <- c("Planning bodies", "Locals", "Developers", "Environmental organizations", "Government")

# Merge quotes with project status information
merged_data <- merge(all_quotes, filtered_projects, by.x = "project_code", by.y = "plan_number")

# Filter data for the specific affiliations
filtered_data <- subset(merged_data, affiliation %in% desired_affiliations)

# Create a new column for project status
filtered_data$project_status <- as.factor(filtered_data$project_status)

# Verify the filtered data
# str(filtered_data)
# head(filtered_data)

# Create the box plot
p <- ggplot(filtered_data, aes(x = affiliation, y = sentiment, fill = project_status)) +
  geom_boxplot() +
  #geom_jitter(width = 0.2, aes(color = project_status), alpha = 0.5, size = 0.5) +
  scale_y_continuous(limits = c(-1, 1), 
                     breaks = c(-1, 1), 
                     labels = c("Negative", "Positive")) +
  scale_fill_manual(values = c("approved" = "lightblue", "rejected" = "lightcoral")) +
  scale_color_manual(values = c("approved" = "darkblue", "rejected" = "darkred")) +
  labs(x = "Affiliation", y = "Sentiment", fill = "Project Status", color = "Project Status") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8) # Rotate text and adjust size
  )

# Explicitly print the plot
print(p)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")

# Summarize data
summary_stats <- filtered_data %>%
  group_by(affiliation, project_status) %>%
  summarise(
    average_sentiment = mean(sentiment, na.rm = TRUE),
    median_sentiment = median(sentiment, na.rm = TRUE)
  )

print(summary_stats)
