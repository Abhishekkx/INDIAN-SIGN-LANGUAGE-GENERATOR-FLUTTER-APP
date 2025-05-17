import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

import cv2
import mediapipe as mp
import numpy as np
from math import sqrt

class HandGestureRecognizer:
    def __init__(self):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        self.mp_draw = mp.solutions.drawing_utils

    def calculate_distance(self, p1, p2):
        return sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)

    def get_finger_states(self, hand_landmarks):
        """
        Get detailed finger states including curl and angles
        Returns array of dictionaries containing finger states
        """
        fingers = []

        # Get hand orientation (left/right)
        is_right_hand = hand_landmarks.landmark[5].x < hand_landmarks.landmark[17].x

        # Reference points
        wrist = hand_landmarks.landmark[0]
        thumb_tip = hand_landmarks.landmark[4]
        thumb_ip = hand_landmarks.landmark[3]
        thumb_mcp = hand_landmarks.landmark[2]

        # Detailed thumb state
        thumb = {
            'extended': (thumb_tip.x < thumb_ip.x) if is_right_hand else (thumb_tip.x > thumb_ip.x),
            'curl': self.calculate_distance(thumb_tip, thumb_mcp),
            'angle': self.get_angle(thumb_mcp, thumb_ip, thumb_tip)
        }
        fingers.append(thumb)

        # For each finger
        for i in range(4):
            tip_id = 8 + (i * 4)
            pip_id = 6 + (i * 4)
            mcp_id = 5 + (i * 4)

            tip = hand_landmarks.landmark[tip_id]
            pip = hand_landmarks.landmark[pip_id]
            mcp = hand_landmarks.landmark[mcp_id]

            finger = {
                'extended': tip.y < pip.y,
                'curl': self.calculate_distance(tip, mcp),
                'angle': self.get_angle(mcp, pip, tip),
                'side_angle': abs(tip.x - pip.x)
            }
            fingers.append(finger)

        return fingers

    def get_angle(self, p1, p2, p3):
        """Calculate angle between three points"""
        v1 = np.array([p1.x - p2.x, p1.y - p2.y])
        v2 = np.array([p3.x - p2.x, p3.y - p2.y])

        angle = np.arccos(np.clip(np.dot(v1, v2) /
                         (np.linalg.norm(v1) * np.linalg.norm(v2)), -1.0, 1.0))
        return np.degrees(angle)

    # Letter gesture detection methods
    def is_a_gesture(self, fingers):
        """ASL Letter A: Fist with thumb pointing up"""
        return (fingers[0]['extended'] and
                not any(f['extended'] for f in fingers[1:]) and
                all(f['curl'] < 0.15 for f in fingers[1:]))

    def is_b_gesture(self, fingers):
        """ASL Letter B: All fingers extended upward, thumb tucked"""
        return (not fingers[0]['extended'] and
                all(f['extended'] for f in fingers[1:]) and
                all(f['side_angle'] < 0.1 for f in fingers[1:]))

    def is_c_gesture(self, fingers):
        """ASL Letter C: Curved hand shape like holding a 'C'"""
        return (all(0.2 < f['curl'] < 0.4 for f in fingers) and
                all(f['angle'] > 130 for f in fingers[1:]))

    def recognize_gesture(self, hand_landmarks_list):
        """
        Recognize gestures based on the reference images
        """
        if len(hand_landmarks_list) == 2:
            return self.recognize_two_hand_gesture(hand_landmarks_list)

        hand_landmarks = hand_landmarks_list[0]
        fingers = self.get_finger_states(hand_landmarks)

        # Get basic hand orientation
        palm_center = hand_landmarks.landmark[9]
        wrist = hand_landmarks.landmark[0]
        is_palm_up = palm_center.y < wrist.y

        # Letter gestures (A-Z)
        if self.is_a_gesture(fingers):
            return "GOOD", 0.85
        elif self.is_b_gesture(fingers):
            return "NICE", 0.88
        elif self.is_c_gesture(fingers):
            return "C", 0.86

        # Common gestures
        if self.is_hello_gesture(fingers):
            return "HELLO", 0.89
        elif self.is_thank_you_gesture(fingers):
            return "THANK YOU", 0.88
        elif self.is_good_gesture(fingers, is_palm_up):
            return "GOOD", 0.90
        elif self.is_wrong_gesture(fingers, is_palm_up):
            return "WRONG", 0.85
        elif self.is_nice_gesture(fingers):
            return "BAD", 0.84
        elif self.is_accident_gesture(fingers):
            return "GOODBYE", 0.83
        elif self.is_help_gesture(fingers):
            return "HELP", 0.94
        elif self.is_busy_gesture(fingers):
            return "BUSY", 0.93
        elif self.is_confident_gesture(fingers):
            return "CONFIDENT", 0.81

        return "Unknown", 0.0

    # Common gesture detection methods
    def is_hello_gesture(self, fingers):
        return all(f['extended'] for f in fingers)

    def is_thank_you_gesture(self, fingers):
        return (fingers[0]['extended'] and fingers[4]['extended'] and
                not any(f['extended'] for f in fingers[1:4]))

    def is_good_gesture(self, fingers, is_palm_up):
        return (fingers[0]['extended'] and
                not any(f['extended'] for f in fingers[1:]) and
                is_palm_up)

    def is_wrong_gesture(self, fingers, is_palm_up):
        return (fingers[0]['extended'] and
                not any(f['extended'] for f in fingers[1:]) and
                not is_palm_up)

    def is_nice_gesture(self, fingers):
        return (fingers[0]['extended'] and fingers[1]['extended'] and
                not any(f['extended'] for f in fingers[2:]))

    def is_accident_gesture(self, fingers):
        return (not any(f['extended'] for f in fingers) and
                fingers[0]['curl'] < 0.1)

    def is_help_gesture(self, fingers):
        return (fingers[0]['extended'] and
                not any(f['extended'] for f in fingers[1:]))

    def is_busy_gesture(self, fingers):
        return all(not f['extended'] and f['curl'] < 0.15 for f in fingers)

    def is_confident_gesture(self, fingers):
        return all(not f['extended'] for f in fingers)

    def recognize_two_hand_gesture(self, hand_landmarks_list):
        """
        Recognize gestures that require both hands
        """
        hand1_fingers = self.get_finger_states(hand_landmarks_list[0])
        hand2_fingers = self.get_finger_states(hand_landmarks_list[1])

        # Calculate distance between hands
        hand1_center = hand_landmarks_list[0].landmark[9]
        hand2_center = hand_landmarks_list[1].landmark[9]
        hand_distance = self.calculate_distance(hand1_center, hand2_center)

        # Namaste detection
        if (hand_distance < 0.1 and
            all(f['extended'] for f in hand1_fingers[1:]) and
            all(f['extended'] for f in hand2_fingers[1:])):
            return "NAMASTE", 0.95

        # Together detection
        if hand_distance < 0.15:
            return "TOGETHER", 0.94

        return "Unknown", 0.0

    def process_frame(self, frame):
        if frame is None:
            return None
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.hands.process(rgb_frame)
        if results.multi_hand_landmarks:
            gesture, confidence = self.recognize_gesture(results.multi_hand_landmarks)

            # Draw landmarks and gesture
            for hand_landmarks in results.multi_hand_landmarks:
                self.mp_draw.draw_landmarks(
                    frame,
                    hand_landmarks,
                    self.mp_hands.HAND_CONNECTIONS,
                    self.mp_draw.DrawingSpec(color=(0, 255, 0), thickness=2, circle_radius=2),
                    self.mp_draw.DrawingSpec(color=(0, 0, 255), thickness=2)
                )
            if gesture != "Unknown":
                cv2.putText(
                    frame,
                    f"{gesture} ({confidence:.2f})",
                    (10, 50),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1,
                    (0, 255, 0),
                    2
                )
        return frame