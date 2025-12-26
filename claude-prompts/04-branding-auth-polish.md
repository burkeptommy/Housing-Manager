# Claude Code Prompt: Phase 4 - Branding, Auth Flow & Polish

## Context

Phases 1-3 built the onboarding flow structure, wizard pages, and scheduling integration. Phase 4 focuses on:
1. Beautiful, branded login/register pages
2. Connecting registration to onboarding flow
3. Consistent Haven branding throughout
4. Polish and visual refinement

**Project Location:** `/Users/tomburke/Projects/Housing-Manager/`
**Web App Location:** `apps/web/src/`

## Haven Brand Guidelines (CRITICAL)

### Colors
```
Navy (Primary):
- navy-950: #0a1929 (darkest - hero backgrounds)
- navy-900: #102a43 (primary buttons, headings)
- navy-800: #243b53 (secondary elements)
- navy-700: #334e68 (hover states)

Champagne (Accent):
- champagne-500: #c4a574 (primary accent, CTAs)
- champagne-400: #d4c4a5 (hover states)
- champagne-300: #e9dcc4 (light accents)
- champagne-100: #faf6ed (subtle backgrounds)

NO BRIGHT GREEN - This is deprecated.
```

### Brand Voice
- **Tagline:** "Stop managing your home. Start living in it."
- **Tone:** Warm, professional, reassuring
- **Key message:** Service, not software. We do the work for you.

---

# PART 1: BRANDED LOGIN PAGE

Create a beautiful, branded login page:

```typescript
// apps/web/src/app/login/page.tsx

'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, ArrowRight, Home, Shield, Clock, Users } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // TODO: Implement actual login logic
      // For now, simulate login
      await new Promise(resolve => setTimeout(resolve, 1000));
      router.push('/app');
    } catch (err) {
      setError('Invalid email or password');
    } finally {
      setIsLoading(false);
    }
  };

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
              <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                {error}
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
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
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
              className="w-full border border-gray-300 hover:bg-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-3 transition-colors bg-white"
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

# PART 2: REDIRECT REGISTER TO ONBOARDING

Create a redirect from /register to /onboarding/welcome:

```typescript
// apps/web/src/app/register/page.tsx

import { redirect } from 'next/navigation';

export default function RegisterPage() {
  redirect('/onboarding/welcome');
}
```

---

# PART 3: ENHANCED ONBOARDING WELCOME PAGE (REGISTRATION)

Update the welcome page to be a proper branded registration page:

```typescript
// apps/web/src/app/onboarding/welcome/page.tsx

'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowRight, Eye, EyeOff, Home, Check, Shield, Clock, Users } from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';

export default function OnboardingWelcomePage() {
  const router = useRouter();
  const { setTier } = useOnboarding();
  
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
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

    setIsLoading(true);

    try {
      // TODO: Implement actual registration logic
      // For now, simulate registration
      await new Promise(resolve => setTimeout(resolve, 1000));
      router.push('/onboarding/choose-path');
    } catch (err) {
      setErrors({ submit: 'Something went wrong. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

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
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
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
              className="w-full border border-gray-300 hover:bg-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-3 transition-colors bg-white"
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

# PART 4: UPDATE ONBOARDING LAYOUT

Remove the default header for welcome page since it has its own branding:

```typescript
// apps/web/src/app/onboarding/layout.tsx

'use client';

import { usePathname } from 'next/navigation';
import { OnboardingHeader } from '@/components/onboarding/OnboardingHeader';
import { HelpFloatingButton } from '@/components/onboarding/HelpFloatingButton';
import { OnboardingProvider } from '@/context/OnboardingContext';

export default function OnboardingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  
  // Don't show header on welcome page (it has its own branding)
  const showHeader = !pathname.includes('/onboarding/welcome');

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

# PART 5: UPDATE HOMEPAGE CTA BUTTONS

Find and update any "Get Started" or registration links on the homepage to point to `/onboarding/welcome`:

```typescript
// Look for these patterns in apps/web/src/app/page.tsx and update them:

// CHANGE FROM:
href="/register"
// CHANGE TO:
href="/onboarding/welcome"

// CHANGE FROM:
href="/signup"
// CHANGE TO:
href="/onboarding/welcome"

// Also update any navigation components that might have register links
```

Search for and update these files:
- `apps/web/src/app/page.tsx` (homepage)
- `apps/web/src/components/Header.tsx` or similar navigation components
- `apps/web/src/components/Navbar.tsx` if it exists
- Any marketing/landing page components

---

# PART 6: FORGOT PASSWORD PAGE (BRANDED)

```typescript
// apps/web/src/app/forgot-password/page.tsx

'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Mail, CheckCircle, Home } from 'lucide-react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // TODO: Implement actual password reset logic
      await new Promise(resolve => setTimeout(resolve, 1000));
      setIsSubmitted(true);
    } catch (err) {
      setError('Something went wrong. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <Link href="/" className="inline-flex items-center gap-3">
            <div className="w-10 h-10 bg-haven-navy-900 rounded-xl flex items-center justify-center">
              <Home className="w-5 h-5 text-white" />
            </div>
            <span className="text-2xl font-bold text-haven-navy-900">Haven</span>
          </Link>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8">
          {!isSubmitted ? (
            <>
              {/* Header */}
              <div className="text-center mb-6">
                <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <Mail className="w-7 h-7 text-haven-champagne-600" />
                </div>
                <h1 className="text-2xl font-bold text-haven-navy-900">Reset your password</h1>
                <p className="text-gray-600 mt-2">
                  Enter your email and we'll send you a link to reset your password.
                </p>
              </div>

              {/* Form */}
              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                    {error}
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email address
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-200 outline-none transition-all"
                    placeholder="you@example.com"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors disabled:opacity-50"
                >
                  {isLoading ? (
                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    'Send reset link'
                  )}
                </button>
              </form>
            </>
          ) : (
            /* Success State */
            <div className="text-center py-4">
              <div className="w-14 h-14 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="w-7 h-7 text-green-600" />
              </div>
              <h2 className="text-2xl font-bold text-haven-navy-900 mb-2">Check your email</h2>
              <p className="text-gray-600 mb-6">
                We've sent a password reset link to <strong>{email}</strong>
              </p>
              <p className="text-sm text-gray-500">
                Didn't receive the email? Check your spam folder or{' '}
                <button
                  onClick={() => setIsSubmitted(false)}
                  className="text-haven-champagne-600 hover:text-haven-champagne-700 font-medium"
                >
                  try again
                </button>
              </p>
            </div>
          )}

          {/* Back to Login */}
          <div className="mt-6 pt-6 border-t border-gray-200">
            <Link
              href="/login"
              className="flex items-center justify-center gap-2 text-gray-600 hover:text-haven-navy-900 font-medium transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to sign in
            </Link>
          </div>
        </div>

        {/* Support */}
        <p className="text-center text-sm text-gray-500 mt-6">
          Need help?{' '}
          <a href="tel:508-333-8630" className="text-haven-champagne-600 hover:underline">
            (508) 333-8630
          </a>
        </p>
      </div>
    </div>
  );
}
```

---

# PART 7: UPDATE ONBOARDING HEADER STYLING

Ensure the onboarding header matches the brand:

```typescript
// apps/web/src/components/onboarding/OnboardingHeader.tsx

'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Home } from 'lucide-react';
import { TierComparisonModal } from './TierComparisonModal';

export function OnboardingHeader() {
  const [showTierModal, setShowTierModal] = useState(false);

  return (
    <>
      <header className="bg-white border-b border-gray-200 sticky top-0 z-30">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          {/* Haven Logo */}
          <Link href="/" className="flex items-center gap-2.5">
            <div className="w-9 h-9 bg-haven-navy-900 rounded-lg flex items-center justify-center">
              <Home className="w-4 h-4 text-white" />
            </div>
            <span className="text-xl font-bold text-haven-navy-900">Haven</span>
          </Link>

          {/* Pricing Link */}
          <button
            onClick={() => setShowTierModal(true)}
            className="text-sm text-gray-500 hover:text-haven-navy-900 transition-colors font-medium"
          >
            Compare plans
          </button>
        </div>
      </header>

      {/* Tier Modal */}
      {showTierModal && (
        <TierComparisonModal onClose={() => setShowTierModal(false)} />
      )}
    </>
  );
}
```

---

# PART 8: ENHANCE TIER COMPARISON MODAL

```typescript
// apps/web/src/components/onboarding/TierComparisonModal.tsx

'use client';

import { X, Check, Star } from 'lucide-react';
import { cn } from '@/lib/utils';

interface TierComparisonModalProps {
  onClose: () => void;
}

export function TierComparisonModal({ onClose }: TierComparisonModalProps) {
  const tiers = [
    {
      name: 'Essentials',
      price: 39,
      description: 'Track & organize',
      features: [
        'Bill consolidation dashboard',
        'Payment tracking & reminders',
        'Maintenance schedule',
        'Document storage',
      ],
      notIncluded: [
        'Dedicated Home Manager',
        'Bill payment service',
        'Vendor coordination',
      ],
    },
    {
      name: 'Lite',
      price: 349,
      description: 'Text-based support',
      features: [
        'Everything in Essentials',
        'Text your Home Manager',
        'Reactive support',
        'Basic vendor coordination',
      ],
      notIncluded: [
        'Proactive management',
        'Monthly handyman hours',
      ],
    },
    {
      name: 'Haven',
      price: 749,
      description: 'Full-service management',
      popular: true,
      features: [
        'Everything in Lite',
        'Proactive Home Manager',
        'We pay all your bills',
        'Full vendor coordination',
        '2 handyman hours/month',
        'Priority support',
      ],
      notIncluded: [],
    },
    {
      name: 'Haven+',
      price: 1499,
      description: 'Lifestyle services',
      features: [
        'Everything in Haven',
        '4 handyman hours/month',
        'Errand running',
        'Package handling',
        'Lifestyle concierge',
        'Guest preparation',
      ],
      notIncluded: [],
    },
    {
      name: 'Estate',
      price: 3499,
      description: 'Multi-property, white-glove',
      features: [
        'Everything in Haven+',
        'Multiple properties',
        'Dedicated team',
        '8 handyman hours/month',
        'Seasonal home prep',
        'Full estate management',
      ],
      notIncluded: [],
    },
  ];

  return (
    <div 
      className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4 overflow-y-auto"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="bg-white rounded-2xl max-w-5xl w-full max-h-[90vh] overflow-y-auto my-8">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10">
          <div>
            <h2 className="text-xl font-bold text-haven-navy-900">Compare plans</h2>
            <p className="text-sm text-gray-500">Choose the level of service that's right for you</p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Plans Grid */}
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {tiers.map((tier) => (
              <div
                key={tier.name}
                className={cn(
                  'rounded-2xl border-2 p-5 relative flex flex-col',
                  tier.popular
                    ? 'border-haven-champagne-500 bg-haven-champagne-50'
                    : 'border-gray-200 bg-white'
                )}
              >
                {/* Popular Badge */}
                {tier.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-haven-champagne-500 text-haven-navy-900 text-xs font-semibold px-3 py-1 rounded-full flex items-center gap-1">
                    <Star className="w-3 h-3" />
                    Most Popular
                  </div>
                )}

                {/* Tier Name */}
                <h3 className="text-lg font-bold text-haven-navy-900 mt-1">
                  {tier.name}
                </h3>
                
                {/* Price */}
                <div className="mt-2">
                  <span className="text-3xl font-bold text-haven-navy-900">
                    ${tier.price}
                  </span>
                  <span className="text-gray-500">/mo</span>
                </div>
                
                {/* Description */}
                <p className="text-sm text-gray-600 mt-1">{tier.description}</p>

                {/* Features */}
                <ul className="mt-4 space-y-2 flex-1">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2 text-sm">
                      <Check className="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">{feature}</span>
                    </li>
                  ))}
                  {tier.notIncluded.map((feature) => (
                    <li key={feature} className="flex items-start gap-2 text-sm opacity-50">
                      <X className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-500">{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          {/* Footer Note */}
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">
              All plans include free onboarding call or home visit.{' '}
              <a href="tel:508-333-8630" className="text-haven-champagne-600 hover:underline font-medium">
                Call us
              </a>
              {' '}to discuss which plan is right for you.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

# PART 9: FIX ANY REMAINING GREEN COLORS

Search the codebase for any remaining green that should be champagne or navy:

```bash
# Run this to find remaining green colors
grep -rn --include="*.tsx" --include="*.ts" -E "(bg-green|text-green|bg-emerald|text-emerald|#10b981|#22c55e|#059669)" apps/web/src/

# Exception: Keep green ONLY for success states like checkmarks, "Paid", "Confirmed"
```

Replace non-success green with appropriate Haven colors.

---

# VERIFICATION CHECKLIST

After implementation, verify:

1. ✅ `/login` page is beautifully branded with split layout
2. ✅ `/register` redirects to `/onboarding/welcome`
3. ✅ `/onboarding/welcome` is a full registration page with branding
4. ✅ `/forgot-password` exists and is branded
5. ✅ Homepage "Get Started" links go to `/onboarding/welcome`
6. ✅ Onboarding header shows Haven logo correctly
7. ✅ Tier comparison modal is comprehensive
8. ✅ All phone numbers show 508-333-8630
9. ✅ No bright green colors (except success states)
10. ✅ Mobile responsive on all auth pages
11. ✅ `pnpm build` completes without errors

## Test Auth Flow

1. Go to `/` → Click "Get Started" → Should go to `/onboarding/welcome`
2. On welcome page → Click "Sign in" → Should go to `/login`
3. On login page → Click "Forgot password" → Should go to `/forgot-password`
4. On login page → Click "Get started" → Should go to `/onboarding/welcome`
5. On forgot password → Click "Back to sign in" → Should go to `/login`
