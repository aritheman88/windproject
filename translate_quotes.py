import sqlite3
from easygoogletranslate import EasyGoogleTranslate

def translate_long_text(translator, text, max_length=5000):
    """Splits the text into chunks and translates them individually."""
    translated_chunks = []
    for i in range(0, len(text), max_length):
        chunk = text[i:i + max_length]
        translated_chunk = translator.translate(chunk)
        translated_chunks.append(translated_chunk)
    return ''.join(translated_chunks)

# Connect to the SQLite database
db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Add a new column "quote_en" to the "all_quotes" table if it doesn't already exist
try:
    cursor.execute('''ALTER TABLE all_quotes ADD COLUMN quote_en TEXT''')
    print("Column 'quote_en' added successfully.")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("Column 'quote_en' already exists.")
    else:
        print(f"An error occurred: {e}")

# Initialize the translator
translator = EasyGoogleTranslate(
    source_language='he',
    target_language='en',
    timeout=10
)

# Fetch all quotes that need to be translated
cursor.execute('SELECT rowid, quote FROM all_quotes')
rows = cursor.fetchall()
print(f"Fetched {len(rows)} rows.")

# Translate each quote and update the database
for rowid, quote in rows:
    if quote:  # Ensure there is a quote to translate
        try:
            print(f"Translating quote with rowid {rowid}: {quote[:50]}...")  # Print the first 50 characters for context
            if len(quote) > 5000:
                translated_quote = translate_long_text(translator, quote)
            else:
                translated_quote = translator.translate(quote)
            cursor.execute('UPDATE all_quotes SET quote_en = ? WHERE rowid = ?', (translated_quote, rowid))
            print(f"Updated rowid {rowid} with translation: {translated_quote[:50]}...")  # Print the first 50 characters for context
        except Exception as e:
            print(f"Error translating rowid {rowid}: {e}")

# Commit the changes and close the connection
conn.commit()
print("Changes committed to the database.")
conn.close()
print("Connection closed.")
