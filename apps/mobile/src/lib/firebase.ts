import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import {
  getAuth,
  Auth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
  onAuthStateChanged,
  User as FirebaseUser,
} from 'firebase/auth';

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

// Initialize Firebase (ensure single instance)
let firebaseApp: FirebaseApp;
let auth: Auth;

function getFirebaseApp(): FirebaseApp {
  if (firebaseApp) return firebaseApp;

  const apps = getApps();
  if (apps.length > 0) {
    firebaseApp = apps[0]!;
  } else {
    firebaseApp = initializeApp(firebaseConfig);
  }

  return firebaseApp;
}

export function getFirebaseAuth(): Auth {
  if (auth) return auth;

  const app = getFirebaseApp();
  auth = getAuth(app);

  return auth;
}

/**
 * Sign in with email and password
 */
export async function signIn(email: string, password: string) {
  const authInstance = getFirebaseAuth();
  const credential = await signInWithEmailAndPassword(authInstance, email, password);
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
  const authInstance = getFirebaseAuth();
  const credential = await createUserWithEmailAndPassword(authInstance, email, password);

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
  const authInstance = getFirebaseAuth();
  await firebaseSignOut(authInstance);
}

/**
 * Send password reset email
 */
export async function resetPassword(email: string) {
  const authInstance = getFirebaseAuth();
  await sendPasswordResetEmail(authInstance, email);
}

/**
 * Get the current Firebase ID token
 * Returns null if no user is signed in
 */
export async function getIdToken(forceRefresh = false): Promise<string | null> {
  const authInstance = getFirebaseAuth();
  const user = authInstance.currentUser;

  if (!user) return null;

  return user.getIdToken(forceRefresh);
}

/**
 * Get the current user
 */
export function getCurrentUser(): FirebaseUser | null {
  const authInstance = getFirebaseAuth();
  return authInstance.currentUser;
}

/**
 * Subscribe to auth state changes
 */
export function onAuthChange(
  callback: (user: FirebaseUser | null) => void
): () => void {
  const authInstance = getFirebaseAuth();
  return onAuthStateChanged(authInstance, callback);
}

export type { FirebaseUser };
