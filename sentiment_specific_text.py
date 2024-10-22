from transformers import pipeline

def analyze_sentiment_long_text(sentiment_analyzer, text, max_length=512):
    """Splits the text into chunks, analyzes the sentiment of each chunk, and aggregates the results."""
    num_chunks = (len(text) + max_length - 1) // max_length  # Calculate number of chunks needed
    sentiments = []
    for i in range(num_chunks):
        chunk = text[i * max_length: (i + 1) * max_length]
        result = sentiment_analyzer(chunk)[0]
        score = result['score'] if result['label'] == 'POSITIVE' else -result['score']
        sentiments.append(score)

    # Aggregate the sentiment scores
    avg_sentiment = sum(sentiments) / len(sentiments)
    return avg_sentiment

# Initialize the sentiment analysis pipeline
sentiment_analyzer = pipeline('sentiment-analysis')

# Manually input the text you want to analyze
input_text = """
My name is Ahova Black. I came to the Lower Galilee as part of the Galilee zoning in 1977, an operation that was successful for the partition and since then we are constantly trying to thicken, we are trying to thicken our settlements, thank God we were able to thicken the settlement, we added another 103 young families, which made our settlement rise again. We currently have a situation of a terrible fracture. We had promised them a quality of life, we had promised them that even though they have to travel to Tel Aviv and the center for jobs, they will receive a quality of life with us, and they signed for us on their part that agriculture can continue, turbines are not agriculture, turbines are industry, turbines are dangerous experimental farms Unparalleled in the country, at a dangerous height unmatched in the country, we are guinea pigs, we don't want to be guinea pigs. Just one more thing, we are surrounded by settlements from which we have already received letters, see you have been warned, we are as close to the turbines as you are, we will not be silent. I want to say one more thing, we came here as volunteers, at our own expense, this situation is very sensitive, we care a lot about what is happening in our area and we are here
"""

# Analyze the sentiment of the input text
try:
    sentiment_score = analyze_sentiment_long_text(sentiment_analyzer, input_text)
    print(f"Sentiment score: {sentiment_score}")
except Exception as e:
    print(f"Error analyzing sentiment: {e}")
