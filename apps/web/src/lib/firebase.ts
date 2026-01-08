import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import {
  getAuth,
  Auth,
  connectAuthEmulator,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
  onAuthStateChanged,
  signInWithPopup,
  GoogleAuthProvider,
  User as FirebaseUser,
} from 'firebase/auth';

// Firebase configuration from environment variables
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// Initialize Firebase (ensure single instance)
let firebaseApp: FirebaseApp | null = null;
let auth: Auth | null = null;

function getFirebaseApp(): FirebaseApp | null {
  // Prevent initialization on server
  if (typeof window === 'undefined') {
    return null;
  }

  if (firebaseApp) return firebaseApp;

  try {
    const apps = getApps();
    if (apps.length > 0) {
      firebaseApp = apps[0]!;
    } else {
      firebaseApp = initializeApp(firebaseConfig);
    }
  } catch (error) {
    console.error('Failed to initialize Firebase:', error);
    return null;
  }

  return firebaseApp;
}

export function getFirebaseAuth(): Auth | null {
  // Prevent initialization on server
  if (typeof window === 'undefined') {
    return null;
  }

  if (auth) return auth;

  try {
    const app = getFirebaseApp();
    if (!app) return null;

    auth = getAuth(app);

    // Connect to emulator in development if configured
    if (
      process.env.NODE_ENV === 'development' &&
      process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST
    ) {
      connectAuthEmulator(
        auth,
        `http://${process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST}`,
        { disableWarnings: true }
      );
    }
  } catch (error) {
    console.error('Failed to get Firebase Auth:', error);
    return null;
  }

  return auth;
}

/**
 * Sign in with email and password
 */
export async function signIn(email: string, password: string) {
  const auth = getFirebaseAuth();
  if (!auth) throw new Error('Firebase not initialized');
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
  if (!auth) throw new Error('Firebase not initialized');
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
  if (!auth) return;
  await firebaseSignOut(auth);
}

/**
 * Send password reset email
 */
export async function resetPassword(email: string) {
  const auth = getFirebaseAuth();
  if (!auth) throw new Error('Firebase not initialized');
  await sendPasswordResetEmail(auth, email);
}

/**
 * Sign in with Google using popup
 */
export async function signInWithGoogle() {
  const auth = getFirebaseAuth();
  if (!auth) throw new Error('Firebase not initialized');
  const provider = new GoogleAuthProvider();

  // Request additional scopes if needed
  provider.addScope('email');
  provider.addScope('profile');

  const result = await signInWithPopup(auth, provider);
  return result.user;
}

/**
 * Get the current Firebase ID token
 * Returns null if no user is signed in
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
 */
export function onAuthChange(
  callback: (user: FirebaseUser | null) => void
): () => void {
  const auth = getFirebaseAuth();
  if (!auth) {
    // Return a no-op unsubscribe function on server
    return () => {};
  }
  return onAuthStateChanged(auth, callback);
}

export type { FirebaseUser };
