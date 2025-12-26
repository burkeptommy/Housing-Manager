# Claude Code Prompt: Phase 5 - Connect Onboarding to Real Auth System

## Context

The onboarding flow UI is built, but it's not connected to the real authentication system. The app uses:
- **Firebase** for authentication
- **Backend API** at `/api/me` for user data
- **AuthContext** at `apps/web/src/contexts/auth-context.tsx` with `register()`, `login()`, and `completeOnboarding()` functions

## Current Problems

1. The onboarding welcome page has a fake registration form that doesn't actually register users
2. After "registration", it redirects to login instead of continuing onboarding
3. The onboarding flow doesn't use the real `useAuth()` hook
4. At the end of onboarding, `completeOnboarding()` isn't called to create the household

## Desired Flow

```
User clicks "Get Started"
        ↓
/onboarding/welcome (Registration form)
        ↓
User fills form → calls useAuth().register()
        ↓
User is now logged in (Firebase + backend user created)
        ↓
/onboarding/choose-path (Select onboarding method)
        ↓
Either: Schedule call/visit OR Self-serve wizard
        ↓
/onboarding/wizard/* (Complete all steps)
        ↓
/onboarding/activation (Schedule activation call)
        ↓
/onboarding/complete → calls completeOnboarding() → redirects to /app
```

---

# PART 1: UPDATE ONBOARDING LAYOUT

The layout needs to:
1. Wrap children with OnboardingProvider (already done)
2. Check auth state and handle appropriately
3. NOT redirect away from onboarding if user needs it

```typescript
// apps/web/src/app/onboarding/layout.tsx

'use client';

import { usePathname } from 'next/navigation';
import { OnboardingHeader } from '@/components/onboarding/OnboardingHeader';
import { HelpFloatingButton } from '@/components/onboarding/HelpFloatingButton';
import { OnboardingProvider } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function OnboardingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, isLoading, isAuthenticated, needsOnboarding } = useAuth();
  
  // Don't show header on welcome page (it has its own branding)
  const showHeader = !pathname.includes('/onboarding/welcome');

  // Handle auth-based redirects
  useEffect(() => {
    if (isLoading) return;

    // If user is authenticated and DOESN'T need onboarding, send to dashboard
    if (isAuthenticated && !needsOnboarding && !pathname.includes('/onboarding/welcome')) {
      router.push('/app');
      return;
    }

    // If user is authenticated and on welcome page, skip to choose-path
    if (isAuthenticated && pathname.includes('/onboarding/welcome')) {
      router.push('/onboarding/choose-path');
      return;
    }
  }, [isLoading, isAuthenticated, needsOnboarding, pathname, router]);

  // Show loading state while checking auth
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-10 h-10 border-4 border-haven-champagne-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <OnboardingProvider>
      <div className="min-h-screen bg-gray-50">
        {showHeader && <OnboardingHeader />}
        <main className={showHeader ? 'pb-24' : ''}>
          {children}
        </main>
        <HelpFloatingButton />
      </div>
    </OnboardingProvider>
  );
}
```

---

# PART 2: UPDATE WELCOME PAGE TO USE REAL AUTH

The welcome page needs to use `useAuth().register()` for real registration:

```typescript
// apps/web/src/app/onboarding/welcome/page.tsx

'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowRight, Eye, EyeOff, Home, Check, Shield, Users, AlertCircle } from 'lucide-react';
import { useAuth } from '@/contexts/auth-context';
import { useOnboarding } from '@/context/OnboardingContext';

export default function OnboardingWelcomePage() {
  const router = useRouter();
  const { register, isLoading: authLoading } = useAuth();
  const { addFamilyMember } = useOnboarding();
  
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const formatPhone = (value: string) => {
    const cleaned = value.replace(/\D/g, '');
    if (cleaned.length <= 3) return cleaned;
    if (cleaned.length <= 6) return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3)}`;
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6, 10)}`;
  };

  const handlePhoneChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPhone(formatPhone(e.target.value));
  };

  const validate = () => {
    const newErrors: Record<string, string> = {};
    if (!firstName.trim()) newErrors.firstName = 'First name is required';
    if (!lastName.trim()) newErrors.lastName = 'Last name is required';
    if (!email.trim()) newErrors.email = 'Email is required';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) newErrors.email = 'Please enter a valid email';
    if (!password) newErrors.password = 'Password is required';
    if (password.length < 8) newErrors.password = 'Password must be at least 8 characters';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    setErrors({});

    try {
      // Register with Firebase + backend using the auth context
      const displayName = `${firstName} ${lastName}`.trim();
      await register(email, password, displayName);
      
      // Add the user as a family member in onboarding context
      addFamilyMember({
        id: 'primary-user',
        type: 'adult',
        firstName,
        lastName,
        email,
        phone: phone || undefined,
        relationship: 'head_of_household',
      });

      // Registration successful - redirect to choose path
      // The auth system will keep them logged in
      router.push('/onboarding/choose-path');
    } catch (err: any) {
      console.error('Registration error:', err);
      
      // Handle specific Firebase errors
      if (err.code === 'auth/email-already-in-use') {
        setErrors({ email: 'This email is already registered. Please sign in instead.' });
      } else if (err.code === 'auth/weak-password') {
        setErrors({ password: 'Password is too weak. Please use a stronger password.' });
      } else if (err.code === 'auth/invalid-email') {
        setErrors({ email: 'Please enter a valid email address.' });
      } else {
        setErrors({ submit: err.message || 'Something went wrong. Please try again.' });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const isLoading = isSubmitting || authLoading;

  return (
    <div className="min-h-screen flex">
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-haven-navy-950 text-white flex-col justify-between p-12 relative overflow-hidden">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 left-0 w-96 h-96 bg-haven-champagne-500 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-haven-champagne-500 rounded-full blur-3xl translate-x-1/2 translate-y-1/2" />
        </div>

        {/* Logo */}
        <div className="relative z-10">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-haven-champagne-500 rounded-xl flex items-center justify-center">
              <Home className="w-5 h-5 text-haven-navy-900" />
            </div>
            <span className="text-2xl font-bold">Haven</span>
          </Link>
        </div>

        {/* Main Message */}
        <div className="relative z-10 space-y-6">
          <h1 className="text-4xl font-bold leading-tight">
            Your home,
            <br />
            <span className="text-haven-champagne-400">handled.</span>
          </h1>
          <p className="text-lg text-white/70 max-w-md">
            Join thousands of homeowners who've reclaimed their time with Haven's full-service home management.
          </p>

          {/* Benefits */}
          <div className="space-y-4 pt-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-haven-champagne-500/20 flex items-center justify-center">
                <Check className="w-4 h-4 text-haven-champagne-400" />
              </div>
              <span className="text-white/80">One bill for everything</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-haven-champagne-500/20 flex items-center justify-center">
                <Check className="w-4 h-4 text-haven-champagne-400" />
              </div>
              <span className="text-white/80">Dedicated Home Manager</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-haven-champagne-500/20 flex items-center justify-center">
                <Check className="w-4 h-4 text-haven-champagne-400" />
              </div>
              <span className="text-white/80">Free onboarding & home visit</span>
            </div>
          </div>
        </div>

        {/* Trust Indicators */}
        <div className="relative z-10 flex items-center gap-6 text-white/50 text-sm">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4" />
            <span>Bank-level security</span>
          </div>
          <div className="flex items-center gap-2">
            <Users className="w-4 h-4" />
            <span>500+ happy families</span>
          </div>
        </div>
      </div>

      {/* Right Side - Registration Form */}
      <div className="flex-1 flex items-center justify-center p-8 bg-gray-50">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden mb-8 text-center">
            <Link href="/" className="inline-flex items-center gap-3">
              <div className="w-10 h-10 bg-haven-navy-900 rounded-xl flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="text-2xl font-bold text-haven-navy-900">Haven</span>
            </Link>
          </div>

          {/* Header */}
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-haven-navy-900">Create your account</h2>
            <p className="text-gray-600 mt-2">Get started with Haven in minutes</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {errors.submit && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm flex items-start gap-3">
                <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
                <span>{errors.submit}</span>
              </div>
            )}

            {/* Name Fields */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  First name
                </label>
                <input
                  type="text"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className={`w-full px-4 py-3 rounded-xl border transition-all outline-none focus:ring-2 focus:ring-haven-champagne-200 ${
                    errors.firstName ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-haven-champagne-500'
                  }`}
                  placeholder="Bob"
                  disabled={isLoading}
                />
                {errors.firstName && (
                  <p className="text-red-600 text-xs mt-1">{errors.firstName}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Last name
                </label>
                <input
                  type="text"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className={`w-full px-4 py-3 rounded-xl border transition-all outline-none focus:ring-2 focus:ring-haven-champagne-200 ${
                    errors.lastName ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-haven-champagne-500'
                  }`}
                  placeholder="Morrison"
                  disabled={isLoading}
                />
                {errors.lastName && (
                  <p className="text-red-600 text-xs mt-1">{errors.lastName}</p>
                )}
              </div>
            </div>

            {/* Email */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={`w-full px-4 py-3 rounded-xl border transition-all outline-none focus:ring-2 focus:ring-haven-champagne-200 ${
                  errors.email ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-haven-champagne-500'
                }`}
                placeholder="bob@example.com"
                disabled={isLoading}
              />
              {errors.email && (
                <p className="text-red-600 text-xs mt-1">{errors.email}</p>
              )}
            </div>

            {/* Phone */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Phone <span className="text-gray-400 font-normal">(optional)</span>
              </label>
              <input
                type="tel"
                value={phone}
                onChange={handlePhoneChange}
                className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all"
                placeholder="(203) 555-0100"
                disabled={isLoading}
              />
            </div>

            {/* Password */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className={`w-full px-4 py-3 rounded-xl border transition-all outline-none focus:ring-2 focus:ring-haven-champagne-200 pr-12 ${
                    errors.password ? 'border-red-300 focus:border-red-500' : 'border-gray-300 focus:border-haven-champagne-500'
                  }`}
                  placeholder="••••••••"
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              {errors.password && (
                <p className="text-red-600 text-xs mt-1">{errors.password}</p>
              )}
              <p className="text-gray-400 text-xs mt-1.5">Must be at least 8 characters</p>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3.5 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed mt-6"
            >
              {isLoading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  Create account
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>

            {/* Divider */}
            <div className="relative my-6">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-3 bg-gray-50 text-gray-500">or continue with</span>
              </div>
            </div>

            {/* Social Login */}
            <button
              type="button"
              disabled={isLoading}
              className="w-full border border-gray-300 hover:bg-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-3 transition-colors bg-white disabled:opacity-50"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Continue with Google
            </button>

            {/* Terms */}
            <p className="text-xs text-gray-500 text-center mt-4">
              By creating an account, you agree to our{' '}
              <Link href="/terms" className="text-haven-navy-900 hover:underline">Terms of Service</Link>
              {' '}and{' '}
              <Link href="/privacy" className="text-haven-navy-900 hover:underline">Privacy Policy</Link>
            </p>
          </form>

          {/* Sign In Link */}
          <p className="text-center text-gray-600 mt-8">
            Already have an account?{' '}
            <Link
              href="/login"
              className="text-haven-navy-900 hover:text-haven-navy-700 font-semibold"
            >
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
```

---

# PART 3: UPDATE COMPLETE PAGE TO FINISH ONBOARDING

The complete page needs to call `completeOnboarding()` to create the household:

```typescript
// apps/web/src/app/onboarding/complete/page.tsx

'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { 
  PartyPopper, 
  Home, 
  MessageSquare, 
  ArrowRight,
  CheckCircle,
  Calendar,
  User,
  Sparkles,
  Loader2,
} from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';

export default function CompletePage() {
  const router = useRouter();
  const { data } = useOnboarding();
  const { user, completeOnboarding, isLoading: authLoading } = useAuth();
  
  const [isCompleting, setIsCompleting] = useState(false);
  const [isComplete, setIsComplete] = useState(false);
  const [showConfetti, setShowConfetti] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Get first name from family members or user
  const firstName = data.familyMembers.find(m => m.type === 'adult')?.firstName || user?.firstName || 'there';

  // Complete the onboarding process
  const handleCompleteOnboarding = useCallback(async () => {
    if (isCompleting || isComplete) return;
    
    setIsCompleting(true);
    setError(null);

    try {
      // Create household data from onboarding data
      // The completeOnboarding function will create the household in the backend
      
      // For now, we need to create the household via API first
      // Then call completeOnboarding with the household ID
      
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api'}/households`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            // Token should be set by auth context
          },
          credentials: 'include',
          body: JSON.stringify({
            name: data.property?.propertyName || `${firstName}'s Home`,
            address: data.property?.address?.formatted,
            // Add more data as needed
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to create household');
      }

      const household = await response.json();
      
      // Complete onboarding with the new household ID
      await completeOnboarding(household.id);
      
      setIsComplete(true);
      setShowConfetti(true);
      
      // Stop confetti after 5 seconds
      setTimeout(() => setShowConfetti(false), 5000);
      
    } catch (err: any) {
      console.error('Error completing onboarding:', err);
      setError(err.message || 'Something went wrong. Please try again.');
      setIsCompleting(false);
    }
  }, [isCompleting, isComplete, data, firstName, completeOnboarding]);

  // Auto-complete on mount (or show manual button if needed)
  useEffect(() => {
    // Don't auto-complete - let user click the button
    // This gives them a moment to see the celebration
  }, []);

  if (authLoading) {
    return (
      <div className="min-h-[calc(100vh-80px)] flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-10 h-10 text-haven-champagne-500 animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center px-4 py-12 relative overflow-hidden">
      {/* Confetti - using CSS animation instead of library for simplicity */}
      {showConfetti && (
        <div className="fixed inset-0 pointer-events-none z-50">
          {[...Array(50)].map((_, i) => (
            <div
              key={i}
              className="absolute animate-confetti"
              style={{
                left: `${Math.random() * 100}%`,
                top: '-10px',
                animationDelay: `${Math.random() * 3}s`,
                animationDuration: `${3 + Math.random() * 2}s`,
              }}
            >
              <div
                className="w-3 h-3 rounded-sm"
                style={{
                  backgroundColor: ['#c4a574', '#102a43', '#faf6ed', '#d4c4a5', '#243b53'][Math.floor(Math.random() * 5)],
                  transform: `rotate(${Math.random() * 360}deg)`,
                }}
              />
            </div>
          ))}
        </div>
      )}

      <div className="max-w-2xl w-full relative z-10">
        {/* Hero */}
        <div className="text-center mb-10">
          <div className="relative inline-block mb-6">
            <div className="w-24 h-24 bg-gradient-to-br from-haven-champagne-400 to-haven-champagne-600 rounded-3xl flex items-center justify-center mx-auto shadow-lg">
              <PartyPopper className="w-12 h-12 text-white" />
            </div>
            <div className="absolute -top-2 -right-2 w-10 h-10 bg-green-500 rounded-full flex items-center justify-center shadow-md">
              <CheckCircle className="w-6 h-6 text-white" />
            </div>
          </div>
          <h1 className="text-4xl font-bold text-haven-navy-900 mb-3">
            Welcome to Haven, {firstName}!
          </h1>
          <p className="text-xl text-gray-600">
            You're all set. Time to stop managing your home and start living in it.
          </p>
        </div>

        {/* Error State */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-2xl p-6 mb-8 text-center">
            <p className="text-red-700 mb-4">{error}</p>
            <button
              onClick={handleCompleteOnboarding}
              className="px-6 py-2 bg-red-600 text-white rounded-xl hover:bg-red-700 transition-colors"
            >
              Try Again
            </button>
          </div>
        )}

        {/* Activation Call Reminder */}
        {data.activationCallAt && (
          <div className="bg-haven-champagne-50 border border-haven-champagne-200 rounded-2xl p-6 mb-8">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-haven-champagne-100 rounded-xl flex items-center justify-center flex-shrink-0">
                <Calendar className="w-6 h-6 text-haven-champagne-600" />
              </div>
              <div>
                <h3 className="font-semibold text-haven-navy-900">Activation call scheduled!</h3>
                <p className="text-sm text-gray-600 mt-1">
                  Check your email for the calendar invite. We'll review everything and get your Haven Wallet set up.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Your Home Manager */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-haven-champagne-400 to-haven-champagne-600 flex items-center justify-center">
              <User className="w-8 h-8 text-white" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Your Home Manager</p>
              <h3 className="text-xl font-semibold text-haven-navy-900">Sarah Chen</h3>
            </div>
          </div>
          <p className="text-gray-600 mb-4">
            Sarah is your dedicated point of contact at Haven. Need something? Just text or call her — 
            she handles everything from there.
          </p>
          <div className="flex gap-3">
            <a
              href="sms:+15083338630"
              className="flex-1 py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors"
            >
              <MessageSquare className="w-4 h-4" />
              Text Sarah
            </a>
            <a
              href="tel:+15083338630"
              className="flex-1 py-3 px-4 border border-gray-200 text-haven-navy-900 rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
            >
              Call Sarah
            </a>
          </div>
        </div>

        {/* What's Next */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-8">
          <h3 className="font-semibold text-haven-navy-900 mb-4 flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-haven-champagne-500" />
            What happens next
          </h3>
          <div className="space-y-4">
            <div className="flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-haven-navy-100 flex items-center justify-center flex-shrink-0 text-sm font-semibold text-haven-navy-900">
                1
              </div>
              <div>
                <p className="font-medium text-haven-navy-900">Activation call</p>
                <p className="text-sm text-gray-500">We'll finalize your setup and fund your Haven Wallet</p>
              </div>
            </div>
            <div className="flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-haven-navy-100 flex items-center justify-center flex-shrink-0 text-sm font-semibold text-haven-navy-900">
                2
              </div>
              <div>
                <p className="font-medium text-haven-navy-900">We take over your bills</p>
                <p className="text-sm text-gray-500">Sarah will coordinate transferring bill payments to Haven</p>
              </div>
            </div>
            <div className="flex items-start gap-4">
              <div className="w-8 h-8 rounded-full bg-haven-navy-100 flex items-center justify-center flex-shrink-0 text-sm font-semibold text-haven-navy-900">
                3
              </div>
              <div>
                <p className="font-medium text-haven-navy-900">Relax</p>
                <p className="text-sm text-gray-500">We handle everything — you just live in your home</p>
              </div>
            </div>
          </div>
        </div>

        {/* CTA */}
        {!isComplete ? (
          <button
            onClick={handleCompleteOnboarding}
            disabled={isCompleting}
            className="w-full py-4 px-6 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors disabled:opacity-50"
          >
            {isCompleting ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Setting up your account...
              </>
            ) : (
              <>
                <Home className="w-5 h-5" />
                Complete setup & go to dashboard
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        ) : (
          <Link
            href="/app"
            className="w-full py-4 px-6 bg-haven-navy-900 text-white rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-haven-navy-800 transition-colors"
          >
            <Home className="w-5 h-5" />
            Go to your dashboard
            <ArrowRight className="w-4 h-4" />
          </Link>
        )}

        {/* Contact */}
        <p className="text-center text-sm text-gray-500 mt-8">
          Questions? Call us anytime at{' '}
          <a href="tel:508-333-8630" className="text-haven-navy-900 font-medium hover:underline">
            (508) 333-8630
          </a>
        </p>
      </div>

      {/* Confetti Animation Styles */}
      <style jsx>{`
        @keyframes confetti-fall {
          0% {
            transform: translateY(-10px) rotate(0deg);
            opacity: 1;
          }
          100% {
            transform: translateY(100vh) rotate(720deg);
            opacity: 0;
          }
        }
        .animate-confetti {
          animation: confetti-fall linear forwards;
        }
      `}</style>
    </div>
  );
}
```

---

# PART 4: UPDATE LOGIN PAGE TO USE REAL AUTH

```typescript
// apps/web/src/app/login/page.tsx

'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, ArrowRight, Home, Shield, Clock, Users, AlertCircle } from 'lucide-react';
import { useAuth } from '@/contexts/auth-context';

export default function LoginPage() {
  const router = useRouter();
  const { login, isAuthenticated, isLoading: authLoading, needsOnboarding } = useAuth();
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  // Redirect if already authenticated
  useEffect(() => {
    if (!authLoading && isAuthenticated) {
      if (needsOnboarding) {
        router.push('/onboarding/choose-path');
      } else {
        router.push('/app');
      }
    }
  }, [authLoading, isAuthenticated, needsOnboarding, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    try {
      await login(email, password);
      // Auth context will handle redirect based on needsOnboarding
    } catch (err: any) {
      console.error('Login error:', err);
      
      // Handle specific Firebase errors
      if (err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password') {
        setError('Invalid email or password');
      } else if (err.code === 'auth/too-many-requests') {
        setError('Too many failed attempts. Please try again later.');
      } else if (err.code === 'auth/user-disabled') {
        setError('This account has been disabled. Please contact support.');
      } else {
        setError(err.message || 'Something went wrong. Please try again.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const isLoading = isSubmitting || authLoading;

  // Show loading while checking auth state
  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="w-10 h-10 border-4 border-haven-champagne-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex">
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-haven-navy-950 text-white flex-col justify-between p-12 relative overflow-hidden">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 left-0 w-96 h-96 bg-haven-champagne-500 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-haven-champagne-500 rounded-full blur-3xl translate-x-1/2 translate-y-1/2" />
        </div>

        {/* Logo */}
        <div className="relative z-10">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-haven-champagne-500 rounded-xl flex items-center justify-center">
              <Home className="w-5 h-5 text-haven-navy-900" />
            </div>
            <span className="text-2xl font-bold">Haven</span>
          </Link>
        </div>

        {/* Main Message */}
        <div className="relative z-10 space-y-6">
          <h1 className="text-4xl font-bold leading-tight">
            Stop managing your home.
            <br />
            <span className="text-haven-champagne-400">Start living in it.</span>
          </h1>
          <p className="text-lg text-white/70 max-w-md">
            One payment. One contact. Zero hassle. Your dedicated Home Manager handles everything.
          </p>

          {/* Feature Pills */}
          <div className="flex flex-wrap gap-3 pt-4">
            <div className="flex items-center gap-2 bg-white/10 rounded-full px-4 py-2">
              <Shield className="w-4 h-4 text-haven-champagne-400" />
              <span className="text-sm">Bill Management</span>
            </div>
            <div className="flex items-center gap-2 bg-white/10 rounded-full px-4 py-2">
              <Clock className="w-4 h-4 text-haven-champagne-400" />
              <span className="text-sm">24/7 Support</span>
            </div>
            <div className="flex items-center gap-2 bg-white/10 rounded-full px-4 py-2">
              <Users className="w-4 h-4 text-haven-champagne-400" />
              <span className="text-sm">Dedicated Manager</span>
            </div>
          </div>
        </div>

        {/* Testimonial */}
        <div className="relative z-10">
          <blockquote className="text-white/80 italic">
            "Haven gave me back my weekends. No more chasing contractors or juggling bills."
          </blockquote>
          <div className="mt-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-haven-champagne-500/20 flex items-center justify-center text-haven-champagne-400 font-semibold">
              SM
            </div>
            <div>
              <p className="text-sm font-medium">Sarah M.</p>
              <p className="text-xs text-white/50">Greenwich, CT</p>
            </div>
          </div>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="flex-1 flex items-center justify-center p-8 bg-gray-50">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden mb-8 text-center">
            <Link href="/" className="inline-flex items-center gap-3">
              <div className="w-10 h-10 bg-haven-navy-900 rounded-xl flex items-center justify-center">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="text-2xl font-bold text-haven-navy-900">Haven</span>
            </Link>
          </div>

          {/* Header */}
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-haven-navy-900">Welcome back</h2>
            <p className="text-gray-600 mt-2">Sign in to your Haven account</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm flex items-start gap-3">
                <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all"
                  placeholder="you@example.com"
                  required
                  disabled={isLoading}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Password
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all pr-12"
                    placeholder="••••••••"
                    required
                    disabled={isLoading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    tabIndex={-1}
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>
            </div>

            {/* Forgot Password */}
            <div className="flex justify-end">
              <Link
                href="/forgot-password"
                className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700 font-medium"
              >
                Forgot password?
              </Link>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  Sign in
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>

            {/* Divider */}
            <div className="relative my-6">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-3 bg-gray-50 text-gray-500">or continue with</span>
              </div>
            </div>

            {/* Social Login */}
            <button
              type="button"
              disabled={isLoading}
              className="w-full border border-gray-300 hover:bg-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-3 transition-colors bg-white disabled:opacity-50"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Continue with Google
            </button>
          </form>

          {/* Sign Up Link */}
          <p className="text-center text-gray-600 mt-8">
            Don't have an account?{' '}
            <Link
              href="/onboarding/welcome"
              className="text-haven-navy-900 hover:text-haven-navy-700 font-semibold"
            >
              Get started
            </Link>
          </p>

          {/* Support */}
          <p className="text-center text-sm text-gray-400 mt-6">
            Need help?{' '}
            <a href="tel:508-333-8630" className="text-haven-champagne-600 hover:underline">
              (508) 333-8630
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}
```

---

# PART 5: UPDATE ONBOARDING ENTRY PAGE

```typescript
// apps/web/src/app/onboarding/page.tsx

'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { Loader2 } from 'lucide-react';

export default function OnboardingPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading, needsOnboarding } = useAuth();

  useEffect(() => {
    if (isLoading) return;

    if (!isAuthenticated) {
      // Not logged in - go to registration
      router.push('/onboarding/welcome');
    } else if (!needsOnboarding) {
      // Already completed onboarding - go to dashboard
      router.push('/app');
    } else {
      // Needs onboarding - go to choose path
      router.push('/onboarding/choose-path');
    }
  }, [isLoading, isAuthenticated, needsOnboarding, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <Loader2 className="w-10 h-10 text-haven-champagne-500 animate-spin mx-auto mb-4" />
        <p className="text-gray-500">Loading...</p>
      </div>
    </div>
  );
}
```

---

# PART 6: FIX AUTH CONTEXT ROUTING

The auth context has some routing logic that might conflict. We need to make sure it doesn't redirect away from onboarding pages while the user is in the onboarding flow.

Look at `apps/web/src/contexts/auth-context.tsx` and find the routing useEffect. Update it to allow users to stay in onboarding:

```typescript
// In the useEffect that handles routing, update the logic:

// Handle routing based on auth state
useEffect(() => {
  if (!isInitialized || isLoading) return;

  const path = window.location.pathname;

  // Allow public pages
  const publicPaths = ['/', '/login', '/register', '/forgot-password', '/terms', '/privacy'];
  const isPublicPath = publicPaths.some(p => path === p || path.startsWith('/pricing'));
  
  // Allow onboarding pages for authenticated users who need onboarding
  const isOnboardingPath = path.startsWith('/onboarding');

  if (!user) {
    // Not authenticated
    // Allow public paths and onboarding welcome (registration)
    if (!isPublicPath && !path.startsWith('/onboarding/welcome')) {
      // Redirect protected pages to login
      if (path.startsWith('/app') || path.startsWith('/manager') || path.startsWith('/admin') || path.startsWith('/handyman') || path.startsWith('/vendor')) {
        router.push('/login');
      }
    }
    return;
  }

  // User is authenticated from here on

  // If on login/register, redirect to appropriate place
  if (path === '/login' || path === '/register') {
    if (needsOnboarding) {
      router.push('/onboarding/choose-path');
    } else {
      router.push('/app');
    }
    return;
  }

  // If user needs onboarding, allow them to stay in onboarding flow
  if (needsOnboarding && isOnboardingPath) {
    // Let them continue onboarding
    return;
  }

  // If user needs onboarding but is trying to access /app, redirect to onboarding
  if (needsOnboarding && path.startsWith('/app')) {
    router.push('/onboarding/choose-path');
    return;
  }

  // If user doesn't need onboarding but is in onboarding flow, let them finish
  // (This handles the case where they just completed registration)
  if (!needsOnboarding && isOnboardingPath) {
    // They can stay - they're probably on the complete page
    // The complete page will redirect them when they click the button
    return;
  }

  // ... rest of role-based routing
}, [isInitialized, isLoading, user, needsOnboarding, router]);
```

---

# VERIFICATION CHECKLIST

After implementation, test this complete flow:

1. ✅ Go to `/onboarding/welcome` - Should show registration form
2. ✅ Fill out form and submit - Should call `useAuth().register()`
3. ✅ After registration - Should redirect to `/onboarding/choose-path`
4. ✅ User should stay logged in throughout onboarding
5. ✅ Complete wizard steps
6. ✅ Go to activation page - Schedule call
7. ✅ Go to complete page - Click "Complete setup"
8. ✅ Should create household and redirect to `/app`
9. ✅ Test login page with existing user - Should work and redirect appropriately
10. ✅ Test that users who need onboarding can't access `/app` directly
11. ✅ `pnpm build` completes without errors

## Important: Check for TypeScript Errors

Run `pnpm build` and fix any type errors, especially around:
- `useAuth()` hook usage
- `useOnboarding()` context usage
- Firebase error types
