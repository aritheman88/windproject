# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)

# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Read the CSV file into R
query_result <- read.csv("quotes_sentiment_status.csv")
print("CSV file read")

# Check the structure of the data
str(query_result)
head(query_result)

# Ensure 'affiliation' and 'sentiment' columns are properly formatted
query_result$affiliation <- as.factor(query_result$affiliation)
query_result$sentiment <- as.numeric(query_result$sentiment)
print("Data formatted")

# Filter data for the specific affiliations and considerations
desired_affiliations <- c("Developers", "Environmental organizations", "Government", "Locals", "Planning bodies")
considerations <- c("Environmental", "Planning", "Community_acceptance", "Technical", "Finance")
filtered_data <- subset(query_result, affiliation %in% desired_affiliations)
print("Data filtered")

# Melt the data to have one consideration per row
library(reshape2)
melted_data <- melt(filtered_data, id.vars = c("affiliation", "sentiment"), measure.vars = considerations)
melted_data <- subset(melted_data, value == 1)
print("Data melted")

# Calculate the average sentiment for each combination of affiliation and consideration
average_sentiment <- melted_data %>%
  group_by(affiliation, variable) %>%
  summarise(avg_sentiment = mean(sentiment), .groups = 'drop')
print("Average sentiment calculated")

# Create the heatmap
p <- ggplot(average_sentiment, aes(x = variable, y = affiliation, fill = avg_sentiment)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "black", high = "white", limits = c(-1, 0), name = "Sentiment") +
  labs(x = "Consideration", y = "Affiliation") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10), # Rotate text and adjust size
    axis.text.y = element_text(size = 10)  # Adjust size of y-axis text
  )

# Explicitly print the plot
print(p)
