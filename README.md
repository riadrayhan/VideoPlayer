<h2>Video Playback App</h2>


A Flutter-based video playback application that loads video schedules from JSON instructions and plays videos in a continuous loop.

<h3>Features</h3>

<h4>Cross-platform - Runs on Android (and other platforms)</h4>

<h4>Video Playback - Supports MP4 video playback</h4>

<h4>Dynamic Scheduling - Loads video schedules from JSON</h4>

<h4>Persistent Storage - Saves schedule data locally</h4>

<h4>Real-time Controls - Play, pause, skip, and restart controls</h4>

<h4>Auto-refresh - Automatically detects JSON changes</h4>

<h3>Project Structure</h3>

## 📁 Project Structure

<pre>
VideoPlayer/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── video_player_screen.dart  # Main video player UI
│   ├── models/                   # Data models
│   │   └── instruction_model.dart
│   └── services/                 # Business logic services
│       ├── video_schedule_service.dart
│       ├── storage_service.dart
│       ├── json_parser_service.dart
│       └── asset_video_loader.dart
├── assets/
│   ├── instructions.json         # Video schedule configuration
│   └── videos/ads/               # Video files directory
│       ├── sample1.mp4
│       ├── sample2.mp4
│       └── sample3.mp4
├── pubspec.yaml                  # Flutter dependencies and assets
├── README.md                     # Project documentation
└── LICENSE                       # MIT License
</pre>



<h3>1. Installation & Setup</h3>
git clone <your-repository-url>
cd video_playback_app

<h3>2. Install Dependencies</h3>
flutter pub get

<h3>Running the App</h3>
flutter run

<h3>Install APK Directly</h3>

flutter install

adb install build/app/outputs/flutter-apk/app-release.apk

<h1>Output:</h1>

https://github.com/user-attachments/assets/ca292713-e2a1-4599-95db-5dc1dc33fb28


=================xxxxxxxxxxx===================






