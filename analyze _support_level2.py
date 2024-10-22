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

# Connect to the SQLite database
conn = sqlite3.connect(db_path)

# Define the order of affiliations with correct capitalization
affiliation_order = ['Developers', 'Environmental organizations', 'Government', 'Locals', 'Planning bodies']

# Capacity ranges
ranges = [(0, 20), (20, 200)]  # Changed to (20, 200)

# Create a figure
fig = go.Figure()

# Positions in desired order
positions = ['Negative', 'Reservations', 'Neutral', 'Positive']

# Colors for each position
colors = ['red', 'yellow', 'grey', 'green']

# Store affiliation labels to avoid repetition in legend
affiliation_labels = {}

# Fetch and process data for each capacity range
for min_capacity, max_capacity in ranges:
    # Fetch the relevant data
    query = f"""
    SELECT a.affiliation, a.position
    FROM all_quotes a
    JOIN projects p ON p.plan_number = a.project_code
    WHERE p.installed_capacity >= {min_capacity} AND p.installed_capacity < {max_capacity}
    """
    df_quotes = pd.read_sql_query(query, conn)

    # Group by affiliation, position, and capacity range, then calculate the percentage
    grouped = df_quotes.groupby(['affiliation', 'position']).size().unstack(fill_value=0)
    grouped = grouped.div(grouped.sum(axis=1), axis=0) * 100

    # Plot each affiliation's support level for this capacity range
    for affiliation in affiliation_order:
        data = grouped.loc[affiliation]
        affiliation_label = f"{affiliation} {max_capacity}+"  # Change range label to 20+
        if affiliation not in affiliation_labels:
            affiliation_labels[affiliation] = affiliation_label
        for i, position in enumerate(positions):
            fig.add_trace(go.Bar(
                x=[affiliation_label],
                y=[data[position]],
                name=position,
                marker_color=colors[i],
                hoverinfo='text',
                text=f"{position}: {data[position]:.2f}%",  # Text to display on hover
                hovertemplate='%{text}<extra></extra>'
            ))

# Update layout for the bar chart
fig.update_layout(
    barmode='stack',
    title='Level of Support for Projects by Affiliation and Capacity Range',
    xaxis_title='Affiliation (Capacity Range)',
    yaxis_title='Percentage of Quotes',
    legend_title='Position',
    legend=dict(
        # Reverse legend order to match the stacked bar order
        traceorder='reversed'
    )
)

# Add affiliations as annotations to the plot
for affiliation, label in affiliation_labels.items():
    fig.add_annotation(
        x=label,
        y=100,  # Arbitrary position for the annotation
        text=affiliation,
        font=dict(size=10),  # Smaller font size for affiliation
        showarrow=False,
        xshift=-10,  # Adjust position slightly to the left
        align='center'  # Align text to the center of the column
    )

# Close the connection
conn.close()

# Save the graph as HTML file
current_datetime = datetime.now().strftime("%Y-%m-%d_%H-%M")
file_path = f'C:\\Users\\ariel\\MyPythonScripts\\wind\\graphs\\support_by_affiliation_{current_datetime}.html'
fig.write_html(file_path)
print(f"Graph saved as HTML at: {file_path}")
