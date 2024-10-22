import sqlite3
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification

def analyze_stance_long_text(stance_analyzer, text, subject, max_length=512):
    """Splits the text into chunks, analyzes the stance of each chunk, and aggregates the results."""
    num_chunks = (len(text) + max_length - 1) // max_length  # Calculate number of chunks needed
    stances = []
    for i in range(num_chunks):
        chunk = text[i * max_length: (i + 1) * max_length]
        result = stance_analyzer(f"{chunk} [SEP] {subject}")[0]
        score = result['score'] if result['label'] == 'SUPPORT' else -result['score']
        stances.append(score)

    # Aggregate the stance scores
    avg_stance = sum(stances) / len(stances)
    return avg_stance

# Connect to the SQLite database
db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Add a new column "stance_detection" to the "all_quotes" table if it doesn't already exist
try:
    cursor.execute('''ALTER TABLE all_quotes ADD COLUMN stance_detection REAL''')
    print("Column 'stance_detection' added successfully.")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("Column 'stance_detection' already exists.")
    else:
        print(f"An error occurred: {e}")

# Clear existing values in the "stance_detection" column
cursor.execute('UPDATE all_quotes SET stance_detection = NULL')
print("Cleared existing values in the 'stance_detection' column.")

# Initialize the stance detection pipeline
model_name = "dominiks/stance-detection"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name)
stance_analyzer = pipeline('text-classification', model=model, tokenizer=tokenizer)

# Fetch all translated quotes that need stance detection analysis
cursor.execute('SELECT rowid, quote_en FROM all_quotes WHERE quote_en IS NOT NULL')
rows = cursor.fetchall()
print(f"Fetched {len(rows)} rows.")

# Analyze the stance of each quote and update the database
subject = "wind turbine project"  # The subject of interest
for rowid, quote_en in rows:
    try:
        print(f"Analyzing stance for rowid {rowid}: {quote_en[:50]}...")  # Print the first 50 characters for context
        stance_score = analyze_stance_long_text(stance_analyzer, quote_en, subject)
        cursor.execute('UPDATE all_quotes SET stance_detection = ? WHERE rowid = ?', (stance_score, rowid))
        print(f"Updated rowid {rowid} with stance score: {stance_score}")
    except Exception as e:
        print(f"Error analyzing stance for rowid {rowid}: {e}")

# Commit the changes and close the connection
conn.commit()
print("Changes committed to the database.")
conn.close()
print("Connection closed.")
