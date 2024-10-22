# Install required libraries if not already installed
if (!require("RSQLite")) install.packages("RSQLite", dependencies=TRUE)
if (!require("dplyr")) install.packages("dplyr", dependencies=TRUE)

# Load necessary libraries
library(RSQLite)
library(dplyr)

# Connect to the SQLite database
db_path <- "C:/Users/ariel/MyPythonScripts/wind/wind_project.db"  # Adjust path if necessary
conn <- dbConnect(RSQLite::SQLite(), dbname = db_path)

# Query the data from the 'all_quotes' table
all_quotes <- dbGetQuery(conn, "SELECT position, GPT_stance_detection FROM all_quotes WHERE position IS NOT NULL AND GPT_stance_detection IS NOT NULL")

# Check the structure of the data
str(all_quotes)

# Convert 'Position' to numeric values
# Positive = 4, Neutral = 3, Reservation (partial opposition) = 2, Negative = 1
all_quotes$position_numeric <- case_when(
  all_quotes$position == "Positive" ~ 4,
  all_quotes$position == "Neutral" ~ 3,
  all_quotes$position == "reservation" ~ 2,
  all_quotes$position == "Negative" ~ 1,
  TRUE ~ NA_real_  # Handle any unexpected values
)

# Convert 'GPT_stance_detection' to numeric values
# Strong support = 5, Weak support = 4, Neutral = 3, Weak oppose = 2, Strong oppose = 1
all_quotes$GPT_stance_numeric <- case_when(
  all_quotes$GPT_stance_detection == "Strong support" ~ 5,
  all_quotes$GPT_stance_detection == "Weak support" ~ 4,
  all_quotes$GPT_stance_detection == "Neutral" ~ 3,
  all_quotes$GPT_stance_detection == "Weak oppose" ~ 2,
  all_quotes$GPT_stance_detection == "Strong oppose" ~ 1,
  TRUE ~ NA_real_  # Handle any unexpected values
)

# Check if the conversion was successful
summary(all_quotes)

# Perform a correlation analysis between the two numeric columns
correlation_result <- cor(all_quotes$position_numeric, all_quotes$GPT_stance_numeric, use="complete.obs")
print(paste("Correlation between Position and GPT_stance_detection: ", correlation_result))

# Perform a linear regression to express the relationship
lm_model <- lm(GPT_stance_numeric ~ position_numeric, data=all_quotes)
summary(lm_model)

# Disconnect from the database
dbDisconnect(conn)

# Convert 'Position' to numeric values
# Positive = 4, Neutral = 3, Reservations = 2, Negative = 1
all_quotes$position_numeric <- case_when(
  all_quotes$position == "Positive" ~ 4,
  all_quotes$position == "Neutral" ~ 3,
  all_quotes$position == "Reservations" ~ 2,  # Ensure this is capitalized correctly
  all_quotes$position == "reservation" ~ 2,   # Include lowercase option to handle inconsistencies
  all_quotes$position == "Negative" ~ 1,
  TRUE ~ NA_real_  # Handle any unexpected values
)

# Create a bar plot of the average GPT stance detection for each manual position
avg_gpt_stance <- all_quotes %>%
  group_by(position_numeric) %>%
  summarise(mean_gpt_stance = mean(GPT_stance_numeric, na.rm = TRUE))

# Create a bar plot
ggplot(avg_gpt_stance, aes(x = factor(position_numeric), y = mean_gpt_stance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Average GPT Stance Detection by Position",
       x = "Manual Position (1 = Negative, 4 = Positive)",
       y = "Average GPT Stance (1 = Oppose, 5 = Support)") +
  theme_minimal()


