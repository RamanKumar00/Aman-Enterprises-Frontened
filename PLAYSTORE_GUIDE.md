# 🚀 Aman Enterprises - Play Store Deployment Guide

## ✅ Completed Setup

The following have been configured for Play Store release:

- [x] App display name: "Aman Enterprises"
- [x] Target SDK: 34 (meets Play Store requirement)
- [x] Privacy Policy page created
- [x] Release signing configuration set up
- [x] ProGuard code obfuscation enabled
- [x] 64-bit architecture support

---

## 📋 Step-by-Step: Generate Release Keystore

### Step 1: Create the Keystore

Open PowerShell/Terminal and run:

```powershell
cd "c:\Users\raman\OneDrive\Desktop\Aman Enterprises\android\app"

keytool -genkey -v -keystore aman-enterprises-release.keystore -alias amanenterprises -keyalg RSA -keysize 2048 -validity 10000
```

You'll be prompted to enter:
- **Keystore password**: Create a strong password (SAVE THIS!)
- **Key password**: Can be same as keystore password
- **First and last name**: Your name or company name
- **Organization**: Aman Enterprises
- **City/State/Country**: Your location

⚠️ **IMPORTANT**: Save your passwords securely! You cannot recover them!

### Step 2: Update key.properties

Edit `android/key.properties` with your actual passwords:

```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=amanenterprises
storeFile=aman-enterprises-release.keystore
```

### Step 3: Build Release APK/Bundle

```powershell
# Navigate to project root
cd "c:\Users\raman\OneDrive\Desktop\Aman Enterprises"

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# OR Build APK
flutter build apk --release
```

The output will be in:
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🏪 Play Store Console Setup

### 1. Create Developer Account
- Go to [Google Play Console](https://play.google.com/console)
- Pay $25 one-time registration fee
- Complete account setup (takes 48 hours for new accounts)

### 2. Create New App
- Click **Create app**
- App name: "Aman Enterprises"
- Default language: English (India)
- App or game: App
- Free or paid: Free
- Accept declarations

### 3. Store Listing (Required)
| Field | Value |
|-------|-------|
| App name | Aman Enterprises |
| Short description | Fresh groceries delivered to your doorstep in minutes! |
| Full description | (See below) |
| App icon | 512x512 PNG (already have) |
| Feature graphic | 1024x500 PNG |
| Screenshots | At least 2 phone screenshots |

#### Suggested Full Description:
```
🛒 Aman Enterprises - Your Trusted Grocery Partner

Get fresh groceries, fruits, vegetables, dairy products, and daily essentials delivered right to your doorstep!

✨ FEATURES:
• Wide range of quality products
• Easy ordering with voice search
• Multiple payment options (COD, Online, UPI)
• Real-time order tracking
• Fast delivery service
• Secure checkout

🥦 CATEGORIES:
• Fresh Vegetables & Fruits
• Dairy Products
• Groceries & Staples
• Snacks & Beverages
• Household Essentials

💳 EASY PAYMENTS:
• Cash on Delivery
• Online Payment
• UPI/QR Code
• Bank Transfer

📱 WHY CHOOSE US:
• Quality assured products
• Competitive prices
• Timely delivery
• Excellent customer support
• Available in Hindi & English

Download now and experience hassle-free grocery shopping!

📞 Support: support@amanenterprises.com
```

### 4. Privacy Policy
Upload or link to: `docs/privacy-policy.html`

Options to host:
1. **GitHub Pages**: Push to GitHub and enable Pages
2. **Your Backend**: Add route `/privacy-policy`
3. **Netlify/Vercel**: Free hosting

### 5. Content Rating
- Complete the questionnaire
- Your app will likely be rated: Everyone

### 6. Data Safety Form
Declare the following data collection:
| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Email | Yes | No | Account, communication |
| Phone | Yes | No | Account, OTP |
| Name | Yes | No | Personalization |
| Address | Yes | Delivery partners | Order delivery |
| Payment info | Yes | Payment processor | Transactions |
| Location | Yes | Delivery | Delivery service |

### 7. Upload App Bundle
- Go to **Release** > **Production**
- Create new release
- Upload `.aab` file
- Add release notes

### 8. Review & Submit
- Review all sections
- Fix any errors
- Submit for review (takes 1-7 days)

---

## 📱 Screenshots Checklist

Take screenshots for these screens:
1. Home screen (products & categories)
2. Product details page
3. Cart/Checkout
4. Order tracking
5. Profile/Account

**Tip**: Use a phone with 1080x1920 resolution or emulator

---

## ⚠️ Common Rejection Reasons

Avoid these:
- [ ] Missing Privacy Policy
- [ ] Requesting unnecessary permissions
- [ ] App crashes during review
- [ ] Login not working
- [ ] Payment issues
- [ ] Incomplete Data Safety form

---

## 🔐 Security Reminders

Never commit these to Git:
- `android/key.properties`
- `*.keystore` files
- Firebase config with sensitive keys
- API secret keys

---

## 📞 Need Help?

- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Deployment Docs](https://docs.flutter.dev/deployment/android)

Good luck with your launch! 🚀
