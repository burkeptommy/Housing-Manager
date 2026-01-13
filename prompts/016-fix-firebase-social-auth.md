# Fix Firebase Auth - Apple/Google Sign In + Better UX Flow

## Problem 1: Firebase Audience Mismatch Error

**Error:** `Firebase: The audience in ID Token [com.havenhome.app] does not match the expected audience. (auth/invalid-credential).`

This means Firebase is rejecting the ID token from Apple/Google Sign In because the audience (your app's bundle ID) isn't properly configured in Firebase.

---

## PHASE 1: Fix Firebase Configuration

### 1a. Verify Firebase Project Settings

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select the Haven project
3. Go to **Project Settings** → **General**
4. Under **Your apps**, verify there's an iOS app with:
   - Bundle ID: `com.havenhome.app`
   - App ID should match what's in your Xcode project

If the iOS app isn't registered:
- Click **Add app** → iOS
- Enter Bundle ID: `com.havenhome.app`
- Download the new `GoogleService-Info.plist`
- Replace the existing one in `apps/mobile/`

### 1b. Configure Apple Sign In in Firebase

1. Firebase Console → **Authentication** → **Sign-in method**
2. Click **Apple** → Enable it
3. Configure:
   - **Services ID**: This should be your Apple Services ID (usually `com.havenhome.app.signin` or similar)
   - **Apple Team ID**: Your Apple Developer Team ID
   - **Key ID**: The Key ID from your Apple Sign In key
   - **Private Key**: Upload the `.p8` file from Apple Developer

4. In Apple Developer Console:
   - Go to **Identifiers** → **Services IDs**
   - Create or verify a Services ID for Sign in with Apple
   - Configure the **Return URLs** to include Firebase's callback URL:
     ```
     https://YOUR-PROJECT-ID.firebaseapp.com/__/auth/handler
     ```

### 1c. Configure Google Sign In in Firebase

1. Firebase Console → **Authentication** → **Sign-in method**
2. Click **Google** → Enable it
3. Note the **Web client ID** - you'll need this in the app

4. Go to [Google Cloud Console](https://console.cloud.google.com)
5. Select your Firebase project
6. Go to **APIs & Services** → **Credentials**
7. Verify you have OAuth 2.0 Client IDs for:
   - **iOS**: With bundle ID `com.havenhome.app`
   - **Web**: For Firebase Auth

### 1d. Update Mobile App Configuration

Check `apps/mobile/app.json` or `app.config.js`:

```json
{
  "expo": {
    "ios": {
      "bundleIdentifier": "com.havenhome.app",
      "googleServicesFile": "./GoogleService-Info.plist",
      "usesAppleSignIn": true,
      "infoPlist": {
        "CFBundleURLTypes": [
          {
            "CFBundleURLSchemes": [
              "com.googleusercontent.apps.YOUR-IOS-CLIENT-ID"
            ]
          }
        ]
      }
    },
    "plugins": [
      "expo-apple-authentication",
      "@react-native-google-signin/google-signin"
    ]
  }
}
```

### 1e. Verify GoogleService-Info.plist

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check if GoogleService-Info.plist exists and has correct bundle ID
cat GoogleService-Info.plist | grep -A1 "BUNDLE_ID"
```

The `BUNDLE_ID` should be `com.havenhome.app`.

If it's wrong, download a fresh one from Firebase Console.

---

## PHASE 2: Check Auth Code Implementation

### 2a. Find the auth implementation

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find Firebase auth files
find . -name "*.ts" -o -name "*.tsx" | xargs grep -l "signInWithApple\|GoogleSignin\|auth/\|firebase" | head -20

# Find the login screen
find . -name "*login*" -o -name "*Login*" -o -name "*auth*" | head -20
```

### 2b. Verify Apple Sign In Implementation

The Apple Sign In flow should:
1. Get credential from Apple
2. Create Firebase OAuthProvider credential
3. Sign in to Firebase with that credential

```typescript
import * as AppleAuthentication from 'expo-apple-authentication';
import { OAuthProvider, signInWithCredential } from 'firebase/auth';
import { auth } from '../lib/firebase';

async function signInWithApple() {
  try {
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
    });

    // Create Firebase credential
    const provider = new OAuthProvider('apple.com');
    const oAuthCredential = provider.credential({
      idToken: credential.identityToken!,
      rawNonce: credential.authorizationCode, // or use a nonce
    });

    // Sign in to Firebase
    const result = await signInWithCredential(auth, oAuthCredential);
    return result.user;
  } catch (error) {
    console.error('Apple Sign In error:', error);
    throw error;
  }
}
```

### 2c. Verify Google Sign In Implementation

```typescript
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';
import { auth } from '../lib/firebase';

// Configure Google Sign In (do this once, e.g., in App.tsx)
GoogleSignin.configure({
  webClientId: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com', // From Firebase Console
  iosClientId: 'YOUR-IOS-CLIENT-ID.apps.googleusercontent.com', // From Google Cloud Console
});

async function signInWithGoogle() {
  try {
    await GoogleSignin.hasPlayServices();
    const userInfo = await GoogleSignin.signIn();
    
    // Create Firebase credential
    const googleCredential = GoogleAuthProvider.credential(userInfo.idToken);
    
    // Sign in to Firebase
    const result = await signInWithCredential(auth, googleCredential);
    return result.user;
  } catch (error) {
    console.error('Google Sign In error:', error);
    throw error;
  }
}
```

---

## PHASE 3: Better UX - Handle Non-Existent Users

When a user tries to sign in with Apple/Google but doesn't have an account, we should handle it gracefully.

### Recommended Flow:
**Auto-create account on first social sign-in** (most common pattern)

Firebase automatically creates an account when someone signs in with Apple/Google for the first time. The issue is usually that your backend might require additional onboarding data.

### Implementation:

```typescript
// In your auth context or login handler

async function handleSocialSignIn(provider: 'apple' | 'google') {
  try {
    let firebaseUser;
    
    if (provider === 'apple') {
      firebaseUser = await signInWithApple();
    } else {
      firebaseUser = await signInWithGoogle();
    }

    // Check if user exists in YOUR backend (not just Firebase)
    const token = await firebaseUser.getIdToken();
    const response = await fetch(`${API_BASE_URL}/auth/check-user`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.status === 404) {
      // User exists in Firebase but not in your backend
      // Option A: Auto-create and go to onboarding
      navigation.navigate('Onboarding');
      
      // Option B: Show prompt
      Alert.alert(
        'Create Account',
        'No account found. Would you like to create one?',
        [
          { text: 'Cancel', style: 'cancel' },
          { 
            text: 'Create Account', 
            onPress: () => navigation.navigate('Onboarding'),
          },
        ]
      );
    } else if (response.ok) {
      // User exists - check if onboarding complete
      const userData = await response.json();
      if (userData.needsOnboarding) {
        navigation.navigate('Onboarding');
      } else {
        navigation.navigate('Dashboard');
      }
    }
  } catch (error: any) {
    // Handle specific errors
    if (error.code === 'auth/account-exists-with-different-credential') {
      Alert.alert(
        'Account Exists',
        'An account already exists with this email using a different sign-in method. Please sign in with your original method.',
      );
    } else {
      Alert.alert('Sign In Error', error.message);
    }
  }
}
```

### Update Login Screen:

```tsx
// In your login screen

const handleAppleSignIn = async () => {
  setIsLoading(true);
  setError(null);
  
  try {
    await handleSocialSignIn('apple');
  } catch (error: any) {
    setError(error.message);
  } finally {
    setIsLoading(false);
  }
};

const handleGoogleSignIn = async () => {
  setIsLoading(true);
  setError(null);
  
  try {
    await handleSocialSignIn('google');
  } catch (error: any) {
    setError(error.message);
  } finally {
    setIsLoading(false);
  }
};
```

---

## PHASE 4: Debug the Current Error

To pinpoint the exact issue, add logging:

```typescript
// In your Apple Sign In handler, log the credential details

const credential = await AppleAuthentication.signInAsync({...});

console.log('Apple credential:', {
  identityToken: credential.identityToken?.substring(0, 50) + '...',
  authorizationCode: credential.authorizationCode?.substring(0, 20) + '...',
  user: credential.user,
});

// Decode the JWT to see the audience
const tokenParts = credential.identityToken?.split('.');
if (tokenParts && tokenParts[1]) {
  const payload = JSON.parse(atob(tokenParts[1]));
  console.log('Token payload:', payload);
  console.log('Token audience:', payload.aud);
}
```

The `aud` (audience) in the token should match what Firebase expects.

---

## PHASE 5: Common Fixes

### Fix 1: Services ID Mismatch (Apple)

In Firebase Console → Authentication → Sign-in method → Apple:
- The **Services ID** must match exactly what's configured in Apple Developer Console

### Fix 2: Wrong GoogleService-Info.plist

```bash
# Re-download from Firebase Console and replace
cd apps/mobile
# Delete old one
rm GoogleService-Info.plist
# Add new one from Firebase Console download
```

### Fix 3: Expo Config Not Updated

After changing GoogleService-Info.plist:
```bash
cd apps/mobile
npx expo prebuild --clean
npx eas build --platform ios --profile development
```

### Fix 4: Backend Token Verification

If your backend verifies tokens, ensure it accepts the correct audience:

```typescript
// In your NestJS API
import { auth } from 'firebase-admin';

async verifyToken(idToken: string) {
  // This should automatically accept tokens from your Firebase project
  const decodedToken = await auth().verifyIdToken(idToken);
  return decodedToken;
}
```

---

## Checklist

### Firebase Console:
- [ ] iOS app registered with bundle ID `com.havenhome.app`
- [ ] Apple Sign In enabled and configured
- [ ] Google Sign In enabled
- [ ] Download fresh GoogleService-Info.plist

### Apple Developer Console:
- [ ] App ID has Sign in with Apple capability
- [ ] Services ID created for Sign in with Apple
- [ ] Return URL includes Firebase callback

### Google Cloud Console:
- [ ] OAuth client for iOS with correct bundle ID
- [ ] OAuth client for Web (used by Firebase)

### Mobile App:
- [ ] GoogleService-Info.plist has correct BUNDLE_ID
- [ ] app.json has correct bundleIdentifier
- [ ] Google Sign In configured with correct client IDs
- [ ] Run `expo prebuild --clean` after config changes

### Code:
- [ ] Apple Sign In creates OAuthProvider credential correctly
- [ ] Google Sign In uses correct webClientId
- [ ] Error handling for non-existent users
- [ ] Proper navigation after social sign in

---

## Quick Test After Fixes

1. Delete the app from device/simulator
2. Run `npx expo prebuild --clean`
3. Build fresh: `npx eas build --platform ios --profile development`
4. Install and test Apple Sign In
5. Check Firebase Console → Authentication → Users to see if user was created
