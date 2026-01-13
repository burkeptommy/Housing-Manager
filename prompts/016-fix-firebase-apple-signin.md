# Fix Firebase Apple Sign In - Audience Mismatch Error

## The Error
```
Firebase: The audience in ID Token [com.havenhome.app] does not match the expected audience. (auth/invalid-credential).
```

## Root Cause
Firebase is receiving a token with audience `com.havenhome.app` (your bundle ID) but is expecting a different audience. This happens when Apple Sign In isn't properly configured in Firebase Console.

## Quick Fix Steps

### Step 1: Configure Apple Sign In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Haven project
3. Go to **Authentication** → **Sign-in method**
4. Click on **Apple**
5. Enable it and configure:

**Required Settings:**
- **Services ID**: `com.havenhome.app` ← This is the key fix!
  - For mobile apps, the Services ID should match your bundle ID
  - OR create a dedicated Services ID like `com.havenhome.app.signin`
  
- **Apple Team ID**: Your 10-character Team ID from Apple Developer
  - Find it at: https://developer.apple.com/account → Membership
  
- **Key ID**: The ID of your Sign in with Apple key
  - Create at: Apple Developer → Certificates, Identifiers & Profiles → Keys
  
- **Private Key**: Upload the `.p8` file you downloaded when creating the key

### Step 2: Configure in Apple Developer Console

1. Go to [Apple Developer](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. Find or create your App ID (`com.havenhome.app`)
4. Ensure **Sign in with Apple** capability is enabled
5. Click **Configure** next to Sign in with Apple
6. Add a **Primary App ID** if prompted

If you need a Services ID:
1. Click **+** to create new identifier
2. Select **Services IDs**
3. Create with ID: `com.havenhome.app.signin` (or similar)
4. Enable **Sign in with Apple**
5. Configure:
   - Primary App ID: `com.havenhome.app`
   - Domains and Subdomains: `havenhome.dev`
   - Return URLs: `https://YOUR-FIREBASE-PROJECT.firebaseapp.com/__/auth/handler`

### Step 3: Create Sign in with Apple Key (if not done)

1. Apple Developer → **Keys** → **+**
2. Name: "Haven Sign In Key"
3. Enable **Sign in with Apple**
4. Configure → Select Primary App ID: `com.havenhome.app`
5. Click **Continue** → **Register**
6. **Download the .p8 file** (you can only download once!)
7. Note the **Key ID** (10 characters)

### Step 4: Upload Key to Firebase

1. Firebase Console → Authentication → Sign-in method → Apple
2. Paste your **Team ID**
3. Paste your **Key ID**
4. Upload your **.p8 private key file**
5. Set **Services ID** to `com.havenhome.app` (or your dedicated Services ID)
6. Click **Save**

---

## For Google Sign In

Note: Google Sign In is currently **stubbed** in your app. It won't work until you:

1. Add the Google Sign In config plugin to app.json:
```json
{
  "expo": {
    "plugins": [
      ["@react-native-google-signin/google-signin", {
        "iosUrlScheme": "com.googleusercontent.apps.YOUR-IOS-CLIENT-ID"
      }]
    ]
  }
}
```

2. Implement the actual Google Sign In (currently a stub in `google-auth.ts`)

3. Run `npx expo prebuild --clean`

For now, focus on getting Apple Sign In working first.

---

## Better UX: Handle Non-Existent Users

Your code already handles this well! Looking at `auth-context.tsx`:

```typescript
// loginWithApple checks if user exists after Firebase auth
const loginWithApple = useCallback(async () => {
  const result = await signInWithApple();
  // If Firebase auth succeeds, the onAuthChange listener will:
  // 1. Call fetchMe() to check if user exists in your backend
  // 2. If not, set appropriate state (needsOnboarding, etc.)
});
```

However, we can improve the error handling. Update `apps/mobile/app/(auth)/login.tsx`:

```typescript
const handleAppleLogin = async () => {
  setError('');
  const result = await loginWithApple();

  if (!result.success) {
    // Don't show error for user cancellation
    if (result.error === 'Sign in was cancelled') {
      return;
    }
    
    // Check if this is a "user not found" scenario
    if (result.error?.includes('user-not-found') || result.error?.includes('invalid-credential')) {
      // Show helpful message
      Alert.alert(
        'Account Not Found',
        'No Haven account exists for this Apple ID. Would you like to create one?',
        [
          { text: 'Cancel', style: 'cancel' },
          { 
            text: 'Create Account', 
            onPress: () => router.push('/(auth)/register'),
          },
        ]
      );
      return;
    }
    
    setError(result.error || 'Apple Sign In failed');
  }
};
```

---

## Testing After Configuration

1. **Delete the app** from device/simulator
2. Run: `npx expo prebuild --clean` (if you have native modules)
3. Build fresh: `npx eas build --platform ios --profile development`
4. Or for simulator: `npx expo run:ios`
5. Try Apple Sign In again

---

## Debugging Checklist

If it still doesn't work, check:

- [ ] Firebase Console → Apple is **Enabled** (toggle is on)
- [ ] **Services ID** matches your bundle ID or is correctly configured
- [ ] **Team ID** is correct (10 characters)
- [ ] **Key ID** is correct (10 characters)
- [ ] **.p8 file** was uploaded (not expired, not revoked)
- [ ] Apple Developer → App ID has **Sign in with Apple** capability enabled
- [ ] You're testing on a **real device** or **iOS Simulator** (not Expo Go)

---

## Environment Variables Check

Make sure your `.env` file in the mobile app has all Firebase config:

```bash
# Check current env
cat apps/mobile/.env

# Should have:
EXPO_PUBLIC_FIREBASE_API_KEY=xxx
EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN=xxx.firebaseapp.com
EXPO_PUBLIC_FIREBASE_PROJECT_ID=xxx
EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET=xxx.appspot.com
EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=xxx
EXPO_PUBLIC_FIREBASE_APP_ID=xxx
```

---

## Summary

The error `The audience in ID Token [com.havenhome.app] does not match the expected audience` means:

1. Apple sends a token with `aud: "com.havenhome.app"`
2. Firebase expects a different audience (based on your Services ID setting)

**Fix**: Set the Services ID in Firebase Console to match your bundle ID (`com.havenhome.app`), or properly configure a dedicated Services ID.
