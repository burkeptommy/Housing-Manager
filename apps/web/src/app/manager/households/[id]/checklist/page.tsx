'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  CheckCircle,
  Circle,
  Phone,
  Home,
  AlertCircle,
  ChevronDown,
  ChevronUp,
  ArrowLeft,
  Sparkles,
  Loader2,
  Save,
  Send,
  Clock,
  Building2,
} from 'lucide-react';
import { getIdToken } from '@/lib/firebase';

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

interface Household {
  id: string;
  name: string;
  address: string;
  propertyData?: any;
}

const CATEGORIES = [
  { id: 'utilities', label: 'Utilities', icon: '⚡', description: 'Power, gas, water providers' },
  { id: 'vendors', label: 'Service Vendors', icon: '🔧', description: 'Regular service providers' },
  { id: 'systems', label: 'Home Systems', icon: '🏠', description: 'HVAC, water heater, etc.' },
  { id: 'maintenance', label: 'Maintenance History', icon: '📅', description: 'Last service dates' },
  { id: 'info', label: 'Additional Info', icon: 'ℹ️', description: 'Other important details' },
];

export default function ManagerChecklistPage() {
  const params = useParams();
  const router = useRouter();
  const householdId = params.id as string;

  const [checklist, setChecklist] = useState<ChecklistItem[]>([]);
  const [expandedCategories, setExpandedCategories] = useState<string[]>(['utilities', 'vendors']);
  const [household, setHousehold] = useState<Household | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);

  useEffect(() => {
    fetchChecklist();
  }, [householdId]);

  const fetchChecklist = async () => {
    setIsLoading(true);
    try {
      // TODO: Fetch actual household and checklist data from API
      // For now, using mock data based on ATTOM property data

      // Mock household data
      setHousehold({
        id: householdId,
        name: 'Morrison Family',
        address: '38 Bedford Road, Greenwich, CT 06831',
      });

      // Generate checklist by calling API
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/property/checklist/generate`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          street: '38 Bedford Road',
          city: 'Greenwich',
          state: 'CT',
          zip: '06831',
        }),
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          setChecklist(data.checklist.map((item: ChecklistItem) => ({
            ...item,
            answered: false,
            answer: '',
          })));
        }
      }
    } catch (error) {
      console.error('Error fetching checklist:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const completedCount = checklist.filter((c) => c.answered).length;
  const totalCount = checklist.length;
  const progress = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

  const handleAnswer = async (itemId: string, answer: string) => {
    // Update locally
    setChecklist((prev) =>
      prev.map((item) =>
        item.id === itemId ? { ...item, answer, answered: !!answer } : item
      )
    );

    // Auto-save debounced
    setIsSaving(true);
    setTimeout(() => {
      // TODO: Save to API
      setIsSaving(false);
      setLastSaved(new Date());
    }, 500);
  };

  const toggleCategory = (categoryId: string) => {
    setExpandedCategories((prev) =>
      prev.includes(categoryId)
        ? prev.filter((c) => c !== categoryId)
        : [...prev, categoryId]
    );
  };

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'high':
        return (
          <span className="px-2 py-0.5 text-xs font-medium bg-red-100 text-red-700 rounded-full">
            High
          </span>
        );
      case 'medium':
        return (
          <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
            Medium
          </span>
        );
      default:
        return null;
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-haven-600 mx-auto mb-4" />
          <p className="text-gray-500">Loading checklist...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link
                href={`/manager/households/${householdId}`}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
              >
                <ArrowLeft className="w-5 h-5" />
              </Link>
              <div>
                <h1 className="text-lg font-semibold text-haven-900">
                  Intake Checklist
                </h1>
                <div className="flex items-center gap-2 text-sm text-gray-500">
                  <Building2 className="w-4 h-4" />
                  {household?.name}
                </div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              {lastSaved && (
                <div className="flex items-center gap-1 text-xs text-gray-400">
                  <Clock className="w-3 h-3" />
                  Saved {lastSaved.toLocaleTimeString()}
                </div>
              )}
              {isSaving && (
                <div className="flex items-center gap-1 text-xs text-haven-600">
                  <Loader2 className="w-3 h-3 animate-spin" />
                  Saving...
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6">
        {/* Property Card */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 mb-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-haven-100 rounded-xl flex items-center justify-center flex-shrink-0">
              <Home className="w-6 h-6 text-haven-600" />
            </div>
            <div className="flex-1">
              <h2 className="font-semibold text-haven-900">{household?.name}</h2>
              <p className="text-sm text-gray-500">{household?.address}</p>
            </div>
            <button className="flex items-center gap-2 px-4 py-2 bg-haven-900 text-white text-sm rounded-lg hover:bg-haven-800 transition">
              <Phone className="w-4 h-4" />
              Call Homeowner
            </button>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 mb-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Intake Progress</span>
            <span className="text-sm font-bold text-haven-900">
              {completedCount} / {totalCount} items
            </span>
          </div>
          <div className="w-full h-3 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-emerald-400 to-emerald-500 transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
          {progress === 100 && (
            <div className="flex items-center gap-2 mt-3 text-sm text-emerald-600">
              <CheckCircle className="w-4 h-4" />
              <span>All items completed!</span>
            </div>
          )}
        </div>

        {/* Quick Actions */}
        <div className="flex gap-3 mb-6">
          <button className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm">
            <Send className="w-4 h-4" />
            Send Questionnaire Link
          </button>
          <button className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm">
            <Save className="w-4 h-4" />
            Save & Exit
          </button>
        </div>

        {/* Checklist by Category */}
        <div className="space-y-4">
          {CATEGORIES.map((category) => {
            const items = checklist.filter((c) => c.category === category.id);
            if (items.length === 0) return null;

            const isExpanded = expandedCategories.includes(category.id);
            const categoryCompleted = items.filter((i) => i.answered).length;

            return (
              <div
                key={category.id}
                className="bg-white rounded-xl border border-gray-200 overflow-hidden"
              >
                <button
                  onClick={() => toggleCategory(category.id)}
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50 transition"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xl">{category.icon}</span>
                    <div className="text-left">
                      <span className="font-medium text-haven-900">{category.label}</span>
                      <p className="text-xs text-gray-400">{category.description}</p>
                    </div>
                    <span className="text-sm text-gray-400">
                      {categoryCompleted}/{items.length}
                    </span>
                    {categoryCompleted === items.length && items.length > 0 && (
                      <CheckCircle className="w-4 h-4 text-emerald-500" />
                    )}
                  </div>
                  {isExpanded ? (
                    <ChevronUp className="w-5 h-5 text-gray-400" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-gray-400" />
                  )}
                </button>

                {isExpanded && (
                  <div className="border-t divide-y">
                    {items.map((item) => (
                      <div key={item.id} className="p-4">
                        <div className="flex items-start gap-3">
                          <div className="mt-1">
                            {item.answered ? (
                              <CheckCircle className="w-5 h-5 text-emerald-500" />
                            ) : item.priority === 'high' ? (
                              <AlertCircle className="w-5 h-5 text-orange-500" />
                            ) : (
                              <Circle className="w-5 h-5 text-gray-300" />
                            )}
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <p className="font-medium text-haven-900">{item.question}</p>
                              {getPriorityBadge(item.priority)}
                            </div>
                            {item.context && (
                              <div className="flex items-center gap-1 text-xs text-haven-600 mb-2">
                                <Sparkles className="w-3 h-3" />
                                {item.context}
                              </div>
                            )}

                            {/* Input based on type */}
                            {item.inputType === 'select' && item.options ? (
                              <select
                                value={item.answer || ''}
                                onChange={(e) => handleAnswer(item.id, e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-500 focus:ring-2 focus:ring-haven-100 outline-none transition"
                              >
                                <option value="">Select...</option>
                                {item.options.map((opt) => (
                                  <option key={opt} value={opt}>
                                    {opt}
                                  </option>
                                ))}
                              </select>
                            ) : item.inputType === 'vendor' ? (
                              <div className="flex gap-2">
                                <input
                                  type="text"
                                  value={item.answer || ''}
                                  onChange={(e) => handleAnswer(item.id, e.target.value)}
                                  placeholder="Vendor name..."
                                  className="flex-1 px-3 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-500 focus:ring-2 focus:ring-haven-100 outline-none transition"
                                />
                                <button className="px-3 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition whitespace-nowrap">
                                  + Add to Vendors
                                </button>
                              </div>
                            ) : item.inputType === 'date' ? (
                              <input
                                type="month"
                                value={item.answer || ''}
                                onChange={(e) => handleAnswer(item.id, e.target.value)}
                                className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-500 focus:ring-2 focus:ring-haven-100 outline-none transition"
                              />
                            ) : (
                              <input
                                type="text"
                                value={item.answer || ''}
                                onChange={(e) => handleAnswer(item.id, e.target.value)}
                                placeholder="Enter response..."
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:border-haven-500 focus:ring-2 focus:ring-haven-100 outline-none transition"
                              />
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Complete Button */}
        {progress === 100 && (
          <div className="mt-6 text-center">
            <button className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 text-white rounded-xl font-medium hover:bg-emerald-700 transition">
              <CheckCircle className="w-5 h-5" />
              Mark Intake Complete
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
