# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(reshape2)) install.packages("reshape2")
library(reshape2)

# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Read the CSV file into R
query_result <- read.csv("quotes_sentiment_status.csv")
print("CSV file read")

# Check the structure of the data
str(query_result)
head(query_result)

# Ensure 'affiliation', 'project_status', and 'sentiment' columns are properly formatted
query_result$affiliation <- as.factor(query_result$affiliation)
query_result$project_status <- as.factor(query_result$project_status)
query_result$sentiment <- as.numeric(query_result$sentiment)
print("Data formatted")

# Filter data for the specific affiliations, considerations, and rejected projects
desired_affiliations <- c("Developers", "Environmental organizations", "Government", "Locals", "Planning bodies")
considerations <- c("Environmental", "Planning", "Community_acceptance", "Technical", "Finance")
filtered_data <- subset(query_result, affiliation %in% desired_affiliations & project_status == "rejected")
print("Data filtered")

# Melt the data to have one consideration per row
melted_data <- melt(filtered_data, id.vars = c("affiliation", "sentiment"), measure.vars = considerations)
melted_data <- subset(melted_data, value == 1)
print("Data melted")

# Filter data for at least 5 observations per affiliation-consideration combination
min_observations <- 5
filtered_melted_data <- melted_data %>%
  group_by(affiliation, variable) %>%
  filter(n() >= min_observations)

# Calculate the average sentiment for each combination of affiliation and consideration for rejected projects
average_sentiment_rejected <- filtered_melted_data %>%
  group_by(affiliation, variable) %>%
  summarise(avg_sentiment = mean(pmin(sentiment, 0)), .groups = 'drop')
print("Average sentiment calculated for rejected projects")

# Create the heatmap for rejected projects
p_rejected <- ggplot(average_sentiment_rejected, aes(x = variable, y = affiliation, fill = avg_sentiment)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", limits = c(-1, 0), 
                      breaks = c(-1, -0.5, 0), 
                      labels = c("-1.00", "-0.50", "0.00+"), 
                      name = "Sentiment") +
  labs(x = "Consideration", y = "Affiliation", title = "Rejected projects") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10), # Rotate text and adjust size
    axis.text.y = element_text(size = 10),  # Adjust size of y-axis text
    plot.title = element_text(hjust = 0.5)  # Center the title
  )

# Explicitly print the plot
print(p_rejected)
