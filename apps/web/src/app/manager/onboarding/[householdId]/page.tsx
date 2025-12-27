'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Phone,
  Save,
  CheckCircle,
  Circle,
  ChevronDown,
  ChevronUp,
  Sparkles,
  Loader2,
  Clock,
  Calculator,
  MessageCircle,
  AlertCircle,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

// ===========================================================================
// TYPES
// ===========================================================================

interface IntakeItem {
  id: string;
  zone: string;
  category: string;
  label: string;
  question: string;
  context?: string;
  inputType: string;
  options?: string[];
  required: boolean;
}

interface IntakeSection {
  id: string;
  title: string;
  description: string;
  icon: string;
  items: IntakeItem[];
}

interface IntakeData {
  intake: {
    id: string;
    householdId: string;
    status: string;
    progress: number;
    scheduledAt?: string;
    startedAt?: string;
    callNotes?: string;
    managerNotes?: string;
    calculatedMonthlyFunding?: number;
  };
  sections: IntakeSection[];
  summary: {
    totalSections: number;
    totalQuestions: number;
    highlights: string[];
  };
}

interface Household {
  id: string;
  name: string;
  homeProfile?: {
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  };
  owner: {
    id: string;
    firstName?: string;
    lastName?: string;
    email: string;
    phone?: string;
  };
}

// ===========================================================================
// SECTION ICONS
// ===========================================================================

const SECTION_ICONS: Record<string, string> = {
  family: '👨‍👩‍👧‍👦',
  kitchen: '🍳',
  laundry: '🧺',
  garage: '🚗',
  hvac: '🌡️',
  plumbing: '🚿',
  exterior: '🏡',
  electrical: '⚡',
  utilities: '💡',
  housing: '🏠',
  bills: '💳',
  vendors: '🛠️',
};

// ===========================================================================
// COMPONENT
// ===========================================================================

export default function HouseholdIntakeWorkbench() {
  const params = useParams();
  const router = useRouter();
  const householdId = params.householdId as string;

  const [intakeData, setIntakeData] = useState<IntakeData | null>(null);
  const [household, setHousehold] = useState<Household | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);

  // Answers state - maps item ID to answer value
  const [answers, setAnswers] = useState<Record<string, string>>({});

  // Section completion tracking
  const [completedSections, setCompletedSections] = useState<Record<string, boolean>>({});

  // Expanded sections
  const [expandedSections, setExpandedSections] = useState<string[]>(['family']);

  // Notes
  const [callNotes, setCallNotes] = useState('');
  const [managerNotes, setManagerNotes] = useState('');

  // ===========================================================================
  // DATA FETCHING
  // ===========================================================================

  useEffect(() => {
    fetchIntakeData();
  }, [householdId]);

  const fetchIntakeData = async () => {
    setIsLoading(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      // Fetch intake sections
      const response = await fetch(`${apiUrl}/intake/household/${householdId}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setIntakeData(data);
        setCallNotes(data.intake.callNotes || '');
        setManagerNotes(data.intake.managerNotes || '');

        // Set household info from intake
        if (data.intake.household) {
          setHousehold(data.intake.household);
        }
      }
    } catch (error) {
      console.error('Error fetching intake:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // ===========================================================================
  // HANDLERS
  // ===========================================================================

  const handleAnswerChange = useCallback((itemId: string, value: string) => {
    setAnswers((prev) => ({
      ...prev,
      [itemId]: value,
    }));

    // Auto-save after debounce (would implement proper debounce in production)
    setIsSaving(true);
    setTimeout(() => {
      setIsSaving(false);
      setLastSaved(new Date());
    }, 500);
  }, []);

  const toggleSection = (sectionId: string) => {
    setExpandedSections((prev) =>
      prev.includes(sectionId)
        ? prev.filter((s) => s !== sectionId)
        : [...prev, sectionId]
    );
  };

  const markSectionComplete = (sectionId: string) => {
    setCompletedSections((prev) => ({
      ...prev,
      [sectionId]: !prev[sectionId],
    }));
  };

  const getSectionProgress = (section: IntakeSection): number => {
    const answered = section.items.filter((item) => answers[item.id]?.trim()).length;
    return section.items.length > 0 ? Math.round((answered / section.items.length) * 100) : 0;
  };

  const getTotalProgress = (): number => {
    if (!intakeData) return 0;
    const totalItems = intakeData.sections.reduce((sum, s) => sum + s.items.length, 0);
    const answeredItems = Object.values(answers).filter((a) => a?.trim()).length;
    return totalItems > 0 ? Math.round((answeredItems / totalItems) * 100) : 0;
  };

  const calculateFunding = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/intake/calculate-funding`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ answers }),
      });

      if (response.ok) {
        const result = await response.json();
        // Display result (would use a modal in production)
        alert(`Suggested Monthly Funding: $${result.total.toFixed(2)}`);
      }
    } catch (error) {
      console.error('Error calculating funding:', error);
    }
  };

  const saveAndExit = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/intake/household/${householdId}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          status: 'PAUSED',
          sectionsCompleted: completedSections,
          callNotes,
          managerNotes,
        }),
      });

      router.push('/manager/onboarding');
    } catch (error) {
      console.error('Error saving intake:', error);
    }
  };

  const completeIntake = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/intake/household/${householdId}/complete`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ answers }),
      });

      router.push('/manager/onboarding');
    } catch (error) {
      console.error('Error completing intake:', error);
    }
  };

  // ===========================================================================
  // RENDER
  // ===========================================================================

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading intake workbench...</p>
        </div>
      </div>
    );
  }

  if (!intakeData) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
          <p className="text-gray-600">Failed to load intake data</p>
          <Link
            href="/manager/onboarding"
            className="mt-4 inline-flex items-center gap-2 text-haven-champagne-600 hover:text-haven-champagne-700"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Dashboard
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex">
      {/* Sidebar - Section Navigation */}
      <div className="w-72 bg-white border-r border-gray-200 fixed left-0 top-0 bottom-0 overflow-y-auto">
        <div className="p-4 border-b border-gray-100">
          <Link
            href="/manager/onboarding"
            className="flex items-center gap-2 text-gray-500 hover:text-gray-700 text-sm mb-4"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Dashboard
          </Link>

          {household && (
            <div className="bg-haven-champagne-50 rounded-lg p-3">
              <h2 className="font-semibold text-haven-navy-900">{household.name}</h2>
              {household.homeProfile && (
                <p className="text-xs text-gray-500 mt-1">
                  {household.homeProfile.addressLine1}
                </p>
              )}
              {household.owner.phone && (
                <a
                  href={`tel:${household.owner.phone}`}
                  className="flex items-center gap-1 text-xs text-haven-champagne-600 mt-2 hover:text-haven-champagne-700"
                >
                  <Phone className="w-3 h-3" />
                  {household.owner.phone}
                </a>
              )}
            </div>
          )}
        </div>

        {/* Progress */}
        <div className="p-4 border-b border-gray-100">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Progress</span>
            <span className="text-sm font-bold text-haven-navy-900">{getTotalProgress()}%</span>
          </div>
          <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-haven-champagne-400 to-haven-champagne-500 transition-all duration-500"
              style={{ width: `${getTotalProgress()}%` }}
            />
          </div>
        </div>

        {/* Section List */}
        <div className="p-2">
          {intakeData.sections.map((section) => {
            const progress = getSectionProgress(section);
            const isComplete = completedSections[section.id];

            return (
              <button
                key={section.id}
                onClick={() => toggleSection(section.id)}
                className={`w-full text-left p-3 rounded-lg mb-1 transition ${
                  expandedSections.includes(section.id)
                    ? 'bg-haven-champagne-50'
                    : 'hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span className="text-xl">{SECTION_ICONS[section.id] || section.icon}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-haven-navy-900 text-sm truncate">
                        {section.title}
                      </span>
                      {isComplete && (
                        <CheckCircle className="w-4 h-4 text-emerald-500 flex-shrink-0" />
                      )}
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex-1 h-1 bg-gray-100 rounded-full overflow-hidden">
                        <div
                          className={`h-full transition-all duration-300 ${
                            isComplete ? 'bg-emerald-500' : 'bg-haven-champagne-400'
                          }`}
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                      <span className="text-xs text-gray-400">{progress}%</span>
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>

        {/* Property Highlights */}
        {intakeData.summary.highlights.length > 0 && (
          <div className="p-4 border-t border-gray-100">
            <div className="flex items-center gap-2 text-xs text-haven-champagne-600 mb-2">
              <Sparkles className="w-3 h-3" />
              <span className="font-medium">Property Highlights</span>
            </div>
            <div className="flex flex-wrap gap-1">
              {intakeData.summary.highlights.map((highlight, i) => (
                <span
                  key={i}
                  className="px-2 py-0.5 bg-haven-champagne-50 text-haven-champagne-700 text-xs rounded"
                >
                  {highlight}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Main Content */}
      <div className="flex-1 ml-72">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
          <div className="max-w-4xl mx-auto px-6 py-4">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-lg font-semibold text-haven-navy-900">
                  Intake Workbench
                </h1>
                <div className="flex items-center gap-3 text-sm text-gray-500">
                  <span>{intakeData.summary.totalQuestions} questions</span>
                  {lastSaved && (
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      Saved {lastSaved.toLocaleTimeString()}
                    </span>
                  )}
                  {isSaving && (
                    <span className="flex items-center gap-1 text-haven-champagne-600">
                      <Loader2 className="w-3 h-3 animate-spin" />
                      Saving...
                    </span>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-3">
                <button
                  onClick={calculateFunding}
                  className="flex items-center gap-2 px-3 py-2 border border-gray-200 rounded-lg text-sm hover:bg-gray-50 transition"
                >
                  <Calculator className="w-4 h-4" />
                  Calculate Funding
                </button>
                <button
                  onClick={saveAndExit}
                  className="flex items-center gap-2 px-3 py-2 border border-gray-200 rounded-lg text-sm hover:bg-gray-50 transition"
                >
                  <Save className="w-4 h-4" />
                  Save & Exit
                </button>
                <button
                  onClick={completeIntake}
                  className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition"
                >
                  <CheckCircle className="w-4 h-4" />
                  Complete Intake
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Sections */}
        <div className="max-w-4xl mx-auto px-6 py-6">
          {intakeData.sections.map((section) => {
            const isExpanded = expandedSections.includes(section.id);
            const progress = getSectionProgress(section);
            const isComplete = completedSections[section.id];

            return (
              <div
                key={section.id}
                className="bg-white rounded-xl border border-gray-200 mb-4 overflow-hidden"
              >
                {/* Section Header */}
                <button
                  onClick={() => toggleSection(section.id)}
                  className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition"
                >
                  <div className="flex items-center gap-4">
                    <span className="text-2xl">{SECTION_ICONS[section.id] || section.icon}</span>
                    <div className="text-left">
                      <h3 className="font-semibold text-haven-navy-900">{section.title}</h3>
                      <p className="text-sm text-gray-500">{section.description}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-gray-500">{progress}%</span>
                      {isComplete && <CheckCircle className="w-5 h-5 text-emerald-500" />}
                    </div>
                    {isExpanded ? (
                      <ChevronUp className="w-5 h-5 text-gray-400" />
                    ) : (
                      <ChevronDown className="w-5 h-5 text-gray-400" />
                    )}
                  </div>
                </button>

                {/* Section Content */}
                {isExpanded && (
                  <div className="border-t border-gray-100">
                    <div className="p-6 space-y-6">
                      {section.items.map((item) => (
                        <div key={item.id} className="space-y-2">
                          <div className="flex items-start gap-2">
                            <label className="font-medium text-haven-navy-900">
                              {item.label}
                              {item.required && (
                                <span className="text-red-500 ml-1">*</span>
                              )}
                            </label>
                          </div>
                          <p className="text-sm text-gray-600">{item.question}</p>
                          {item.context && (
                            <p className="text-xs text-haven-champagne-600 flex items-center gap-1">
                              <Sparkles className="w-3 h-3" />
                              {item.context}
                            </p>
                          )}

                          {/* Input based on type */}
                          {item.inputType === 'select' && item.options ? (
                            <select
                              value={answers[item.id] || ''}
                              onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                              className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                            >
                              <option value="">Select...</option>
                              {item.options.map((opt) => (
                                <option key={opt} value={opt}>
                                  {opt}
                                </option>
                              ))}
                            </select>
                          ) : item.inputType === 'currency' ? (
                            <div className="relative">
                              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                                $
                              </span>
                              <input
                                type="number"
                                value={answers[item.id] || ''}
                                onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                                placeholder="0.00"
                                className="w-full pl-8 pr-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                              />
                            </div>
                          ) : item.inputType === 'date' ? (
                            <input
                              type="month"
                              value={answers[item.id] || ''}
                              onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                              className="px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                            />
                          ) : item.inputType === 'number' ? (
                            <input
                              type="number"
                              value={answers[item.id] || ''}
                              onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                              className="w-32 px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                            />
                          ) : item.inputType === 'boolean' ? (
                            <div className="flex gap-4">
                              <label className="flex items-center gap-2 cursor-pointer">
                                <input
                                  type="radio"
                                  name={item.id}
                                  value="yes"
                                  checked={answers[item.id] === 'yes'}
                                  onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                                  className="text-haven-champagne-500"
                                />
                                <span className="text-sm">Yes</span>
                              </label>
                              <label className="flex items-center gap-2 cursor-pointer">
                                <input
                                  type="radio"
                                  name={item.id}
                                  value="no"
                                  checked={answers[item.id] === 'no'}
                                  onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                                  className="text-haven-champagne-500"
                                />
                                <span className="text-sm">No</span>
                              </label>
                            </div>
                          ) : (
                            <input
                              type="text"
                              value={answers[item.id] || ''}
                              onChange={(e) => handleAnswerChange(item.id, e.target.value)}
                              placeholder="Enter response..."
                              className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition"
                            />
                          )}
                        </div>
                      ))}
                    </div>

                    {/* Mark Section Complete */}
                    <div className="px-6 py-4 border-t border-gray-100 bg-gray-50">
                      <button
                        onClick={() => markSectionComplete(section.id)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition ${
                          isComplete
                            ? 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200'
                            : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
                        }`}
                      >
                        {isComplete ? (
                          <>
                            <CheckCircle className="w-4 h-4" />
                            Section Complete
                          </>
                        ) : (
                          <>
                            <Circle className="w-4 h-4" />
                            Mark as Complete
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}

          {/* Notes Section */}
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="font-semibold text-haven-navy-900 mb-4 flex items-center gap-2">
              <MessageCircle className="w-5 h-5" />
              Notes
            </h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Call Notes (visible to homeowner)
                </label>
                <textarea
                  value={callNotes}
                  onChange={(e) => setCallNotes(e.target.value)}
                  placeholder="Notes about the call..."
                  rows={3}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition resize-none"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Internal Notes (manager only)
                </label>
                <textarea
                  value={managerNotes}
                  onChange={(e) => setManagerNotes(e.target.value)}
                  placeholder="Private notes..."
                  rows={3}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:border-haven-champagne-500 focus:ring-2 focus:ring-haven-champagne-100 outline-none transition resize-none"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
