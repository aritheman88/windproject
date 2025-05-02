import openai
import sqlite3
import re
import config

# Set up the GPT API key
openai.api_key = config.api_key
OPENAI_MODEL = "gpt-4-turbo"
MODEL_TEMPERATURE = 0

# Connect to your SQLite database
db_path = r'C:\Users\ariel\MyPythonScripts\wind\wind_project.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Fetch all statements that don't have a GPT_3_prediction value yet
cursor.execute("SELECT COUNT(*) FROM all_quotes WHERE GPT_3_prediction IS NULL")
row_count = cursor.fetchone()[0]
print(f"The script will run on {row_count} rows.")

cursor.execute("SELECT quote_en, rowid FROM all_quotes WHERE GPT_3_prediction IS NULL")
quotes = cursor.fetchall()


def get_stance_detection(quote):
    """ Function to call GPT API to detect stance on a statement with explanation for each criterion """

    # Limit the quote to the last 2500 characters
    truncated_quote = quote[-2500:]

    prompt = f"""
    You are an energy policy analyst. Please analyze the following statement regarding a wind turbine project and provide a brief response. Your goal is to assess whether the speaker is supportive of the project, opposed, or neutral.
    
    STANCE IDENTIFICATION GUIDELINES:
    
    Summarize the overall stance based on these criteria:
    1. Supporters think the impact the project will have on avian populations (birds and bats) is small or within guidelines. Opposed think impact on avian is high or exceeds guidelines.
    2. Supporters think current avian impact assessments are sufficient, opposed demand more tests and more data. 
    3. Supporters think the impact on nature will be minimal and that the turbines are visually attractive. Opposed emphasize the project will hurt nature and make the skyline uglier. 
    4. Supporters think the projects will not affect nearby residents significantly. Opposed think the project will have serious negative effects on residents: adverse health, ugly landscape, noise. 
    5. Supporters emphasize the clean energy produced by the turbines and the need for renewable energy, opposed minimize the energy value of the turbines. 
    6. Supporters think the project should be approved, opposed think it should be rejected.
    7. Supporters emphasize that the public and residents will benefit from the project financially and with clean energy. Opposed emphasize corporate profits from the project.
    8. Supporters emphasize consultation meetings with residents; opposed stress that locals were not adequately consulted. 
    9. Supporters emphasize the efforts done to approve the project and complete all the required tests, bureaucratic hurdles, coordination tasks. Opposed believe the developers are not taking these requirements seriously enough. 
    10. Supporters accuse environmental organizations such as RTG, society for the protection of nature in Israel (SPNI) of being irrational, dishonest, in their objections to the project.
    11. Note that a speaker may be describing other actors' opinions or opposition. Try and see whether the speaker is simply expressing their opinion, or actually attacking other speakers' opinions. 
    12. If it can be understood that the speaker is the developer pushing the project, they are supportive.
    
    IMPORTANT CLARIFICATION ON SUPPORT VS. OPPOSE:
    
    When a statement mentions impacts, assessments, or environmental concerns, pay careful attention to the context:
    
    SUPPORT indicators even when environmental impacts are mentioned:
    - Describing actions already taken to address impacts or concerns
    - Explaining how the project complies with environmental guidelines
    - Discussing implementation of studies or assessments (rather than demanding more)
    - Mentioning coordination with authorities on environmental matters
    - Describing technical solutions to minimize impacts
    - Acknowledging impacts while emphasizing they are within acceptable limits
    - Questions about how to implement environmental protections (rather than whether they're adequate)
    
    Examples of SUPPORT statements that mention environmental topics:
    1. "We've conducted the bird studies and found the impact is within guidelines."
    2. "The environmental assessment addressed the concerns about noise levels."
    3. "We're working with environmental authorities to ensure compliance."
    4. "The turbines are designed to minimize visual impact on the landscape."
    
    IMPORTANT NOTE ON NEUTRAL CLASSIFICATION:
    A statement should only be classified as "neutral" if it is purely informational or procedural, without any indication of support or opposition. Be careful not to overuse the neutral category. The following are NOT automatically neutral:
    - Technical discussions about project implementation (usually indicate support)
    - Questions about impacts or concerns (often indicate opposition)
    - Discussions of regulatory processes by those involved (usually indicate support)
    - Requests for more information about environmental impacts (often indicate opposition)
    
    Only classify as neutral when there is truly no indication of leaning either way. When in doubt between neutral and a mild position, prefer the mild position (support or oppose).
    
    DISTINGUISHING BETWEEN STANCES:
    
    SUPPORT indicators (even when subtle):
    - Discussing project logistics or implementation details
    - Mentioning coordination with authorities or compliance efforts
    - Describing technical aspects of construction or operation
    - Referring to approvals obtained or regulatory processes completed
    - Explaining how impacts will be minimized or managed
    - Focusing on adherence to guidelines or regulations
    
    OPPOSE indicators (even when subtle):
    - Demanding additional studies, surveys, or assessments
    - Challenging the adequacy of current impact assessments
    - Expressing doubts about compliance with regulations
    - Emphasizing potential negative consequences without offering solutions
    - Suggesting the project should be delayed, reconsidered, or rejected
    - Questioning whether impacts can be adequately mitigated
    
    NEUTRAL indicators (must be strictly neutral):
    - Purely procedural questions without implied concerns
    - Factual statements about regulations without judgment
    - Requests for basic factual information unrelated to impacts
    - Descriptions of processes without expressing preferences
    
    Please provide a concise summary (up to 2-3 sentences) that gives the stance and the key reasons.
    
    Your response must end with a clearly labeled stance in this exact format:
    "STANCE: [select one of: 'support', 'neutral', 'oppose']"
    
    Statement:
    "{truncated_quote}"
    """

    try:
        # Use the ChatCompletion API for chat-based models (openai==0.28)
        response = openai.ChatCompletion.create(
            model=OPENAI_MODEL,
            messages=[
                {"role": "system","content": "You are an energy policy analyst."},
                {"role": "user","content": prompt}
            ],
            temperature=MODEL_TEMPERATURE,
            max_tokens=500  # Limit tokens to reduce output length
        )

        # Extract the text output from GPT response
        full_response = response['choices'][0]['message']['content'].strip()

        # Debug: Print the full response
        print(f"Full response: {full_response}")

        # Try to extract the final stance from the response using regex
        explanation = full_response
        stance = None

        # Look for the stance label at the end of the response
        stance_match = re.search(r"STANCE:\s*(support|neutral|oppose)",full_response.lower())
        if stance_match:
            stance = stance_match.group(1)

        # If stance not found, look for other patterns
        if not stance:
            lower_response = full_response.lower()
            if "stance: support" in lower_response:
                stance = "support"
            elif "stance: neutral" in lower_response:
                stance = "neutral"
            elif "stance: oppose" in lower_response:
                stance = "oppose"

        # Convert stance to numeric value
        numeric_stance = None
        if stance:
            if stance == "support":
                numeric_stance = 1
            elif stance == "neutral":
                numeric_stance = 0
            elif stance == "oppose":
                numeric_stance = -0.5

        # Debug: Print the stance, numeric stance, and explanation
        print(f"Stance: {stance}")
        print(f"Numeric Stance: {numeric_stance}")
        print(f"Explanation: {explanation}")

        return stance,numeric_stance,explanation

    except Exception as e:
        print(f"Error with GPT API: {e}")
        return None,None,None


# Update statements with GPT stance detection and analysis
for quote,rowid in quotes:
    stance,numeric_stance,explanation = get_stance_detection(quote)
    if stance:
        cursor.execute("UPDATE all_quotes SET GPT_3_prediction = ?, GPT_3_analysis = ? WHERE rowid = ?",
                       (numeric_stance,explanation,rowid))
        print(f"Updated row {rowid} with stance: {stance} (numeric: {numeric_stance}) and analysis.")
    else:
        print(f"No stance detected for row {rowid}.")
    conn.commit()

conn.close()