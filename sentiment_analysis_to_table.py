import sqlite3
from transformers import pipeline

def analyze_sentiment_long_text(sentiment_analyzer, text, max_length=512):
    """Splits the text into chunks, analyzes the sentiment of each chunk, and aggregates the results."""
    num_chunks = (len(text) + max_length - 1) // max_length  # Calculate number of chunks needed
    sentiments = []
    for i in range(num_chunks):
        chunk = text[i * max_length: (i + 1) * max_length]
        result = sentiment_analyzer(chunk)[0]
        score = result['score'] if result['label'] == 'POSITIVE' else -result['score']
        sentiments.append(score)

    # Aggregate the sentiment scores
    avg_sentiment = sum(sentiments) / len(sentiments)
    return avg_sentiment

# Connect to the SQLite database
db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Add a new column "sentiment" to the "all_quotes" table if it doesn't already exist
try:
    cursor.execute('''ALTER TABLE all_quotes ADD COLUMN sentiment REAL''')
    print("Column 'sentiment' added successfully.")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("Column 'sentiment' already exists.")
    else:
        print(f"An error occurred: {e}")

# Clear existing values in the "sentiment" column
cursor.execute('UPDATE all_quotes SET sentiment = NULL')
print("Cleared existing values in the 'sentiment' column.")

# Initialize the sentiment analysis pipeline
sentiment_analyzer = pipeline('sentiment-analysis')

# Fetch all translated quotes that need sentiment analysis
cursor.execute('SELECT rowid, quote_en FROM all_quotes WHERE quote_en IS NOT NULL')
rows = cursor.fetchall()
print(f"Fetched {len(rows)} rows.")

# Analyze the sentiment of each quote and update the database
for rowid, quote_en in rows:
    try:
        print(f"Analyzing sentiment for rowid {rowid}: {quote_en[:50]}...")  # Print the first 50 characters for context
        sentiment_score = analyze_sentiment_long_text(sentiment_analyzer, quote_en)
        cursor.execute('UPDATE all_quotes SET sentiment = ? WHERE rowid = ?', (sentiment_score, rowid))
        print(f"Updated rowid {rowid} with sentiment score: {sentiment_score}")
    except Exception as e:
        print(f"Error analyzing sentiment for rowid {rowid}: {e}")

# Commit the changes and close the connection
conn.commit()
print("Changes committed to the database.")
conn.close()
print("Connection closed.")