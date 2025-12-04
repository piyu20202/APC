# CyberSource Payment Gateway API Documentation

## Overview
This document provides complete API specifications for integrating CyberSource payment gateway into the APC Project backend. All endpoints require user authentication and handle payment processing through CyberSource.

---

## Base Configuration

**Base URL:** `https://www.gurgaonit.com/apc_production_dev/api`

**Authentication:** All endpoints require Bearer token authentication
- Header: `Authorization: Bearer {access_token}`
- Token obtained from `/login` endpoint

**Content-Type:** `application/json`

**Response Format:** All responses are JSON objects

---

## API Endpoints

### 1. Create Payment Intent

**Purpose:** Initialize a payment session for an order before processing payment.

**Endpoint:** `POST /user/payment/create-intent`

**Authentication:** Required (Bearer token)

**Request Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "order_number": "ORD-12345",
  "amount": 1525.00,
  "currency": "AUD"
}
```

**Request Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `order_number` | string | Yes | Order number from order creation | "ORD-12345" |
| `amount` | float/decimal | Yes | Payment amount (must match order total) | 1525.00 |
| `currency` | string | Yes | Currency code (ISO 4217) | "AUD" |

**Validation Rules:**
- `order_number`: Must exist in database, must belong to authenticated user
- `amount`: Must be greater than 0, must match order total amount
- `currency`: Must be valid ISO 4217 code (e.g., "AUD", "USD")

**Success Response (200 OK):**
```json
{
  "success": true,
  "payment_intent_id": "pi_abc123xyz789",
  "client_secret": "cs_test_abc123xyz789",
  "status": "requires_payment_method",
  "message": "Payment intent created successfully"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always true for success |
| `payment_intent_id` | string | Unique payment intent identifier |
| `client_secret` | string | Client secret for client-side SDK (optional) |
| `status` | string | Payment intent status: "requires_payment_method", "requires_confirmation", etc. |
| `message` | string | Success message |

**Error Responses:**

**400 Bad Request - Invalid Order:**
```json
{
  "success": false,
  "error": "invalid_order",
  "message": "Order not found or does not belong to user"
}
```

**400 Bad Request - Invalid Amount:**
```json
{
  "success": false,
  "error": "invalid_amount",
  "message": "Amount does not match order total"
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "error": "unauthorized",
  "message": "Invalid or expired authentication token"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "error": "server_error",
  "message": "Failed to create payment intent. Please try again."
}
```

**Backend Implementation Notes:**
1. Verify order exists and belongs to authenticated user
2. Validate amount matches order total
3. Create payment intent in CyberSource
4. Store payment intent ID in database linked to order
5. Return payment intent details to client

---

### 2. Process Payment

**Purpose:** Process the actual payment using card details provided by the user.

**Endpoint:** `POST /user/payment/process`

**Authentication:** Required (Bearer token)

**Request Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "order_number": "ORD-12345",
  "card_number": "4111111111111111",
  "expiry_month": "12",
  "expiry_year": "2025",
  "cvv": "123",
  "cardholder_name": "John Doe",
  "amount": 1525.00,
  "currency": "AUD"
}
```

**Request Parameters:**

| Parameter | Type | Required | Description | Example | Validation |
|-----------|------|----------|-------------|---------|------------|
| `order_number` | string | Yes | Order number | "ORD-12345" | Must exist |
| `card_number` | string | Yes | Card number (13-19 digits) | "4111111111111111" | Luhn algorithm valid |
| `expiry_month` | string | Yes | Expiry month (01-12) | "12" | 2 digits, 01-12 |
| `expiry_year` | string | Yes | Expiry year (YYYY) | "2025" | 4 digits, not expired |
| `cvv` | string | Yes | CVV code | "123" | 3-4 digits |
| `cardholder_name` | string | Yes | Cardholder full name | "John Doe" | Not empty |
| `amount` | float/decimal | Yes | Payment amount | 1525.00 | Must match order |
| `currency` | string | Yes | Currency code | "AUD" | ISO 4217 code |

**Validation Rules:**
- `card_number`: Remove spaces, validate using Luhn algorithm, length 13-19 digits
- `expiry_month`: Must be 01-12, 2 digits
- `expiry_year`: Must be current year or future, 4 digits
- `cvv`: Must be 3-4 digits
- `cardholder_name`: Must not be empty, trim whitespace
- `amount`: Must match order total exactly
- `order_number`: Must exist and belong to user

**Success Response (200 OK):**
```json
{
  "success": true,
  "transaction_id": "txn_abc123xyz789",
  "order_status": "paid",
  "payment_status": "completed",
  "amount": 1525.00,
  "currency": "AUD",
  "paid_at": "2024-01-15T10:30:00Z",
  "message": "Payment processed successfully"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always true for success |
| `transaction_id` | string | CyberSource transaction ID |
| `order_status` | string | Updated order status: "paid" |
| `payment_status` | string | Payment status: "completed", "pending", "failed" |
| `amount` | float | Processed amount |
| `currency` | string | Currency code |
| `paid_at` | string | ISO 8601 timestamp of payment |
| `message` | string | Success message |

**Error Responses:**

**400 Bad Request - Card Declined:**
```json
{
  "success": false,
  "error": "card_declined",
  "message": "Your card was declined. Please try a different card.",
  "decline_reason": "insufficient_funds"
}
```

**400 Bad Request - Invalid Card Number:**
```json
{
  "success": false,
  "error": "invalid_card",
  "message": "Invalid card number. Please check and try again."
}
```

**400 Bad Request - Invalid CVV:**
```json
{
  "success": false,
  "error": "invalid_cvv",
  "message": "Invalid CVV. Please check your card details."
}
```

**400 Bad Request - Expired Card:**
```json
{
  "success": false,
  "error": "expired_card",
  "message": "Your card has expired. Please use a different card."
}
```

**400 Bad Request - Invalid Expiry:**
```json
{
  "success": false,
  "error": "invalid_expiry",
  "message": "Invalid expiry date. Please check and try again."
}
```

**400 Bad Request - Amount Mismatch:**
```json
{
  "success": false,
  "error": "amount_mismatch",
  "message": "Payment amount does not match order total."
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "error": "unauthorized",
  "message": "Invalid or expired authentication token"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "error": "server_error",
  "message": "Payment processing failed. Please try again later."
}
```

**Possible Error Codes:**

| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `card_declined` | Card was declined by bank | 400 |
| `invalid_card` | Invalid card number format | 400 |
| `invalid_cvv` | Invalid CVV code | 400 |
| `expired_card` | Card expiry date has passed | 400 |
| `invalid_expiry` | Invalid expiry date format | 400 |
| `insufficient_funds` | Insufficient funds in account | 400 |
| `amount_mismatch` | Amount doesn't match order | 400 |
| `invalid_order` | Order not found | 400 |
| `unauthorized` | Authentication failed | 401 |
| `server_error` | Internal server error | 500 |

**Backend Implementation Notes:**
1. Validate all card details before sending to CyberSource
2. Never store full card numbers - use tokenization
3. Call CyberSource API to process payment
4. Update order status in database to "paid"
5. Store transaction ID in database
6. Log transaction for audit purposes
7. Send order confirmation email to user
8. Handle CyberSource API errors and map to user-friendly messages

---

### 3. Verify Payment Status

**Purpose:** Check the current payment status of an order.

**Endpoint:** `GET /user/payment/verify-status`

**Authentication:** Required (Bearer token)

**Request Headers:**
```
Authorization: Bearer {access_token}
Accept: application/json
```

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `order_number` | string | Yes | Order number to verify | "ORD-12345" |

**Request Example:**
```
GET /user/payment/verify-status?order_number=ORD-12345
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "order_number": "ORD-12345",
  "payment_status": "completed",
  "transaction_id": "txn_abc123xyz789",
  "amount": 1525.00,
  "currency": "AUD",
  "paid_at": "2024-01-15T10:30:00Z",
  "payment_method": "credit_card"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always true for success |
| `order_number` | string | Order number |
| `payment_status` | string | Status: "completed", "pending", "failed", "refunded" |
| `transaction_id` | string | CyberSource transaction ID (if paid) |
| `amount` | float | Payment amount |
| `currency` | string | Currency code |
| `paid_at` | string | ISO 8601 timestamp (null if not paid) |
| `payment_method` | string | Payment method used |

**Error Responses:**

**400 Bad Request - Missing Parameter:**
```json
{
  "success": false,
  "error": "missing_parameter",
  "message": "order_number parameter is required"
}
```

**404 Not Found - Order Not Found:**
```json
{
  "success": false,
  "error": "order_not_found",
  "message": "Order not found or does not belong to user"
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "error": "unauthorized",
  "message": "Invalid or expired authentication token"
}
```

**Backend Implementation Notes:**
1. Verify order belongs to authenticated user
2. Check payment status from database
3. Optionally verify with CyberSource API for latest status
4. Return current payment status

---

## CyberSource Integration Details

### CyberSource API Configuration

**Environment:** 
- Sandbox: For testing
- Production: For live payments

**Required CyberSource Credentials:**
- Merchant ID
- API Key
- Shared Secret Key
- API Endpoint URL

### CyberSource API Calls

#### 1. Create Payment Intent (CyberSource)
```http
POST https://api.cybersource.com/payments/v1/payment-intents
Authorization: Basic {base64_encoded_credentials}
Content-Type: application/json

{
  "amount": {
    "total": "1525.00",
    "currency": "AUD"
  },
  "paymentMethod": {
    "card": {
      "number": "4111111111111111",
      "expirationMonth": "12",
      "expirationYear": "2025",
      "securityCode": "123"
    }
  }
}
```

#### 2. Process Payment (CyberSource)
```http
POST https://api.cybersource.com/payments/v1/charges
Authorization: Basic {base64_encoded_credentials}
Content-Type: application/json

{
  "amount": {
    "total": "1525.00",
    "currency": "AUD"
  },
  "paymentMethod": {
    "card": {
      "number": "4111111111111111",
      "expirationMonth": "12",
      "expirationYear": "2025",
      "securityCode": "123"
    }
  },
  "referenceInformation": {
    "code": "ORD-12345"
  }
}
```

### Security Best Practices

1. **Never Store Card Data:**
   - Do not store full card numbers in database
   - Use CyberSource tokenization
   - Store only transaction IDs

2. **Input Validation:**
   - Validate card number using Luhn algorithm
   - Validate expiry dates
   - Sanitize all inputs

3. **HTTPS Only:**
   - All API calls must use HTTPS
   - Enforce SSL/TLS encryption

4. **Error Handling:**
   - Do not expose sensitive error details to client
   - Log errors server-side for debugging
   - Return user-friendly error messages

5. **Rate Limiting:**
   - Implement rate limiting to prevent abuse
   - Limit payment attempts per order

6. **Audit Logging:**
   - Log all payment transactions
   - Store transaction history
   - Maintain audit trail

### Database Schema Suggestions

**Payment Transactions Table:**
```sql
CREATE TABLE payment_transactions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) NOT NULL,
    user_id INT NOT NULL,
    payment_intent_id VARCHAR(100),
    transaction_id VARCHAR(100),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'AUD',
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    payment_method VARCHAR(50),
    cyber_source_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    paid_at TIMESTAMP NULL,
    INDEX idx_order_number (order_number),
    INDEX idx_user_id (user_id),
    INDEX idx_transaction_id (transaction_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Testing

**Test Card Numbers (Sandbox):**
- Success: `4111111111111111`
- Decline: `4000000000000002`
- Insufficient Funds: `4000000000009995`
- Expired Card: `4000000000000069`

**Test CVV:** Any 3-4 digit number

**Test Expiry:** Any future date (MM/YYYY)

---

## Error Handling Guidelines

### Standard Error Response Format

All error responses should follow this format:
```json
{
  "success": false,
  "error": "error_code",
  "message": "User-friendly error message"
}
```

### Error Code Standards

- Use lowercase with underscores
- Be descriptive and specific
- Map CyberSource errors to user-friendly codes

### Common Error Scenarios

1. **Network Timeout:**
   - Retry logic (max 3 attempts)
   - Return timeout error to client

2. **CyberSource API Errors:**
   - Map to user-friendly messages
   - Log full error details server-side

3. **Database Errors:**
   - Handle gracefully
   - Return generic error to client

---

## Testing Checklist

- [ ] Create payment intent with valid order
- [ ] Create payment intent with invalid order (should fail)
- [ ] Create payment intent with amount mismatch (should fail)
- [ ] Process payment with valid card (should succeed)
- [ ] Process payment with declined card (should fail gracefully)
- [ ] Process payment with expired card (should fail)
- [ ] Process payment with invalid CVV (should fail)
- [ ] Verify payment status for paid order
- [ ] Verify payment status for unpaid order
- [ ] Test authentication (should fail without token)
- [ ] Test with expired token (should fail)
- [ ] Test rate limiting
- [ ] Test error handling and logging

---

## Implementation Priority

### Phase 1: Basic Implementation
1. Create Payment Intent endpoint
2. Process Payment endpoint
3. Basic error handling

### Phase 2: Enhanced Features
1. Verify Payment Status endpoint
2. Payment status updates
3. Transaction logging

### Phase 3: Advanced Features
1. Payment retry logic
2. Refund functionality
3. Payment webhooks

---

## Support & Contact

For questions or issues regarding this API specification, please contact the development team.

**Document Version:** 1.0  
**Last Updated:** 2024-01-15  
**API Base URL:** `https://www.gurgaonit.com/apc_production_dev/api`

---

## Additional Resources

- [CyberSource API Documentation](https://developer.cybersource.com/)
- [CyberSource Testing Guide](https://developer.cybersource.com/hello-world/sandbox-testing)
- [PCI DSS Compliance Guidelines](https://www.pcisecuritystandards.org/)

