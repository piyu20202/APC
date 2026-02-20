# Codemagic se iOS Build – TestFlight Upload Guide

Is document mein bataya gaya hai ki **Codemagic** use karte hue iOS app ko **TestFlight** par upload karne ke liye kya karna hai aur **client se kya cheezein chahiye**.

---

## 1. Client se Kya Chahiye (Checklist)

### 1.1 Apple Developer Account
- Client ke paas **Apple Developer Program** membership honi chahiye (yearly subscription).
- Ya client aapko apne Apple Developer account ka **Team Agent / Admin** access de.

---

### 1.2 App Store Connect API Key (Recommended)

Codemagic ko TestFlight par build upload karne ke liye **App Store Connect API Key** best option hai. Client ye teen cheezein provide kare:

| # | Item | Kya Hai | Client Kya Bhejega |
|---|------|---------|---------------------|
| 1 | **Issuer ID** | App Store Connect mein API keys ka issuer ID | Copy-paste (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`) |
| 2 | **Key ID** | Naya key banate waqt milne wala Key ID | Copy-paste (e.g. `XXXXXXXXXX`) |
| 3 | **Private Key (.p8 file)** | Key create karte waqt download hoti hai – **sirf ek baar** milti hai | `.p8` file (secure share karein, dobara download nahi hoti) |

**API Key kaise banaye (Client ke liye):**
1. [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Keys** tab
2. **"+"** (Generate API Key) par click karein
3. Name dein (e.g. "Codemagic CI")
4. **Access** mein **App Manager** role select karein
5. **Generate** par click karein
6. **Key ID** note kar lein
7. **Download .p8 file** kar lein (ye sirf ek baar dikhai degi – safe rakhein)
8. **Issuer ID** page ke upar **Keys** section mein dikhta hai

---

### 1.3 Code Signing – Option B (Agar API Key Na Ho)

Agar client API Key nahi dena chahta, to ye provide karein:

| # | Item | Details |
|---|------|---------|
| 1 | **Distribution Certificate (.p12)** | Mac se Keychain Access se export kiya hua certificate |
| 2 | **Certificate Password** | .p12 export karte waqt set kiya password |
| 3 | **Provisioning Profile** | App Store distribution type ka profile (`.mobileprovision`) – app ke Bundle ID ke saath |

---

### 1.4 App Details (Confirm with Client)

| Item | Description |
|------|-------------|
| **Bundle ID** | App ka bundle identifier (e.g. `com.company.apcproject`) – Xcode/App Store Connect mein same hona chahiye |
| **App Name** | App Store par dikhne wala name |
| **App in App Store Connect** | Client ne App Store Connect par app create karni hai (agar abhi nahi hai) |

---

## 2. Kya Karna Hai (Steps)

### Step 1: Codemagic Account
- [Codemagic](https://codemagic.io) par account banao / login karo
- GitHub/GitLab/Bitbucket repo ko Codemagic se connect karo (ye project ka repo)

### Step 2: iOS App Add karo
- Codemagic dashboard → **Add application**
- Repository select karo
- **iOS** platform enable karo
- Flutter project detect ho jayega

### Step 3: Apple Credentials Set karo
- Application settings → **Apple credentials** (ya **Code signing**)
- **Option A – App Store Connect API Key:**
  - **Issuer ID** – client se liya hua
  - **Key ID** – client se liya hua
  - **App Store Connect API Key** – .p8 file upload karo (ya content paste)
- **Option B – Manual:**
  - **Distribution certificate** – .p12 upload + password
  - **Provisioning profile** – .mobileprovision upload

Credentials ko ek **credentials group** (e.g. `app_store_credentials`) mein save karo – workflow mein isi group ka reference dena hai.

### Step 4: Workflow / codemagic.yaml
- Agar `codemagic.yaml` use kar rahe ho to:
  - iOS workflow mein `groups: [app_store_credentials]` (ya jo group name diya hai) set karo
  - **Publish to App Store Connect** step add karo – isse build automatically TestFlight par upload hogi
- Codemagic UI se bhi “Publish” step add kar sakte ho: **Post-build** → **Publish to App Store Connect**

### Step 5: Build Run karo
- Workflow start karo (manual ya trigger on commit)
- Build complete hone ke baid Codemagic build ko App Store Connect par upload karega
- **TestFlight** tab mein build dikh jayegi (processing ke baad)

### Step 6: TestFlight par Test
- Client / aap App Store Connect → **TestFlight** → build select karke internal/external testers add kar sakte ho
- Testers ko TestFlight app se invite jayega

---

## 3. Client ko Bhejne ke liye Short List

Client se ye list share kar sakte ho:

```
iOS app ko Codemagic se TestFlight par upload karne ke liye chahiye:

1. App Store Connect API Key (recommended):
   • Issuer ID
   • Key ID  
   • Private Key (.p8 file)

2. Confirm karein:
   • Apple Developer Program active hai
   • App Store Connect par app create ho chuki hai (ya create karni hai)
   • Bundle ID jo app mein use ho raha hai wahi App Store Connect par hai

3. (Optional) Agar API Key nahi dena:
   • Distribution certificate (.p12) + password
   • App Store provisioning profile (.mobileprovision)
```

---

## 4. Reference Links

- [Codemagic – iOS code signing](https://docs.codemagic.io/code-signing/ios-code-signing/)
- [Codemagic – Publish to App Store Connect](https://docs.codemagic.io/publishing/publishing-to-app-store/)
- [Apple – App Store Connect API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)

---

*Document version: 1.0 – Codemagic + iOS TestFlight*
