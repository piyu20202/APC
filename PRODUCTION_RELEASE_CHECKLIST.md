# APC Flutter App – Production Release Checklist

Complete summary for production build, backend requirements, and payment config verification.

---

## 1. Production Build

### Build Command (Play Store)
```bash
flutter build appbundle --dart-define=APP_ENV=prod
```

### What NOT to include (vs testing)
- Do **not** use `ALLOW_TEST_CREDS=true` (removes auto-fill login/address)
- Do **not** use `TEST_EMAIL` or `TEST_PASSWORD`

### Testing vs Production Mode
| Dart Define | Effect |
|-------------|--------|
| `APP_ENV=prod` | Production mode – Google Pay uses `google_pay_config.json` (PRODUCTION) |
| `APP_ENV=closed` | Testing mode – Google Pay uses `google_pay_config_test.json` (TEST) |

---

## 2. Base URL

**Current:** `https://www.gurgaonit.com/apc_production_dev/api`

- Same URL used for both testing and production (no env-based switch in code).
- Confirm with backend: Is this the correct production API URL, or is there a separate production URL?

---

## 3. Payment Service – Mock Flags (Must Change for Production)

In `lib/data/services/payment_service.dart`, set these to `false` when backend is ready:

| Flag | Current | Production |
|------|---------|------------|
| `useMockApi` | `true` | `false` |
| `useMockGooglePay` | `true` | `false` |
| `useMockApplePay` | `true` | `false` |
| `useMockPayPal` | `true` | `false` |

---

## 4. Backend Developer Requirements

### 4.1 Base URL & Auth
- **Production Base URL:** Confirm exact production API URL.
- **Auth:** All endpoints require `Authorization: Bearer {access_token}`.

### 4.2 API Endpoints Used by App

**Auth:** `/login`, `/user/register`, `/forgot`, `/social/login`, `/social/register`, `/logout`, `/user/change-password`

**Settings:** `/settings`, `/homepage-settings`

**Products:** `/latest-products`, `/sale-products`, `/search-products`, `/product-details`, `/category-details`, `/subcategory-details`, `/childcategory-details`, `/subchildcategory-details`, `/get/category/products`, `/get/all_categories/`

**Cart:** `/user/cart/add-products`, `/user/cart/remove-products`, `/user/cart/update`, `/user/cart/coupon/apply`

**Orders:** `/user/store/order`, `/user/orders`, `/user/orders/details/{orderId}`

**Profile:** `/user/profile`

### 4.3 Payment Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/user/payment/create-intent` | POST | Create payment intent |
| `/user/payment/cybersource/card` | POST | Card payment (raw details) |
| `/user/payment/process-google-pay` | POST | Google Pay (or `/user/payment/cybersource/googlepay/token`) |
| `/user/payment/cybersource/applepay/token` | POST | Apple Pay |
| `/user/payment/paypal/process` | POST | PayPal |
| `/user/payment/verify-status` | GET | Verify payment status |

### 4.4 Payment Request/Response Format

**Common success response:**
```json
{
  "order": {
    "id": 123,
    "user_id": 1,
    "pay_amount": 1525.00,
    "payment_status": "completed",
    "order_number": "ORD-12345"
  },
  "process_payment": 0,
  "show_order_success": 1
}
```

**PayPal request body:** `{ "orderid", "order_number", "amount", "currency", "email", "payment_token" }`

**Google Pay request body:** `{ "order_number", "amount", "payment_token", "payment_method": "google_pay" }`

**Apple Pay request body:** `{ "token": "<base64>", "orderid", "email" }`

**Card payment request body:** `{ "number", "expirationMonth", "expirationYear", "securityCode", "cardholderName", "orderid", "email" }`

---

## 5. Payment Config Files (assets folder)

### 5.1 google_pay_config.json (Production)

| Field | Value | Confirm With |
|-------|-------|--------------|
| `environment` | `"PRODUCTION"` | — |
| `gatewayMerchantId` | `"anzapcau"` | CyberSource/Backend |
| `merchantId` | `"BCR2DN7TRDA73ZCT"` | Google Pay Business Console |
| `merchantName` | `"Automotion Plus"` | — |
| `currencyCode` | `"AUD"` | — |
| `countryCode` | `"AU"` | — |

### 5.2 google_pay_config_test.json (Testing)

| Field | Value | Confirm With |
|-------|-------|--------------|
| `environment` | `"TEST"` | — |
| `gatewayMerchantId` | `"anzgate"` | CyberSource test config |
| `merchantId` | `"BCR2DN7TRDA73ZCT"` | Google Pay |
| `merchantName` | `"Automotion Plus"` | — |

### 5.3 apple_pay_config.json

| Field | Value | Confirm With |
|-------|-------|--------------|
| `merchantIdentifier` | `"merchant.automotionplus.com.au"` | Apple Developer account |
| `displayName` | `"Automotion Plus"` | — |
| `countryCode` | `"AU"` | — |
| `currencyCode` | `"AUD"` | — |
| `supportedNetworks` | `["visa", "masterCard", "amex", "discover"]` | — |

### 5.4 paypal_config.json

**Note:** File is in `.gitignore`. Copy from `paypal_config.example.json` and fill keys.

| Field | Testing | Production |
|-------|---------|------------|
| `mode` | `"sandbox"` | `"production"` |
| `sandbox_client_id` | From PayPal Sandbox app | — |
| `sandbox_secret_key` | From PayPal Sandbox app | — |
| `production_client_id` | — | From PayPal Live app |
| `production_secret_key` | — | From PayPal Live app |
| `currency` | `"AUD"` | `"AUD"` |
| `country` | `"AU"` | `"AU"` |

**Source:** PayPal Developer Dashboard – Sandbox app (testing) and Live app (production).

---

## 6. Pre-Release Checklist

- [ ] Build: `flutter build appbundle --dart-define=APP_ENV=prod`
- [ ] Base URL confirmed with backend
- [ ] `useMockApi`, `useMockGooglePay`, `useMockApplePay`, `useMockPayPal` = `false` (when backend ready)
- [ ] `google_pay_config.json` – `environment: "PRODUCTION"`, `gatewayMerchantId` verified
- [ ] `apple_pay_config.json` – `merchantIdentifier` verified in Apple Developer
- [ ] `paypal_config.json` – `mode: "production"`, production keys filled, file exists in assets
- [ ] All payment config files listed in `pubspec.yaml` assets

---

## 7. Reference Files

- `lib/core/network/api_endpoints.dart` – All API endpoints
- `lib/config/environment.dart` – APP_ENV, Google Pay config selection
- `lib/data/services/payment_service.dart` – Mock flags, payment logic
- `lib/docs/CYBERSOURCE_PAYMENT_API.md` – CyberSource API details


bana di hai project root mein.
Is file mein yeh sections hain:
Production build – command, dart-defines, testing vs production
Base URL – current URL aur backend se confirm karne wale points
Payment service mock flags – production ke liye kya change karna hai
Backend developer requirements – API endpoints, payment specs, request/response format
Payment config files – google_pay_config.json, apple_pay_config_test.json, apple_pay_config.json, paypal_config.json ke fields aur kya verify karna hai
Pre-release checklist – release se pehle sab steps
Reference files – related code files
