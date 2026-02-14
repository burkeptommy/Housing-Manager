'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  CheckCircle,
  Circle,
  ArrowRight,
  ArrowLeft,
  Sparkles,
  Loader2,
  Home,
  X,
  MessageCircle,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';
import { useOnboarding } from '@/context/OnboardingContext';

interface ChecklistItem {
  id: string;
  category: string;
  priority: 'high' | 'medium' | 'low';
  question: string;
  context?: string;
  inputType: string;
  options?: string[];
  answered: boolean;
  answer?: string;
}

export default function HomeSetupPage() {
  const router = useRouter();
  const { data } = useOnboarding();

  const [checklist, setChecklist] = useState<ChecklistItem[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [inputValue, setInputValue] = useState('');
  const [isComplete, setIsComplete] = useState(false);

  useEffect(() => {
    fetchChecklist();
  }, []);

  const fetchChecklist = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      // Get address from onboarding context
      const property = data.property;
      const enrichment = data.propertyEnrichment;

      const response = await fetch(`${apiUrl}/property/checklist/generate`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          street: property?.address?.street || '',
          city: property?.address?.city || '',
          state: property?.address?.state || '',
          zip: property?.address?.zipCode || '',
          propertyData: enrichment,
        }),
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          // Filter to high/medium priority only for self-service
          const relevantItems = result.checklist
            .filter((item: ChecklistItem) => item.priority !== 'low')
            .map((item: ChecklistItem) => ({
              ...item,
              answered: false,
              answer: '',
            }));
          setChecklist(relevantItems);
        }
      }
    } catch (error) {
      console.error('Error fetching checklist:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const currentItem = checklist[currentIndex];
  const progress = checklist.length > 0 ? ((currentIndex + 1) / checklist.length) * 100 : 0;
  const answeredCount = checklist.filter((c) => c.answered).length;

  const handleAnswer = useCallback((answer: string) => {
    // Save answer
    setChecklist((prev) =>
      prev.map((item, idx) =>
        idx === currentIndex ? { ...item, answer, answered: true } : item
      )
    );

    // Move to next or finish
    if (currentIndex < checklist.length - 1) {
      setCurrentIndex((prev) => prev + 1);
      setInputValue('');
    } else {
      // Complete!
      handleComplete();
    }
  }, [currentIndex, checklist.length]);

  const handleSkip = () => {
    if (currentIndex < checklist.length - 1) {
      setCurrentIndex((prev) => prev + 1);
      setInputValue('');
    } else {
      handleComplete();
    }
  };

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex((prev) => prev - 1);
      setInputValue(checklist[currentIndex - 1]?.answer || '');
    }
  };

  const handleComplete = async () => {
    setIsComplete(true);
    // TODO: Save all answers to API
  };

  const handleLetManagerHandle = () => {
    router.push('/app');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-600 mx-auto mb-4" />
          <p className="text-gray-500">Preparing your questionnaire...</p>
        </div>
      </div>
    );
  }

  if (isComplete) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="w-full max-w-lg bg-white rounded-2xl p-8 shadow-lg text-center">
          <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <CheckCircle className="w-10 h-10 text-emerald-600" />
          </div>

          <h1 className="text-2xl font-bold text-haven-900 mb-2">
            Thank you!
          </h1>

          <p className="text-gray-500 mb-8">
            You answered {answeredCount} of {checklist.length} questions.
            Your Home Manager will follow up on any remaining items.
          </p>

          <button
            onClick={() => router.push('/app')}
            className="w-full bg-haven-900 text-white py-3 rounded-xl font-medium hover:bg-haven-800 transition"
          >
            Go to Dashboard
          </button>
        </div>
      </div>
    );
  }

  if (!currentItem) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="text-center">
          <Home className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500">No questions to answer right now.</p>
          <button
            onClick={() => router.push('/app')}
            className="mt-4 text-haven-600 hover:text-haven-700 font-medium"
          >
            Go to Dashboard →
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-4 py-3">
        <div className="max-w-lg mx-auto flex items-center justify-between">
          <button
            onClick={() => router.push('/app')}
            className="p-2 text-gray-400 hover:text-gray-600 transition"
          >
            <X className="w-5 h-5" />
          </button>
          <div className="text-sm text-gray-500">
            {currentIndex + 1} of {checklist.length}
          </div>
          <div className="w-9" /> {/* Spacer for alignment */}
        </div>
      </div>

      {/* Progress Bar */}
      <div className="bg-white px-4 pb-4">
        <div className="max-w-lg mx-auto">
          <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-haven-500 transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-lg">
          {/* Question Card */}
          <div className="bg-white rounded-2xl p-8 shadow-lg">
            {currentItem.context && (
              <div className="flex items-center gap-2 text-sm text-haven-600 mb-4">
                <Sparkles className="w-4 h-4" />
                {currentItem.context}
              </div>
            )}

            <h2 className="text-xl font-bold text-haven-900 mb-6">
              {currentItem.question}
            </h2>

            {/* Input based on type */}
            {currentItem.inputType === 'select' && currentItem.options ? (
              <div className="space-y-2">
                {currentItem.options.map((opt) => (
                  <button
                    key={opt}
                    onClick={() => handleAnswer(opt)}
                    className="w-full text-left px-4 py-3 border border-gray-200 rounded-xl hover:border-haven-500 hover:bg-haven-50 transition flex items-center justify-between group"
                  >
                    <span>{opt}</span>
                    <ArrowRight className="w-4 h-4 text-gray-300 group-hover:text-haven-500 transition" />
                  </button>
                ))}
              </div>
            ) : (
              <div className="space-y-4">
                <input
                  type={currentItem.inputType === 'date' ? 'month' : 'text'}
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  placeholder={
                    currentItem.inputType === 'vendor'
                      ? 'Company name or "I don\'t have one"'
                      : 'Type your answer...'
                  }
                  className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:border-haven-500 focus:ring-2 focus:ring-haven-100 outline-none transition"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && inputValue) {
                      handleAnswer(inputValue);
                    }
                  }}
                />
                <button
                  onClick={() => inputValue && handleAnswer(inputValue)}
                  disabled={!inputValue}
                  className="w-full bg-haven-900 text-white py-3 rounded-xl font-medium hover:bg-haven-800 transition flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Continue
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* Navigation */}
            <div className="mt-6 pt-4 border-t flex justify-between items-center">
              {currentIndex > 0 ? (
                <button
                  onClick={handlePrevious}
                  className="flex items-center gap-1 text-gray-400 hover:text-gray-600 text-sm transition"
                >
                  <ArrowLeft className="w-4 h-4" />
                  Back
                </button>
              ) : (
                <div />
              )}
              <button
                onClick={handleSkip}
                className="text-gray-400 hover:text-gray-600 text-sm transition"
              >
                Skip this
              </button>
            </div>
          </div>

          {/* Let Manager Handle Button */}
          <button
            onClick={handleLetManagerHandle}
            className="w-full mt-6 py-3 text-haven-600 hover:text-haven-700 text-sm font-medium transition flex items-center justify-center gap-2"
          >
            <MessageCircle className="w-4 h-4" />
            Let my Home Manager handle the rest
          </button>
        </div>
      </div>

      {/* Footer with answered count */}
      <div className="bg-white border-t border-gray-100 px-4 py-3">
        <div className="max-w-lg mx-auto flex items-center justify-center gap-2 text-sm text-gray-400">
          <CheckCircle className="w-4 h-4" />
          {answeredCount} answered
        </div>
      </div>
    </div>
  );
}
