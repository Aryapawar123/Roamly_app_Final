import requests
import time
import os
from dotenv import load_dotenv

load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

GOA_LOCATION = {"lat": 15.2993, "lng": 74.1240}
RADIUS = 10000  # 10 km
TEXT_SEARCH_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
DETAILS_URL = "https://maps.googleapis.com/maps/api/place/details/json"

CATEGORIES = [
    # Nature & Geography
    "beach", "island", "waterfall", "forest", "desert", "cave", "mountain", "national park", "coastal", "astro-tourism", "geotourism",
    # Culture/History/Arts
    "heritage site", "fort", "temple", "church", "museum", "gallery", "tribal village", "literary tourism", "pilgrimage", "art festival",
    # Entertainment/Lifestyle
    "urban city", "nightlife", "theme park", "gastronomy", "wine tour", "shopping", "gambling", "wedding tourism", "fashion tourism",
    # Health/Wellness/Purpose
    "spa", "yoga retreat", "wellness center", "medical tourism", "ecotourism", "volunteering", "accessible tourism", "spiritual retreat",
    # Activity & Thrill-Seeking
    "adventure sports", "water sports", "winter sports", "cycling", "wildlife safari", "nautical/cruise",
    # Niche & Offbeat
    "dark tourism", "atomic tourism", "agritourism", "industrial tourism", "space tourism", "disaster tourism", "lighthouse tourism",
    # Support Services
    "restaurant", "cafe", "hotel", "resort", "ferry ride"
]

AGENCY_KEYWORDS = {
    "water sports": ["water sports", "jet ski", "banana boat", "parasailing"],
    "adventure sports": ["rock climbing", "zipline", "rafting", "mountain sports"]
}

def fetch_place_details(place_id):
    params = {
        "place_id": place_id,
        "fields": "formatted_phone_number,website,opening_hours,price_level,photos",
        "key": GOOGLE_API_KEY
    }
    resp = requests.get(DETAILS_URL, params=params).json()
    return resp.get("result", {})

def fetch_places(query, location=GOA_LOCATION, radius=RADIUS, max_pages=3):
    places = []
    params = {"query": query, "key": GOOGLE_API_KEY, "location": f"{location['lat']},{location['lng']}", "radius": radius}
    seen_ids = set()

    for page in range(max_pages):
        resp = requests.get(TEXT_SEARCH_URL, params=params).json()
        if resp.get("status") not in ["OK", "ZERO_RESULTS"]:
            print("⚠️ Google API Error:", resp.get("status"))
            break
        for p in resp.get("results", []):
            pid = p.get("place_id")
            if pid in seen_ids: continue
            seen_ids.add(pid)

            details = fetch_place_details(pid)
            photos = [ph["photo_reference"] for ph in p.get("photos", [])] if p.get("photos") else []

            place_data = {
                "googlePlaceId": pid,
                "name": p.get("name"),
                "category": map_category(p.get("types", []), query),
                "lat": p["geometry"]["location"]["lat"],
                "lng": p["geometry"]["location"]["lng"],
                "address": p.get("formatted_address", ""),
                "rating": p.get("rating", 0),
                "ratingCount": p.get("user_ratings_total", 0),
                "photo_refs": photos,
                "contact": details.get("formatted_phone_number"),
                "website": details.get("website"),
                "opening_hours": details.get("opening_hours", {}),
                "ticket_price": details.get("price_level")
            }
            places.append(place_data)

        next_token = resp.get("next_page_token")
        if not next_token: break
        params = {"key": GOOGLE_API_KEY, "pagetoken": next_token}
        time.sleep(2)
    return places

def map_category(types_list, query):
    types_lower = [t.lower() for t in types_list]
    q_lower = query.lower()
    for cat in CATEGORIES:
        if cat.replace("-", " ") in q_lower: return cat
    for agency_type, keywords in AGENCY_KEYWORDS.items():
        if any(k in q_lower for k in keywords): return agency_type
    return "other"

def fetch_all_goa():
    all_places = []
    for cat in CATEGORIES:
        print(f"Fetching: {cat} in Goa")
        all_places.extend(fetch_places(f"{cat} in Goa, India"))
        time.sleep(1)
    print(f"✅ Total places fetched for Goa: {len(all_places)}")
    return all_places

if __name__=="__main__":
    import json
    places = fetch_all_goa()
    with open("goa_places_raw.json","w",encoding="utf-8") as f:
        json.dump(places,f,ensure_ascii=False,indent=2)
