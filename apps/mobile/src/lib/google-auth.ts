import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';
import { getFirebaseAuth, isFirebaseConfigured } from './firebase';
import { makeRedirectUri, type AuthSessionResult } from 'expo-auth-session';

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
 * Configure Google Sign In (called at app startup)
 */
export function configureGoogleSignIn(): void {
  if (!WEB_CLIENT_ID) {
    console.warn('Google Sign In: EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID not configured');
    return;
  }
  console.log('Google Sign In: Configured with web client');
}

/**
 * Check if Google Sign In is available
 */
export async function isGoogleAuthAvailable(): Promise<boolean> {
  // Available if Firebase is configured and we have a client ID
  if (!isFirebaseConfigured()) {
    return false;
  }
  return !!WEB_CLIENT_ID;
}

/**
 * Get the Google auth request configuration
 */
export function useGoogleAuth() {
  // Create redirect URI using the app's custom scheme
  // For production iOS: uses the app's scheme (haven://)
  // For Expo Go: uses the Expo proxy automatically
  const redirectUri = makeRedirectUri({
    scheme: 'haven',
  });

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
