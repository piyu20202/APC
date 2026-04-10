
# Payment Page Flow Documentation

## Overview
Your APC Project has **two distinct payment flows**:
1. **Normal Flow** - Immediate payment through various payment gateways
2. **Pay Later Flow** - Order completion without immediate payment (for manual/freight quote orders)

---

## NORMAL FLOW (Immediate Payment)

### Step 1: Order Summary Display
- User arrives at the payment page with items in their cart
- Page displays:
  - **Subtotal** (excluding GST)
  - **Shipping Cost** (may show "FREE" if applicable, or "Request Quote" for large items)
  - **GST/Tax** amount
  - **Applied Coupon** (if any)
  - **Grand Total** (final payable amount)

### Step 2: Coupon Section (Optional)
User can manage coupons:

#### **Applying a Coupon:**
1. User clicks "Apply Coupon" button
2. Two options available:
   - **Manual Entry**: User types coupon code in the text field
   - **View Available Offers**: User clicks to browse available coupons in a modal
3. When coupon is applied:
   - API recalculates the entire order breakdown
   - **New discount is applied** to the subtotal
   - **GST is recalculated** based on new subtotal
   - **Grand Total is updated** with new discount
   - **Payment intent is updated** (backend prepares payment session with new amount)
   - Success message shows coupon details (e.g., "10% OFF", "$5 OFF")
   - Button changes from "Apply" to "Remove"

#### **Removing a Coupon:**
1. User clicks "Remove" button (previously "Apply" button)
2. When coupon is removed:
   - API recalculates the entire order breakdown **without the discount**
   - **Original discount is reset to 0**
   - **GST is recalculated** to original amount
   - **Grand Total reverts** to original price
   - **Payment intent is updated** with original amount
   - Success message confirms removal
   - Button changes back to "Apply"
   - Coupon text field is cleared

### Step 3: Select Payment Method
User chooses ONE of these payment methods:
- **Credit Card** (Visa, Mastercard, American Express)
- **PayPal**
- **Google Pay** (Android only)
- **Apple Pay** (iOS only)

### Step 4: Payment Processing

#### **If Credit Card:**
- User enters: Card number, Expiry (MM/YY), CVV, Cardholder name
- Validation checks all fields
- On "PAY NOW" button:
  - Card details are securely sent to CyberSource backend
  - Payment gateway processes the transaction
  - User sees loading spinner while processing

#### **If PayPal:**
- User clicks PayPal button
- PayPal modal/app opens
- User authenticates and confirms payment in PayPal
- PayPal returns payment token to app

#### **If Google Pay/Apple Pay:**
- User clicks button
- Device payment authentication modal appears
- User authenticates (fingerprint, face, PIN, etc.)
- Payment gateway processes the token
- Returns confirmation to app

### Step 5: Payment Success
- Backend confirms payment is successful
- **Old checkout cart is cleared from storage** (the original cart_data that user added items to)
- User is navigated to **"Order Placed Success"** page
- Order confirmation is displayed with:
  - Order number
  - Payment method used
  - Order details

### Step 6: Payment Failure
- If payment gateway declines or error occurs:
  - **Cart data is NOT cleared** (user should be able to retry or modify order)
  - Error message is shown (e.g., "Card declined", "Invalid CVV", "Google Pay failed", etc.)
  - User stays on payment page
  - User can:
    - Try again with a different card/method
    - Go back to modify order (quantity, add/remove items)
    - Then retry payment
  - Cart snapshot remains available for the payment session

---

## PAY LATER FLOW (Manual/Freight Quote Orders)

### Visual Indicator
- A **breadcrumb navigation** appears in the app bar showing:
  ```
  My Orders › Order Details › Pay Later
  ```

### Step 1: Order Summary Display
- Same as Normal Flow
- Displays order breakdown with all items, shipping, GST, totals
- **No payment method selection required**
- Coupon functionality works **exactly the same** as Normal Flow:
  - Can apply coupons (order recalculates, grand total updates)
  - Can remove coupons (order reverts, grand total reverts)

### Step 2: Complete Order Button
- The button changes from **"PAY NOW"** to **"COMPLETE ORDER"**
- No payment gateway integration happens
- When clicked:
  - **No cart to clear** (order already exists on server, not in checkout state)
  - The order cart came as **argument from My Orders page**, not from storage
  - **No payment processing** occurs
  - User is navigated directly to **"Order Placed Success"** page
  - Order status is marked as **"Awaiting Manual Payment"** on server
  - Payment method shows as **"Manual / Freight Quote"**

### Key Difference from Normal Flow
```
NORMAL FLOW:
  User at Cart/Checkout
  ↓
  Add to Cart (stored in storage)
  ↓
  Payment Page (uses cart from storage)
  ↓
  Payment Success
  ↓
  CLEAR old checkout cart from storage (clearCartData)
  ↓
  Success Page

PAY LATER FLOW:
  User at My Orders Page (existing unpaid order)
  ↓
  Click "Pay Now" 
  ↓
  Payment Page (order data passed as argument - NO storage cart)
  ↓
  "Complete Order" Button Clicked
  ↓
  NO clearing needed (cart never stored - came from argument)
  ↓
  Success Page (Order marked as awaiting manual payment)
```

---

## Coupon Behavior (Same in Both Flows)

### What Happens When Coupon is Applied:
1. **Discount Calculation**: Backend applies coupon rules (percentage or fixed amount)
2. **Subtotal Update**: Original subtotal - discount = new subtotal
3. **GST Recalculation**: GST is recalculated on the **new subtotal**
4. **Grand Total Update**: New subtotal + new GST + shipping = new grand total
5. **Payment Amount Update**: If paying, payment gateway uses new amount
6. **UI Update**: 
   - Shows coupon code applied
   - Shows discount amount (e.g., "10% OFF" or "$5 OFF")
   - Updates all displayed amounts
   - Changes button to "Remove"

### What Happens When Coupon is Removed:
1. **Discount Reset**: Coupon is removed from order
2. **Subtotal Revert**: Subtotal goes back to original
3. **GST Recalculation**: GST recalculated on original subtotal
4. **Grand Total Revert**: Grand total returns to original price
5. **Payment Amount Update**: If paying, payment gateway uses original amount
6. **UI Update**:
   - Clears coupon code display
   - Shows discount as $0
   - Updates all amounts back to original
   - Changes button back to "Apply"
   - Clears coupon text field

---

## Cart Clearing Strategy (Normal Flow Only)

### When is Cart Cleared?
**✓ CLEARED ON SUCCESS:**
- When payment is successfully processed by CyberSource, PayPal, Google Pay, or Apple Pay
- Before navigating to "Order Placed" success page
- Ensures no duplicate orders if user performs accidental actions

**✗ NOT CLEARED ON FAILURE:**
- When payment is declined or fails for any reason
- User stays on payment page with cart intact
- User can retry payment or modify order items and retry
- Provides better user experience by preserving their work

**✗ NOT CLEARED FOR PAY LATER:**
- Pay Later flow never stores cart locally (comes from My Orders argument)
- No cart_data to clear
- Explicit `clearCartData()` is harmless but unnecessary

### Why This Approach?

```
PAYMENT SUCCESS:
  ✓ Clear cart → Prevents duplicate orders
  ✓ Only happens after confirmed success
  ✓ Protects against accidental resubmission

PAYMENT FAILURE:
  ✓ Keep cart → User can retry immediately
  ✓ Better UX → No loss of order data
  ✓ User can modify and try different payment method
  ✓ Cart snapshot preserved for payment session
```

---

## Storage & Data Model Differences

### Normal Flow - Cart Storage:
```
1. User adds items to cart
   └─ Stored in SharedPreferences as 'cart_data'
   
2. User clicks "Checkout"
   └─ Order created on server
   └─ Order data stored in SharedPreferences as 'order_data'
   └─ Cart snapshot saved as 'payment_cart_snapshot'
   
3. Payment Page Loads
   └─ Reads from: payment_cart_snapshot (priority)
   └─ Fallback: order_data['cart']
   └─ Fallback: cart_data
   
4. Payment Success/Failure
   └─ clearCartData() called
   └─ Removes: 'cart_data' (original checkout cart)
   └─ Keeps: 'order_data' and 'payment_cart_snapshot' until app restart/logout
```

### Pay Later Flow - No Local Cart Storage:
```
1. User in My Orders page (order already on server)
   └─ NO local cart_data stored (order created before this flow)
   └─ Order data includes cart items inside it
   
2. User clicks "Pay Now"
   └─ Payment Page receives order data as ARGUMENT (not from storage)
   └─ order_cart and order_data passed directly from My Orders
   └─ NO new cart data stored locally
   
3. Payment Page Loads
   └─ Reads from: widget.arguments['order_cart'] (priority)
   └─ Fallback: widget.arguments['order_data']['cart']
   └─ Fallback: storage (for emergency cases)
   
4. "Complete Order" Clicked
   └─ clearCartData() called (for safety - but likely nothing to clear)
   └─ NO cart in storage anyway (came from argument)
   └─ Order remains on server marked as "awaiting payment"
```

### Why This Matters:
- **Normal Flow**: Cart lives in storage → must be cleared after payment
- **Pay Later Flow**: Cart comes from order on server → just displayed locally, not stored
- **Coupon Changes**: In BOTH flows, breakdown recalculates server-side, but locally different sources

---

## Summary Chart

| Aspect | Normal Flow | Pay Later Flow |
|--------|------------|----------------|
| **Use Case** | Immediate payment orders | Freight quotes, large orders, manual billing |
| **Payment Methods** | Credit Card, PayPal, Google Pay, Apple Pay | None (manual payment) |
| **Coupon Support** | ✅ Yes (apply/remove) | ✅ Yes (apply/remove) |
| **Final Button** | "PAY NOW" | "COMPLETE ORDER" |
| **Payment Processing** | Via CyberSource/PayPal/GPay/APay | No processing |
| **Cart Source** | From local storage (cart_data) | From argument passed from My Orders |
| **Cart on Success** | Cleared (order confirmed) | N/A (no local cart) |
| **Cart on Failure** | Kept (user can retry) | N/A (no local cart) |
| **Success Page** | Shows payment method | Shows "Manual / Freight Quote" |
| **Breadcrumb** | Regular navigation | "My Orders › Order Details › Pay Later" |

---

## Technical Notes

### Cart Preservation
- If user **presses back button** (without completing payment):
  - Cart snapshot is **preserved** in storage
  - User can return to Order Price Details page
  - Can try different coupon or payment method
  - Snapshot is only cleared after **successful** payment completion

### Amount Consistency Checks
- Before payment, system logs and verifies:
  - API calculated amount
  - UI displayed amount
  - Ensures they match to prevent discrepancies

### Payment Security
- Card details are **never stored** by app
- Sent directly to CyberSource backend
- Backend tokenizes payment for security
