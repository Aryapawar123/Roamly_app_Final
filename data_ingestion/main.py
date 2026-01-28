from fetch_places import fetch_places
from enrich_places import enrich_places
from upload_firestore import upload_places

raw_places = fetch_places()
enriched_places = enrich_places(raw_places)
upload_places(enriched_places)
