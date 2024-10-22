# Load necessary libraries
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(DBI)) install.packages("DBI")
library(DBI)
if (!require(RSQLite)) install.packages("RSQLite")
library(RSQLite)
if (!require(reshape2)) install.packages("reshape2")
library(reshape2)

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
all_quotes$sentiment <- as.numeric(all_quotes$end_sentiment)
print("Data formatted")

# Filter data for the specific affiliations and considerations
desired_affiliations <- c("Developers", "Environmental organizations", "Government", "Locals", "Planning bodies")
considerations <- c("Environmental", "Planning", "Community_acceptance", "Technical", "Finance")

# Define a function to calculate average sentiment for given project size
calculate_avg_sentiment <- function(project_size) {
  project_filter <- if (project_size == "large") {
    projects$installed_capacity >= 20
  } else {
    projects$installed_capacity < 20
  }
  
  filtered_projects <- subset(projects, project_filter)
  filtered_quotes <- subset(all_quotes, affiliation %in% desired_affiliations & project_code %in% filtered_projects$plan_number)
  
  melted_data <- melt(filtered_quotes, id.vars = c("affiliation", "sentiment"), measure.vars = considerations)
  melted_data <- subset(melted_data, value == 1)
  
  min_observations <- 3
  filtered_melted_data <- melted_data %>%
    group_by(affiliation, variable) %>%
    filter(n() >= min_observations)
  
  filtered_melted_data$variable <- recode(filtered_melted_data$variable, 
                                          "Environmental" = "Environmental", 
                                          "Planning" = "Planning", 
                                          "Community_acceptance" = "Community acceptance", 
                                          "Technical" = "Technical", 
                                          "Finance" = "Finance")
  
  average_sentiment <- filtered_melted_data %>%
    group_by(affiliation, variable) %>%
    summarise(avg_sentiment = mean(sentiment), .groups = 'drop')
  
  average_sentiment$avg_sentiment <- pmin(average_sentiment$avg_sentiment, 0)
  return(average_sentiment)
}

# Calculate average sentiment for large and small projects
average_sentiment_large <- calculate_avg_sentiment("large")
average_sentiment_small <- calculate_avg_sentiment("small")

# Merge the average sentiments and calculate differences
sentiment_diff <- merge(average_sentiment_large, average_sentiment_small, by = c("affiliation", "variable"), suffixes = c("_large", "_small"))
sentiment_diff <- sentiment_diff %>%
  mutate(sentiment_difference = avg_sentiment_large - avg_sentiment_small)

# Print the sentiment differences
print(sentiment_diff)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
