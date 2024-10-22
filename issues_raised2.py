import sqlite3
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

# Fetch the relevant columns for range 0-20
query = f"""
SELECT 
    SUM(Community_acceptance) AS Community_acceptance,
    SUM(Technical) AS Technical,
    SUM(Finance) AS Finance,
    SUM(Environmental) AS Environmental,
    SUM(Planning) AS Planning
FROM all_quotes a
JOIN projects p ON p.plan_number = a.project_code
WHERE p.installed_capacity >= {min_capacity} AND p.installed_capacity < {max_capacity}
"""

df_factors = pd.read_sql_query(query, conn)

# Fetch the relevant columns for over 20
query_over_20 = f"""
SELECT 
    SUM(Community_acceptance) AS Community_acceptance,
    SUM(Technical) AS Technical,
    SUM(Finance) AS Finance,
    SUM(Environmental) AS Environmental,
    SUM(Planning) AS Planning,
    SUM(Size_mention) AS size_mention

FROM all_quotes a
JOIN projects p ON p.plan_number = a.project_code
WHERE p.installed_capacity >= {max_capacity}
"""

df_factors_over_20 = pd.read_sql_query(query_over_20, conn)

# Close the connection
conn.close()

# Combine the two DataFrames
df_combined = pd.concat([df_factors, df_factors_over_20], keys=['0-20', 'Over 20'], names=['Capacity Range'])

# Transform the DataFrame for plotting
df_factors_melted = df_combined.melt(var_name='Factor', value_name='Number of Quotes', ignore_index=False).reset_index()

# Create a column (bar) chart with Plotly
fig = go.Figure()

# Add bars for each capacity range
for capacity_range, df_range in df_factors_melted.groupby('Capacity Range'):
    fig.add_trace(go.Bar(
        x=df_range['Factor'],
        y=df_range['Number of Quotes'],
        name=f'Capacity Range: {capacity_range}',
        marker_color='blue' if capacity_range == '0-20' else 'purple'
    ))

# Update chart layout
fig.update_layout(
    title=f'Number of quotes referring to each factor, small vs. large projects',
    xaxis_title='Factor',
    yaxis_title='Number of quotes',
    xaxis={'categoryorder': 'total descending'},  # Optional: sort bars by count
    barmode='group'  # Display bars side by side
)

current_datetime = datetime.now().strftime("%Y-%m-%d_%H-%M")
file_path = f'C:\\Users\\ariel\\MyPythonScripts\\wind\\graphs\\factors_raised_by_installed_capacity_{current_datetime}.html'
fig.write_html(file_path)
print(f"Graph saved as HTML at: {file_path}")
