import sqlite3, time
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime, date

db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
today = date.today()
print("Date: ", today)
now = datetime.now()
current_time = now.strftime("%H:%M:%S")
print("Current Time =", current_time[:-3])

## Capacity range
min_capacity = 0  # Example minimum capacity
max_capacity = 20  # Example maximum capacity

# Connect to the SQLite database
conn = sqlite3.connect(db_path)

# Fetch the relevant columns
query = f"""
SELECT a.affiliation, a.position
FROM all_quotes a
JOIN projects p ON p.plan_number = a.project_code
WHERE p.installed_capacity >= {min_capacity} AND p.installed_capacity < {max_capacity}
"""
df_quotes = pd.read_sql_query(query, conn)

# Close the connection
conn.close()

# Group by affiliation and position, then count the occurrences
grouped = df_quotes.groupby(['affiliation', 'position']).size().reset_index(name='count')

# Calculate total counts by affiliation for percentage calculation
total_counts = grouped.groupby('affiliation')['count'].transform('sum')

# Calculate percentage
grouped['percentage'] = grouped['count'] / total_counts * 100

# Pivot the data for plotting
pivot_df = grouped.pivot(index='affiliation', columns='position', values='percentage').fillna(0)

# Create a figure
fig = go.Figure()

# Positions in desired order
positions = ['Negative', 'Reservations', 'Neutral', 'Positive']

# Colors for each position
colors = ['red', 'yellow', 'grey', 'green']

for position, color in zip(positions, colors):
    fig.add_trace(go.Bar(
        x=pivot_df.index,
        y=pivot_df[position],
        name=position,
        marker_color=color
    ))
# Update layout for stacked bar chart
fig.update_layout(
    barmode='stack',
    title=f'Level of Support for Projects by Affiliation (Filtered by Installed Capacity, {min_capacity} to {max_capacity} MW)',
    xaxis_title='Affiliation',
    yaxis_title='Percentage of Quotes',
    legend_title='Position',
    legend=dict(
        # Reverse legend order to match the stacked bar order
        traceorder='reversed'
    )
)

current_datetime = datetime.now().strftime("%Y-%m-%d_%H-%M")
file_path = f'C:\\Users\\ariel\\MyPythonScripts\\wind\\graphs\\support_by_affiliation_{current_datetime}.html'
fig.write_html(file_path)
print(f"Graph saved as HTML at: {file_path}")