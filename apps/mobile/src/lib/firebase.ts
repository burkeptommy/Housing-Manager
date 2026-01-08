import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import {
  initializeAuth,
  getAuth,
  Auth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
  onAuthStateChanged,
  User as FirebaseUser,
  // @ts-ignore - getReactNativePersistence is exported from firebase/auth in React Native
  getReactNativePersistence,
} from 'firebase/auth';
import ReactNativeAsyncStorage from '@react-native-async-storage/async-storage';

// Expo environment variable type declaration
declare const process: {
  env: {
    EXPO_PUBLIC_FIREBASE_API_KEY?: string;
    EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN?: string;
    EXPO_PUBLIC_FIREBASE_PROJECT_ID?: string;
    EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET?: string;
    EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID?: string;
    EXPO_PUBLIC_FIREBASE_APP_ID?: string;
  };
};

// Firebase configuration from environment variables
const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
};

/**
 * Check if Firebase is properly configured
 */
export function isFirebaseConfigured(): boolean {
  return Boolean(
    firebaseConfig.apiKey &&
    firebaseConfig.projectId &&
    firebaseConfig.apiKey.length > 10
  );
}

// Initialize Firebase (ensure single instance)
let firebaseApp: FirebaseApp | null = null;
let authInstance: Auth | null = null;

function getFirebaseApp(): FirebaseApp | null {
  if (firebaseApp) return firebaseApp;

  // Skip initialization if not configured
  if (!isFirebaseConfigured()) {
    console.log('Firebase: Skipping initialization - no valid configuration');
    return null;
  }

  try {
    const apps = getApps();
    if (apps.length > 0) {
      firebaseApp = apps[0]!;
    } else {
      firebaseApp = initializeApp(firebaseConfig);
    }
    return firebaseApp;
  } catch (error) {
    console.error('Firebase initialization failed:', error);
    return null;
  }
}

export function getFirebaseAuth(): Auth | null {
  if (authInstance) return authInstance;

  const app = getFirebaseApp();
  if (!app) {
    console.warn('Firebase: Auth not available - Firebase is not configured');
    return null;
  }

  try {
    // Use initializeAuth with AsyncStorage persistence for React Native
    authInstance = initializeAuth(app, {
      persistence: getReactNativePersistence(ReactNativeAsyncStorage),
    });
    return authInstance;
  } catch (error: any) {
    // If auth is already initialized, just get the existing instance
    if (error.code === 'auth/already-initialized') {
      authInstance = getAuth(app);
      return authInstance;
    }
    console.error('Firebase: Failed to get auth instance:', error);
    return null;
  }
}

// Legacy export for backwards compatibility - prefer getFirebaseAuth()
// Returns a proxy that safely handles missing Firebase configuration
export const auth = (() => {
  // Return a proxy that lazily initializes auth
  // This prevents crashes when importing before Firebase is ready
  return new Proxy({} as Auth, {
    get(_, prop) {
      const realAuth = getFirebaseAuth();
      if (!realAuth) {
        // Return safe no-op functions for common methods
        if (prop === 'currentUser') return null;
        if (typeof prop === 'string' && prop.startsWith('on')) {
          return () => () => {}; // Return a function that returns an unsubscribe function
        }
        return undefined;
      }
      return (realAuth as any)[prop];
    },
  });
})();

/**
 * Sign in with email and password
 */
export async function signIn(email: string, password: string) {
  const auth = getFirebaseAuth();
  if (!auth) {
    throw new Error('Firebase is not configured');
  }
  const credential = await signInWithEmailAndPassword(auth, email, password);
  return credential.user;
}

/**
 * Register a new user with email and password
 */
export async function signUp(
  email: string,
  password: string,
  displayName?: string
) {
  const auth = getFirebaseAuth();
  if (!auth) {
    throw new Error('Firebase is not configured');
  }
  const credential = await createUserWithEmailAndPassword(auth, email, password);

  // Update profile with display name if provided
  if (displayName && credential.user) {
    await updateProfile(credential.user, { displayName });
  }

  return credential.user;
}

/**
 * Sign out the current user
 */
export async function signOut() {
  const auth = getFirebaseAuth();
  if (!auth) {
    console.warn('Firebase: Cannot sign out - Firebase is not configured');
    return;
  }
  await firebaseSignOut(auth);
}

/**
 * Send password reset email
 */
export async function resetPassword(email: string) {
  const auth = getFirebaseAuth();
  if (!auth) {
    throw new Error('Firebase is not configured');
  }
  await sendPasswordResetEmail(auth, email);
}

/**
 * Get the current Firebase ID token
 * Returns null if no user is signed in or Firebase is not configured
 */
export async function getIdToken(forceRefresh = false): Promise<string | null> {
  const auth = getFirebaseAuth();
  if (!auth) return null;

  const user = auth.currentUser;
  if (!user) return null;

  return user.getIdToken(forceRefresh);
}

/**
 * Get the current user
 */
export function getCurrentUser(): FirebaseUser | null {
  const auth = getFirebaseAuth();
  if (!auth) return null;
  return auth.currentUser;
}

/**
 * Subscribe to auth state changes
 * Returns a no-op unsubscribe function if Firebase is not configured
 */
export function onAuthChange(
  callback: (user: FirebaseUser | null) => void
): () => void {
  const auth = getFirebaseAuth();
  if (!auth) {
    // Firebase not configured - call callback with null and return no-op unsubscribe
    console.warn('Firebase: Auth state listener not active - Firebase is not configured');
    // Call callback once with null to indicate no user
    setTimeout(() => callback(null), 0);
    return () => {};
  }
  return onAuthStateChanged(auth, callback);
}

export type { FirebaseUser };
