import express from "express";
import { createClient } from "@supabase/supabase-js";

const app = express();
app.use(express.json());

if (
  !process.env.SUPABASE_URL ||
  !process.env.SUPABASE_SERVICE_ROLE_KEY ||
  !process.env.AI_API_URL
) {
  console.error("❌ Missing environment variables");
  process.exit(1);
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);


app.get("/", (req, res) => {
  res.send("Backend is running 🚀");
});

async function processPendingRows() {
  try {
    console.log("🔍 Checking for pending rows...");

    const { data: rows, error } = await supabase
      .from("patient_data")
      .select("*")
      .is("ai_result", null);

    if (error) {
      console.error("❌ Fetch Error:", error);
      return;
    }

    if (!rows || rows.length === 0) {
      console.log("✅ No pending rows");
      return;
    }

    for (const row of rows) {
      try {
        console.log("⚡ Processing ID:", row.id);

        const modelPayload = {
          "Age": row["Age"],
          "Gender": row["Gender"],
          "Glucose": row["Glucose"],
          "Blood Pressure": row["Blood Pressure"],
          "BMI": row["BMI"],
          "Oxygen Saturation": row["Oxygen Saturation"],
          "LengthOfStay": row["LengthOfStay"],
          "Cholesterol": row["Cholesterol"],
          "Triglycerides": row["Triglycerides"],
          "HbA1c": row["HbA1c"],
          "Smoking": row["Smoking"],
          "Alcohol": row["Alcohol"],
          "Physical Activity": row["Physical Activity"] ?? 0,
          "Diet Score": row["Diet Score"],
          "Family History": row["Family History"],
          "Stress Level": row["Stress Level"],
          "Sleep Hours": row["Sleep Hours"]
        };

        const aiResponse = await fetch(process.env.AI_API_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(modelPayload)
        });

        const result = await aiResponse.json();

        if (!aiResponse.ok) {
          console.error("❌ AI Error:", result);
          continue;
        }

        
        const { error: updateError } = await supabase
          .from("patient_data")
          .update({ ai_result: result })
          .eq("id", row.id);

        if (updateError) {
          console.error("❌ Update Error:", updateError);
        } else {
          console.log("✅ Saved AI result for ID:", row.id);
        }

      } catch (err) {
        console.error("🔥 Row Processing Error:", err);
      }
    }

  } catch (err) {
    console.error("🔥 General Processing Error:", err);
  }
}

processPendingRows();

setInterval(processPendingRows, 10000);


const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
