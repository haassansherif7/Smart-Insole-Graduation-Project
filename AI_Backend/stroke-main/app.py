from fastapi import FastAPI
from pydantic import BaseModel
import pandas as pd
import pickle

# =====================
# Load Stroke Model
# =====================

with open("stroke_model.pkl", "rb") as f:
    model = pickle.load(f)

app = FastAPI()

@app.get("/")
def root():
    return {"message": "🧠 Stroke Prediction API Running"}

# =====================
# Input Schema
# =====================

class InputData(BaseModel):
    Sex: float
    BMI: float
    Smoking: float
    AlcoholDrinking: float
    HeartDisease: float
    PhysicalHealth: float
    MentalHealth: float
    DiffWalking: float
    Diabetic: float
    AgeCategory: float
    PhysicalActivity: float
    GenHealth: float
    SleepTime: float
    Asthma: float
    KidneyDisease: float

# =====================
# Predict Endpoint
# =====================

@app.post("/predict")
def predict(data: InputData):
    try:
        df = pd.DataFrame([data.dict()])

        prediction = model.predict(df)
        probability = model.predict_proba(df)

        pred = int(prediction[0])

        return {
            "prediction": pred,
            "disease": "Stroke" if pred == 1 else "No Stroke",
            "probability": float(probability[0][1])
        }

    except Exception as e:
        return {"error": str(e)}
