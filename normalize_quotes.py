import sqlite3

db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
# Connect to the SQLite database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()
# Fetch all rows from the database
cursor.execute("SELECT rowid, * FROM all_quotes")
rows = cursor.fetchall()
# Prepare the SQL insert statement for adding new rows
insert_statement = """INSERT INTO all_quotes (
    session_date, year, project_code, committee, speaker, role, affiliation, position, quote, 
    Community_acceptance, Technical, Finance, Landrights, Environmental, Planning, veto_actor, size_mention
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"""

for row in rows:
    project_codes = str(row[3])  # Ensure we're using the correct index for project_code
    if ';' in project_codes:
        # Split the project codes and strip whitespace
        codes = [code.strip() for code in project_codes.split(';')]
        # For each project code, prepare data for inserting a new row
        for code in codes:
            # Correctly construct new_row_data with a single project code
            # Ensuring only 17 values are included, matching the placeholders
            new_row_data = (row[1], row[2], code) + row[4:]  # Skip rowid and original project_code column
            cursor.execute(insert_statement, new_row_data)

# Commit the changes to the database and close the connection
conn.commit()
conn.close()

print("Rows with multiple project codes have been duplicated.")
