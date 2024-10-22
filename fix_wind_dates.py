import sqlite3
from datetime import datetime

# Path to your SQLite database
db_path = "C:/Users/ariel/MyPythonScripts/wind/wind_project.db"

# Connect to the database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Selecting all rows from the projects table
cursor.execute("SELECT rowid, initiation_date, final_decision_date FROM projects")
rows = cursor.fetchall()

# Function to convert date format from DD/MM/YYYY to YYYY-MM-DD, handling None values
def convert_date_format(date_str):
    if date_str is None:
        return None  # or return an empty string "", depending on your requirement
    try:
        return datetime.strptime(date_str, "%d/%m/%Y").strftime("%Y-%m-%d")
    except ValueError:
        # Return the original string if it doesn't match the expected format
        return date_str

# Updating the initiation_date and final_decision_date in the database
for row in rows:
    rowid, initiation_date, final_decision_date = row
    new_initiation_date = convert_date_format(initiation_date)
    new_final_decision_date = convert_date_format(final_decision_date)

    update_query = """UPDATE projects SET initiation_date = ?, final_decision_date = ? WHERE rowid = ?"""
    cursor.execute(update_query, (new_initiation_date, new_final_decision_date, rowid))

# Committing the changes and closing the connection
conn.commit()
conn.close()

print("Date formats in the projects table have been updated.")
