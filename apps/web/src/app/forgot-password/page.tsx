'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Mail, CheckCircle } from 'lucide-react';

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
      // TODO: Implement actual password reset logic with Firebase
      await new Promise(resolve => setTimeout(resolve, 1000));
      setIsSubmitted(true);
    } catch {
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
          <Link href="/" className="inline-flex items-center">
            <img
              src="/logo-wordmark.svg"
              alt="Haven"
              className="h-9 w-auto"
            />
          </Link>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8">
          {!isSubmitted ? (
            <>
              {/* Header */}
              <div className="text-center mb-6">
                <div className="w-14 h-14 bg-haven-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <Mail className="w-7 h-7 text-haven-600" />
                </div>
                <h1 className="text-2xl font-bold text-haven-900">Reset your password</h1>
                <p className="text-gray-600 mt-2">
                  Enter your email and we&apos;ll send you a link to reset your password.
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
                    className="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-haven-500 focus:ring-2 focus:ring-haven-200 outline-none transition-all"
                    placeholder="you@example.com"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full bg-haven-900 hover:bg-haven-800 text-white py-3 px-4 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors disabled:opacity-50"
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
              <h2 className="text-2xl font-bold text-haven-900 mb-2">Check your email</h2>
              <p className="text-gray-600 mb-6">
                We&apos;ve sent a password reset link to <strong>{email}</strong>
              </p>
              <p className="text-sm text-gray-500">
                Didn&apos;t receive the email? Check your spam folder or{' '}
                <button
                  onClick={() => setIsSubmitted(false)}
                  className="text-haven-600 hover:text-haven-700 font-medium"
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
              className="flex items-center justify-center gap-2 text-gray-600 hover:text-haven-900 font-medium transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to sign in
            </Link>
          </div>
        </div>

        {/* Support */}
        <p className="text-center text-sm text-gray-500 mt-6">
          Need help?{' '}
          <a href="tel:508-333-8630" className="text-haven-600 hover:underline">
            (508) 333-8630
          </a>
        </p>
      </div>
    </div>
  );
}
