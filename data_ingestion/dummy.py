import google.generativeai as genai
genai.configure(api_key="AIzaSyA7fCCYBsaiTK2QbT1J1Gq28ZB6DjvHJ9M")

model = genai.GenerativeModel("models/text-bison-001")
print(model.generate_content("Return JSON: {\"hello\": \"world\"}").text)
