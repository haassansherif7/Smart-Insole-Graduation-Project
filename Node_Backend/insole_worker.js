import { createClient } from "@supabase/supabase-js";
import fetch from "node-fetch";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const MODEL_URL = process.env.MODEL_URL;
const POLL_INTERVAL_MS = 10000;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !MODEL_URL) {
  console.error("Missing env variables");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Function: sends row data to your ML model
async function sendToModel(row) {
  const body = {
    Temp1: row.Temp1,
    Temp2: row.Temp2,
    BigF_T: row.BigF_T,
    Side_T: row.Side_T,
    Center_T: row.Center_T,
    Pres1: row.Pres1,
    Pres2: row.Pres2,
    BigF_P: row.BigF_P,
    Side_P: row.Side_P,
    Center_P: row.Center_P
  };

  console.log("Sending to model:", body);

  const res = await fetch(MODEL_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });

  const out = await res.json();
  return out;
}

// Save prediction into ai_result
async function savePrediction(id, prediction) {
  await supabase
    .from("readings")
    .update({ ai_result: prediction })
    .eq("id", id);
}

async function processPending() {
  console.log("Checking for new rows...");

  const { data: rows } = await supabase
    .from("readings")
    .select("*")
    .is("ai_result", null)
    .limit(20);

  if (!rows || rows.length === 0) return;

  for (const row of rows) {
    try {
      const prediction = await sendToModel(row);

      await savePrediction(row.id, {
        prediction,
        computed_at: new Date().toISOString()
      });

      console.log(`Updated row ${row.id}!`);
    } catch (err) {
      console.error("Error:", err);
    }
  }
}

setInterval(processPending, POLL_INTERVAL_MS);
console.log("Worker started...");
