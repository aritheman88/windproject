import sqlite3
from transformers import pipeline

def analyze_sentiment(text, sentiment_analyzer):
    """Analyzes the sentiment of the provided text."""
    result = sentiment_analyzer(text)[0]
    score = result['score'] if result['label'] == 'POSITIVE' else -result['score']
    return score

# Connect to the SQLite database
db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Add a new column "end_sentiment" to the "all_quotes" table if it doesn't already exist
try:
    cursor.execute('''ALTER TABLE all_quotes ADD COLUMN end_sentiment REAL''')
    print("Column 'end_sentiment' added successfully.")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("Column 'end_sentiment' already exists.")
    else:
        print(f"An error occurred: {e}")

# Clear existing values in the "end_sentiment" column
cursor.execute('UPDATE all_quotes SET end_sentiment = NULL')
print("Cleared existing values in the 'end_sentiment' column.")

# Initialize the sentiment analysis pipeline
sentiment_analyzer = pipeline('sentiment-analysis')

# Fetch all translated quotes that need sentiment analysis
cursor.execute('SELECT rowid, quote_en FROM all_quotes WHERE quote_en IS NOT NULL')
rows = cursor.fetchall()
print(f"Fetched {len(rows)} rows.")

# Analyze the sentiment of the last 500 characters of each quote and update the database
for rowid, quote_en in rows:
    try:
        end_quote = quote_en[-500:]  # Get the last 500 characters
        print(f"Analyzing end sentiment for rowid {rowid}: {end_quote[:50]}...")  # Print the first 50 characters for context
        end_sentiment_score = analyze_sentiment(end_quote, sentiment_analyzer)
        cursor.execute('UPDATE all_quotes SET end_sentiment = ? WHERE rowid = ?', (end_sentiment_score, rowid))
        print(f"Updated rowid {rowid} with end sentiment score: {end_sentiment_score}")
    except Exception as e:
        print(f"Error analyzing end sentiment for rowid {rowid}: {e}")

# Commit the changes and close the connection
conn.commit()
print("Changes committed to the database.")
conn.close()
print("Connection closed.")
