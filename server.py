from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import cv2
from hand_gesture_recognizer import HandGestureRecognizer  # Corrected import
import uvicorn

app = FastAPI()

# Add CORS middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the recognizer
recognizer = HandGestureRecognizer()

@app.post("/process-frame/")
async def process_frame(file: UploadFile = File(...)):
    try:
        # Read the image file
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None:
            return {"gesture": "Unknown", "confidence": 0.0}

        # Process the frame using your existing code
        results = recognizer.hands.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

        if not results.multi_hand_landmarks:
            return {"gesture": "Unknown", "confidence": 0.0}

        # Recognize gestures
        hand_landmarks_list = results.multi_hand_landmarks
        gesture, confidence = recognizer.recognize_gesture(hand_landmarks_list)

        return {"gesture": gesture, "confidence": confidence}
    except Exception as e:
        print(f"Error processing frame: {e}")
        return {"gesture": "Error", "confidence": 0.0}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)