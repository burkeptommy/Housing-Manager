import * as AppleAuthentication from 'expo-apple-authentication';
import * as Crypto from 'expo-crypto';
import { OAuthProvider, signInWithCredential } from 'firebase/auth';
import { getFirebaseAuth, isFirebaseConfigured } from './firebase';

/**
 * Apple Sign In for Haven
 *
 * Flow:
 * 1. Generate nonce for security
 * 2. Request Apple credentials
 * 3. Create Firebase credential
 * 4. Sign in to Firebase
 */

export interface AppleAuthResult {
  success: boolean;
  user?: {
    uid: string;
    email: string | null;
    displayName: string | null;
  };
  error?: string;
}

/**
 * Generate a random nonce for Apple Sign In
 */
async function generateNonce(length = 32): Promise<string> {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  let result = '';
  const randomValues = await Crypto.getRandomBytesAsync(length);
  for (let i = 0; i < length; i++) {
    result += charset[randomValues[i] % charset.length];
  }
  return result;
}

/**
 * Hash the nonce using SHA256
 */
async function sha256(input: string): Promise<string> {
  return await Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, input);
}

/**
 * Check if Apple Sign In is available on this device
 */
export async function isAppleAuthAvailable(): Promise<boolean> {
  // Not available if Firebase is not configured
  if (!isFirebaseConfigured()) {
    return false;
  }
  return await AppleAuthentication.isAvailableAsync();
}

/**
 * Sign in with Apple
 */
export async function signInWithApple(): Promise<AppleAuthResult> {
  try {
    // Check availability
    const isAvailable = await isAppleAuthAvailable();
    if (!isAvailable) {
      return {
        success: false,
        error: 'Apple Sign In is not available on this device',
      };
    }

    // Generate nonce
    const rawNonce = await generateNonce();
    const hashedNonce = await sha256(rawNonce);

    // Request Apple credentials
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
      nonce: hashedNonce,
    });

    if (!credential.identityToken) {
      return {
        success: false,
        error: 'No identity token received from Apple',
      };
    }

    // Create Firebase credential
    const provider = new OAuthProvider('apple.com');
    const firebaseCredential = provider.credential({
      idToken: credential.identityToken,
      rawNonce,
    });

    // Sign in to Firebase
    const auth = getFirebaseAuth();
    if (!auth) {
      return {
        success: false,
        error: 'Firebase is not configured',
      };
    }
    const userCredential = await signInWithCredential(auth, firebaseCredential);
    const user = userCredential.user;

    // Apple only provides name on first sign in, so we need to handle that
    let displayName = user.displayName;
    if (!displayName && credential.fullName) {
      const { givenName, familyName } = credential.fullName;
      if (givenName || familyName) {
        displayName = [givenName, familyName].filter(Boolean).join(' ');
        // Note: You might want to update the user profile here
      }
    }

    return {
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName,
      },
    };
  } catch (error: any) {
    // Handle specific Apple auth errors
    if (error.code === 'ERR_REQUEST_CANCELED') {
      return {
        success: false,
        error: 'Sign in was cancelled',
      };
    }

    console.error('Apple Sign In error:', error);
    return {
      success: false,
      error: error.message || 'Failed to sign in with Apple',
    };
  }
}
