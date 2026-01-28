import requests
import os
import time
from dotenv import load_dotenv

load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")
PHOTO_URL = "https://maps.googleapis.com/maps/api/place/photo"
DETAILS_URL = "https://maps.googleapis.com/maps/api/place/details/json"

def fetch_place_details(place_id):
    params = {
        "place_id": place_id,
        "fields": "opening_hours,formatted_phone_number,website,price_level,photos",
        "key": GOOGLE_API_KEY
    }
    resp = requests.get(DETAILS_URL, params=params).json()
    return resp.get("result", {})

def get_photo_urls(photo_refs, max_photos=3):
    return [f"{PHOTO_URL}?maxwidth=400&photoreference={ref}&key={GOOGLE_API_KEY}" for ref in photo_refs[:max_photos]]

def enrich_place(place):
    category = place.get("category","").lower()
    default_durations = {"beach":2,"fort":1.5,"temple":1,"church":1,"museum":2,"cafe":0.75,"water_sports":2,"adventure_sports":3}
    duration = default_durations.get(category, 1)
    priority = "must-visit" if category in ["beach","fort","temple","museum","water_sports"] else "optional"
    tags = [category]
    popularityScore = place.get("rating",0)*10 + place.get("ratingCount",0)/10
    photo_urls = get_photo_urls(place.get("photo_refs",[]))

    # Details
    details = fetch_place_details(place["googlePlaceId"])
    oh = details.get("opening_hours", {})
    weekday_text = oh.get("weekday_text", [])
    open_now = oh.get("open_now", None)
    phone = details.get("formatted_phone_number")
    website = details.get("website")
    ticket_price = details.get("price_level")

    if not weekday_text:
        weekday_text = [
            "Monday: 06:00 – 18:00","Tuesday: 06:00 – 18:00","Wednesday: 06:00 – 18:00",
            "Thursday: 06:00 – 18:00","Friday: 06:00 – 18:00","Saturday: 06:00 – 18:00","Sunday: 06:00 – 18:00"
        ]
        open_now = True

    facilities = ["toilets","parking"] if category in ["temple","church","museum"] else ["equipment provided","instructor available"]
    safety_notes = ["Avoid late night visit","Carry water"] if category in ["beach","water_sports","adventure_sports"] else []

    return {
        **place,
        "duration": duration,
        "priority": priority,
        "tags": tags,
        "popularityScore": popularityScore,
        "opening_hours": {"weekday_text": weekday_text,"open_now":open_now},
        "open_on_weekends": any("Saturday" in d or "Sunday" in d for d in weekday_text),
        "sensitive_margins": True,
        "phone_number": phone,
        "website": website,
        "ticket_price": ticket_price,
        "photo_urls": photo_urls,
        "facilities": facilities,
        "safety_notes": safety_notes
    }

def enrich_places(raw_places):
    enriched_list = []
    seen_ids = set()
    for i, place in enumerate(raw_places,1):
        if place["googlePlaceId"] not in seen_ids:
            enriched_list.append(enrich_place(place))
            seen_ids.add(place["googlePlaceId"])
        if i%10==0: print(f"Enriched {i}/{len(raw_places)} places")
    return enriched_list

if __name__=="__main__":
    import json
    with open("goa_places_raw.json","r",encoding="utf-8") as f:
        raw = json.load(f)
    enriched = enrich_places(raw)
    with open("goa_places_enriched.json","w",encoding="utf-8") as f:
        json.dump(enriched,f,ensure_ascii=False,indent=2)
