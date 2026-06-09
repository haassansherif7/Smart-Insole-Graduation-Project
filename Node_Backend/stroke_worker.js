// index.js (Node + Express)
import express from "express";
import fetch from "node-fetch";

const app = express();
app.use(express.json());

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const DEVICE_SECRET = process.env.DEVICE_SECRET;

app.get("/", (req, res) => res.send("ingest running"));

app.post("/ingest", async (req, res) => {
  try {
    const token = req.header("x-device-token");
    if (!token || token !== DEVICE_SECRET) return res.status(401).json({ error: "Unauthorized" });

    const body = req.body;
    if (!body.device_id) return res.status(400).json({ error: "device_id required" });

    const resp = await fetch(`${SUPABASE_URL}/rest/v1/readings`, {
      method: "POST",
      headers: {
        "apikey": SUPABASE_KEY,
        "Authorization": `Bearer ${SUPABASE_KEY}`,
        "Content-Type": "application/json",
        "Prefer": "return=representation"
      },
      body: JSON.stringify([body])
    });

    const data = await resp.json();
    if (!resp.ok) return res.status(500).json({ error: "db insert failed", detail: data });

    return res.json({ status: "ok", inserted: data[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "server error", detail: String(err) });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server listening on ${port}`));
