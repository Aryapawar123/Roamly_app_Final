import random
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore

# ------------------ INIT ------------------
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

MAIN_USER_ID = "vW7aGmoziBbXnhud0zpoUtAd1df1"

# ------------------ HELPERS ------------------
def ts():
    return firestore.SERVER_TIMESTAMP

def random_amount(min_=100, max_=1500):
    return random.randint(min_, max_)

def unsplash(city, idx):
    return f"https://source.unsplash.com/800x600/?{city},travel,{idx}"

# ------------------ USERS ------------------
users = []
for i in range(10):
    uid = f"user_{i+1}"
    users.append(uid)

    db.collection("users").document(uid).set({
        "createdAt": ts(),
        "email": f"user{i+1}@mail.com",
        "fullName": f"Traveler {i+1}",
        "phone": f"90000000{i+1}",
        "travelStats": {
            "totalTrips": random.randint(1, 8),
            "completedTrips": random.randint(0, 5),
            "favoriteCity": random.choice(["Jaipur", "Goa", "Udaipur"]),
        }
    })

# main user
db.collection("users").document(MAIN_USER_ID).set({
    "createdAt": ts(),
    "email": "haharshinii@gmail.com",
    "fullName": "Harshini Mishal",
    "phone": "7738672266",
})

# ------------------ TRIPS ------------------
trip_configs = [
    ("ONGOING", -1, 3),
    ("PENDING", 5, 10),
    ("COMPLETED", -20, -10),
    ("COMPLETED", -40, -30),
    ("COMPLETED", -60, -50),
]

for idx, (status, start_offset, end_offset) in enumerate(trip_configs):
    trip_ref = db.collection("users").document(MAIN_USER_ID) \
        .collection("savedTrips").document(f"trip_{idx+1}")

    start = datetime.now() + timedelta(days=start_offset)
    end = datetime.now() + timedelta(days=end_offset)

    trip_ref.set({
        "destination": random.choice(["Rajasthan, India", "Goa, India"]),
        "budget": 20000,
        "status": status,
        "startDate": start.isoformat(),
        "endDate": end.isoformat(),
        "createdAt": ts(),
        "travelStyle": "Cultural",
        "travelers": 2,
        "stats": {
            "totalDays": 4,
            "totalSpent": random_amount(15000, 20000),
            "memoriesCount": 0 if status != "COMPLETED" else 10
        }
    })

    # ------------------ DAYS ------------------
    for day in range(1, 5):
        trip_ref.collection("days").document(f"day_{day}").set({
            "day": day,
            "title": f"Day {day} Exploration",
            "completed": status == "COMPLETED",
            "estimatedDayCost": random_amount(1500, 3000)
        })

        # ------------------ EXPENSES ------------------
        for e in range(2):
            trip_ref.collection("expenses").add({
                "day": day,
                "category": random.choice(["Food", "Travel", "Stay"]),
                "amount": random_amount(),
                "paidBy": "Harshini Mishal",
                "createdAt": ts()
            })

    # ------------------ MEMBERS ------------------
    for u in random.sample(users, 3):
        trip_ref.collection("members").document(u).set({
            "userId": u,
            "role": "EDITOR",
            "joinedAt": ts()
        })

    # ------------------ MEMORIES (ONLY COMPLETED) ------------------
    if status == "COMPLETED":
        for m in range(10):
            trip_ref.collection("memories").add({
                "imageUrl": unsplash("travel", m),
                "caption": f"Memory {m+1}",
                "day": random.randint(1, 4),
                "likedBy": random.sample(users, 2),
                "createdAt": ts()
            })

print("🔥 Firestore dummy data seeded successfully!")
