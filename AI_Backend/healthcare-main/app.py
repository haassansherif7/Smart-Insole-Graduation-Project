from fastapi import FastAPI
from pydantic import BaseModel, Field
import pandas as pd
import pickle

# =====================
# Load Model
# =====================

with open("medical_healthcare_model.pkl", "rb") as f:
    model = pickle.load(f)

app = FastAPI()

@app.get("/")
def root():
    return {"message": "🚀 Healthcare Medical Condition API Running!"}


# =====================
# Input Schema
# =====================

class InputData(BaseModel):
    Age: float
    Gender: str
    Glucose: float
    Blood_Pressure: float = Field(alias="Blood Pressure")
    BMI: float
    Oxygen_Saturation: float = Field(alias="Oxygen Saturation")
    LengthOfStay: float
    Cholesterol: float
    Triglycerides: float
    HbA1c: float
    Smoking: float
    Alcohol: float
    Physical_Activity: float = Field(alias="Physical Activity")
    Diet_Score: float = Field(alias="Diet Score")
    Family_History: float = Field(alias="Family History")
    Stress_Level: float = Field(alias="Stress Level")
    Sleep_Hours: float = Field(alias="Sleep Hours")

    class Config:
        populate_by_name = True


# =====================
# Predict Endpoint
# =====================

@app.post("/predict")
def predict(data: InputData):
    try:
        df = pd.DataFrame([data.model_dump(by_alias=True)])

        prediction = model.predict(df)
        probability = model.predict_proba(df)

        # Class mapping
        class_mapping = {
            0: "Arthritis",
            1: "Asthma",
            2: "Cancer",
            3: "Diabetes",
            4: "Healthy",
            5: "Hypertension",
            6: "Obesity"
        }

        predicted_id = int(prediction[0])
        disease_name = class_mapping.get(predicted_id, "Unknown")

        return {
            "prediction": predicted_id,          # الرقم
            "disease_name": disease_name,        # الاسم
            "probability": float(probability[0].max())  # النسبة
        }

    except Exception as e:
        return {"error": str(e)}
    


