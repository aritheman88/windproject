# Load necessary libraries
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(DBI)) install.packages("DBI")
library(DBI)
if (!require(RSQLite)) install.packages("RSQLite")
library(RSQLite)
if (!require(tidyr)) install.packages("tidyr")
library(tidyr)
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(extrafont)) install.packages("extrafont")
library(extrafont)

loadfonts(device = "win")  # Load system fonts for Windows

# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Connect to the SQLite database
con <- dbConnect(RSQLite::SQLite(), "wind_project.db")
print("Database connected")

# Query the data from the all_quotes table
all_quotes <- dbGetQuery(con, "SELECT * FROM all_quotes")
# Retrieve data from the "projects" table
projects <- dbGetQuery(con, "SELECT plan_number, installed_capacity FROM projects")

# Join the "all_quotes" table with the "projects" table
all_quotes_joined <- all_quotes %>%
  left_join(projects, by = c("project_code" = "plan_number"))

# Classify projects as small (<20 MW) or large (>=20 MW)
all_quotes_joined <- all_quotes_joined %>%
  mutate(
    project_size = ifelse(installed_capacity < 20, "Small projects", "Large projects")  # Updated labels
  )

# Filter out rows where project_size is NA
all_quotes_joined <- all_quotes_joined %>%
  filter(!is.na(project_size))

# Calculate the share of statements that are 1 for each factor, grouped by project size
factor_shares_by_size <- all_quotes_joined %>%
  group_by(project_size) %>%
  summarise(
    Community_acceptance = mean(Community_acceptance, na.rm = TRUE),
    Technical = mean(Technical, na.rm = TRUE),
    Finance = mean(Finance, na.rm = TRUE),
    Environmental = mean(Environmental, na.rm = TRUE),
    Planning = mean(Planning, na.rm = TRUE)
  )

# Convert the result to a long format for plotting
factor_shares_long <- factor_shares_by_size %>%
  pivot_longer(cols = -project_size, names_to = "Factor", values_to = "Share") %>%
  mutate(Factor = recode(Factor, "Community_acceptance" = "Community acceptance"))  # Updated column name

# Create the grouped bar chart
ggplot(factor_shares_long, aes(x = Factor, y = Share * 100, fill = project_size)) +  # Convert Share to percentage
  geom_bar(stat = "identity", position = position_dodge(width = 0.8)) +
  labs(title = "Share of statements by factor and project size", 
       x = "Factor", 
       y = "Share of statements (%)") +  # Updated y-axis label
  scale_fill_manual(values = c("Small projects" = "skyblue", "Large projects" = "orange")) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +  # Show percentages on y-axis
  theme_minimal() +
  theme(
    text = element_text(family = "Times New Roman", size = 12),  # Use Times New Roman
    legend.title = element_blank(),
    legend.text = element_text(size = 10),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10),
    plot.title = element_text(size = 14)
  )

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
