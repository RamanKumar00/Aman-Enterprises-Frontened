# Internal Testing & Reviewer Notes
**App Name:** Aman Enterprises
**Version:** 1.0.0 (MVP)
**Date:** 2026-01-29

## 📱 App Summary
Aman Enterprises is a comprehensive grocery delivery platform designed for both individual customers (B2C) and retail partners (B2B). The app facilitates product discovery, secure ordering, and order management, streamlining the supply chain for local businesses.

---

## 🧪 Testing Instructions for Reviewers

### 1. Credentials
To facilitate your review, please use the following test accounts or register a new one using a valid phone number.

*   **Role: Retailer (B2B)** - *To test bulk ordering & MOQ rules*
    *   **Phone:** `9999901748`
    *   **Password:** `password123`
    *   *Note: This account sees "Wholesale" prices and Pack Size restrictions.*

*   **Role: Customer (B2C)** - *To test standard flow*
    *   **Phone:** Register a new number (OTP will be sent to email/console for test env).
    *   **OTP/Password:** If testing OTP flow, use simulated OTP sent to email.

### 2. Key Flows to Test
*   **Onboarding:** Sign up as a new user. Verify address selection.
*   **Browsing:** Check Categories and Search functionality.
*   **B2B Logic:** As a Retailer, try adding partially filled packs to cart (System should enforce Minimum Order Quantity).
*   **Checkout:**
    *   **COD:** Place an order using Cash on Delivery.
    *   **Online Payment:** Select "Online Payment" -> Use Razorpay Test Card (Card: `success@razorpay`, Any future date, Any CVV).

### 3. Known Limitations (MVP Scope)
*   **OTP Delivery:** For this test build, OTPs are sent via Email/Logged to server console instead of SMS to avoid gateway costs during testing.
*   **Live Tracking:** The "Live Map" is a UI simulation for demonstration; real-time driver tracking is a post-MVP feature.
*   **Refunds:** Refund processing is currently a manual administrative workflow.

---

## 🛠️ Maintenance & Optimization
### 1. Fixing Broken Images
If products are missing images, an Admin can trigger the auto-repair tool which fetches fresh images from Pexels:
*   **Endpoint:** `GET /api/v1/product/fix-images` (Requires Admin Auth)
*   *Note: This will scan all products and update those with missing images.*

### 2. Performance
*   **APK Size:** The release build is now optimized with R8 shrinking and ABI splitting.
*   **Images:** All images are cached locally to save data.

---

## ⚠️ Stability Note
This is an Internal Test Release intended for functional validation. While stable, it runs on a staging environment. Please report any critical UI crashes or blocking bugs directly to the development team.

**Thank you for helping us deliver a quality experience!**
