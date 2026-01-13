# Haven Mobile - Implement Google Sign-In

## OVERVIEW

Add Google Sign-In to the Haven mobile app using Expo AuthSession and Firebase Authentication.

---

## CREDENTIALS

```
Google OAuth Client ID: 421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8.apps.googleusercontent.com
Reversed Client ID: com.googleusercontent.apps.421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8
Bundle ID: com.havenhome.app
```

---

## STEP 1: Install Required Packages

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo install expo-auth-session expo-crypto expo-web-browser
```

---

## STEP 2: Update app.json / app.config.js

Add the URL scheme for Google OAuth callback:

```json
{
  "expo": {
    "scheme": "com.googleusercontent.apps.421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8",
    "ios": {
      "bundleIdentifier": "com.havenhome.app",
      "infoPlist": {
        "CFBundleURLTypes": [
          {
            "CFBundleURLSchemes": [
              "com.googleusercontent.apps.421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8"
            ]
          }
        ]
      }
    },
    "android": {
      "package": "com.havenhome.app"
    }
  }
}
```

If using `app.config.js` or `app.config.ts`, add:

```typescript
export default {
  expo: {
    // ... existing config
    scheme: "com.googleusercontent.apps.421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8",
    ios: {
      // ... existing ios config
      bundleIdentifier: "com.havenhome.app",
      infoPlist: {
        CFBundleURLTypes: [
          {
            CFBundleURLSchemes: [
              "com.googleusercontent.apps.421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8"
            ]
          }
        ]
      }
    },
  }
};
```

---

## STEP 3: Create Google Auth Hook

Create `apps/mobile/src/hooks/useGoogleAuth.ts`:

```typescript
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { useEffect, useState } from 'react';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';
import { auth } from '../lib/firebase';

// Required for web browser auth session
WebBrowser.maybeCompleteAuthSession();

const GOOGLE_CLIENT_ID = '421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8.apps.googleusercontent.com';

// You may also need web and Android client IDs if supporting those platforms
// const GOOGLE_WEB_CLIENT_ID = 'your-web-client-id.apps.googleusercontent.com';
// const GOOGLE_ANDROID_CLIENT_ID = 'your-android-client-id.apps.googleusercontent.com';

export function useGoogleAuth() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [request, response, promptAsync] = Google.useAuthRequest({
    iosClientId: GOOGLE_CLIENT_ID,
    // webClientId: GOOGLE_WEB_CLIENT_ID,
    // androidClientId: GOOGLE_ANDROID_CLIENT_ID,
    scopes: ['profile', 'email'],
  });

  useEffect(() => {
    handleAuthResponse();
  }, [response]);

  const handleAuthResponse = async () => {
    if (response?.type === 'success') {
      setIsLoading(true);
      setError(null);
      
      try {
        const { id_token, access_token } = response.params;
        
        // Create Firebase credential with the Google tokens
        const credential = GoogleAuthProvider.credential(id_token, access_token);
        
        // Sign in to Firebase with the credential
        const userCredential = await signInWithCredential(auth, credential);
        
        console.log('Google Sign-In successful:', userCredential.user.email);
        
        // The auth state listener in your auth context will handle navigation
      } catch (err: any) {
        console.error('Google Sign-In error:', err);
        setError(err.message || 'Failed to sign in with Google');
      } finally {
        setIsLoading(false);
      }
    } else if (response?.type === 'error') {
      setError(response.error?.message || 'Google Sign-In was cancelled');
    }
  };

  const signInWithGoogle = async () => {
    setError(null);
    try {
      await promptAsync();
    } catch (err: any) {
      setError(err.message || 'Failed to initiate Google Sign-In');
    }
  };

  return {
    signInWithGoogle,
    isLoading,
    error,
    isReady: !!request,
  };
}
```

---

## STEP 4: Create Google Sign-In Button Component

Create `apps/mobile/src/components/auth/GoogleSignInButton.tsx`:

```typescript
import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  View,
  Image,
} from 'react-native';
import { useGoogleAuth } from '../../hooks/useGoogleAuth';

interface GoogleSignInButtonProps {
  onError?: (error: string) => void;
}

export function GoogleSignInButton({ onError }: GoogleSignInButtonProps) {
  const { signInWithGoogle, isLoading, error, isReady } = useGoogleAuth();

  React.useEffect(() => {
    if (error && onError) {
      onError(error);
    }
  }, [error, onError]);

  return (
    <TouchableOpacity
      style={[styles.button, (!isReady || isLoading) && styles.buttonDisabled]}
      onPress={signInWithGoogle}
      disabled={!isReady || isLoading}
      activeOpacity={0.8}
    >
      {isLoading ? (
        <ActivityIndicator color="#757575" size="small" />
      ) : (
        <>
          {/* Google "G" Logo */}
          <View style={styles.iconContainer}>
            <GoogleLogo />
          </View>
          <Text style={styles.buttonText}>Continue with Google</Text>
        </>
      )}
    </TouchableOpacity>
  );
}

// Simple Google "G" logo using colored shapes
function GoogleLogo() {
  return (
    <View style={styles.logoContainer}>
      {/* You can use an SVG or image here */}
      {/* For simplicity, using text-based representation */}
      <Text style={styles.googleG}>G</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#ffffff',
    borderWidth: 1,
    borderColor: '#e2e8f0',
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 24,
    height: 52,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  iconContainer: {
    marginRight: 12,
  },
  logoContainer: {
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  googleG: {
    fontSize: 18,
    fontWeight: '700',
    color: '#4285F4',  // Google Blue
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
  },
});
```

### Alternative: Use Official Google Logo Image

If you have access to the official Google logo, use it:

```typescript
<Image 
  source={require('../../assets/google-logo.png')} 
  style={{ width: 20, height: 20 }}
  resizeMode="contain"
/>
```

Or use a vector icon from `@expo/vector-icons`:

```typescript
import { Ionicons } from '@expo/vector-icons';

// Note: Ionicons doesn't have official Google logo, use custom SVG
```

---

## STEP 5: Update Login Screen

Update `apps/mobile/app/(auth)/login.tsx` (or wherever your login screen is):

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { GoogleSignInButton } from '../../src/components/auth/GoogleSignInButton';
import { useAuth } from '../../src/contexts/AuthContext';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const { signIn } = useAuth();

  const handleEmailSignIn = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Please enter email and password');
      return;
    }

    setIsLoading(true);
    try {
      await signIn(email, password);
      // Navigation handled by auth state listener
    } catch (error: any) {
      Alert.alert('Sign In Failed', error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleError = (error: string) => {
    Alert.alert('Google Sign-In Failed', error);
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView 
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.title}>Welcome back</Text>
            <Text style={styles.subtitle}>Sign in to your Haven account</Text>
          </View>

          {/* Google Sign-In Button - PROMINENT */}
          <View style={styles.socialSection}>
            <GoogleSignInButton onError={handleGoogleError} />
          </View>

          {/* Divider */}
          <View style={styles.divider}>
            <View style={styles.dividerLine} />
            <Text style={styles.dividerText}>or</Text>
            <View style={styles.dividerLine} />
          </View>

          {/* Email/Password Form */}
          <View style={styles.form}>
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Email</Text>
              <TextInput
                style={styles.input}
                placeholder="you@example.com"
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                autoCapitalize="none"
                autoCorrect={false}
                placeholderTextColor="#9ca3af"
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Password</Text>
              <TextInput
                style={styles.input}
                placeholder="Enter your password"
                value={password}
                onChangeText={setPassword}
                secureTextEntry
                placeholderTextColor="#9ca3af"
              />
            </View>

            <TouchableOpacity 
              style={styles.forgotPassword}
              onPress={() => router.push('/(auth)/forgot-password')}
            >
              <Text style={styles.forgotPasswordText}>Forgot password?</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.signInButton, isLoading && styles.signInButtonDisabled]}
              onPress={handleEmailSignIn}
              disabled={isLoading}
            >
              <Text style={styles.signInButtonText}>
                {isLoading ? 'Signing in...' : 'Sign In'}
              </Text>
            </TouchableOpacity>
          </View>

          {/* Sign Up Link */}
          <View style={styles.signUpSection}>
            <Text style={styles.signUpText}>Don't have an account? </Text>
            <TouchableOpacity onPress={() => router.push('/(auth)/signup')}>
              <Text style={styles.signUpLink}>Sign up</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    padding: 24,
  },
  header: {
    marginBottom: 32,
    marginTop: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#0a1929',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#627d98',
  },
  socialSection: {
    marginBottom: 24,
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 24,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#e2e8f0',
  },
  dividerText: {
    marginHorizontal: 16,
    fontSize: 14,
    color: '#9ca3af',
  },
  form: {
    marginBottom: 24,
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
    color: '#374151',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f8fafc',
    borderWidth: 1,
    borderColor: '#e2e8f0',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    color: '#0a1929',
  },
  forgotPassword: {
    alignSelf: 'flex-end',
    marginBottom: 24,
  },
  forgotPasswordText: {
    fontSize: 14,
    color: '#c4a574',
    fontWeight: '500',
  },
  signInButton: {
    backgroundColor: '#0a1929',
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
  },
  signInButtonDisabled: {
    opacity: 0.6,
  },
  signInButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
  },
  signUpSection: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 'auto',
    paddingVertical: 16,
  },
  signUpText: {
    fontSize: 14,
    color: '#627d98',
  },
  signUpLink: {
    fontSize: 14,
    fontWeight: '600',
    color: '#c4a574',
  },
});
```

---

## STEP 6: Update Sign Up Screen Similarly

Apply the same pattern to the signup screen - add `GoogleSignInButton` at the top with "or" divider.

---

## STEP 7: Ensure Firebase Google Auth is Enabled

In Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable "Google" provider
3. Add your iOS bundle ID (com.havenhome.app) to the authorized domains
4. Download updated GoogleService-Info.plist if needed

---

## STEP 8: Copy the Plist File (if needed)

If you need the plist in the project:

```bash
cp /path/to/client_421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8_apps_googleusercontent_com.plist \
   /Users/tomburke/Projects/Housing-Manager/apps/mobile/GoogleService-Info.plist
```

---

## VERIFICATION CHECKLIST

### Installation
- [ ] expo-auth-session installed
- [ ] expo-crypto installed  
- [ ] expo-web-browser installed

### Configuration
- [ ] app.json/app.config has correct scheme
- [ ] iOS infoPlist has CFBundleURLSchemes
- [ ] Bundle ID matches (com.havenhome.app)

### Code
- [ ] useGoogleAuth hook created
- [ ] GoogleSignInButton component created
- [ ] Login screen has Google button
- [ ] Signup screen has Google button
- [ ] Error handling in place

### Firebase
- [ ] Google sign-in enabled in Firebase Console
- [ ] iOS bundle ID added to Firebase

### Testing
- [ ] Build the app: `npx expo run:ios` or `eas build`
- [ ] Tap "Continue with Google"
- [ ] Google OAuth popup appears
- [ ] After auth, user is signed in to Firebase
- [ ] User lands on main app screen

---

## TEST COMMANDS

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Install dependencies
npx expo install expo-auth-session expo-crypto expo-web-browser

# Run on iOS simulator
npx expo run:ios

# Or start development server
npx expo start --clear
```

---

## TROUBLESHOOTING

### "redirect_uri_mismatch" Error
- Ensure the scheme in app.json matches the reversed client ID
- Rebuild the app after changing app.json

### "Invalid client_id" Error
- Verify the client ID is correct
- Ensure it's an iOS client, not web client

### OAuth Popup Doesn't Open
- Check that expo-web-browser is installed
- Ensure `WebBrowser.maybeCompleteAuthSession()` is called

### Firebase Error After Google Auth
- Ensure Google provider is enabled in Firebase Console
- Verify you're using the correct Firebase project
