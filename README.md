# 🌿 AgriVision - AI Crop Disease Detector

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://agrivision-app.vercel.app/)

**AgriVision** is an AI-powered Flutter application designed to empower farmers, gardeners, and agricultural workers with instant plant health diagnostics and crop disease detection directly from leaf photographs.

🔗 **Live Web App**: [https://agrivision-app.vercel.app/](https://agrivision-app.vercel.app/)

---

## ✨ Features

- 📸 **Instant Image Capture & Upload**: Capture leaf photos using the device camera or select images from the gallery.
- 🔬 **AI-Powered Disease Detection**: Integrates with Plant.id API to analyze leaf health, identify crop species, and diagnose plant diseases with high accuracy confidence scores.
- 💊 **Actionable Care & Treatment Plans**: Provides detailed treatment, prevention steps, and management practices (biological, chemical, and cultural).
- 📜 **Scan History**: Saves past diagnostics locally using `shared_preferences` for tracking crop health over time.
- 🎨 **Modern & Responsive UI**: Clean, accessible Material 3 design with dark mode styling built for smooth field usage.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.0.0`)
- **API**: Plant.id v3 REST API
- **State & Storage**: `shared_preferences` (Local History Storage)
- **UI & Fonts**: `google_fonts`, Material Design 3
- **Media**: `image_picker`
- **Deployment**: [Vercel](https://agrivision-app.vercel.app/)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Dart SDK installed
- Plant.id API Key (Get one at [Plant.id](https://plant.id/))

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/surya-090906/AgriVision-AI_Crop_Disease_Detector.git
   cd AgriVision-AI_Crop_Disease_Detector
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Key**
   Add your Plant.id API key in `lib/config.dart`:
   ```dart
   class AppConfig {
     static const String plantIdApiKey = 'YOUR_PLANT_ID_API_KEY';
   }
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

