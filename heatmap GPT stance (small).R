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

# Ensure 'affiliation', 'installed_capacity', and 'GPT_stance_detection' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
projects$installed_capacity <- as.numeric(projects$installed_capacity)

# Convert 'GPT_stance_detection' to numeric values:
# Strong oppose = -1, Weak oppose = -0.5, Neutral = 0, Weak support = 0.5, Strong support = 1
all_quotes$GPT_stance_numeric <- case_when(
  all_quotes$GPT_stance_detection == "Strong oppose" ~ -1,
  all_quotes$GPT_stance_detection == "Weak oppose" ~ -0.5,
  all_quotes$GPT_stance_detection == "Neutral" ~ 0,
  all_quotes$GPT_stance_detection == "Weak support" ~ 0.5,
  all_quotes$GPT_stance_detection == "Strong support" ~ 1,
  TRUE ~ NA_real_
)
print("GPT_stance_detection converted to numeric")

# Filter data for specific affiliations, considerations, and small projects (installed_capacity < 20 MW)
desired_affiliations <- c("Developers", "Environmental organizations", "Government", "Locals", "Planning bodies")
considerations <- c("Environmental", "Planning", "Community_acceptance", "Technical", "Finance")
small_projects <- subset(projects, installed_capacity < 20)
filtered_quotes <- subset(all_quotes, affiliation %in% desired_affiliations & project_code %in% small_projects$plan_number)
print("Data filtered for small projects")

# Melt the data to have one consideration per row
melted_data <- melt(filtered_quotes, id.vars = c("affiliation", "GPT_stance_numeric"), measure.vars = considerations)
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

# Calculate the average GPT stance for each combination of affiliation and consideration for small projects
average_stance_small_projects <- filtered_melted_data %>%
  group_by(affiliation, variable) %>%
  summarise(avg_stance = mean(GPT_stance_numeric, na.rm = TRUE), .groups = 'drop')
print("Average GPT stance calculated for small projects")

# Create the heatmap for small projects
p_small_projects <- ggplot(average_stance_small_projects, aes(x = variable, y = affiliation, fill = avg_stance)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "red", high = "green", limits = c(-1, 1), 
                      breaks = c(-1, 0, 1), 
                      labels = c("Strong Oppose", "Neutral", "Strong Support"), 
                      name = "GPT Stance") +
  labs(x = "Consideration", y = "Affiliation", title = "Small Projects (Installed Capacity < 20 MW) - GPT Stance Detection") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8), # Rotate and adjust size of x-axis text
    axis.text.y = element_text(angle = 45, hjust = 1, size = 8), # Rotate and adjust size of y-axis text
    plot.title = element_text(hjust = 0.5)  # Center the title
  )

# Explicitly print the plot
print(p_small_projects)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
