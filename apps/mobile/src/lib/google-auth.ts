import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';
import { getFirebaseAuth, isFirebaseConfigured } from './firebase';
import { makeRedirectUri, type AuthSessionResult } from 'expo-auth-session';
import { Platform } from 'react-native';

// Required for web browser auth session
WebBrowser.maybeCompleteAuthSession();

/**
 * Google Sign In for Haven
 *
 * Flow:
 * 1. Use expo-auth-session to get Google OAuth token
 * 2. Create Firebase credential from the ID token
 * 3. Sign in to Firebase
 */

export interface GoogleAuthResult {
  success: boolean;
  user?: {
    uid: string;
    email: string | null;
    displayName: string | null;
    photoURL: string | null;
  };
  error?: string;
}

// Google OAuth Client IDs
// Web client ID is used for both web and native OAuth flows with Firebase
const WEB_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;
// iOS client ID - needs to be created in Google Cloud Console for native iOS
const IOS_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID;
// Android client ID - needs to be created in Google Cloud Console for native Android
const ANDROID_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID;

/**
 * Check if Google Sign In is properly configured for the current platform
 */
export function isGoogleSignInConfigured(): boolean {
  if (!WEB_CLIENT_ID) return false;
  if (Platform.OS === 'ios' && !IOS_CLIENT_ID) return false;
  if (Platform.OS === 'android' && !ANDROID_CLIENT_ID) return false;
  return true;
}

/**
 * Configure Google Sign In (called at app startup)
 */
export function configureGoogleSignIn(): void {
  if (!WEB_CLIENT_ID) {
    console.warn('Google Sign In: EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID not configured');
    return;
  }
  if (Platform.OS === 'ios' && !IOS_CLIENT_ID) {
    console.warn('Google Sign In: EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID not configured for iOS');
    return;
  }
  console.log('Google Sign In: Configured');
}

/**
 * Check if Google Sign In is available
 */
export async function isGoogleAuthAvailable(): Promise<boolean> {
  if (!isFirebaseConfigured()) return false;
  return isGoogleSignInConfigured();
}

/**
 * Get the reversed client ID for iOS OAuth redirect
 * The reversed client ID is used as the URL scheme for OAuth callbacks
 */
function getIOSReversedClientId(): string | undefined {
  if (!IOS_CLIENT_ID) return undefined;
  // iOS client ID format: XXX.apps.googleusercontent.com
  // Reversed format: com.googleusercontent.apps.XXX
  const parts = IOS_CLIENT_ID.split('.');
  if (parts.length >= 4) {
    // Extract the unique ID part (e.g., 421884826038-oi6sdgqco1g7umpogf1g2b754tpg80q8)
    const uniqueId = parts[0];
    return `com.googleusercontent.apps.${uniqueId}`;
  }
  return undefined;
}

/**
 * Get the Google auth request configuration
 * Only call this hook if isGoogleSignInConfigured() returns true
 */
export function useGoogleAuth() {
  // For iOS, use the reversed client ID as the redirect scheme
  // This is required for Google OAuth to properly redirect back to the app
  let redirectUri: string;

  if (Platform.OS === 'ios') {
    const reversedClientId = getIOSReversedClientId();
    if (reversedClientId) {
      redirectUri = `${reversedClientId}:/`;
    } else {
      redirectUri = makeRedirectUri({ scheme: 'haven' });
    }
  } else {
    redirectUri = makeRedirectUri({ scheme: 'haven' });
  }

  console.log('Google Auth redirect URI:', redirectUri);

  return Google.useAuthRequest({
    webClientId: WEB_CLIENT_ID,
    iosClientId: IOS_CLIENT_ID,
    androidClientId: ANDROID_CLIENT_ID,
    scopes: ['profile', 'email'],
    redirectUri,
  });
}

/**
 * Sign in with Google using the response from useGoogleAuth
 */
export async function handleGoogleAuthResponse(
  response: AuthSessionResult | null
): Promise<GoogleAuthResult> {
  if (!response) {
    return {
      success: false,
      error: 'No response from Google',
    };
  }

  if (response.type === 'cancel' || response.type === 'dismiss') {
    return {
      success: false,
      error: 'Sign in was cancelled',
    };
  }

  if (response.type !== 'success') {
    return {
      success: false,
      error: `Google sign in failed: ${response.type}`,
    };
  }

  try {
    const { id_token, access_token } = response.params;

    if (!id_token) {
      return {
        success: false,
        error: 'No ID token received from Google',
      };
    }

    // Create Firebase credential
    const credential = GoogleAuthProvider.credential(id_token, access_token);

    // Sign in to Firebase
    const auth = getFirebaseAuth();
    if (!auth) {
      return {
        success: false,
        error: 'Firebase is not configured',
      };
    }

    const userCredential = await signInWithCredential(auth, credential);
    const user = userCredential.user;

    return {
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
      },
    };
  } catch (error: any) {
    console.error('Google Sign In error:', error);
    return {
      success: false,
      error: error.message || 'Failed to sign in with Google',
    };
  }
}

/**
 * Sign out from Google (clears Firebase auth)
 */
export async function signOutGoogle(): Promise<void> {
  const auth = getFirebaseAuth();
  if (auth) {
    await auth.signOut();
  }
}

// Legacy function for backwards compatibility - now handled via hooks
export async function signInWithGoogle(): Promise<GoogleAuthResult> {
  return {
    success: false,
    error: 'Use useGoogleAuth hook and handleGoogleAuthResponse instead',
  };
}
