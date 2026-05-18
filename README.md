# FarmTok - AI-Powered Smart Farming Assistant

**FarmTok** is a comprehensive, production-ready mobile application designed specifically for Tanzanian and African farmers. It combines cutting-edge AI, real-time weather intelligence, expert farming tools, and offline-first architecture into one powerful platform.

---

## Latest Updates (May 2026)

### Major Improvements

- **Real-time Analytics** — Removed all dummy data. Analytics now pull live data from local cache and display actual scan statistics, disease trends, and success rates.
- **Fully Working Dark Mode & Language** — Theme switching and language selection now persist and apply app-wide using `SettingsProvider`.
- **Fixed Weather Intelligence Screen** — Resolved blank screen and type-casting errors (`int` vs `double`) in forecast parsing.
- **Expert-Level Crop Disease Scanner** — Complete UI overhaul with professional gradient header, confidence indicators, structured treatment/prevention sections, and share functionality.
- **Enhanced AI Farming Assistant** —
  - 36+ expert quick questions covering crops, soil, pests, climate, livestock, and business.
  - Robust provider fallback chain: **Groq → OpenRouter → Together AI → Hugging Face → Smart Fallback**.
- **Working Edit Profile** — Full-featured modal dialog for updating name, phone, region, district, language, and main crop with Supabase sync.
- **Working Forgot Password** — Integrated Supabase password reset flow with email confirmation.
- **Zero Lint Issues** — All errors, warnings, and info diagnostics resolved (including `use_build_context_synchronously` and deprecated APIs).

---

## Core Features

### 1. AI Crop Disease Scanner

- Professional camera/gallery capture interface
- Real-time image compression and analysis
- Detailed disease identification with confidence score
- Treatment recommendations and prevention measures
- One-tap save to history and share results
- Expert photography tips for best results

### 2. AI Farming Assistant (Chat)

- 36+ curated expert questions with detailed answers
- Multi-provider AI routing (Groq primary, OpenRouter fallback)
- Context-aware smart fallback responses
- Chat history persistence with local cache
- Clean, modern chat UI with timestamps and avatars

### 3. Weather Intelligence

- Real-time current weather + 7-day forecast
- Smart farming recommendations (spraying safety, fungal risk, etc.)
- Location-based (default: Dar es Salaam, configurable)
- Robust error handling and retry logic

### 4. Farm Analytics (Real-time)

- Live statistics from actual crop scans
- Disease trend pie charts and activity line graphs
- Recent scan history with confidence levels
- Success rate and healthy crop percentage calculations

### 5. Profile & Settings

- Full profile editing (name, phone, region, district, language, main crop)
- Dark mode toggle with persistent theme switching
- Language selection (English / Swahili)
- Notification preferences
- Sign out functionality

### 6. Authentication

- Email/password login & registration via Supabase
- Forgot password with secure email reset flow
- Session persistence across app restarts

---

## How the App Works (User Flow)

1. **First Launch**

   - Onboarding screens explaining key features
   - User completes onboarding → `OnboardingService.completeOnboarding()`

2. **Authentication**

   - Login or Sign Up via Supabase Auth
   - Profile created/loaded into `AuthProvider`

3. **Main Dashboard**

   - Bottom navigation: Dashboard | Analytics | Profile
   - Quick access to Scanner, AI Chat, and Weather from home

4. **Crop Scanner Flow**

   - User takes photo or selects from gallery
   - Image compressed → sent to `AIService.analyzeCropDisease()`
   - Results displayed with treatment & prevention
   - Saved to `LocalCacheService` + Supabase

5. **AI Assistant Flow**

   - User selects quick question or types custom query
   - `AIService.chatWithAI()` tries Groq → OpenRouter → others
   - Response shown in chat with history saved locally

6. **Weather Flow**

   - `WeatherBloc` loads data via `WeatherRepositoryImpl`
   - Displays current conditions + forecast
   - Shows smart alerts (safe spraying, fungal risk, etc.)

7. **Analytics**

   - Loads real scans from `LocalCacheService.getCachedScans()`
   - Calculates statistics and renders charts using `fl_chart`

---

## Technical Architecture

### State Management

- **Provider** pattern with multiple providers:
  - `AuthProvider` – user authentication & profile
  - `SettingsProvider` – theme, language, preferences
  - `WeatherBloc` – weather state management (Bloc pattern)

### Services Layer

- `AIService` – crop analysis + multi-provider chat
- `SupabaseService` – auth, database, password reset
- `WeatherService` – OpenWeatherMap integration
- `LocalCacheService` – Hive-based offline storage
- `EnhancedNotificationService`, `PerformanceService`, etc.

### Data Flow

```text
UI (Screens)
   ↓
Providers / Bloc
   ↓
Services (API + Local Cache)
   ↓
Supabase / External APIs
```

### Offline Support

- All core features work without internet
- Scans, chats, and settings cached locally with Hive
- Automatic sync when connection is restored

---

## Tech Stack

| Layer              | Technology                              |
|--------------------|-----------------------------------------|
| Framework          | Flutter 3.11+                           |
| State Management   | Provider + Bloc                         |
| Backend            | Supabase (Auth, Postgres, Storage)      |
| AI                 | Groq (Llama3), OpenRouter, Together     |
| Weather            | OpenWeatherMap API                      |
| Local Storage      | Hive + SharedPreferences                |
| Charts             | fl_chart                                |
| Image Processing   | flutter_image_compress + Google ML Kit  |
| Theming            | Dynamic light/dark via SettingsProvider |

---

## Project Structure

```text
lib/
├── core/               # Locator (GetIt), constants
├── models/             # User, CropScan, WeatherData, ForecastDay
├── providers/          # AuthProvider, SettingsProvider
├── services/           # AIService, SupabaseService, WeatherService, LocalCacheService...
├── screens/            # Login, Home, Scanner, Chat, Weather, Analytics, Profile...
├── widgets/             # Reusable components
└── blocs/              # WeatherBloc (Bloc pattern)
```

---

## Setup Instructions

### 1. Prerequisites

- Flutter 3.11+
- Dart SDK
- Supabase project
- Groq API key
- OpenWeatherMap API key
- OpenRouter API key (recommended for fallback)

### 2. Environment Variables

Create `.env` in project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GROQ_API_KEY=gsk_...
OPENWEATHERMAP_API_KEY=...
OPENROUTER_API_KEY=sk-or-...
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

---

## Database Tables (Supabase)

- `users`
- `crop_scans`
- `ai_chats`
- `weather_logs`

---

## Recent Technical Improvements

- Fixed all type safety issues in weather parsing (`int` vs `double`)
- Implemented proper `context.mounted` checks to eliminate `use_build_context_synchronously` warnings
- Replaced dummy analytics with live data from `LocalCacheService`
- Built robust AI provider fallback chain with clear logging
- Added professional UI components (gradient headers, confidence indicators, action buttons)
- Achieved zero lint issues across the entire codebase

---

## Future Roadmap

- Push notification system for weather alerts and disease outbreaks
- Offline AI model for on-device inference
- Community forum for farmers
- Market price integration
- Satellite imagery and NDVI crop health monitoring

---

**FarmTok** — Empowering African farmers with intelligent, accessible, and reliable agricultural technology.

### AI Disease Scanner

- Camera integration for image capture
- AI-powered disease detection
- Treatment recommendations
- Offline scan caching

### AI Chatbot

- Real-time chat interface
- Groq AI integration
- Conversation history
- Offline message caching

### Weather Intelligence

- OpenWeatherMap API integration
- 7-day weather forecast
- Farming condition recommendations
- Safety alerts for spraying

### Offline-First

- Hive local storage
- Cached data synchronization
- Graceful offline mode

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions:

- Create an issue on GitHub
- Contact the development team

---

**FarmTok** - Empowering African farmers with AI technology 🌱
