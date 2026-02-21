# IPA ko TestFlight par Manual Upload Karne ka Guide

Is document mein bataya gaya hai ki **IPA file** ko **TestFlight** par manually kaise upload karein — Transporter, Xcode, aur App Store Connect use karke.

---

## 1. Prerequisites (Pehle Kya Chahiye)

| Item | Details |
|------|---------|
| **IPA file** | Codemagic build se download kiya hua (Artifacts section se) |
| **Mac** | Transporter ya Xcode ke liye Mac zaroori hai |
| **Apple ID** | Woh Apple ID jo App Store Connect par app ka owner/admin hai |
| **App in App Store Connect** | App pehle se create honi chahiye, Bundle ID match hona chahiye |

---

## 2. Method 1: Transporter App (Recommended)

Transporter Apple ka official app hai jo Mac par IPA upload karta hai.

### Step 1: Transporter Install karo

1. **Mac App Store** kholo
2. Search karo: **Transporter**
3. **Get** / **Install** par click karo
4. Install hone ke baad Transporter open karo

### Step 2: Apple ID se Login

1. Transporter open karo
2. **Sign In** par click karo
3. Woh **Apple ID** use karo jo **App Store Connect** par app ka owner/admin hai

### Step 3: IPA Upload karo

1. **Deliver Your App** / **+** button par click karo
2. **Choose** se `Automotion Plus.ipa` (ya jo bhi IPA file hai) select karo
3. **Deliver** par click karo
4. Upload complete hone tak wait karo (file size ke hisaab se 2–10 min)

### Step 4: Processing

- Upload ke baad Apple build process karega (5–15 min)
- Status **App Store Connect** → **TestFlight** mein check ho sakta hai

---

## 3. Method 2: Xcode Organizer

Agar Mac par Xcode already installed hai.

### Step 1: Xcode Organizer kholo

1. **Xcode** open karo
2. Menu: **Window** → **Organizer**
3. **Distribute App** par click karo

### Step 2: IPA Upload karo

1. **App Store Connect** select karo
2. **Upload** select karo
3. **Next** → **Next**
4. **Choose** se IPA file select karo
5. **Upload** par click karo

---

## 4. Method 3: App Store Connect (Browser)

**Note:** App Store Connect (browser) se direct IPA upload **nahi** hota. Ye sirf upload ke baad status aur testers manage karne ke liye hai.

### Upload ke baad kya karna hai

1. [App Store Connect](https://appstoreconnect.apple.com) → Login
2. **My Apps** → apni app (e.g. **Automotion Plus**)
3. **TestFlight** tab par jao
4. **iOS** section mein build status dekho:
   - **Processing** — wait karo
   - **Ready to Submit** — build use karne ke liye ready hai

### Testers Add karo

1. **Internal Testing** ya **External Testing** section
2. **+** se tester group banao (agar nahi hai)
3. **Add Build** se apna build select karo
4. **Add Testers** se email IDs add karo
5. Testers ko TestFlight app se invite jayega

---

## 5. IPA Kahan se Milega (Codemagic)

Agar build Codemagic par successful hua hai:

1. **Codemagic** → apna app → **Builds**
2. Successful build par click karo
3. **Artifacts** section mein scroll karo
4. **Automotion Plus.ipa** download karo

---

## 6. Checklist

- [ ] IPA file download kar li
- [ ] Mac par Transporter install kar li (ya Xcode hai)
- [ ] Apple ID se login kar li
- [ ] IPA select karke Deliver/Upload kar di
- [ ] 5–15 min processing ka wait kiya
- [ ] App Store Connect → TestFlight mein build check kiya
- [ ] Testers add kar diye (optional)

---

## 7. Common Issues aur Solutions

| Problem | Solution |
|---------|----------|
| "Invalid IPA" | IPA sahi se build hua hai confirm karo, corrupt download na ho |
| "Wrong credentials" | Woh Apple ID use karo jo App Store Connect par app ka owner hai |
| "App not found" | App Store Connect par app create karo, Bundle ID match karo |
| "Missing compliance" | Export compliance (encryption) App Store Connect par set karo |
| Transporter Mac par nahi hai | Windows par Transporter nahi hai — Mac use karo ya Codemagic auto-publish fix karo |

---

## 8. Windows par Mac nahi hai?

- **Transporter** sirf Mac par available hai
- **Options:**
  1. Kisi Mac user se IPA upload karwao
  2. Codemagic par App Store Connect API key (.p8) set karke auto-publish enable karo — phir manual upload ki zaroorat nahi

---

## 9. Reference Links

- [Apple – Transporter](https://apps.apple.com/app/transporter/id1450874784)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Codemagic – Publish to App Store Connect](https://docs.codemagic.io/publishing/publishing-to-app-store/)

---

*Document version: 1.0 – IPA Manual Upload to TestFlight*
