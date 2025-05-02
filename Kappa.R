# Load necessary libraries
library(DBI)
library(RSQLite)
library(irr)  # For Cohen's Kappa
library(ggplot2) # For visualization

# Connect to the SQLite database
db_path <- "C:/Users/ariel/MyPythonScripts/wind/wind_project.db"
conn <- dbConnect(SQLite(), dbname = db_path)

# Query data from the database
query <- "SELECT position, GPT_3_prediction FROM all_quotes WHERE position IS NOT NULL AND GPT_3_prediction IS NOT NULL"
data <- dbGetQuery(conn, query)

# Convert GPT_3_prediction numeric values to categorical
data$gpt3_category <- NA
data$gpt3_category[data$GPT_3_prediction == 1] <- "support"
data$gpt3_category[data$GPT_3_prediction == 0] <- "neutral"
data$gpt3_category[data$GPT_3_prediction == -0.5 | data$GPT_3_prediction == -1] <- "oppose"

# Ensure consistent capitalization
data$position <- tolower(data$position)

# Merge negative stances into a single category for position
data$position[grepl("oppose", data$position)] <- "oppose"

# Display the distribution of categories before factoring
print("Distribution before factoring:")
print(table(data$position))
print(table(data$gpt3_category))

# Ensure categories match the desired order
desired_order <- c("support", "neutral", "oppose")
data$position <- factor(data$position, levels = desired_order)
data$gpt3_category <- factor(data$gpt3_category, levels = desired_order)

# Create a contingency table
cont_table <- table(data$position, data$gpt3_category)
print("Contingency Table:")
print(cont_table)

# Calculate Cohen's Kappa
kappa_result <- kappa2(data[, c("position", "gpt3_category")])

# After calculating kappa_result
print("Cohen's Kappa:")
print(kappa_result)

# Extract values directly from the printed output
# This is a workaround - not elegant but might work
kappa_output <- capture.output(print(kappa_result))
print(kappa_output)

# Try to find the z-value line
z_line <- grep("z", kappa_output, value = TRUE)
if (length(z_line) > 0) {
  z_score <- as.numeric(gsub(".*z = ([0-9.]+).*", "\\1", z_line))
  exact_p_value <- 2 * pnorm(-abs(z_score))
  
  print("Significance Statistics:")
  print(paste("z-score:", round(z_score, 3)))
  print(paste("Exact p-value:", format(exact_p_value, scientific = TRUE, digits = 10)))
} else {
  print("Could not extract z-score from output")
}

# Calculate precision, recall and F1 score for each category
categories <- desired_order
precision <- numeric(length(categories))
recall <- numeric(length(categories))
f1 <- numeric(length(categories))

for (i in 1:length(categories)) {
  category <- categories[i]
  true_positive <- cont_table[category, category]
  false_positive <- sum(cont_table[, category]) - true_positive
  false_negative <- sum(cont_table[category, ]) - true_positive
  
  precision[i] <- ifelse(true_positive + false_positive > 0, 
                         true_positive / (true_positive + false_positive), 0)
  recall[i] <- ifelse(true_positive + false_negative > 0, 
                      true_positive / (true_positive + false_negative), 0)
  f1[i] <- ifelse(precision[i] + recall[i] > 0, 
                  2 * precision[i] * recall[i] / (precision[i] + recall[i]), 0)
}

metrics_df <- data.frame(
  Category = categories,
  Precision = round(precision, 3),
  Recall = round(recall, 3),
  F1_Score = round(f1, 3)
)

print("Performance Metrics by Category:")
print(metrics_df)

# Visualize the confusion matrix
confusion_df <- as.data.frame.table(cont_table)
names(confusion_df) <- c("Manual", "GPT3", "Frequency")

# Calculate percentages for each row (manual position)
confusion_df$Percentage <- 0
for (pos in desired_order) {
  total <- sum(confusion_df$Frequency[confusion_df$Manual == pos])
  confusion_df$Percentage[confusion_df$Manual == pos] <- 
    confusion_df$Frequency[confusion_df$Manual == pos] / total * 100
}

# Create heatmap of confusion matrix
ggplot(confusion_df, aes(x = GPT3, y = Manual, fill = Percentage)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.1f%%", Percentage)), color = "black", size = 4) +
  scale_fill_gradient(low = "white", high = "steelblue") +
  theme_minimal() +
  labs(
    title = "Confusion Matrix: Manual vs. GPT-3 Stance Detection",
    x = "GPT-3 Prediction", 
    y = "Manual Position",
    fill = "Percentage"
  )

# Save the plot if desired
ggsave("confusion_matrix.png", width = 8, height = 6)

# Close the database connection
dbDisconnect(conn)