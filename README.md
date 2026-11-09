# 🌿 AgriVision - AI Plant Disease Detection & Prevention System

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://agrivision-app.vercel.app/)

**AgriVision** is a stage-aware, dual-branch AI agricultural application developed to protect crops **before** and **after** pathogen damage occurs.

Developed at **Maharaja Surajmal Institute of Technology (MSIT), New Delhi** (Department of Computer Science & Engineering, Session 2023–27).
- **Project Team**: Sameer Diwakar, Rohit Khandelwal, Vinay Pratap Singh Chauhan
- **Project Supervisor**: Mr. Deepak

---

## 🏛️ System Architecture: Dual-Branch Paradigm

When AgriVision launches, the user is presented with a **Branch Selection Hub** to choose between two stage-appropriate branches:

```
                                 AgriVision AI Hub
                                        │
                 ┌──────────────────────┴──────────────────────┐
                 ▼                                             ▼
       [ DETECTION BRANCH ]                           [ PREVENTION BRANCH ]
          (Reactive / Post-Symptom)                      (Proactive / Pre-Symptom)
                 │                                             │
      Leaf Image Captured                            Weather & Microclimate Data
                 │                                             │
       CNN Classifier Backbone                        ANN Regression Risk Model
                 │                                             │
      Disease Class & Severity                       Continuous Day-wise Risk Score
                 │                                             │
     Targeted Treatment Advisory                    Stage A: Preventive Action Plan
```

### 1. 📸 Detection Branch (Reactive • State B)
- **When to use**: When visible necrotic lesions, rust pustules, chlorosis, or mildew patches are already present on leaves.
- **Workflow**: Leaf photo upload/capture → Deep-learning CNN classifier → Instant identification & confidence score.
- **Output**: Disease class, pathogen description, and comprehensive curative remedies (biological, chemical, and cultural management).

### 2. 🌦️ Prevention Branch (Proactive • State A • M3 & M4)
- **When to use**: During crop growing season before visible symptoms appear.
- **Goal**: Warn the farmer **3–6 days before** visible damage occurs.
- **Workflow**:
  - **4 Weather Inputs**:
    1. **Temperature (°C)**: Pathogen sporulation window.
    2. **Relative Humidity (%)**: Canopy moisture viability (>78%).
    3. **Leaf Wetness Duration (Hours/day)**: Continuous leaf moisture (strongest predictor in literature).
    4. **Daily Rainfall (mm)**: Splash dispersal & canopy moisture persistence.
    *(Note: Wind speed & dew point evaluated and excluded with literature justification to prevent overfitting).*
  - **3 Engineered Features**:
    - **$F_5$ Rolling Humidity Average**: $H_{roll,t} = \frac{1}{k} \sum_{i=0}^{k-1} H_{t-i}$ (sustained moisture over multi-day window).
    - **$F_6$ Cumulative Leaf Wetness Duration**: $L_{cum,t} = \sum_{i=0}^{k-1} L_{t-i}$ (accumulated wetness hours).
    - **$F_7$ Infection Window Flag**: $I_w = 1$ if favourable infection conditions exist, 0 otherwise.
  - **ANN Regression Model**:
    - 7 inputs → Dense fully connected hidden layers (ReLU) → Single continuous neuron output ($0.0 - 1.0$).
    - Loss: Mean Squared Error (MSE) • Optimizer: Adam • Metric: $R^2$ ($0.96 - 0.98$ literature benchmark).
- **Stage A Preventive Advisory**:
  - 💧 **Irrigation Control**: Adjust / withhold overhead watering to dry canopy early.
  - 🛡️ **Preventive Fungicide & Bio-Agent Scheduling**: Prophylactic protective spray (Mancozeb, Copper Oxychloride, Trichoderma) *before* the infection window closes.
  - 🌾 **Field Sanitation & Aeration**: Pruning lower foliage, weed border clearing.
  - 🔍 **Field Scouting Protocol**: Monitoring cadence and target leaf zones.
  - 🔄 **Stage-Aware Fusion**: Direct button to switch to Detection Branch if lesions start showing.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.0.0`)
- **UI & Design**: Material Design 3, Google Fonts (Poppins), Custom Earthy Agricultural Palette
- **Detection Engine**: Plant.id v3 REST API
- **Prevention Engine**: Formulated ANN Microclimate Regression Model + Free Open-Meteo REST API (for live weather fetching)
- **State & Storage**: `shared_preferences` (Persistent Detection & Prevention Histories)
- **Media**: `image_picker`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Dart SDK installed

### Installation & Execution

1. **Clone the Repository**
   ```bash
   git clone https://github.com/surya-090906/AgriVision-AI_Crop_Disease_Detector.git
   cd AgriVision-AI_Crop_Disease_Detector
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Key (For Detection Branch)**
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

5. **Run Automated Tests**
   ```bash
   flutter test
   ```

---

## 👥 Authors & Academic Credit

Department of Computer Science & Engineering  
**Maharaja Surajmal Institute of Technology (MSIT)**, Janakpuri, New Delhi  
Session 2023–27

- **Sameer Diwakar** (02396302723)
- **Rohit Khandelwal** (04596302723)
- **Vinay Pratap Singh Chauhan** (04696302723)
- **Supervisor**: Mr. Deepak
