'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowRight, Eye, EyeOff, Leaf, Check, Shield, Users } from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';
import { useAuth } from '@/contexts/auth-context';

export default function OnboardingWelcomePage() {
  const router = useRouter();
  const { addFamilyMember } = useOnboarding();
  const { register, signInWithGoogle, isAuthenticated, isLoading: authLoading } = useAuth();

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // If user is already authenticated, redirect to choose-path
  // This runs in useEffect so it doesn't block rendering
  useEffect(() => {
    if (!authLoading && isAuthenticated) {
      router.push('/onboarding/choose-path');
    }
  }, [authLoading, isAuthenticated, router]);

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
      // Register the user with Firebase
      const displayName = `${firstName} ${lastName}`;
      await register(email, password, displayName);

      // Add the user as the first family member (primary account holder)
      addFamilyMember({
        type: 'adult',
        firstName,
        lastName,
        email,
        phone: phone.replace(/\D/g, ''),
        isPrimary: true,
      });

      router.push('/onboarding/choose-path');
    } catch (err: unknown) {
      // Handle Firebase error codes
      const errorObj = err as { code?: string; message?: string };
      let message = 'Something went wrong. Please try again.';

      if (errorObj.code === 'auth/email-already-in-use') {
        message = 'This email is already registered. Please sign in instead.';
      } else if (errorObj.code === 'auth/weak-password') {
        message = 'Password is too weak. Please use a stronger password.';
      } else if (errorObj.code === 'auth/invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (errorObj.message) {
        message = errorObj.message;
      }

      setErrors({ submit: message });
    } finally {
      setIsSubmitting(false);
    }
  };

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

  // Always render the form - don't block on auth loading
  // Auth is only needed for the submit action and redirect check

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
              <Leaf className="w-5 h-5 text-haven-navy-900" />
            </div>
            <span className="text-2xl font-bold">Haven</span>
          </Link>
        </div>

        {/* Main Message */}
        <div className="relative z-10 space-y-6">
          <h1 className="text-4xl font-bold leading-tight text-white">
            Your home,
            <br />
            <span className="text-haven-champagne-400">handled.</span>
          </h1>
          <p className="text-lg text-white/70 max-w-md">
            Join thousands of homeowners who&apos;ve reclaimed their time with Haven&apos;s full-service home management.
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
                <Leaf className="w-5 h-5 text-white" />
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
              <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                {errors.submit}
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
                  disabled={isSubmitting}
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
                  disabled={isSubmitting}
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
                disabled={isSubmitting}
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
                disabled={isSubmitting}
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
                  disabled={isSubmitting}
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
              disabled={isSubmitting}
              className="w-full bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3.5 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed mt-6"
            >
              {isSubmitting ? (
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
