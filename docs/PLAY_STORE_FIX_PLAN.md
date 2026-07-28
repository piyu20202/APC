# APCProject — Play Store Fix Implementation Plan

> **App:** Automotion Plus (APCProject)  
> **Current version:** 2.0.7+41  
> **Flutter:** 3.32.8  
> **Target SDK (current):** API 35  
> **Status:** Production — changes must be staged and tested carefully

---

## Play Console Issues Summary

| # | Issue | Type | Urgency |
|---|-------|------|---------|
| 1 | Target API 36 required | Policy | 🔴 High (deadline: Aug 31, 2026) |
| 2 | Edge-to-edge may not display for all users | UX | 🟡 Medium |
| 3 | Deprecated edge-to-edge APIs | UX | 🟢 Low |
| 4 | R8 optimization not enabled | Performance | 🟢 Low (optional) |

---

## Risk Summary (Production)

| Issue | Ignore risk (now) | Fix risk (now) | Recommended action |
|-------|-------------------|------------------|--------------------|
| API 36 | 🟢 Low | 🟡 Medium | Plan for Q2–Q3 2026 |
| Edge-to-edge UI | 🟡 Medium | 🟢 Low | **Fix first — safe, small change** |
| Deprecated APIs | 🟢 Low | 🟡 Medium | Fix with Flutter upgrade |
| R8 optimization | 🟢 Low | 🟡 Medium | Optional, later |

**Bottom line:** App is safe in production today. No warnings are blocking. The most immediate user-facing risk is UI overlap on Android 15+ devices. The biggest future risk is missing the API 36 deadline.

---

## Implementation Phases

Do **not** combine all phases into one release. High-risk areas in this app:

- CyberSource payment
- Google Pay / Apple Pay
- Facebook / Google login
- WebView checkout
- Cart / orders

---

## Phase 1 — Edge-to-edge UI Fix (Do This First)

**Timeline:** 1–2 days  
**Risk:** Low  
**Fixes:** Edge-to-edge display warning  
**Target release:** 2.0.8+42

### 1.1 Update MainActivity

**File:** `android/app/src/main/kotlin/com/apc/automotionplus/MainActivity.kt`

**Current:**

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    WindowCompat.setDecorFitsSystemWindows(window, false)
}
```

**Change to:**

```kotlin
import androidx.activity.enableEdgeToEdge

override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)
}
```

`enableEdgeToEdge()` is Google's recommended approach. The project already has `androidx.activity:activity-ktx:1.9.1`.

---

### 1.2 Wrap bottom navigation in SafeArea

**File:** `lib/main_navigation.dart`

Prevent the bottom nav from sitting under the Android gesture bar:

```dart
bottomNavigationBar: SafeArea(
  top: false,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      BottomNavigationBar(
        // ... existing config
      ),
    ],
  ),
),
```

---

### 1.3 Wrap splash screen in SafeArea

**File:** `lib/ui/screens/splash_view/splash.dart`

Prevent the logo from sitting under the status bar:

```dart
body: SafeArea(
  child: Container(
    // ... existing content
  ),
),
```

---

### 1.4 Audit screens with fixed bottom buttons

Screens that already use `SafeArea` (no change needed unless issues appear on device):

- `lib/ui/screens/signin_view/signin.dart`
- `lib/ui/screens/cart_view/cart.dart`
- `lib/ui/screens/home_view/home.dart`
- `lib/ui/screens/payment_page/payment.dart`

Screens to verify on Android 15+ (fixed bottom actions):

| Screen | File | What to check |
|--------|------|---------------|
| Checkout | `lib/ui/screens/checkout_page/checkout.dart` | Place Order button |
| Payment | `lib/ui/screens/payment_page/payment.dart` | Pay button area |
| Sign up | `lib/ui/screens/signup_view/signup_new.dart` | Submit button |
| Profile edit | `lib/ui/screens/profile_page/editprofile.dart` | Save button |

**Rule:** Any fixed bottom button should use `SafeArea` or `MediaQuery.of(context).padding`.

---

### 1.5 Test checklist

```
□ Android 15 emulator or physical device
□ Splash — logo centered, not under status bar
□ Home — search bar not under status bar
□ Bottom nav — above gesture bar
□ Checkout — Place Order button visible and tappable
□ Payment — Pay button visible and tappable
□ Login / Signup — fields move correctly with keyboard
□ Cart — checkout flow intact
□ Optional: landscape orientation check
```

---

### 1.6 Release steps

```bash
# 1. Bump version in pubspec.yaml
# version: 2.0.8+42

# 2. Build release bundle
flutter build appbundle --release

# 3. Upload to Play Console
#    Internal testing → 2–3 days
#    Closed testing → small rollout
#    Production → 100%
```

---

## Phase 2 — Target API 36 (Before Aug 31, 2026)

**Timeline:** 1–2 weeks (planning + testing)  
**Risk:** Medium  
**Mandatory:** Yes — updates will be blocked after Aug 31, 2026  
**Target release:** 2.1.0+43 (or next minor version)

### 2.1 Upgrade Flutter

```bash
flutter upgrade
flutter doctor
flutter pub upgrade
```

Confirm the stable Flutter version supports API 36 before proceeding.

---

### 2.2 Install Android SDK

Android Studio → SDK Manager:

- Android 16 (API 36) SDK Platform
- Latest Android SDK Build-Tools

---

### 2.3 Update build.gradle.kts

**File:** `android/app/build.gradle.kts`

```kotlin
android {
    compileSdk = 36   // was: flutter.compileSdkVersion (35)

    defaultConfig {
        targetSdk = 36  // was: flutter.targetSdkVersion (35)
    }
}
```

---

### 2.4 Verify plugin compatibility

| Plugin | Area | Priority |
|--------|------|----------|
| `cybersource_inapp` | Card payment | 🔴 Highest |
| `pay` | Google Pay | 🔴 Highest |
| `flutter_facebook_auth` | Login | 🟡 High |
| `google_sign_in` | Login | 🟡 High |
| `webview_flutter` | Checkout WebView | 🟡 High |
| `syncfusion_flutter_pdfviewer` | Manuals PDF | 🟢 Medium |

```bash
flutter pub outdated
```

Upgrade outdated plugins one at a time; retest after each critical plugin update.

Also update the local plugin if needed:

- `packages/cybersource_inapp/android/build.gradle` — currently `compileSdk = 35`

---

### 2.5 Full regression test

```
□ Guest browse — home, categories, search
□ Login — email, Google, Facebook
□ Add to cart → checkout → payment
□ Google Pay flow
□ CyberSource card payment
□ Order placed confirmation
□ Profile — edit profile, view orders
□ Manuals — open PDF
□ Logout → login again
□ Reinstall app → session / cart behavior
```

---

### 2.6 Staged rollout

```
Week 1: Internal track — dev team full test
Week 2: Closed track — ~5% users
Week 3: Open track — ~25% users
Week 4: Production — 100%
```

Keep the previous production bundle available for rollback in Play Console.

---

## Phase 3 — R8 Optimization (Optional)

**Timeline:** 3–5 days  
**Risk:** Medium  
**Mandatory:** No — APK size and performance improvement only

### 3.1 Create ProGuard rules

**New file:** `android/app/proguard-rules.pro`

```proguard
# Flutter
-keep class io.flutter.** { *; }

# CyberSource
-keep class com.cybersource.** { *; }

# Google Pay
-keep class com.google.android.gms.** { *; }

# Facebook
-keep class com.facebook.** { *; }
```

Adjust rules if release builds crash or payment/login fails.

---

### 3.2 Enable R8 in release build

**File:** `android/app/build.gradle.kts`

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

---

### 3.3 R8 test checklist

Test on a **release** build only (not debug):

```
□ Full payment flow
□ Facebook login
□ Google login
□ WebView checkout
□ PDF viewer (manuals)
```

If something breaks, add `-keep` rules for the affected library and rebuild.

---

### 3.4 Android Gradle Plugin upgrade (optional, with R8)

**File:** `android/settings.gradle.kts`

Play Console recommends AGP 9.0+. Current version: **8.7.3**.

Only upgrade AGP after Flutter compatibility is confirmed. Do this together with Phase 3 or after Phase 2 is stable in production.

---

## Phase 4 — Deprecated Edge-to-edge APIs

**Timeline:** With Phase 2 (Flutter upgrade)  
**Risk:** Low — mostly automatic

These deprecated APIs are called from the Flutter engine / plugins, not from app Dart code:

- `android.view.Window.setStatusBarColor`
- `android.view.Window.setNavigationBarColor`
- `android.view.Window.setNavigationBarDividerColor`

**Action:** No separate work required. After Flutter upgrade and a new production release, recheck Play Console pre-launch reports.

---

## Complete Timeline

```
┌─────────────────────────────────────────────────────────┐
│  NOW (Week 1–2)                                         │
│  ✅ Phase 1: Edge-to-edge UI fix                        │
│     → Release 2.0.8+42                                  │
├─────────────────────────────────────────────────────────┤
│  Q2 2026 (Apr–Jun)                                      │
│  ⚠️ Phase 2: API 36 upgrade                             │
│     → Release 2.1.0+43                                  │
│     → Staged rollout                                    │
├─────────────────────────────────────────────────────────┤
│  Q3 2026 (Jul–Aug) — DEADLINE                           │
│  🔴 API 36 at 100% production                           │
│     → Complete before Aug 31, 2026                      │
├─────────────────────────────────────────────────────────┤
│  OPTIONAL (when time allows)                            │
│  🟢 Phase 3: R8 optimization + AGP 9.0                │
└─────────────────────────────────────────────────────────┘
```

---

## Priority Order

```
1️⃣ Edge-to-edge UI fix     → Do now (safe, small scope)
2️⃣ API 36 upgrade          → Plan for Q2 2026 (mandatory)
3️⃣ R8 optimization         → Optional, later
4️⃣ Deprecated APIs         → Auto-fix with Flutter upgrade
```

---

## Phase 1 — Files to change (start here)

| # | File | Change |
|---|------|--------|
| 1 | `android/app/src/main/kotlin/com/apc/automotionplus/MainActivity.kt` | Use `enableEdgeToEdge()` |
| 2 | `lib/main_navigation.dart` | Wrap bottom nav in `SafeArea` |
| 3 | `lib/ui/screens/splash_view/splash.dart` | Wrap body in `SafeArea` |
| 4 | `pubspec.yaml` | Bump to `2.0.8+42` before release |

Then test on Android 15+ and publish to internal testing track first.

---

## References

- [Android 15 edge-to-edge behavior](https://developer.android.com/about/versions/15/behavior-changes-15#edge-to-edge)
- [Play target API requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Flutter Android Gradle configuration](https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration)
- [enableEdgeToEdge() — AndroidX Activity](https://developer.android.com/reference/androidx/activity/EdgeToEdge)

---

*Last updated: July 28, 2026*
