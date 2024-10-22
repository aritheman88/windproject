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

# Filter data for the specific affiliations, considerations, and rejected projects (project_status = 'rejected')
desired_affiliations <- c("Developers", "Environmental organizations", "Government", "Locals", "Planning bodies")
considerations <- c("Environmental", "Planning", "Community_acceptance", "Technical", "Finance")
rejected_projects <- subset(projects, project_status == "rejected")
filtered_quotes <- subset(all_quotes, affiliation %in% desired_affiliations & project_code %in% rejected_projects$plan_number)
print("Data filtered")

# Melt the data to have one consideration per row
melted_data <- melt(filtered_quotes, id.vars = c("affiliation", "sentiment"), measure.vars = considerations)
melted_data <- subset(melted_data, value == 1)
print("Data melted")

# Filter data for at least 5 observations per affiliation-consideration combination
min_observations <- 5
filtered_melted_data <- melted_data %>%
  group_by(affiliation, variable) %>%
  filter(n() >= min_observations)

# Adjust variable labels for better readability
filtered_melted_data$variable <- recode(filtered_melted_data$variable, 
                                        "Environmental" = "Environmental", 
                                        "Planning" = "Planning", 
                                        "Community_acceptance" = "Community acceptance", 
                                        "Technical" = "Technical", 
                                        "Finance" = "Finance")

# Set the desired order for the variable factor levels alphabetically
filtered_melted_data$variable <- factor(filtered_melted_data$variable, levels = sort(c("Environmental", "Planning", "Community acceptance", "Technical", "Finance")))

# Calculate the average sentiment for each combination of affiliation and consideration for rejected projects
average_sentiment_rejected <- filtered_melted_data %>%
  group_by(affiliation, variable) %>%
  summarise(avg_sentiment = mean(sentiment), .groups = 'drop')
print("Average sentiment calculated for rejected projects")

# Cap the avg_sentiment at 0
average_sentiment_rejected$avg_sentiment <- pmin(average_sentiment_rejected$avg_sentiment, 0)

# Create the heatmap for rejected projects
p_rejected <- ggplot(average_sentiment_rejected, aes(x = variable, y = affiliation, fill = avg_sentiment)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", limits = c(-1, 0), 
                      breaks = c(-1, -0.5, 0), 
                      labels = c("Negative", "Neutral", "Positive"), 
                      name = "Sentiment") +
  labs(x = "Consideration", y = "Affiliation", title = "Rejected projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8), # Rotate and adjust size of x-axis text
    axis.text.y = element_text(angle = 45, hjust = 1, size = 8), # Rotate and adjust size of y-axis text
    plot.title = element_text(hjust = 0.5)  # Center the title
  )

# Explicitly print the plot
print(p_rejected)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
