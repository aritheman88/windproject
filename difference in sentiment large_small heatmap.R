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

# Ensure 'affiliation', 'installed_capacity', and 'sentiment' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$sentiment <- as.numeric(all_quotes$end_sentiment)
print("Data formatted")

# Define common variables
desired_affiliations <- c("Developers", "Environmental organizations", "Government", "Locals", "Planning bodies")
considerations <- c("Environmental", "Planning", "Community_acceptance", "Technical", "Finance")
min_observations <- 3

# Function to calculate average sentiment for given project size
calculate_average_sentiment <- function(project_filter) {
  filtered_projects <- subset(projects, eval(parse(text = project_filter)))
  filtered_quotes <- subset(all_quotes, affiliation %in% desired_affiliations & project_code %in% filtered_projects$plan_number)
  
  melted_data <- melt(filtered_quotes, id.vars = c("affiliation", "sentiment"), measure.vars = considerations)
  melted_data <- subset(melted_data, value == 1)
  
  filtered_melted_data <- melted_data %>%
    group_by(affiliation, variable) %>%
    filter(n() >= min_observations)
  
  average_sentiment <- filtered_melted_data %>%
    group_by(affiliation, variable) %>%
    summarise(avg_sentiment = mean(sentiment), .groups = 'drop')
  
  average_sentiment$avg_sentiment <- pmin(average_sentiment$avg_sentiment, 0)
  
  return(average_sentiment)
}

# Calculate average sentiments for large and small projects
average_sentiment_large <- calculate_average_sentiment("installed_capacity >= 20")
average_sentiment_small <- calculate_average_sentiment("installed_capacity < 20")

# Merge the two data frames and calculate the difference
average_sentiment_diff <- merge(average_sentiment_large, average_sentiment_small, by = c("affiliation", "variable"), suffixes = c("_large", "_small"))
average_sentiment_diff$diff_sentiment <- average_sentiment_diff$avg_sentiment_large - average_sentiment_diff$avg_sentiment_small

# Create the heatmap for the difference in sentiments
p_diff <- ggplot(average_sentiment_diff, aes(x = variable, y = affiliation, fill = diff_sentiment)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "red", mid = "white", high = "green", limits = c(-1, 1), 
                       breaks = c(-1, -0.5, 0, 0.5, 1), 
                       labels = c("-1", "-0.5", "0", "0.5", "1"), 
                       name = "Sentiment Difference") +
  labs(x = "Consideration", y = "Affiliation", title = "Difference in Sentiment: Large vs Small Projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10), # Rotate text and adjust size
    axis.text.y = element_text(size = 10),  # Adjust size of y-axis text
    plot.title = element_text(hjust = 0.5)  # Center the title
  )


# Explicitly print the plot
print(p_diff)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
