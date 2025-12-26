# Prompt 06: Add Google Sign-In and Prepare for Production

## Context
Haven is ready for production deployment to havenhome.dev. We need to:
1. Add Google Sign-In functionality (Firebase Google Auth is already configured)
2. Ensure the "Continue with Google" buttons work on welcome and login pages

## Firebase Google OAuth Already Configured
- Project: home-manager-480616
- OAuth Client ID: 421884826038-j17pdc6q3loa7kr13evbiaraq0d8cnef.apps.googleusercontent.com
- Google provider is enabled in Firebase Authentication

## Tasks

### Task 1: Update firebase.ts to add Google Sign-In

**File:** `apps/web/src/lib/firebase.ts`

Add these imports at the top:
```typescript
import {
  // ... existing imports ...
  signInWithPopup,
  GoogleAuthProvider,
} from 'firebase/auth';
```

Add this new function:
```typescript
/**
 * Sign in with Google using popup
 */
export async function signInWithGoogle() {
  const auth = getFirebaseAuth();
  const provider = new GoogleAuthProvider();
  
  // Request additional scopes if needed
  provider.addScope('email');
  provider.addScope('profile');
  
  const result = await signInWithPopup(auth, provider);
  return result.user;
}
```

### Task 2: Update auth-context.tsx to expose Google Sign-In

**File:** `apps/web/src/contexts/auth-context.tsx`

1. Import the new function:
```typescript
import {
  signIn as firebaseSignIn,
  signUp as firebaseSignUp,
  signOut as firebaseSignOut,
  signInWithGoogle as firebaseSignInWithGoogle,  // ADD THIS
  onAuthChange,
  getIdToken,
  type FirebaseUser,
} from '@/lib/firebase';
```

2. Add to the AuthContextValue interface:
```typescript
interface AuthContextValue {
  // ... existing fields ...
  signInWithGoogle: () => Promise<void>;  // ADD THIS
}
```

3. Add the signInWithGoogle function in the AuthProvider:
```typescript
const signInWithGoogle = useCallback(async () => {
  setIsLoading(true);
  
  try {
    const fbUser = await firebaseSignInWithGoogle();
    
    // Get the token and set it immediately so API calls work
    if (fbUser) {
      const token = await fbUser.getIdToken();
      setFirebaseToken(token);
    }
    
    // Wait for the auth state callback to complete
    await new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('Google sign-in timeout - please try again'));
      }, 10000);
      
      const checkReady = setInterval(() => {
        const tokenSet = sessionStorage.getItem('haven_firebase_token');
        if (tokenSet) {
          clearInterval(checkReady);
          clearTimeout(timeout);
          resolve();
        }
      }, 50);
    });
  } catch (error) {
    setIsLoading(false);
    throw error;
  }
}, []);
```

4. Add to the provider value:
```typescript
<AuthContext.Provider
  value={{
    // ... existing values ...
    signInWithGoogle,  // ADD THIS
  }}
>
```

### Task 3: Wire up the Google button on the Welcome page

**File:** `apps/web/src/app/onboarding/welcome/page.tsx`

1. Get signInWithGoogle from useAuth:
```typescript
const { register, signInWithGoogle, isAuthenticated, isLoading: authLoading } = useAuth();
```

2. Add a handler for Google sign-in:
```typescript
const handleGoogleSignIn = async () => {
  setIsSubmitting(true);
  setErrors({});
  
  try {
    await signInWithGoogle();
    router.push('/onboarding/choose-path');
  } catch (err: unknown) {
    const errorObj = err as { code?: string; message?: string };
    let message = 'Google sign-in failed. Please try again.';
    
    if (errorObj.code === 'auth/popup-closed-by-user') {
      message = 'Sign-in was cancelled.';
    } else if (errorObj.code === 'auth/popup-blocked') {
      message = 'Popup was blocked. Please allow popups and try again.';
    } else if (errorObj.message) {
      message = errorObj.message;
    }
    
    setErrors({ submit: message });
  } finally {
    setIsSubmitting(false);
  }
};
```

3. Update the Google button to use the handler:
```typescript
<button
  type="button"
  onClick={handleGoogleSignIn}
  disabled={isSubmitting}
  className="w-full border border-gray-300 hover:bg-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-3 transition-colors bg-white disabled:opacity-50"
>
  <svg className="w-5 h-5" viewBox="0 0 24 24">
    <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
    <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
    <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
    <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
  </svg>
  {isSubmitting ? 'Signing in...' : 'Continue with Google'}
</button>
```

### Task 4: Wire up the Google button on the Login page

**File:** `apps/web/src/app/login/page.tsx`

Apply the same pattern:
1. Get `signInWithGoogle` from `useAuth()`
2. Add `handleGoogleSignIn` handler
3. Update the Google button onClick

### Task 5: Verify the build works

Run:
```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

Ensure there are no TypeScript errors.

## Expected Result
- Google Sign-In buttons work on both welcome and login pages
- Users can sign in with their Google account
- After Google sign-in, the backend creates/finds the user via Firebase UID
- New Google users are directed to onboarding
- Existing Google users go to their dashboard

## Notes
- The backend Firebase Auth Guard already handles finding/creating users by Firebase UID
- Google users will have their email and displayName populated from their Google account
- The onAuthChange listener will trigger fetchMe() which syncs with the backend
