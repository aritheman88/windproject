# Load necessary libraries
library(DBI)
library(RSQLite)
library(irr)  # For Cohen's Kappa
library(ggplot2) # For visualization
if (!require(extrafont)) install.packages("extrafont")
library(extrafont)

# Load fonts for Windows
loadfonts(device = "win")

# Connect to the SQLite database
db_path <- "C:/Users/ariel/MyPythonScripts/wind/wind_project.db"
conn <- dbConnect(SQLite(), dbname = db_path)

# Query data from the database
query <- "SELECT position, GPT_3_prediction FROM all_quotes WHERE position IS NOT NULL AND GPT_3_prediction IS NOT NULL"
data <- dbGetQuery(conn, query)

# Convert GPT_3_prediction numeric values to categorical
data$gpt3_category <- NA
data$gpt3_category[data$GPT_3_prediction == 1] <- "Support"
data$gpt3_category[data$GPT_3_prediction == 0] <- "Neutral"
data$gpt3_category[data$GPT_3_prediction == -0.5 | data$GPT_3_prediction == -1] <- "Oppose"

# Ensure consistent capitalization for manual position
data$position <- tolower(data$position)

# Map manual positions to 4-level structure
# You may need to adjust these mappings based on your actual data
data$manual_category <- NA
data$manual_category[grepl("support", data$position)] <- "Support"
data$manual_category[grepl("neutral", data$position)] <- "Neutral"
data$manual_category[grepl("weak.*oppos", data$position) | grepl("oppos.*weak", data$position)] <- "Weak Oppose"
data$manual_category[grepl("strong.*oppos", data$position) | grepl("oppos.*strong", data$position)] <- "Strong Oppose"

# If you have other opposition terms that should be categorized:
# Uncomment and modify these lines as needed based on your data
# data$manual_category[grepl("oppose", data$position) & is.na(data$manual_category)] <- "Weak Oppose"  # Default oppose to weak
# data$manual_category[grepl("against", data$position)] <- "Weak Oppose"

# Display the distribution of categories before factoring
print("Distribution before factoring:")
print("Manual positions:")
print(table(data$manual_category, useNA = "always"))
print("GPT-3 predictions:")
print(table(data$gpt3_category, useNA = "always"))

# Set factor levels
manual_levels <- c("Support", "Neutral", "Weak Oppose", "Strong Oppose")
gpt3_levels <- c("Support", "Neutral", "Oppose")

data$manual_category <- factor(data$manual_category, levels = manual_levels)
data$gpt3_category <- factor(data$gpt3_category, levels = gpt3_levels)

# Remove rows with missing categories
data_clean <- data[!is.na(data$manual_category) & !is.na(data$gpt3_category), ]

print(paste("Total observations after cleaning:", nrow(data_clean)))
print(paste("Removed", nrow(data) - nrow(data_clean), "rows with missing categories"))

# Create the confusion matrix (raw counts)
confusion_matrix <- table(data_clean$manual_category, data_clean$gpt3_category)
print("Confusion Matrix (Manual vs GPT-3):")
print("Rows = Manual Detection, Columns = GPT-3 Detection")
print(confusion_matrix)

# Also create a more detailed summary
print("\nDetailed Confusion Matrix:")
confusion_df <- as.data.frame.table(confusion_matrix)
names(confusion_df) <- c("Manual", "GPT3", "Count")
print(confusion_df[confusion_df$Count > 0, ])  # Only show non-zero entries

# Calculate row percentages (what % of each manual category was classified as each GPT-3 category)
row_percentages <- prop.table(confusion_matrix, 1) * 100
print("\nRow Percentages (% of each manual category):")
print(round(row_percentages, 1))

# Calculate column percentages (what % of each GPT-3 category came from each manual category)
col_percentages <- prop.table(confusion_matrix, 2) * 100
print("\nColumn Percentages (% of each GPT-3 category):")
print(round(col_percentages, 1))

# Overall accuracy
total_correct <- sum(diag(confusion_matrix))
total_observations <- sum(confusion_matrix)
overall_accuracy <- total_correct / total_observations
print(paste("\nOverall Agreement:", round(overall_accuracy * 100, 1), "%"))

# Create visualization showing raw counts
confusion_viz_df <- as.data.frame.table(confusion_matrix)
names(confusion_viz_df) <- c("Manual", "GPT3", "Count")

# Create heatmap with raw counts
ggplot(confusion_viz_df, aes(x = GPT3, y = Manual, fill = Count)) +
  geom_tile(color = "white", size = 0.5) +
  geom_text(aes(label = Count), color = "black", size = 5, fontface = "bold", family = "Times New Roman") +
  scale_fill_gradient(low = "white", high = "steelblue", name = "Count") +
  theme_minimal() +
  theme(
    axis.text = element_text(size = 12, family = "Times New Roman"),
    axis.title = element_text(size = 14, face = "bold", family = "Times New Roman"),
    title = element_text(size = 16, face = "bold", family = "Times New Roman"),
    legend.text = element_text(family = "Times New Roman"),
    legend.title = element_text(family = "Times New Roman"),
    panel.grid = element_blank()
  ) +
  labs(
    title = "Correlation Matrix: Manual vs. Automated Stance Detection",
    subtitle = "Raw counts of observations",
    x = "Automated", 
    y = "Manual"
  )

# Save the plot
ggsave("confusion_matrix_counts.pdf", plot = last_plot(), device = cairo_pdf, width = 10, height = 8, dpi = 300)
extrafont::embed_fonts("confusion_matrix_counts.pdf")

# For Cohen's Kappa, we need to collapse to matching categories
# Create a 3x3 version by combining opposition categories
data_clean$manual_3cat <- as.character(data_clean$manual_category)
data_clean$manual_3cat[data_clean$manual_3cat %in% c("Weak Oppose", "Strong Oppose")] <- "Oppose"
data_clean$manual_3cat <- factor(data_clean$manual_3cat, levels = c("Support", "Neutral", "Oppose"))

# Calculate Cohen's Kappa for 3x3 comparison
kappa_result <- kappa2(data_clean[, c("manual_3cat", "gpt3_category")])
print("\nCohen's Kappa (3x3 comparison):")
print(kappa_result)

# Close the database connection
dbDisconnect(conn)