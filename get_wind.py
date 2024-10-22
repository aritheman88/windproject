import openai
import sqlite3

# Set up the GPT API key
openai.api_key = 'sk-proj-###'
OPENAI_MODEL = "gpt-4-turbo"
MODEL_TEMPERATURE = 0

# Connect to your SQLite database
db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Fetch only one statement that doesn't have a GPT_stance_detection value yet
cursor.execute("SELECT quote_en, rowid FROM all_quotes WHERE GPT_stance_detection IS NULL")
quotes = cursor.fetchall()

def get_stance_detection(quote):
    """ Function to call GPT API to detect stance on a statement with explanation for each criterion """

    # Limit the quote to the last 1000 characters
    truncated_quote = quote[-2500:]

    prompt = f"""
        You are an energy policy analyst. Please analyze the following statement regarding a wind turbine project.
        Summarize the overall stance based on these criteria:
        1.	Supporters think the impact on avian populations (birds and bats) is small or within guidelines. Opposed think impact on avian is high or exceeds guidelines.
        2. Supporters think current avian impact assessments are sufficient, opposed demand more tests and more data. 
        3. Supporters think the impact on nature will be minimal, and the people will adjust to the change. Opposed emphasize the project will cause much harm to nature. 
        4. Supporters think the projects will not affect nearby residents significantly. Opposed think the project will have serious negative effects on residents: adverse health, ugly landscape, noise. 
        5. Supporters emphasize the clean energy produced by the turbines and the need for renewable energy, opposed minimize the energy value of the turbines. 
        6. Supporters minimize hurdles pertaining to different government ministries or planning bodies. Opposed emphasize planning hurdles such as coordination with the defense Ministry or transportation.  
        7. Supporters emphasize that the public and residents will benefit from the project financially and with clean energy. Opposed emphasize corporate profits from the project.
        8. Supporters emphasize consultation meetings with residents; opposed stress that locals were not adequately consulted. 

        Please provide a concise summary (up to 2-3 sentences) that gives the stance and the key reasons.

        Conclude by choosing one of the following stances: 'strong support', 'weak support', 'neutral', 'weak oppose', or 'strong oppose'.

        Statement:
        "{truncated_quote}"
    """

    try:
        # Use the ChatCompletion API for chat-based models (openai==0.28)
        response = openai.ChatCompletion.create(
            model=OPENAI_MODEL,
            messages=[
                {"role": "system", "content": "You are an energy policy analyst."},
                {"role": "user", "content": prompt}
            ],
            temperature=MODEL_TEMPERATURE,
            max_tokens=500  # Limit tokens to reduce output length
        )

        # Extract the text output from GPT response
        full_response = response['choices'][0]['message']['content'].strip()

        # Debug: Print the full response
        print(f"Full response: {full_response}")

        # Try to extract the final stance from the response
        stance = None
        explanation = full_response

        # Search for a stance in the response, handling possible capitalization or sentence case
        for s in ['strong support', 'weak support', 'neutral', 'weak oppose', 'strong oppose']:
            if s in full_response.lower():
                stance = s.capitalize()
                break

        # Debug: Print the stance and explanation
        print(f"Stance: {stance}")
        print(f"Explanation: {explanation}")

        return stance, explanation

    except Exception as e:
        print(f"Error with GPT API: {e}")
        return None, None

# Update one statement with GPT stance detection and analysis
for quote, rowid in quotes:
    stance, explanation = get_stance_detection(quote)
    if stance:
        cursor.execute("UPDATE all_quotes SET GPT_stance_detection = ?, GPT_stance_analysis = ? WHERE rowid = ?",
                       (stance, explanation, rowid))
        print(f"Updated row {rowid} with stance: {stance} and analysis.")
    else:
        print(f"No stance detected for row {rowid}.")
    conn.commit()

conn.close()
