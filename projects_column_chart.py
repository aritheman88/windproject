import sqlite3
import os
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
print("Database connection established.")

# Querying the database for projects including installed_capacity
query = """
SELECT initiation_date, final_decision_date, installed_capacity, project_status
FROM projects
WHERE initiation_date IS NOT NULL
"""
df = pd.read_sql_query(query, conn)
conn.close()

print("Data loaded from the database.")

# Convert initiation_date to year and count initiated projects per year
df['initiation_year'] = df['initiation_date'].str[:4]

# Extract years and convert them to integers
years = df['initiation_year'].unique().astype(int)
print(df['initiation_year'].value_counts())

# Initialize dictionaries for initiated projects
initiated_small_projects = {year: 0 for year in years}
initiated_large_projects = {year: 0 for year in years}

# Count initiated projects per year based on installed capacity
for _, row in df.iterrows():
    year = int(row['initiation_year'])
    if row['installed_capacity'] < 20:
        initiated_small_projects[year] += 1
    else:
        initiated_large_projects[year] += 1

print("Initiated small projects:")
print(initiated_small_projects)

print("Initiated large projects:")
print(initiated_large_projects)

# Convert final_decision_date to year and count approved/rejected projects per year based on installed capacity
df['decision_year'] = df['final_decision_date'].str[:4]

# Filter out None values before conversion
decision_years = df['decision_year'].dropna().unique().astype(int)

# Initialize dictionaries for approved and rejected projects
approved_small_projects = {year: 0 for year in decision_years}
rejected_small_projects = {year: 0 for year in decision_years}
approved_large_projects = {year: 0 for year in decision_years}
rejected_large_projects = {year: 0 for year in decision_years}

# Count approved and rejected projects per year based on installed capacity
for _, row in df.iterrows():
    if pd.notnull(row['final_decision_date']):
        year = int(row['decision_year'])
        if row['project_status'] == 'approved':
            if row['installed_capacity'] < 20:
                approved_small_projects[year] += 1
            else:
                approved_large_projects[year] += 1
        elif row['project_status'] == 'rejected' or row['project_status'] == 'cancelled':
            if row['installed_capacity'] < 20:
                rejected_small_projects[year] += 1
            else:
                rejected_large_projects[year] += 1

# Plotting
fig = go.Figure()
bar_width = 0.4  # You can adjust this value as needed

# Plot initiated small projects
fig.add_trace(go.Bar(x=years - bar_width, y=[initiated_small_projects.get(year, 0) for year in years], name='Initiated Small Projects (<20 MW)', marker_color='blue', width=bar_width))

# Plot initiated large projects
fig.add_trace(go.Bar(x=years, y=[initiated_large_projects.get(year, 0) for year in years], name='Initiated Large Projects (>=20 MW)', marker_color='green', width=bar_width))

# Plot approved small projects
fig.add_trace(go.Bar(x=years - bar_width, y=[approved_small_projects.get(year, 0) for year in decision_years], name='Approved Small Projects (<20 MW)', marker_color='lightblue', width=bar_width))

# Plot approved large projects
fig.add_trace(go.Bar(x=years, y=[approved_large_projects.get(year, 0) for year in decision_years], name='Approved Large Projects (>=20 MW)', marker_color='lightgreen', width=bar_width))

# Plot rejected small projects (as negative)
fig.add_trace(go.Bar(x=years - bar_width, y=[-rejected_small_projects.get(year, 0) for year in decision_years], name='Rejected Small Projects (<20 MW)', marker_color='salmon', width=bar_width))

# Plot rejected large projects (as negative)
fig.add_trace(go.Bar(x=years, y=[-rejected_large_projects.get(year, 0) for year in decision_years], name='Rejected Large Projects (>=20 MW)', marker_color='lightcoral', width=bar_width))

# Update layout
fig.update_layout(title='Projects Over Time by Installed Capacity and Decision', xaxis_title='Year', yaxis_title='Number of Projects', barmode='relative', legend_title='Project Type')

# Save the figure as an HTML file
filename = f"projects_over_time_{formatted_time}.html"
directory = "C:/Users/ariel/MyPythonScripts/wind/graphs"
filepath = os.path.join(directory, filename)
fig.write_html(filepath)

print(f"Graph saved as {filepath}")
