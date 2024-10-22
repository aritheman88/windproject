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
min_capacity = 0 # Example minimum capacity
max_capacity = 20 # Example maximum capacity

# Connect to the SQLite database
conn = sqlite3.connect(db_path)

# Fetch the relevant columns
query = f"""
SELECT 
    SUM(Community_acceptance) AS Community_acceptance,
    SUM(Technical) AS Technical,
    SUM(Finance) AS Finance,
    SUM(Landrights) AS Landrights,
    SUM(Environmental) AS Environmental,
    SUM(Planning) AS Planning,
    SUM(veto_actor) AS veto_actor
FROM all_quotes a
JOIN projects p ON p.plan_number = a.project_code
WHERE p.installed_capacity >= {min_capacity} AND p.installed_capacity < {max_capacity}
 
"""

df_factors = pd.read_sql_query(query, conn)

# Close the connection
conn.close()

# Transform the DataFrame for plotting
df_factors_melted = df_factors.melt(var_name='Factor', value_name='Number of Quotes')

# Create a column (bar) chart with Plotly
fig = go.Figure(data=[
    go.Bar(
        x=df_factors_melted['Factor'],
        y=df_factors_melted['Number of Quotes'],
        marker_color='blue'  # You can customize the color
    )
])

# Update chart layout
fig.update_layout(
    title=f'Number of Quotes Referring to Each Factor, projects over {min_capacity} and under {max_capacity}',
    xaxis_title='Factor',
    yaxis_title='Number of quotes',
    xaxis={'categoryorder':'total descending'}  # Optional: sort bars by count
)

current_datetime = datetime.now().strftime("%Y-%m-%d_%H-%M")
file_path = f'C:\\Users\\ariel\\MyPythonScripts\\wind\\graphs\\factors_raised_by_installed_capacity_{current_datetime}.html'
fig.write_html(file_path)
print(f"Graph saved as HTML at: {file_path}")

