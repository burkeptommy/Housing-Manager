// =============================================================================
// GOOGLE AUTH STUB
// @react-native-google-signin/google-signin is temporarily stubbed.
// The native module is not linked in Expo managed workflow without a config plugin.
// TODO: Add Google Sign-In Expo config plugin when ready
// =============================================================================

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

/**
 * Configure Google Sign In (no-op stub)
 */
export function configureGoogleSignIn(): void {
  console.log('Google Sign In: Stubbed - native module not available');
}

/**
 * Check if Google Sign In is available
 */
export async function isGoogleAuthAvailable(): Promise<boolean> {
  return false;
}

/**
 * Sign in with Google (stubbed)
 */
export async function signInWithGoogle(): Promise<GoogleAuthResult> {
  return {
    success: false,
    error: 'Google Sign In is not available in this build',
  };
}

/**
 * Sign out from Google (no-op stub)
 */
export async function signOutGoogle(): Promise<void> {
  // No-op
}
