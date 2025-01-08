from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import re
import emoji
import contractions
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


class TextRequest(BaseModel):
    text: str

# Initialize the VADER sentiment analyzer
analyzer = SentimentIntensityAnalyzer()

# Load your model and tokenizer
def load_model_and_tokenizer():
    model_path = 'fyp_mental_health/emotion/roberta_base_emotion_model'
    tokenizer = AutoTokenizer.from_pretrained(model_path)
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)
    model.eval()
    return tokenizer, model, device

tokenizer, model, device = load_model_and_tokenizer()


def preprocess_text(x):
    # Add spaces between words and punctuation
    x = re.sub(r'([a-zA-Z])([,;.!?])', r'\1 \2', x)
    x = re.sub(r'([,;.!?])([a-zA-Z])', r'\1 \2', x)

    # Demojize
    x = emoji.demojize(x)

    # Expand contractions
    x = contractions.fix(x)

    # Convert to lowercase
    x = x.lower()

    # Correct some acronyms, typos, and abbreviations
    x = re.sub(r"\blmao\b", "laughing my ass off", x)  
    x = re.sub(r"\bamirite\b", "am i right", x)
    x = re.sub(r"\btho\b", "though", x)
    x = re.sub(r"\bikr\b", "i know right", x)
    x = re.sub(r"\b(ya|u)\b", "you", x)
    x = re.sub(r"\beu\b", "europe", x)
    x = re.sub(r"\b(da|dat)\b", "the", x)
    x = re.sub(r"\bcuz\b", "because", x)
    x = re.sub(r"\bfkn\b", "fucking", x)
    x = re.sub(r"\btbh\b", "to be honest", x)
    x = re.sub(r"\btbf\b", "to be fair", x)
    x = re.sub(r"\bfaux pas\b", "mistake", x)
    x = re.sub(r"\b(btw|bs)\b", "by the way", x)
    x = re.sub(r"\bkinda\b", "kind of", x)
    x = re.sub(r"\bbruh\b", "bro", x)
    x = re.sub(r"\b(w/e)\b", "whatever", x)
    x = re.sub(r"\b(w/)\b", "with", x)
    x = re.sub(r"\b(w/o)\b", "without", x)
    x = re.sub(r"\b(doj)\b", "department of justice", x)

    # Replace repeated letters
    x = re.sub(r"\bj+e{2,}z+e*\b", "jeez", x)
    x = re.sub(r"\bco+l+\b", "cool", x)
    x = re.sub(r"\b(g+o+a+l+)\b", "goal", x)
    x = re.sub(r"\bs+h+i+t+\b", "shit", x)
    x = re.sub(r"\bo+m+g+\b", "omg", x)
    x = re.sub(r"\bw+t+f+\b", "wtf", x)
    x = re.sub(r"\bw+h+a+t+\b", "what", x)
    x = re.sub(r"\by+e+y+|y+a+y+|y+e+a+h+\b", "yeah", x)
    x = re.sub(r"\bw+o+w+\b", "wow", x)
    x = re.sub(r"\bw+h+y+\b", "why", x)
    x = re.sub(r"\bs+o+\b", "so", x)
    x = re.sub(r"\bf\b", "fuck", x)
    x = re.sub(r"\bw+h+o+p+s+\b", "whoops", x)
    x = re.sub(r"\bofc\b", "of course", x)
    x = re.sub(r"\bthe us\b", "usa", x)
    x = re.sub(r"\bgf\b", "girlfriend", x)
    x = re.sub(r"\bhr\b", "human resources", x)
    x = re.sub(r"\bmh\b", "mental health", x)
    x = re.sub(r"\bidk\b", "i do not know", x)
    x = re.sub(r"\bgotcha\b", "i got you", x)
    x = re.sub(r"\by+e+p+\b", "yes", x)
    x = re.sub(r"\ba*ha+h[ha]*|a*ha +h[ha]*\b", "haha", x)
    x = re.sub(r"\bo?l+o+l+[ol]*\b", "lol", x)
    x = re.sub(r"\bo*ho+h[ho]*|o*ho +h[ho]*\b", "ohoh", x)
    x = re.sub(r"\bo+h+\b", "oh", x)
    x = re.sub(r"\ba+h+\b", "ah", x)
    x = re.sub(r"\bu+h+\b", "uh", x)

    # Emoji replacements
    x = re.sub(r"<3", " love ", x)
    x = re.sub(r"xd", " smiling_face_with_open_mouth_and_tightly_closed_eyes ", x)
    x = re.sub(r":\)", " smiling_face ", x)
    x = re.sub(r"^_^", " smiling_face ", x)
    x = re.sub(r"\*_\*", " star_struck ", x)
    x = re.sub(r":\(", " frowning_face ", x)
    x = re.sub(r":\/",  " confused_face", x)
    x = re.sub(r";\)",  " wink", x)
    x = re.sub(r">__<",  " unamused ", x)
    x = re.sub(r"\b([xo]+x*)\b", " xoxo ", x)
    x = re.sub(r"\bn+a+h+\b", "no", x)

    # Handling specific cases of spaced-out text
    x = re.sub(r"h a m b e r d e r s", "hamburgers", x)
    x = re.sub(r"b e n", "ben", x)
    x = re.sub(r"s a t i r e", "satire", x)
    x = re.sub(r"y i k e s", "yikes", x)
    x = re.sub(r"s p o i l e r", "spoiler", x)
    x = re.sub(r"thankyou", "thank you", x)
    x = re.sub(r"a^r^o^o^o^o^o^o^o^n^d", "around", x)

    # Clean up special characters and extra spaces
    x = re.sub(r"\b([.]{3,})", " dots ", x)
    x = re.sub(r"[^A-Za-z!?_]+", " ", x)
    x = re.sub(r"\b(s)\b *", "", x)
    x = re.sub(r" +", " ", x)
    x = x.strip()

    return x

# Preprocess text
def preprocess_text_sentiment_analysis(text):
    text = re.sub(r'http\S+', '', text)  # Remove URLs
    text = re.sub(r'\[.*?\]', '', text)  # Remove square bracketed text
    text = re.sub(r'[^A-Za-z0-9\s.,!?\'"]+', '', text)  # Remove special characters
    return text
    # Preprocess the journal entry before analyzing
    cleaned_text = preprocess_text_sentiment_analysis(journal_entry)
    
    sentences = sent_tokenize(cleaned_text)
    total_compound_score = 0
    
    for sentence in sentences:
        sentence_scores = analyzer.polarity_scores(sentence)
        total_compound_score += sentence_scores['compound']

    # Calculate the average compound score
    average_compound_score = round(total_compound_score / len(sentences), 4) if sentences else 0    
    return average_compound_score  # Return the average compound score

def analyze_sentiment_journal(journal_entry):
    # Preprocess the journal entry before analyzing
    cleaned_text = preprocess_text_sentiment_analysis(journal_entry)

    cleaned_text = analyzer.polarity_scores(cleaned_text)
    return cleaned_text['compound']


@app.get("/")
def read_root():
    return {"message": "Welcome to the Emotion Prediction API"}

@app.post("/predict")
async def predict(request: TextRequest):
    text = request.text

    if not text:
        raise HTTPException(status_code=400, detail="No text provided")
    
    # Get the sentiment score
    compound_score = analyze_sentiment_journal(text)

    # Preprocess the text
    preprocessed_text = preprocess_text(text)

    predictions = predict_emotions(preprocessed_text, tokenizer, model, device)
    emotions = [
        'admiration', 'amusement', 'anger', 'annoyance', 'approval', 'caring',
        'confusion', 'curiosity', 'desire', 'disappointment', 'disapproval',
        'disgust', 'embarrassment', 'excitement', 'fear', 'gratitude', 'grief',
        'joy', 'love', 'nervousness', 'optimism', 'pride', 'realization',
        'relief', 'remorse', 'sadness', 'surprise', 'neutral'
    ]
    emotion_predictions = {emotions[i]: float(predictions[i]) for i in range(len(emotions))}
    filtered_emotion_predictions = {emotion: prob for emotion, prob in emotion_predictions.items() if prob >= 0.10}
    sorted_emotion_predictions = dict(sorted(filtered_emotion_predictions.items(), key=lambda item: item[1], reverse=True))

    return {
        "status": "success",
        "emotions": sorted_emotion_predictions,
        "sentiment": compound_score
    }

def predict_emotions(text, tokenizer, model, device):
    """Predict emotions with normalized probabilities"""
    encoding = tokenizer.encode_plus(
        text,
        add_special_tokens=True,
        max_length=256,
        padding='max_length',
        truncation=True,
        return_attention_mask=True,
        return_tensors='pt'
    )
    
    input_ids = encoding['input_ids'].to(device)
    attention_mask = encoding['attention_mask'].to(device)
    
    with torch.no_grad():
        outputs = model(input_ids=input_ids, attention_mask=attention_mask)
        predictions = torch.sigmoid(outputs.logits)
    
    return predictions[0].cpu().numpy()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)