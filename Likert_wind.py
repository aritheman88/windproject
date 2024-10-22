import pandas as pd
import plotly.express as px
from datetime import datetime

# Load data from the Excel file
file_path = r'C:\Users\ariel\MyPythonScripts\wind\support_level.xlsx'
df = pd.read_excel(file_path)

# Calculate the total count for each speaker affiliation
df['Total'] = df['Supportive'] + df['Neutral'] + df['Reservations'] + df['Opposed']

# Calculate the percentage values for each support level
df['Supportive_pct'] = df['Supportive'] / df['Total']
df['Neutral_pct'] = df['Neutral'] / df['Total']
df['Reservations_pct'] = df['Reservations'] / df['Total']
df['Opposed_pct'] = df['Opposed'] / df['Total']

# Filter data for small projects and large projects
small_df = df[df['project size'] == 'small']
large_df = df[df['project size'] == 'large']

# Get the current date in the format yyyy-mm-dd
current_date = datetime.now().strftime('%Y-%m-%d')

# Define the file paths for saving the graphs
small_output_path = fr'C:\Users\ariel\MyPythonScripts\wind\graphs\likert_small_projects_{current_date}.html'
large_output_path = fr'C:\Users\ariel\MyPythonScripts\wind\graphs\likert_large_projects_{current_date}.html'

# Function to create and save Likert scale graph
def create_likert_graph(df, title, output_path):
    # Create a horizontal bar chart
    # Rearrange the order of support levels: Neutral, Supportive, Reservations, Opposed
    # Also, convert Reservations and Opposed to negative values
    df['Reservations_pct_neg'] = -df['Reservations_pct']
    df['Opposed_pct_neg'] = -df['Opposed_pct']

    fig = px.bar(df,
                y='speaker affiliation',
                x=['Neutral_pct', 'Supportive_pct', 'Reservations_pct_neg', 'Opposed_pct_neg'],
                orientation='h',
                title=title,
                labels={'value': 'Percentage', 'variable': 'Support Level'},
                color_discrete_map={
                    'Neutral_pct': 'darkgray',
                    'Supportive_pct': 'darkgreen',
                    'Reservations_pct_neg': 'darkorange',
                    'Opposed_pct_neg': 'darkred'
                },
                barmode='relative')  # 'relative' mode aligns bars

    # Customize chart layout
    fig.update_layout(
        xaxis_range=[-1, 1],  # Adjust range if necessary
        xaxis_tickvals=[-1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1],
        xaxis_ticktext=['100%', '75%', '50%', '25%', '0%', '25%', '50%', '75%', '100%'],
        yaxis_title='Speaker Affiliation',
        xaxis_title='',
        legend_title_text='Support Level',
        bargap=0.1  # Reduce space between bars
    )

    # Update legend names
    fig.for_each_trace(lambda t: t.update(name=t.name.replace('_pct', '').replace('_neg', '')))

    # Save the chart as an HTML file
    fig.write_html(output_path)

# Create and save the Likert scale graph for small projects
create_likert_graph(small_df, 'Share of support / opposition to small projects by speaker affiliation', small_output_path)

# Create and save the Likert scale graph for large projects
create_likert_graph(large_df, 'Share of support / opposition to large projects by speaker affiliation', large_output_path)
