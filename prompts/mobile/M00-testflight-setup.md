# Haven Mobile: M00 - TestFlight Setup

**Created:** December 29, 2024  
**Priority:** P0 - Required for proper testing  
**Estimated Time:** 30-45 minutes (includes build time)  
**Dependencies:** Apple Developer Account ($99/year) ✅

---

## Overview

This sets up the professional iOS development workflow:
1. Configure EAS (Expo Application Services)
2. Connect to Apple Developer account
3. Create App Store Connect entry
4. Build and deploy to TestFlight
5. Install on your iPhone

**After this, you can install Haven on your phone and test as we develop.**

---

## PHASE 1: Install & Login to EAS

### Task 1.1: Install EAS CLI

```bash
# Install EAS CLI globally
npm install -g eas-cli

# Verify installation
eas --version
```

### Task 1.2: Login to Expo

```bash
# Login (create account if needed at expo.dev)
eas login
```

### Task 1.3: Initialize EAS in Project

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Initialize EAS configuration
eas build:configure
```

This creates `eas.json` in the mobile app directory.

---

## PHASE 2: Configure eas.json

### Task 2.1: Update eas.json

Replace `apps/mobile/eas.json` with:

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": false
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "simulator": false
      }
    },
    "production": {
      "distribution": "store",
      "ios": {
        "simulator": false
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "YOUR_APPLE_ID_EMAIL",
        "ascAppId": "YOUR_APP_STORE_CONNECT_APP_ID",
        "appleTeamId": "YOUR_TEAM_ID"
      }
    }
  }
}
```

**Note:** We'll fill in the Apple credentials in the next phase.

---

## PHASE 3: Apple Developer Portal Setup

### Task 3.1: Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Click **Identifiers** → **+** button
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Fill in:
   - **Description:** Haven Home
   - **Bundle ID:** Explicit → `com.havenhome.app`
6. Enable Capabilities:
   - ✅ Sign In with Apple
   - ✅ Push Notifications (for later)
   - ✅ Associated Domains (for later)
7. Click **Continue** → **Register**

### Task 3.2: Create App Store Connect Entry

1. Go to [App Store Connect](https://appstoreconnect.apple.com/apps)
2. Click **+** → **New App**
3. Fill in:
   - **Platforms:** iOS
   - **Name:** Haven - Home Management
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `com.havenhome.app`
   - **SKU:** `havenhome-ios-001`
   - **User Access:** Full Access
4. Click **Create**

### Task 3.3: Get Your Credentials

After creating the app, note these values:

| Credential | Where to Find | Example |
|------------|---------------|---------|
| **Apple ID** | Your login email | tom@havenhome.dev |
| **Team ID** | [Membership page](https://developer.apple.com/account/#!/membership) | ABC123XYZ |
| **ASC App ID** | App Store Connect URL after creating app | 6449512345 |

### Task 3.4: Update eas.json with Credentials

Update the `submit.production.ios` section in `eas.json`:

```json
"submit": {
  "production": {
    "ios": {
      "appleId": "tom@havenhome.dev",
      "ascAppId": "6449512345",
      "appleTeamId": "ABC123XYZ"
    }
  }
}
```

---

## PHASE 4: Update app.json for Production

### Task 4.1: Update app.json

Ensure `apps/mobile/app.json` has proper iOS configuration:

```json
{
  "expo": {
    "name": "Haven",
    "slug": "haven-mobile",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "scheme": "haven",
    "userInterfaceStyle": "light",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#0a1929"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.havenhome.app",
      "buildNumber": "1",
      "infoPlist": {
        "NSCameraUsageDescription": "Haven needs camera access to scan documents and take photos.",
        "NSPhotoLibraryUsageDescription": "Haven needs photo library access to upload documents.",
        "NSFaceIDUsageDescription": "Haven uses Face ID for secure, quick login.",
        "LSApplicationQueriesSchemes": ["plaidlink"]
      },
      "associatedDomains": [
        "applinks:havenhome.dev",
        "applinks:api.havenhome.dev"
      ],
      "config": {
        "usesNonExemptEncryption": false
      }
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#0a1929"
      },
      "package": "com.havenhome.app"
    },
    "plugins": [
      "expo-router",
      "expo-secure-store",
      "expo-apple-authentication",
      [
        "expo-local-authentication",
        {
          "faceIDPermission": "Allow Haven to use Face ID for quick login."
        }
      ]
    ],
    "extra": {
      "eas": {
        "projectId": "your-project-id"
      }
    },
    "owner": "havenhome"
  }
}
```

---

## PHASE 5: Create Your First Build

### Task 5.1: Build for Internal Distribution

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Create internal distribution build (TestFlight)
eas build --platform ios --profile preview
```

**This will:**
1. Ask you to log in to your Apple Developer account
2. Auto-generate provisioning profiles and certificates
3. Build the app in the cloud (~15-20 minutes)
4. Provide a download link or submit to TestFlight

### Task 5.2: Submit to TestFlight (after build completes)

```bash
# Submit the build to TestFlight
eas submit --platform ios --latest
```

---

## PHASE 6: Install on Your iPhone

### Task 6.1: TestFlight Internal Testing

1. Open **TestFlight** app on your iPhone (download from App Store if needed)
2. Sign in with your Apple ID (same as Developer account)
3. Haven should appear under "Apps Available to Test"
4. Tap **Install**

### Task 6.2: Add Other Internal Testers (Optional)

1. Go to [App Store Connect](https://appstoreconnect.apple.com/apps) → Haven
2. Click **TestFlight** tab
3. Click **Internal Testing** → **+** → Add testers by Apple ID email
4. They'll receive an email invitation to test

---

## PHASE 7: Development Build (Alternative)

For faster iteration during development, you can also create a development build:

```bash
# Create development build (includes dev tools)
eas build --platform ios --profile development
```

This creates an app you can install directly that connects to your local Metro bundler for hot reloading.

---

## Quick Reference Commands

```bash
# Build for TestFlight (internal testing)
eas build --platform ios --profile preview

# Build for App Store (production)
eas build --platform ios --profile production

# Submit latest build to TestFlight/App Store
eas submit --platform ios --latest

# Check build status
eas build:list

# View credentials
eas credentials
```

---

## Troubleshooting

### "No bundle identifier" error
Ensure `app.json` has `expo.ios.bundleIdentifier` set to `com.havenhome.app`

### Apple login fails
Make sure you're using the Apple ID associated with your Developer account

### Build fails on native modules
Run `npx expo prebuild --clean` then try again

### Provisioning profile issues
```bash
eas credentials --platform ios
# Select "Remove" to clear cached credentials, then rebuild
```

---

## Summary

After completing this setup:
1. ✅ EAS configured for cloud builds
2. ✅ Apple Developer account connected
3. ✅ App Store Connect entry created
4. ✅ Haven app on your iPhone via TestFlight
5. ✅ Ready for ongoing development testing

**Every time you want to test new features:**
```bash
eas build --platform ios --profile preview
eas submit --platform ios --latest
```

Then update via TestFlight on your phone (~5 min after submit).

---

## Next Steps

After setup is complete, continue with:
- **M04** - Plaid Integration
- **M05** - Subscriptions & Apple Pay
- Continue building features and testing on your real device!
