# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(DBI)) install.packages("DBI")
library(DBI)
if (!require(RSQLite)) install.packages("RSQLite")
library(RSQLite)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(extrafont)) install.packages("extrafont")
library(extrafont)
if (!require(ggpattern)) install.packages("ggpattern")
library(ggpattern)

loadfonts(device = "win")  # For Windows

# Set the working directory
setwd("C:/Users/ariel/MyPythonScripts/wind")
print("Working directory set")

# Connect to the SQLite database
con <- dbConnect(RSQLite::SQLite(), "wind_project.db")
print("Database connected")

# Query for submitted projects
submitted_query <- "
  SELECT SUBSTR(initiation_date, 1, 4) AS year, COUNT(*) AS Submitted_count
  FROM projects
  WHERE installed_capacity >= 20
  GROUP BY year
  ORDER BY year
"
submitted_data <- dbGetQuery(con, submitted_query)

# Query for approved projects
approved_query <- "
  SELECT SUBSTR(final_decision_date, 1, 4) AS year, COUNT(*) AS approved_count
  FROM projects
  WHERE installed_capacity >= 20
    AND project_status = 'approved'
  GROUP BY year
  ORDER BY year
"
approved_data <- dbGetQuery(con, approved_query)

# Query for rejected projects
rejected_query <- "
  SELECT SUBSTR(final_decision_date, 1, 4) AS year, COUNT(*) AS rejected_count
  FROM projects
  WHERE installed_capacity >= 20
    AND project_status = 'rejected'
  GROUP BY year
  ORDER BY year
"
rejected_data <- dbGetQuery(con, rejected_query)

# Merge all data by year
all_data <- merge(submitted_data, approved_data, by = "year", all = TRUE)
all_data <- merge(all_data, rejected_data, by = "year", all = TRUE)

# Replace NA values with 0
all_data[is.na(all_data)] <- 0

# Convert year to factor for consistent ordering
all_data$year <- factor(all_data$year, levels = as.character(2010:2023))

# Reshape data for side-by-side plotting
library(tidyr)
long_data <- all_data %>%
  pivot_longer(cols = c("Submitted_count", "approved_count", "rejected_count"),
               names_to = "stage", values_to = "count") %>%
  mutate(stage = recode(stage,
                        "Submitted_count" = "Submitted",
                        "approved_count" = "Approved",
                        "rejected_count" = "Rejected"))

# Create the chart
large_projects_chart <- ggplot(long_data, aes(x = year, y = count, fill = stage, pattern = stage)) +
  geom_bar_pattern(
    stat = "identity", 
    position = position_dodge(width = 0.8), 
    width = 1,
    pattern_color = "white",  # Set stripe lines to white
    pattern_fill = "orange",  # Background fill for "Submitted" bars
    pattern_density = 0.1,   # Adjust density of the stripes
    pattern_angle = 45       # Angle of the stripes
  ) +
  scale_x_discrete(
    limits = as.character(2010:2023), 
    labels = function(x) ifelse(as.numeric(x) %% 2 == 0, x, "")
  ) +
  scale_y_continuous(breaks = seq(0, max(long_data$count, na.rm = TRUE) + 5), 
                     minor_breaks = NULL) +
  scale_fill_manual(values = c("Submitted" = "orange", "Approved" = "darkgreen", "Rejected" = "red")) +
  scale_pattern_manual(values = c("Submitted" = "stripe", "Approved" = "none", "Rejected" = "none")) +
  labs(title = "2(b). Large projects",
       x = "Year",
       y = "Number of projects",
       fill = "Project stage",
       pattern = "Project stage") +
  theme_minimal() +
  theme(
    text = element_text(family = "Times New Roman", size = 10), 
    legend.title = element_text(size = 10), 
    legend.text = element_text(size = 9),
    axis.title = element_text(size = 10),
    axis.text = element_text(size = 9),
    plot.title = element_text(size = 12),
    legend.position = "right",
    panel.grid.major = element_line(color = "gray85", size = 0.5), 
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "black", size = 1),  
    axis.line.y = element_line(color = "black", size = 1),  
    plot.margin = unit(c(1, 1, 0, 1), "lines")
  ) +
  coord_cartesian(clip = "off", ylim = c(0, max(long_data$count, na.rm = TRUE) + 5))

# Print the chart
print(large_projects_chart)

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
