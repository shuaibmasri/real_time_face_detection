📱 Real-Time Face Detection in Flutter

This Flutter project demonstrates real-time face detection using the device camera, powered by Google ML Kit. It detects faces, draws bounding boxes, highlights facial landmarks, and estimates the user's mood based on smile probability.

🚀 Features
📷 Real-time camera stream using camera package
🤖 Face detection using google_mlkit_face_detection
🟩 Draw bounding boxes around detected faces
🔵 Detect and display facial landmarks:
Eyes
Nose
Mouth points
😊 Simple mood classification:
Laughing 😂
Smiling 😊
Serious 😐
Neutral
🔄 Front camera mirroring support
🧠 How It Works

The app processes each camera frame and:

Detects faces using ML Kit
Scales face coordinates to match screen size
Draws:
Face bounding boxes
Landmark points
Calculates smile probability to estimate mood
Displays face ID and mood label on screen
📦 Dependencies

Add the following dependencies in your pubspec.yaml:

dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.0
  google_mlkit_face_detection: ^0.7.0
🛠️ Installation
Clone the repository:
git clone https://github.com/shuaibmasri/real_time_face_detection.git
cd flutter-face-detection
Install dependencies:
flutter pub get
Run the app:
flutter run
📸 Permissions
Android

Add camera permission in AndroidManifest.xml:

<uses-permission android:name="android.permission.CAMERA"/>
iOS

Add this to Info.plist:

<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face detection</string>
🎨 Core Component
FaceDetectionPainter

This is a custom painter responsible for rendering:

Face bounding boxes
Facial landmarks
Mood labels
Key Logic:
Scaling: Adjusts coordinates from camera image to screen
Mirroring: Handles front camera flipping

Mood Detection:

if (smileProb > 0.8) → Laughing 😂
else if (smileProb > 0.5) → Smiling 😊
else if (smileProb > 0.1) → Serious 😐
else → Neutral
📊 Example Output
Face 1
😄 Smiling
Face 2
😐 Serious

Each detected face is labeled and visually tracked in real-time.

⚠️ Limitations
Mood detection is basic (based only on smile probability)
Performance depends on device hardware
Works best in good lighting conditions
🔮 Future Improvements
Add emotion detection using deep learning
Face recognition (identify individuals)
Performance optimization (FPS improvements)
UI enhancements
📄 License

This project is open-source and available under the MIT License.