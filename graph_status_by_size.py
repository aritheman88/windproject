import sqlite3, time
import pandas as pd
import plotly.express as px
from datetime import datetime, date

db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
today = date.today()
print("Date: ", today)
now = datetime.now()
current_time = now.strftime("%H:%M:%S")
print("Current Time =", current_time[:-3])

# Connect to the SQLite database
conn = sqlite3.connect(db_path)

# Execute a query to fetch installed_capacity and project_status
query = "SELECT installed_capacity, project_status FROM projects"
df = pd.read_sql_query(query, conn)

# Calculate counts for each combination of project_status and installed_capacity
df_count = df.groupby(['project_status', 'installed_capacity']).size().reset_index(name='counts')

# Merge this count back into the original DataFrame
df_merged = pd.merge(df, df_count, on=['project_status', 'installed_capacity'])

# Now plot, using the counts for size
fig = px.scatter(df_merged, x='project_status', y='installed_capacity', color='project_status',
                 size='counts',  # Use counts for marker size
                 title='Project Approval Status by Installed Capacity',
                 labels={'installed_capacity': 'Installed Capacity', 'project_status': 'Project Status', 'counts': 'Number of Projects'},
                 category_orders={'project_status': ["rejected or cancelled", "in planning", "approved"]})

current_datetime = datetime.now().strftime("%Y-%m-%d_%H-%M")
file_path = f'C:\\Users\\ariel\\MyPythonScripts\\wind\\graphs\\status_by_size_{current_datetime}.html'
fig.write_html(file_path)
# Show the plot
fig.show()
# Close the database connection
conn.close()
print(f"Graph saved as HTML at: {file_path}")
