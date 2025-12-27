'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Phone,
  Save,
  CheckCircle,
  ChevronDown,
  ChevronRight,
  Loader2,
  Calculator,
  AlertCircle,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

// ===========================================================================
// TYPES
// ===========================================================================

interface SessionData {
  session: {
    id: string;
    status: string;
    biggestChallenge: string;
    selectedTier: string;
    progress: Record<string, number>;
    intakeData: Record<string, any>;
    monthlyFundingEstimate: number | null;
    callNotes: string | null;
    followUpNeeded: boolean;
    followUpNotes: string | null;
  };
  household: {
    id: string;
    name: string;
    users: Array<{
      id: string;
      displayName: string;
      firstName: string;
      lastName: string;
      email: string;
      phone: string;
    }>;
  };
  property: {
    id: string;
    street: string;
    city: string;
    state: string;
    zipCode: string;
    bedrooms: number | null;
    bathrooms: number | null;
    squareFeet: number | null;
  } | null;
  enrichment: {
    bedrooms: number;
    bathrooms: number;
    squareFeet: number;
    heatingFuel: string;
    fireplaces: number;
    pool: boolean;
  } | null;
}

// ===========================================================================
// INTAKE SECTIONS CONFIGURATION
// ===========================================================================

interface IntakeQuestion {
  id: string;
  question: string;
  type: 'text' | 'number' | 'currency' | 'phone' | 'email' | 'date' | 'select' | 'yesno' | 'textarea';
  options?: string[];
  placeholder?: string;
  required?: boolean;
  helpText?: string;
  conditionalOn?: { field: string; value: any };
}

interface IntakeSection {
  id: string;
  title: string;
  icon: string;
  description: string;
  questions: IntakeQuestion[];
}

const intakeSections: IntakeSection[] = [
  {
    id: 'quickStart',
    title: 'Quick Start',
    icon: '🎯',
    description: 'Confirm pain points and set expectations',
    questions: [
      { id: 'confirmedChallenge', question: 'Confirm their biggest challenge', type: 'select', options: ['Bills & Payments', 'Home Maintenance', 'Vendor Coordination', 'Family Logistics', 'All of the above'] },
      { id: 'urgentIssues', question: 'Any urgent issues to address first?', type: 'textarea', placeholder: 'Leaking pipe, overdue bill, etc.' },
      { id: 'expectations', question: 'What would success look like in 30 days?', type: 'textarea' },
    ],
  },
  {
    id: 'family',
    title: 'Family & Household',
    icon: '👨‍👩‍👧‍👦',
    description: 'Adults, children, pets, staff',
    questions: [
      { id: 'adultsCount', question: 'How many adults in the household?', type: 'number' },
      { id: 'hasKids', question: 'Any children in the household?', type: 'yesno' },
      { id: 'kidsCount', question: 'How many children?', type: 'number', conditionalOn: { field: 'hasKids', value: true } },
      { id: 'hasPets', question: 'Any pets?', type: 'yesno' },
      { id: 'petsDescription', question: 'Tell me about the pets', type: 'text', placeholder: '2 dogs, 1 cat', conditionalOn: { field: 'hasPets', value: true } },
      { id: 'hasStaff', question: 'Any household staff (nanny, housekeeper, etc.)?', type: 'yesno' },
    ],
  },
  {
    id: 'systems',
    title: 'Home Systems',
    icon: '⚙️',
    description: 'HVAC, plumbing, electrical',
    questions: [
      { id: 'hvacBrand', question: 'HVAC System Brand', type: 'text' },
      { id: 'hvacAge', question: 'HVAC Age (years)', type: 'number' },
      { id: 'hvacVendor', question: 'Who services your HVAC?', type: 'text', helpText: 'We\'ll add them to your vendors' },
      { id: 'heatingFuel', question: 'Heating fuel type', type: 'select', options: ['Natural Gas', 'Oil', 'Propane', 'Electric', 'Heat Pump'] },
      { id: 'waterHeaterType', question: 'Water heater type', type: 'select', options: ['Tank (Gas)', 'Tank (Electric)', 'Tankless (Gas)', 'Tankless (Electric)'] },
      { id: 'waterHeaterAge', question: 'Water heater age (years)', type: 'number' },
      { id: 'hasGenerator', question: 'Generator?', type: 'yesno' },
      { id: 'hasSecuritySystem', question: 'Security system?', type: 'yesno' },
    ],
  },
  {
    id: 'exterior',
    title: 'Exterior & Grounds',
    icon: '🏡',
    description: 'Lawn, pool, roof, gutters',
    questions: [
      { id: 'hasLawnService', question: 'Lawn/landscape service?', type: 'yesno' },
      { id: 'lawnVendor', question: 'Lawn service company', type: 'text', conditionalOn: { field: 'hasLawnService', value: true } },
      { id: 'lawnCost', question: 'Monthly lawn cost', type: 'currency', conditionalOn: { field: 'hasLawnService', value: true } },
      { id: 'hasPool', question: 'Pool?', type: 'yesno' },
      { id: 'poolVendor', question: 'Pool service company', type: 'text', conditionalOn: { field: 'hasPool', value: true } },
      { id: 'roofAge', question: 'Roof age (years)', type: 'number' },
      { id: 'gutterVendor', question: 'Gutter cleaning company', type: 'text' },
    ],
  },
  {
    id: 'bills',
    title: 'Bills & Accounts',
    icon: '💳',
    description: 'All recurring payments',
    questions: [
      { id: 'mortgageLender', question: 'Mortgage Lender', type: 'text', placeholder: 'Chase, Wells Fargo, etc.' },
      { id: 'mortgagePayment', question: 'Monthly Payment', type: 'currency' },
      { id: 'mortgageDueDay', question: 'Due Date (day of month)', type: 'number' },
      { id: 'electricProvider', question: 'Electric Provider', type: 'text' },
      { id: 'electricAvgBill', question: 'Average Monthly Bill', type: 'currency' },
      { id: 'hasGas', question: 'Natural gas service?', type: 'yesno' },
      { id: 'gasProvider', question: 'Gas Provider', type: 'text', conditionalOn: { field: 'hasGas', value: true } },
      { id: 'waterProvider', question: 'Water/Sewer Provider', type: 'text' },
      { id: 'internetProvider', question: 'Internet Provider', type: 'text' },
      { id: 'internetCost', question: 'Monthly Cost', type: 'currency' },
      { id: 'cellProvider', question: 'Cell Phone Provider', type: 'text' },
      { id: 'cellCost', question: 'Monthly Cost', type: 'currency' },
    ],
  },
];

// ===========================================================================
// COMPONENT
// ===========================================================================

export default function IntakeWorkbenchPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.sessionId as string;

  const [data, setData] = useState<SessionData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['quickStart']));
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [callNotes, setCallNotes] = useState('');

  useEffect(() => {
    fetchSession();
  }, [sessionId]);

  const fetchSession = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/manager/onboarding/${sessionId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const result = await response.json();
        setData(result);
        setFormData(result.session.intakeData || {});
        setCallNotes(result.session.callNotes || '');
      }
    } catch (error) {
      console.error('Failed to load session:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveSection = useCallback(async (sectionId: string) => {
    if (!data) return;

    setSaving(true);
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/manager/onboarding/${sessionId}/intake`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          section: sectionId,
          data: formData[sectionId] || {},
          progress: calculateSectionProgress(sectionId),
        }),
      });
    } catch (error) {
      console.error('Failed to save:', error);
    } finally {
      setSaving(false);
    }
  }, [data, formData, sessionId]);

  const startCall = async () => {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

    await fetch(`${apiUrl}/manager/onboarding/${sessionId}/start-call`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });
    fetchSession();
  };

  const completeIntake = async () => {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

    await fetch(`${apiUrl}/manager/onboarding/${sessionId}/complete`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        callNotes,
        followUpNeeded: false,
      }),
    });
    router.push('/manager/onboarding');
  };

  const calculateSectionProgress = (sectionId: string): number => {
    const section = intakeSections.find((s) => s.id === sectionId);
    if (!section) return 0;

    const sectionData = formData[sectionId] || {};
    const requiredFields = section.questions.filter((q) => q.required);
    if (requiredFields.length === 0) return 100;

    const filledRequired = requiredFields.filter((q) => sectionData[q.id]).length;
    return Math.round((filledRequired / requiredFields.length) * 100);
  };

  const calculateMonthlyFunding = (): number => {
    let total = 0;
    const billsData = formData.bills || {};

    if (billsData.mortgagePayment) total += parseFloat(billsData.mortgagePayment) || 0;
    if (billsData.electricAvgBill) total += parseFloat(billsData.electricAvgBill) || 0;
    if (billsData.internetCost) total += parseFloat(billsData.internetCost) || 0;
    if (billsData.cellCost) total += parseFloat(billsData.cellCost) || 0;

    const exteriorData = formData.exterior || {};
    if (exteriorData.lawnCost) total += parseFloat(exteriorData.lawnCost) || 0;

    // Add 10% buffer
    total *= 1.1;

    return Math.round(total * 100) / 100;
  };

  const updateField = (sectionId: string, fieldId: string, value: any) => {
    setFormData((prev) => ({
      ...prev,
      [sectionId]: {
        ...prev[sectionId],
        [fieldId]: value,
      },
    }));
  };

  const toggleSection = (sectionId: string) => {
    const newSet = new Set(expandedSections);
    if (newSet.has(sectionId)) {
      newSet.delete(sectionId);
    } else {
      newSet.add(sectionId);
    }
    setExpandedSections(newSet);
  };

  const shouldShowQuestion = (question: IntakeQuestion, sectionData: Record<string, any>): boolean => {
    if (!question.conditionalOn) return true;
    return sectionData[question.conditionalOn.field] === question.conditionalOn.value;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-champagne-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading intake workbench...</p>
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
          <p className="text-gray-600 mb-4">Session not found</p>
          <Link href="/manager/onboarding" className="text-haven-champagne-600 hover:underline">
            Back to Queue
          </Link>
        </div>
      </div>
    );
  }

  const homeowner = data.household.users?.[0];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sticky Header */}
      <div className="sticky top-0 z-10 bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-6xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link
                href="/manager/onboarding"
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <ArrowLeft className="w-5 h-5" />
              </Link>
              <div>
                <h1 className="text-xl font-bold text-haven-navy-900">
                  {homeowner?.displayName || `${homeowner?.firstName || ''} ${homeowner?.lastName || ''}`.trim() || 'Unknown'}
                </h1>
                <p className="text-sm text-gray-500">
                  {data.property?.street}, {data.property?.city}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              {data.session.status === 'PENDING_CALL' && (
                <button
                  onClick={startCall}
                  className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                >
                  <Phone className="w-4 h-4" />
                  Start Call
                </button>
              )}

              <button
                onClick={() => {
                  intakeSections.forEach((section) => saveSection(section.id));
                }}
                disabled={saving}
                className="flex items-center gap-2 px-4 py-2 bg-haven-navy-900 text-white rounded-lg hover:bg-haven-navy-800 transition disabled:opacity-50"
              >
                <Save className="w-4 h-4" />
                {saving ? 'Saving...' : 'Save Progress'}
              </button>

              <button
                onClick={completeIntake}
                className="flex items-center gap-2 px-4 py-2 bg-haven-champagne-500 text-haven-navy-900 rounded-lg hover:bg-haven-champagne-400 transition"
              >
                <CheckCircle className="w-4 h-4" />
                Complete
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-6">
        <div className="grid grid-cols-3 gap-6">
          {/* Left Column - Sections */}
          <div className="col-span-2 space-y-4">
            {/* ATTOM Context Banner */}
            {data.enrichment && (
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
                <div className="flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
                  <div>
                    <div className="font-medium text-blue-900">Property Insights</div>
                    <div className="text-sm text-blue-700 mt-1">
                      {data.enrichment.bedrooms} bed • {data.enrichment.bathrooms} bath
                      {data.enrichment.squareFeet && ` • ${data.enrichment.squareFeet.toLocaleString()} sqft`}
                      {data.enrichment.heatingFuel && ` • ${data.enrichment.heatingFuel} heat`}
                      {data.enrichment.fireplaces > 0 && ` • ${data.enrichment.fireplaces} fireplace(s)`}
                      {data.enrichment.pool && ' • Pool'}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Intake Sections */}
            {intakeSections.map((section) => (
              <div key={section.id} className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                <button
                  onClick={() => toggleSection(section.id)}
                  className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50 transition"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{section.icon}</span>
                    <div className="text-left">
                      <div className="font-semibold text-haven-navy-900">{section.title}</div>
                      <div className="text-sm text-gray-500">{section.description}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-sm text-gray-400">
                      {calculateSectionProgress(section.id)}%
                    </div>
                    {expandedSections.has(section.id) ? (
                      <ChevronDown className="w-5 h-5 text-gray-400" />
                    ) : (
                      <ChevronRight className="w-5 h-5 text-gray-400" />
                    )}
                  </div>
                </button>

                {expandedSections.has(section.id) && (
                  <div className="px-5 pb-5 border-t border-gray-100">
                    <div className="mt-4 space-y-4">
                      {section.questions.map((question) => {
                        if (!shouldShowQuestion(question, formData[section.id] || {})) {
                          return null;
                        }

                        return (
                          <div key={question.id}>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                              {question.question}
                              {question.required && <span className="text-red-500 ml-1">*</span>}
                            </label>

                            {question.helpText && (
                              <p className="text-xs text-gray-500 mb-2">{question.helpText}</p>
                            )}

                            {question.type === 'text' && (
                              <input
                                type="text"
                                value={formData[section.id]?.[question.id] || ''}
                                onChange={(e) => updateField(section.id, question.id, e.target.value)}
                                placeholder={question.placeholder}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                              />
                            )}

                            {question.type === 'number' && (
                              <input
                                type="number"
                                value={formData[section.id]?.[question.id] || ''}
                                onChange={(e) => updateField(section.id, question.id, e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                              />
                            )}

                            {question.type === 'currency' && (
                              <div className="relative">
                                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">$</span>
                                <input
                                  type="number"
                                  value={formData[section.id]?.[question.id] || ''}
                                  onChange={(e) => updateField(section.id, question.id, e.target.value)}
                                  className="w-full pl-7 pr-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                                />
                              </div>
                            )}

                            {question.type === 'select' && (
                              <select
                                value={formData[section.id]?.[question.id] || ''}
                                onChange={(e) => updateField(section.id, question.id, e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                              >
                                <option value="">Select...</option>
                                {question.options?.map((opt) => (
                                  <option key={opt} value={opt}>{opt}</option>
                                ))}
                              </select>
                            )}

                            {question.type === 'yesno' && (
                              <div className="flex gap-3">
                                <button
                                  type="button"
                                  onClick={() => updateField(section.id, question.id, true)}
                                  className={`flex-1 py-2 rounded-lg border transition ${
                                    formData[section.id]?.[question.id] === true
                                      ? 'bg-haven-champagne-500 border-haven-champagne-500 text-haven-navy-900'
                                      : 'border-gray-200 hover:bg-gray-50'
                                  }`}
                                >
                                  Yes
                                </button>
                                <button
                                  type="button"
                                  onClick={() => updateField(section.id, question.id, false)}
                                  className={`flex-1 py-2 rounded-lg border transition ${
                                    formData[section.id]?.[question.id] === false
                                      ? 'bg-gray-200 border-gray-200'
                                      : 'border-gray-200 hover:bg-gray-50'
                                  }`}
                                >
                                  No
                                </button>
                              </div>
                            )}

                            {question.type === 'textarea' && (
                              <textarea
                                value={formData[section.id]?.[question.id] || ''}
                                onChange={(e) => updateField(section.id, question.id, e.target.value)}
                                placeholder={question.placeholder}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg h-24 resize-none focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                              />
                            )}
                          </div>
                        );
                      })}
                    </div>

                    <div className="mt-4 pt-4 border-t border-gray-100">
                      <button
                        onClick={() => saveSection(section.id)}
                        className="text-sm text-haven-champagne-600 hover:underline"
                      >
                        Save {section.title}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Right Column - Summary */}
          <div className="space-y-4">
            {/* Progress */}
            <div className="bg-white rounded-xl border border-gray-200 p-5">
              <h3 className="font-semibold text-haven-navy-900 mb-4">Progress</h3>
              <div className="space-y-3">
                {intakeSections.map((section) => (
                  <div key={section.id}>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-gray-600">{section.title}</span>
                      <span className="text-gray-400">{calculateSectionProgress(section.id)}%</span>
                    </div>
                    <div className="w-full bg-gray-100 rounded-full h-1.5">
                      <div
                        className="bg-haven-champagne-500 h-1.5 rounded-full transition-all"
                        style={{ width: `${calculateSectionProgress(section.id)}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Monthly Funding Calculator */}
            <div className="bg-haven-navy-900 rounded-xl p-5 text-white">
              <div className="flex items-center gap-2 mb-4">
                <Calculator className="w-5 h-5 text-haven-champagne-300" />
                <h3 className="font-semibold">Monthly Haven Funding</h3>
              </div>
              <div className="text-3xl font-bold mb-2">
                ${calculateMonthlyFunding().toLocaleString()}
              </div>
              <p className="text-sm text-haven-champagne-300">
                Includes 10% buffer for variable bills
              </p>
            </div>

            {/* Homeowner Info */}
            <div className="bg-white rounded-xl border border-gray-200 p-5">
              <h3 className="font-semibold text-haven-navy-900 mb-4">Contact</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Name</span>
                  <span className="font-medium">{homeowner?.displayName || `${homeowner?.firstName} ${homeowner?.lastName}`}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Email</span>
                  <span className="font-medium">{homeowner?.email}</span>
                </div>
                {homeowner?.phone && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Phone</span>
                    <span className="font-medium">{homeowner.phone}</span>
                  </div>
                )}
                {data.session.selectedTier && (
                  <div className="flex justify-between">
                    <span className="text-gray-500">Tier</span>
                    <span className="font-medium">{data.session.selectedTier}</span>
                  </div>
                )}
              </div>
            </div>

            {/* Call Notes */}
            <div className="bg-white rounded-xl border border-gray-200 p-5">
              <h3 className="font-semibold text-haven-navy-900 mb-4">Call Notes</h3>
              <textarea
                value={callNotes}
                onChange={(e) => setCallNotes(e.target.value)}
                className="w-full h-32 p-3 border border-gray-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-2 focus:ring-haven-champagne-500"
                placeholder="Notes from the call..."
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
