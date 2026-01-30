import express from "express";
import fetch from "node-fetch";
import admin from "firebase-admin";
import dotenv from "dotenv";

dotenv.config();

admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
  ),
});

const db = admin.firestore();
const app = express();
app.use(express.json());

app.post("/generate-itinerary", async (req, res) => {
  const {
    tripId,
    destination,
    startDate,
    endDate,
    travelers,
    budget,
    travelStyle,
    pace,
    startingCity,
    surpriseMe,
  } = req.body;

  const prompt = `
Create a ${travelStyle} itinerary for ${destination}
from ${startDate} to ${endDate}.
Travelers: ${travelers}
Budget: ${budget}
Pace: ${pace}
Starting City: ${startingCity}
Surprise: ${surpriseMe}

Return ONLY JSON itinerary.
`;

  const geminiRes = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      }),
    }
  );

  const data = await geminiRes.json();
  const text = data.candidates[0].content.parts[0].text;
  const itinerary = JSON.parse(text.replace(/```json|```/g, ""));

  await db.collection("trips").doc(tripId).update({
    itinerary,
    status: "READY",
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.json({ success: true });
});

app.listen(3000, () =>
  console.log("🔥 Backend running on port 3000")
);
