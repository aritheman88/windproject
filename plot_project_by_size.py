import sqlite3, os
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime

# Generate the filename with current date and time
current_time = datetime.now()
formatted_time = current_time.strftime("%m%d%H%M")
print(str(formatted_time))

# Database connection
db_path = "C:/Users/ariel/MyPythonScripts/wind/wind_project.db"
conn = sqlite3.connect(db_path)

# Querying the database for projects including installed_capacity
query = """
SELECT initiation_date, final_decision_date, project_status, installed_capacity
FROM projects
WHERE initiation_date IS NOT NULL
"""
df = pd.read_sql_query(query, conn)
conn.close()

# Convert dates to datetime objects for easier manipulation
df['initiation_date'] = pd.to_datetime(df['initiation_date'], errors='coerce', format='%Y-%m-%d')
df['final_decision_date'] = pd.to_datetime(df['final_decision_date'], errors='coerce', format='%Y-%m-%d')

# Ensure all dates are valid
df = df.dropna(subset=['initiation_date'])

# Determine min_year and max_year
min_year = int(df['initiation_date'].dt.year.min() or datetime.now().year)
max_year = int(df['final_decision_date'].dt.year.max() or datetime.now().year)
current_year = datetime.now().year
max_year = max(max_year, current_year)

# Initialize yearly counts for both installed capacity categories
yearly_counts = {
    year: {'planning_low': 0, 'approved_low': 0, 'planning_high': 0, 'approved_high': 0}
    for year in range(min_year, max_year + 1)
}

# Populate yearly_counts with projects, differentiating by installed capacity
for _, row in df.iterrows():
    start_year = int(row['initiation_date'].year)
    end_year = int(row['final_decision_date'].year) if pd.notnull(row['final_decision_date']) else current_year
    capacity_category = 'high' if row['installed_capacity'] >= 20 else 'low'
    for year in range(start_year, end_year + 1):
        yearly_counts[year][f'planning_{capacity_category}'] += 1
    if row['project_status'] == 'approved' and pd.notnull(row['final_decision_date']):
        yearly_counts[end_year][f'approved_{capacity_category}'] += 1

# Adjust planning counts and accumulate approved counts for both categories
corrected_planning_low = []
corrected_planning_high = []
cumulative_approved_low = 0
cumulative_approved_high = 0
for year in range(min_year, max_year + 1):
    planning_low = yearly_counts[year]['planning_low'] - yearly_counts[year]['approved_low']
    planning_high = yearly_counts[year]['planning_high'] - yearly_counts[year]['approved_high']
    corrected_planning_low.append(max(0, planning_low)) # Ensure non-negative numbers
    corrected_planning_high.append(max(0, planning_high)) # Ensure non-negative numbers
    cumulative_approved_low += yearly_counts[year]['approved_low']
    cumulative_approved_high += yearly_counts[year]['approved_high']
    yearly_counts[year]['approved_low'] = cumulative_approved_low
    yearly_counts[year]['approved_high'] = cumulative_approved_high

# Plotting
fig = go.Figure()

years = list(range(min_year, max_year + 1))

# Colors for the lines
colors = {'low': 'blue', 'high': 'red'}

# Plot for planning and approved projects with different line styles and colors
fig.add_trace(go.Scatter(x=years, y=corrected_planning_low, mode='lines', name='Planning (<20 MW)', line=dict(color=colors['low'], dash='dash')))
fig.add_trace(go.Scatter(x=years, y=[yearly_counts[year]['approved_low'] for year in years], mode='lines', name='Approved (<20 MW)', line=dict(color=colors['low'])))
fig.add_trace(go.Scatter(x=years, y=corrected_planning_high, mode='lines', name='Planning (>=20 MW)', line=dict(color=colors['high'], dash='dash')))
fig.add_trace(go.Scatter(x=years, y=[yearly_counts[year]['approved_high'] for year in years], mode='lines', name='Approved (>=20 MW)', line=dict(color=colors['high'])))

# Update layout
fig.update_layout(title='Project status Over Time by Installed Capacity', xaxis_title='Year', yaxis_title='Number of Projects', legend_title='Project Status', xaxis=dict(tickmode='linear', dtick=1))

filename = f"projects_over_time_{formatted_time}.html"
directory = "C:/Users/ariel/MyPythonScripts/wind/graphs"
filepath = os.path.join(directory, filename)

# Save the figure as an HTML file
fig.write_html(filepath)

print(f"Graph saved as {filepath}")
