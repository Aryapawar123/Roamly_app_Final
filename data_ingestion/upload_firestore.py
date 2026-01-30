import firebase_admin
from firebase_admin import credentials, firestore
from enrich_places import enrich_places
from fetch_places import fetch_all_goa
import re

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def sanitize_doc_id(name):
    doc_id = name.strip().replace(" ","_")
    doc_id = re.sub(r"[#/\[\]]","",doc_id)
    return doc_id

def upload_places(places, collection_name="goa"):
    batch = db.batch()
    count = 0
    for place in places:
        doc_id = sanitize_doc_id(place["name"])
        doc_ref = db.collection(collection_name).document(doc_id)
        batch.set(doc_ref, place)
        count += 1
        if count % 450 == 0:
            batch.commit()
            batch = db.batch()
    batch.commit()
    print(f"🔥 Uploaded {count} places to Firestore in {collection_name} collection")

if __name__=="__main__":
    print("Fetching raw places...")
    raw_places = fetch_all_goa()
    print(f"Fetched {len(raw_places)} places")

    print("Enriching places...")
    enriched_places = enrich_places(raw_places)
    print(f"Enriched {len(enriched_places)} places")

    print("Uploading to Firestore...")
    upload_places(enriched_places)
