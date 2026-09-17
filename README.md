# NotiBac 🚀

**The smartest way for Baccalaureate students to memorize history dates effortlessly.**

NotiBac is a unique Flutter application designed to help students memorize historical events (and custom questions) through **system-level overlay popups**. Instead of forcing students to open the app to study, NotiBac brings the study material directly to them by periodically displaying interactive flashcards on top of whatever app they are currently using.

## ✨ Core Features

*   **System-Wide Smart Overlays:** Interactive flashcards pop up globally over other apps using native Android window overlays.
*   **Interactive Flip Cards:** Tap the popup to physically flip the card and reveal the historical event or answer.
*   **Customizable Content:** Comes pre-loaded with 3 default historical units for the Algerian Baccalaureate. Users can also create unlimited custom lists for vocabulary, custom Q&A, or specific subjects.
*   **Total Customization:**
    *   **Positioning:** Choose exactly where the popup appears on your screen (Left, Center, or Right) so it never blocks your workflow.
    *   **Frequency:** Control exactly how often popups appear (from every 5 minutes to every 2 hours).
*   **Do Not Disturb (DND) Mode:** Set your sleeping hours (e.g., 23:00 to 07:00). The background service will automatically pause all popups while you sleep.
*   **Interactive Onboarding:** A beautiful 7-step tutorial for first-time users that lets them physically test the popups, flip cards, and positions before enabling the service.

## 🛠️ Deep Dive: Tech Stack & Architecture

This project is not a standard Flutter UI app. Because iOS and Web do not allow apps to draw completely outside of their own sandbox window, this app relies heavily on **Native Android APIs**. 

*   **Frontend UI:** Flutter & Dart (Material 3 Design). Handles all settings, lists, and the onboarding experience.
*   **Native Android Background Services (Kotlin):** 
    *   **`WindowManager` (TYPE_APPLICATION_OVERLAY):** This is the core magic. We request the "Display over other apps" permission. Kotlin code uses `WindowManager` to inflate a native Android `View` (the pill-shaped card) directly onto the screen, completely independent of the Flutter Engine.
    *   **`PeriodicQuizService` (Foreground Service):** A persistent Android Service that keeps the app alive in the background. It displays a silent notification to the user so the Android OS doesn't kill the process to save battery.
    *   **`QuizSchedulerService` (AlarmManager / Handler):** Handles the strict timing and frequency of the popups.
*   **Bridging Data (Flutter ↔ Native):** 
    *   We use the `shared_preferences` package.
    *   *Technical Note:* Instead of using slow `MethodChannels` to ask Flutter for the settings every 5 minutes, our Kotlin background service reads the underlying `FlutterSharedPreferences` XML file directly on the native side. This allows the background service to instantly read user settings (Position, DND state, Frequency, Enabled state, and JSON lists) with zero overhead, even if the Flutter engine is completely destroyed!

## ⚙️ Developer Notes & Build Configuration

### Custom Build Directory (Important!)
To prevent giant build artifacts from bloating our Git repository history, the Android build output directory has been deliberately moved **outside** of the project folder.

When you run `flutter build apk --release`, you will see a warning that the tool couldn't find the APK. **The build was successful**, it was just placed in the custom temp folder.

*   **Where to find the generated APK:**
    ```
    C:\temp\notibac_build\app\outputs\flutter-apk\app-release.apk
    ```

### How to Revert to the Default Build Folder
If you clone this project on a new machine (like a Mac or Linux) or simply want the `build/` folder back inside the project directory, follow these steps:

1. Open `android/build.gradle.kts`.
2. Locate line 10 (or search for `notibac_build`):
   ```kotlin
   set(java.io.File("C:/temp/notibac_build"))
   ```
3. Change it back to the default Gradle behavior by replacing it with:
   ```kotlin
   set(java.io.File("$buildDir"))
   ```
   *(Or simply delete the line if Gradle defaults take over).*

## 📲 Download the App
Don't want to compile the code yourself? You can just download the ready-to-use Android app!
Head over to the **[Releases Tab](https://github.com/Mohamed-Boukra/NotiBac/releases)** on GitHub and download the latest `.apk` file directly to your phone.

## ⬇️ How to Clone, Build & Test

Because the core feature of this app relies on Android's `SYSTEM_ALERT_WINDOW` permission, **you cannot test the main functionality using Flutter Web (Chrome) or iOS.**

### Step 1: Clone and Setup
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Mohamed-Boukra/NotiBac.git
    cd NotiBac
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

### Step 2: Testing the App
To test the actual popups, you must run the app on a **Physical Android Device** or an **Android Studio Emulator**.

1. Start your Android Emulator, or plug in your Android phone (with USB Debugging enabled).
2. Run the app natively:
    ```bash
    flutter run -d android
    ```
3. **Important:** When the app launches, you must grant the **"Display over other apps"** permission when prompted, otherwise the Native Kotlin `WindowManager` will crash when trying to draw the popup flashcards.

## 🤝 Contributing
Contributions are welcome! If you'd like to improve the UI, add more default lists, or optimize the Kotlin background services, feel free to open a Pull Request.

## 📄 License
This project is licensed under the MIT License - see the LICENSE.md file for details.

## 📧 Contact & Credits
**Developed by Mohamed Boukra**
GitHub: [@Mohamed-Boukra](https://github.com/Mohamed-Boukra)