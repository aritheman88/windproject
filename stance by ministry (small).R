# Load necessary libraries
if (!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)
if (!require(DBI)) install.packages("DBI")
library(DBI)
if (!require(RSQLite)) install.packages("RSQLite")
library(RSQLite)
if (!require(tidyr)) install.packages("tidyr")
library(tidyr)
if (!require(extrafont)) install.packages("extrafont")
library(extrafont)

# Load fonts for Windows
loadfonts(device = "win")

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

# Ensure 'affiliation', 'role', 'installed_capacity', and 'position' columns are properly formatted
all_quotes$affiliation <- as.factor(all_quotes$affiliation)
all_quotes$role <- as.factor(all_quotes$role)
projects$installed_capacity <- as.numeric(projects$installed_capacity)
all_quotes$position <- as.factor(all_quotes$position)
print("Data formatted")

# Filter data for small projects (installed capacity < 20 MW)
small_projects <- subset(projects, installed_capacity < 20)
filtered_quotes <- subset(all_quotes, project_code %in% small_projects$plan_number)
print("Data filtered")

# Filter for government ministries
government_ministries <- c(
  "Environmental Protection", "Defense", "Energy", "Interior",
  "Transportation", "Health", "Agriculture", "Finance"
)
gov_filtered_quotes <- subset(filtered_quotes, affiliation == "Government" & role %in% government_ministries)
print("Filtered for government ministries")

# Verify the filtered data
print("Filtered data verification:")
print(table(gov_filtered_quotes$role, gov_filtered_quotes$position))

# Calculate the count of each stance by government ministry
stance_counts <- gov_filtered_quotes %>%
  group_by(role, position) %>%
  summarise(count = n(), .groups = 'drop')

# Add missing combinations of ministries and positions with counts set to 0
complete_stance_counts <- stance_counts %>%
  complete(role = government_ministries, position = c("Support", "Neutral", "Weakly opposed", "Strongly opposed"), fill = list(count = 0))

# Calculate the percentage of each stance within each ministry
stance_percentages <- complete_stance_counts %>%
  group_by(role) %>%
  mutate(percentage = count / sum(count) * 100)

# Verify the stance percentages
print("Stance percentages verification:")
print(stance_percentages)

# Define the correct stacking order: Support on top, Strongly opposed at the bottom
stance_levels <- c("Strongly opposed", "Weakly opposed", "Neutral", "Support")  # Ensure correct order

# Ensure the factor levels are reversed for the correct stacking
stance_percentages$position <- factor(stance_percentages$position, levels = stance_levels)

# Calculate total observations per ministry
total_counts <- complete_stance_counts %>%
  group_by(role) %>%
  summarise(total = sum(count), .groups = 'drop')


# Map colors for the specified stance levels with adjusted green
stance_colors <- c(
  "Strongly opposed" = "#8B0000",  # Dark red
  "Weakly opposed" = "#CD5C5C",    # Lighter red
  "Neutral" = "#D3D3D3",           # Grey
  "Support" = "#228B22"            # Less bright green
)

# Create the stacked percentage bar chart with updated label for "Environmental Protection"
p_stacked <- ggplot(stance_percentages, aes(x = role, y = percentage, fill = position)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(data = total_counts, aes(x = role, y = 105, label = paste("N =", total)),
            inherit.aes = FALSE, size = 3.5, family = "Times New Roman") +
  scale_fill_manual(values = stance_colors) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  scale_x_discrete(labels = function(x) ifelse(x == "Environmental Protection", "Env. Protection", x)) +
  labs(
    x = "Government Ministry",
    y = "Percentage",
    fill = "Stance",
    title = "5a. Share of stances regarding small projects"
  ) +
  theme_minimal(base_family = "Times New Roman") +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10, family = "Times New Roman"),  
    axis.text.y = element_text(size = 10, family = "Times New Roman"),  
    plot.title = element_text(hjust = 0.5, size = 16, family = "Times New Roman"),  
    legend.text = element_text(size = 10, family = "Times New Roman"),
    legend.title = element_text(size = 12, family = "Times New Roman"),
    strip.text.x = element_text(size = 12, family = "Times New Roman")  
  )


# Explicitly print the plot
print(p_stacked)


# Save the plot with font embedding
ggsave("plot_government_ministries_small_projects.pdf", plot = p_stacked, device = cairo_pdf, width = 10, height = 6)
extrafont::embed_fonts("plot_government_ministries_small_projects.pdf")

# Disconnect from the database
dbDisconnect(con)
print("Database disconnected")
