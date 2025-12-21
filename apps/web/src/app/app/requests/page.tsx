'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import Image from 'next/image';
import { getDemoImage } from '@/lib/imageUtils';
import { getApiClient } from '@/lib/api';
import { useAuth } from '@/contexts/auth-context';
import type {
  ServiceRequest,
  ServiceRequestDetail,
  ServiceRequestStatus,
  ServiceRequestPriority,
  CreateServiceRequestRequest,
} from '@haven/core';
import {
  Plus,
  X,
  Wrench,
  Star,
  Sparkles,
  AlertTriangle,
  Phone,
  Camera,
  Mic,
  MicOff,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  MessageSquare,
  Clock,
  CheckCircle2,
  User,
  DollarSign,
  Send,
  Archive,
  ArrowLeft,
  Zap,
  Home,
  Shield,
  Package,
  HelpCircle,
  ExternalLink,
  Loader2,
  AlertCircle,
  Search,
  UserCheck,
  CalendarCheck,
  Headphones,
  ShoppingCart,
  Calendar,
  RefreshCw,
  Bell,
  ThumbsUp,
  ThumbsDown,
  MapPin,
  Check,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type QuickCategory = 'fix' | 'schedule' | 'buy' | 'research' | 'other';
type RequestStatus = 'received' | 'reviewing' | 'scheduled' | 'in_progress' | 'resolved';
type InputType = 'choice' | 'schedule' | 'approval' | 'info';

interface HomeownerInput {
  id: string;
  requestId: string;
  requestTitle: string;
  type: InputType;
  question: string;
  options?: string[];
  amount?: number;
  scheduleTimes?: { id: string; label: string; datetime: string }[];
  urgent: boolean;
  createdAt: string;
}

interface ActiveRequest {
  id: string;
  title: string;
  status: RequestStatus;
  statusMessage: string;
  vendor?: {
    name: string;
    avatar: string;
  };
  scheduledDate?: string;
  isRecurring?: boolean;
  previousFixInfo?: string;
  createdAt: string;
  updatedAt: string;
}

interface CompletedRequest {
  id: string;
  title: string;
  completedAt: string;
  vendor?: string;
  cost?: number;
  rating?: number;
  addedToMaintenance?: boolean;
}

// ============================================================================
// CONSTANTS
// ============================================================================

const HOUSING_MANAGER = {
  name: 'Sarah',
  title: 'Your Home Manager',
  avatar: getDemoImage('avatar-female', 100, 100, 'sarah-manager'),
  phone: '+1 (512) 555-0100',
};

const QUICK_CATEGORIES: { id: QuickCategory; label: string; icon: typeof Wrench; color: string; examples: string[] }[] = [
  { id: 'fix', label: 'Fix', icon: Wrench, color: 'bg-orange-100 text-orange-600', examples: ['Leaky faucet', 'Door won\'t close', 'AC not working'] },
  { id: 'schedule', label: 'Schedule', icon: Calendar, color: 'bg-blue-100 text-blue-600', examples: ['Cleaning service', 'Lawn care', 'Pool maintenance'] },
  { id: 'buy', label: 'Buy', icon: ShoppingCart, color: 'bg-purple-100 text-purple-600', examples: ['Light bulbs', 'Air filters', 'Groceries'] },
  { id: 'research', label: 'Research', icon: Search, color: 'bg-emerald-100 text-emerald-600', examples: ['Best electrician', 'Solar panel options', 'Roof repair quotes'] },
  { id: 'other', label: 'Other', icon: HelpCircle, color: 'bg-slate-100 text-slate-600', examples: ['Anything else'] },
];

// ============================================================================
// MOCK DATA
// ============================================================================

const MOCK_NEEDS_INPUT: HomeownerInput[] = [
  {
    id: 'input-1',
    requestId: 'req-1',
    requestTitle: 'Kitchen faucet replacement',
    type: 'choice',
    question: 'Which faucet style do you prefer?',
    options: ['Modern Chrome Pull-Down ($189)', 'Traditional Brass ($149)', 'Matte Black Touch-Free ($249)'],
    urgent: false,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'input-2',
    requestId: 'req-2',
    requestTitle: 'HVAC maintenance',
    type: 'schedule',
    question: 'Which time works best for the HVAC technician?',
    scheduleTimes: [
      { id: 's1', label: 'Tuesday 9-11am', datetime: '2024-12-24T09:00:00Z' },
      { id: 's2', label: 'Thursday 2-4pm', datetime: '2024-12-26T14:00:00Z' },
      { id: 's3', label: 'Friday 10am-12pm', datetime: '2024-12-27T10:00:00Z' },
    ],
    urgent: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'input-3',
    requestId: 'req-3',
    requestTitle: 'Garage door motor repair',
    type: 'approval',
    question: 'Approve repair cost?',
    amount: 450,
    urgent: false,
    createdAt: new Date().toISOString(),
  },
];

const MOCK_ACTIVE_REQUESTS: ActiveRequest[] = [
  {
    id: 'req-4',
    title: 'Pool filter replacement',
    status: 'in_progress',
    statusMessage: 'Pool Pro is on site now',
    vendor: { name: 'Pool Pro Services', avatar: getDemoImage('vendor-portrait', 100, 100, 'pool-pro') },
    createdAt: '2024-12-18T09:00:00Z',
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'req-5',
    title: 'Weekly housekeeping',
    status: 'scheduled',
    statusMessage: 'Scheduled for Friday 9am',
    vendor: { name: 'Sparkle Clean', avatar: getDemoImage('avatar-female', 100, 100, 'maria') },
    scheduledDate: '2024-12-20T09:00:00Z',
    createdAt: '2024-12-17T10:00:00Z',
    updatedAt: '2024-12-17T11:00:00Z',
  },
  {
    id: 'req-1',
    title: 'Kitchen faucet replacement',
    status: 'reviewing',
    statusMessage: 'Finding best options for you',
    createdAt: '2024-12-18T08:00:00Z',
    updatedAt: '2024-12-18T08:30:00Z',
  },
  {
    id: 'req-6',
    title: 'Smoke detector batteries',
    status: 'received',
    statusMessage: 'Sarah is reviewing',
    isRecurring: true,
    previousFixInfo: 'Fixed 3 months ago by handyman',
    createdAt: '2024-12-19T08:00:00Z',
    updatedAt: '2024-12-19T08:00:00Z',
  },
];

const MOCK_COMPLETED: CompletedRequest[] = [
  {
    id: 'comp-1',
    title: 'HVAC filter replacement',
    completedAt: '2024-12-12T15:00:00Z',
    vendor: 'Cool Air HVAC',
    cost: 89,
    rating: 5,
    addedToMaintenance: true,
  },
  {
    id: 'comp-2',
    title: 'Utility bill inquiry',
    completedAt: '2024-12-06T10:00:00Z',
    rating: 4,
  },
  {
    id: 'comp-3',
    title: 'Tree branch removal',
    completedAt: '2024-12-01T16:00:00Z',
    vendor: 'Green Thumb Landscaping',
    cost: 175,
    rating: 5,
    addedToMaintenance: true,
  },
];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function getTimeAgo(dateStr: string): string {
  const now = new Date();
  const date = new Date(dateStr);
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return 'yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Manager Summary Card - The main view homeowners see
function ManagerSummaryCard({
  activeCount,
  needsInputCount,
  onExpand,
  isExpanded,
}: {
  activeCount: number;
  needsInputCount: number;
  onExpand: () => void;
  isExpanded: boolean;
}) {
  return (
    <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-2xl p-6 text-white shadow-lg">
      <div className="flex items-start gap-4">
        <div className="relative">
          <div className="w-14 h-14 rounded-full bg-white/20 flex items-center justify-center">
            <Headphones className="w-7 h-7" />
          </div>
          <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-emerald-400 rounded-full flex items-center justify-center">
            <Check className="w-3 h-3 text-white" />
          </div>
        </div>
        <div className="flex-1">
          <h2 className="text-lg font-semibold">{HOUSING_MANAGER.name} is on it</h2>
          <p className="text-emerald-100 text-sm mt-1">
            Managing {activeCount} {activeCount === 1 ? 'item' : 'items'} for you
          </p>
        </div>
        <a
          href={`tel:${HOUSING_MANAGER.phone}`}
          className="p-3 bg-white/20 rounded-xl hover:bg-white/30 transition-colors"
        >
          <Phone className="w-5 h-5" />
        </a>
      </div>

      {needsInputCount > 0 && (
        <div className="mt-4 p-3 bg-amber-500/90 rounded-xl flex items-center gap-3">
          <Bell className="w-5 h-5" />
          <span className="font-medium">{needsInputCount} {needsInputCount === 1 ? 'item needs' : 'items need'} your input</span>
          <ChevronDown className="w-5 h-5 ml-auto" />
        </div>
      )}

      <button
        onClick={onExpand}
        className="mt-4 w-full flex items-center justify-center gap-2 py-2 bg-white/10 rounded-lg hover:bg-white/20 transition-colors text-sm"
      >
        {isExpanded ? (
          <>
            <ChevronUp className="w-4 h-4" />
            Hide details
          </>
        ) : (
          <>
            <ChevronDown className="w-4 h-4" />
            See what's happening
          </>
        )}
      </button>
    </div>
  );
}

// Needs Your Input Card - For homeowner decisions
function NeedsInputCard({
  input,
  onRespond,
}: {
  input: HomeownerInput;
  onRespond: (inputId: string, response: string) => void;
}) {
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (!selectedOption) return;
    setIsSubmitting(true);
    await new Promise((r) => setTimeout(r, 500)); // Simulate API call
    onRespond(input.id, selectedOption);
    setIsSubmitting(false);
  };

  const getIcon = () => {
    switch (input.type) {
      case 'choice':
        return <HelpCircle className="w-5 h-5 text-purple-600" />;
      case 'schedule':
        return <Calendar className="w-5 h-5 text-blue-600" />;
      case 'approval':
        return <DollarSign className="w-5 h-5 text-emerald-600" />;
      default:
        return <MessageSquare className="w-5 h-5 text-slate-600" />;
    }
  };

  return (
    <div className={`bg-white rounded-xl border-2 shadow-sm overflow-hidden ${input.urgent ? 'border-amber-400' : 'border-slate-200'}`}>
      {input.urgent && (
        <div className="bg-amber-50 px-4 py-2 flex items-center gap-2 border-b border-amber-200">
          <AlertCircle className="w-4 h-4 text-amber-600" />
          <span className="text-sm font-medium text-amber-700">Time-sensitive</span>
        </div>
      )}

      <div className="p-4">
        <div className="flex items-start gap-3 mb-4">
          <div className="p-2 bg-slate-100 rounded-lg">
            {getIcon()}
          </div>
          <div className="flex-1">
            <p className="text-sm text-slate-500">{input.requestTitle}</p>
            <h3 className="font-semibold text-slate-900">{input.question}</h3>
          </div>
        </div>

        {/* Choice Options */}
        {input.type === 'choice' && input.options && (
          <div className="space-y-2 mb-4">
            {input.options.map((option) => (
              <button
                key={option}
                onClick={() => setSelectedOption(option)}
                className={`w-full p-3 rounded-lg border text-left transition-all ${
                  selectedOption === option
                    ? 'border-emerald-500 bg-emerald-50 ring-2 ring-emerald-200'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <span className="text-sm font-medium text-slate-900">{option}</span>
              </button>
            ))}
          </div>
        )}

        {/* Schedule Options */}
        {input.type === 'schedule' && input.scheduleTimes && (
          <div className="space-y-2 mb-4">
            {input.scheduleTimes.map((time) => (
              <button
                key={time.id}
                onClick={() => setSelectedOption(time.id)}
                className={`w-full p-3 rounded-lg border text-left transition-all ${
                  selectedOption === time.id
                    ? 'border-emerald-500 bg-emerald-50 ring-2 ring-emerald-200'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-slate-400" />
                  <span className="text-sm font-medium text-slate-900">{time.label}</span>
                </div>
              </button>
            ))}
          </div>
        )}

        {/* Approval */}
        {input.type === 'approval' && input.amount && (
          <div className="mb-4">
            <div className="p-4 bg-slate-50 rounded-lg text-center mb-3">
              <p className="text-3xl font-bold text-slate-900">${input.amount.toLocaleString()}</p>
              <p className="text-sm text-slate-500 mt-1">Estimated repair cost</p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => setSelectedOption('decline')}
                className={`p-3 rounded-lg border transition-all flex items-center justify-center gap-2 ${
                  selectedOption === 'decline'
                    ? 'border-red-500 bg-red-50 text-red-700'
                    : 'border-slate-200 hover:border-slate-300 text-slate-700'
                }`}
              >
                <ThumbsDown className="w-4 h-4" />
                Decline
              </button>
              <button
                onClick={() => setSelectedOption('approve')}
                className={`p-3 rounded-lg border transition-all flex items-center justify-center gap-2 ${
                  selectedOption === 'approve'
                    ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                    : 'border-slate-200 hover:border-slate-300 text-slate-700'
                }`}
              >
                <ThumbsUp className="w-4 h-4" />
                Approve
              </button>
            </div>
          </div>
        )}

        {/* Submit Button */}
        {selectedOption && (
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="w-full py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Sending...
              </>
            ) : (
              <>
                <Send className="w-4 h-4" />
                Send to {HOUSING_MANAGER.name}
              </>
            )}
          </button>
        )}
      </div>
    </div>
  );
}

// Active Request Mini Card
function ActiveRequestMiniCard({ request }: { request: ActiveRequest }) {
  const getStatusColor = () => {
    switch (request.status) {
      case 'in_progress':
        return 'bg-orange-100 text-orange-700';
      case 'scheduled':
        return 'bg-blue-100 text-blue-700';
      case 'reviewing':
        return 'bg-purple-100 text-purple-700';
      default:
        return 'bg-slate-100 text-slate-700';
    }
  };

  const getStatusIcon = () => {
    switch (request.status) {
      case 'in_progress':
        return <Wrench className="w-4 h-4" />;
      case 'scheduled':
        return <CalendarCheck className="w-4 h-4" />;
      case 'reviewing':
        return <Search className="w-4 h-4" />;
      default:
        return <Clock className="w-4 h-4" />;
    }
  };

  return (
    <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
      <div className="flex items-start gap-3">
        <div className="flex-1">
          <h3 className="font-medium text-slate-900">{request.title}</h3>
          <div className={`inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium mt-2 ${getStatusColor()}`}>
            {getStatusIcon()}
            {request.statusMessage}
          </div>

          {request.isRecurring && (
            <div className="mt-2 p-2 bg-amber-50 border border-amber-200 rounded-lg">
              <div className="flex items-center gap-2 text-amber-700">
                <RefreshCw className="w-4 h-4" />
                <span className="text-xs font-medium">Recurring Issue</span>
              </div>
              {request.previousFixInfo && (
                <p className="text-xs text-amber-600 mt-1">{request.previousFixInfo}</p>
              )}
            </div>
          )}
        </div>

        {request.vendor && (
          <div className="relative w-10 h-10 rounded-full overflow-hidden bg-slate-100">
            <Image src={request.vendor.avatar} alt={request.vendor.name} fill className="object-cover" />
          </div>
        )}
      </div>

      <div className="flex items-center justify-between mt-3 pt-3 border-t border-slate-100">
        <span className="text-xs text-slate-500">Updated {getTimeAgo(request.updatedAt)}</span>
        <button className="text-xs text-emerald-600 font-medium hover:text-emerald-700 flex items-center gap-1">
          Details <ChevronRight className="w-3 h-3" />
        </button>
      </div>
    </div>
  );
}

// Completed Request Card
function CompletedRequestCard({
  request,
  onRate,
}: {
  request: CompletedRequest;
  onRate?: (id: string, rating: number) => void;
}) {
  const [showRating, setShowRating] = useState(!request.rating);
  const [selectedRating, setSelectedRating] = useState(0);

  const handleRate = () => {
    if (selectedRating > 0 && onRate) {
      onRate(request.id, selectedRating);
      setShowRating(false);
    }
  };

  return (
    <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
      <div className="flex items-start gap-3">
        <div className="p-2 bg-emerald-100 rounded-lg">
          <CheckCircle2 className="w-5 h-5 text-emerald-600" />
        </div>
        <div className="flex-1">
          <h3 className="font-medium text-slate-900">{request.title}</h3>
          <p className="text-sm text-slate-500">{formatDate(request.completedAt)}</p>

          {request.vendor && (
            <p className="text-sm text-slate-600 mt-1">By {request.vendor}</p>
          )}

          {request.cost && (
            <p className="text-sm font-medium text-slate-900 mt-1">${request.cost.toLocaleString()}</p>
          )}

          {request.addedToMaintenance && (
            <div className="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-50 text-blue-700 text-xs rounded mt-2">
              <Shield className="w-3 h-3" />
              Added to Maintenance
            </div>
          )}
        </div>

        {request.rating ? (
          <div className="flex items-center gap-0.5">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star
                key={star}
                className={`w-4 h-4 ${star <= request.rating! ? 'text-amber-400 fill-amber-400' : 'text-slate-200'}`}
              />
            ))}
          </div>
        ) : showRating && (
          <div className="flex flex-col items-end gap-2">
            <div className="flex items-center gap-0.5">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  onClick={() => setSelectedRating(star)}
                  className="p-0.5"
                >
                  <Star
                    className={`w-5 h-5 transition-colors ${
                      star <= selectedRating ? 'text-amber-400 fill-amber-400' : 'text-slate-200 hover:text-amber-300'
                    }`}
                  />
                </button>
              ))}
            </div>
            {selectedRating > 0 && (
              <button
                onClick={handleRate}
                className="text-xs text-emerald-600 font-medium"
              >
                Submit
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// Ultra-Simple Request Creation
function QuickRequestModal({
  onClose,
  onSubmit,
}: {
  onClose: () => void;
  onSubmit: (category: QuickCategory, description: string, photoUrl?: string) => void;
}) {
  const [step, setStep] = useState<'input' | 'category'>('input');
  const [description, setDescription] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<QuickCategory | null>(null);
  const [isListening, setIsListening] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Focus textarea on mount
  useEffect(() => {
    textareaRef.current?.focus();
  }, []);

  const handleVoiceInput = () => {
    // In a real app, this would use Web Speech API
    setIsListening(!isListening);
    if (!isListening) {
      // Simulate voice input
      setTimeout(() => {
        setDescription('Kitchen faucet is dripping');
        setIsListening(false);
      }, 2000);
    }
  };

  const handleCategorySelect = (category: QuickCategory) => {
    setSelectedCategory(category);
  };

  const handleSubmit = async () => {
    if (!description.trim() || !selectedCategory) return;
    setIsSubmitting(true);
    await new Promise((r) => setTimeout(r, 800));
    onSubmit(selectedCategory, description);
    setIsSubmitting(false);
  };

  const handleNext = () => {
    if (description.trim()) {
      setStep('category');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative w-full sm:max-w-lg bg-white rounded-t-2xl sm:rounded-2xl shadow-xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200">
          <h2 className="text-lg font-semibold text-slate-900">
            {step === 'input' ? 'What do you need?' : 'Almost done!'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        <div className="p-6">
          {step === 'input' ? (
            <>
              {/* Text/Voice Input */}
              <div className="relative">
                <textarea
                  ref={textareaRef}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Tell us what you need... (e.g., kitchen faucet dripping, need groceries picked up)"
                  rows={3}
                  className="w-full px-4 py-3 pr-24 border border-slate-300 rounded-xl focus:ring-2 focus:ring-emerald-600 focus:border-transparent resize-none text-lg"
                />
                <div className="absolute right-2 bottom-2 flex items-center gap-2">
                  <button
                    onClick={handleVoiceInput}
                    className={`p-2 rounded-lg transition-colors ${
                      isListening
                        ? 'bg-red-100 text-red-600 animate-pulse'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                    }`}
                  >
                    {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
                  </button>
                  <button className="p-2 bg-slate-100 text-slate-600 rounded-lg hover:bg-slate-200 transition-colors">
                    <Camera className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {isListening && (
                <div className="mt-3 flex items-center gap-2 text-red-600">
                  <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
                  <span className="text-sm">Listening...</span>
                </div>
              )}

              {/* Quick suggestions */}
              <div className="mt-4">
                <p className="text-sm text-slate-500 mb-2">Quick suggestions:</p>
                <div className="flex flex-wrap gap-2">
                  {['Leaky faucet', 'Schedule cleaning', 'Pick up dry cleaning', 'AC not cooling'].map((suggestion) => (
                    <button
                      key={suggestion}
                      onClick={() => setDescription(suggestion)}
                      className="px-3 py-1.5 bg-slate-100 text-slate-700 rounded-full text-sm hover:bg-slate-200 transition-colors"
                    >
                      {suggestion}
                    </button>
                  ))}
                </div>
              </div>

              {/* Next Button */}
              <button
                onClick={handleNext}
                disabled={!description.trim()}
                className="w-full mt-6 py-3 bg-emerald-600 text-white font-medium rounded-xl hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                Next
                <ChevronRight className="w-5 h-5" />
              </button>
            </>
          ) : (
            <>
              {/* Show what they typed */}
              <div className="p-4 bg-slate-50 rounded-xl mb-6">
                <p className="text-sm text-slate-500">Your request:</p>
                <p className="text-slate-900 font-medium mt-1">{description}</p>
              </div>

              {/* Category Selection */}
              <p className="text-sm text-slate-700 font-medium mb-3">What type of help is this?</p>
              <div className="grid grid-cols-5 gap-2">
                {QUICK_CATEGORIES.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => handleCategorySelect(cat.id)}
                    className={`flex flex-col items-center p-3 rounded-xl border-2 transition-all ${
                      selectedCategory === cat.id
                        ? 'border-emerald-500 bg-emerald-50'
                        : 'border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    <div className={`p-2 rounded-lg ${cat.color}`}>
                      <cat.icon className="w-5 h-5" />
                    </div>
                    <span className="text-xs font-medium text-slate-700 mt-2">{cat.label}</span>
                  </button>
                ))}
              </div>

              {/* Submit */}
              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => setStep('input')}
                  className="flex-1 py-3 border border-slate-300 text-slate-700 font-medium rounded-xl hover:bg-slate-50 transition-colors"
                >
                  Back
                </button>
                <button
                  onClick={handleSubmit}
                  disabled={!selectedCategory || isSubmitting}
                  className="flex-1 py-3 bg-emerald-600 text-white font-medium rounded-xl hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Sending...
                    </>
                  ) : (
                    <>
                      <Send className="w-5 h-5" />
                      Send to {HOUSING_MANAGER.name}
                    </>
                  )}
                </button>
              </div>

              {/* Manager Note */}
              <p className="text-center text-sm text-slate-500 mt-4">
                {HOUSING_MANAGER.name} will take it from here. You&apos;ll only hear from us if we need something.
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

// Success Toast
function SuccessToast({ onClose }: { onClose: () => void }) {
  useEffect(() => {
    const timer = setTimeout(onClose, 4000);
    return () => clearTimeout(timer);
  }, [onClose]);

  return (
    <div className="fixed top-4 left-1/2 -translate-x-1/2 z-[60] animate-in slide-in-from-top-2">
      <div className="flex items-center gap-3 px-4 py-3 bg-emerald-600 text-white rounded-xl shadow-lg">
        <CheckCircle2 className="w-5 h-5" />
        <span className="font-medium">Request sent! {HOUSING_MANAGER.name} is on it.</span>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function RequestsPage() {
  const { currentHousehold } = useAuth();
  const [showQuickRequest, setShowQuickRequest] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const [viewMode, setViewMode] = useState<'active' | 'history'>('active');
  const [needsInput, setNeedsInput] = useState<HomeownerInput[]>(MOCK_NEEDS_INPUT);
  const [activeRequests, setActiveRequests] = useState<ActiveRequest[]>(MOCK_ACTIVE_REQUESTS);
  const [completedRequests, setCompletedRequests] = useState<CompletedRequest[]>(MOCK_COMPLETED);

  const handleSubmitRequest = (category: QuickCategory, description: string) => {
    // In real app, this would call the API
    const newRequest: ActiveRequest = {
      id: `req-${Date.now()}`,
      title: description,
      status: 'received',
      statusMessage: `${HOUSING_MANAGER.name} is reviewing`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setActiveRequests((prev) => [newRequest, ...prev]);
    setShowQuickRequest(false);
    setShowSuccess(true);
  };

  const handleInputRespond = (inputId: string, response: string) => {
    setNeedsInput((prev) => prev.filter((i) => i.id !== inputId));
    // In real app, this would call the API
  };

  const handleRate = (requestId: string, rating: number) => {
    setCompletedRequests((prev) =>
      prev.map((r) => (r.id === requestId ? { ...r, rating } : r))
    );
  };

  const activeCount = activeRequests.length;
  const needsInputCount = needsInput.length;

  return (
    <div className="pb-32 lg:pb-8 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold text-slate-900">Requests</h1>
          <p className="text-slate-500 mt-1">Your home manager handles everything</p>
        </div>
      </div>

      {/* Manager Summary */}
      <ManagerSummaryCard
        activeCount={activeCount}
        needsInputCount={needsInputCount}
        onExpand={() => setIsExpanded(!isExpanded)}
        isExpanded={isExpanded}
      />

      {/* Needs Your Input Section - Always Visible */}
      {needsInput.length > 0 && (
        <div className="mt-6">
          <div className="flex items-center gap-2 mb-4">
            <Bell className="w-5 h-5 text-amber-600" />
            <h2 className="text-lg font-semibold text-slate-900">Needs Your Input</h2>
            <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-sm font-medium rounded-full">
              {needsInput.length}
            </span>
          </div>
          <div className="space-y-4">
            {needsInput.map((input) => (
              <NeedsInputCard key={input.id} input={input} onRespond={handleInputRespond} />
            ))}
          </div>
        </div>
      )}

      {/* Expanded View - Active Requests */}
      {isExpanded && (
        <div className="mt-6">
          {/* View Toggle */}
          <div className="flex bg-slate-100 rounded-lg p-1 mb-4">
            <button
              onClick={() => setViewMode('active')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                viewMode === 'active'
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Clock className="w-4 h-4" />
              In Progress
              <span className="px-1.5 py-0.5 bg-slate-200 rounded text-xs">{activeCount}</span>
            </button>
            <button
              onClick={() => setViewMode('history')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                viewMode === 'history'
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Archive className="w-4 h-4" />
              History
              <span className="px-1.5 py-0.5 bg-slate-200 rounded text-xs">{completedRequests.length}</span>
            </button>
          </div>

          {viewMode === 'active' ? (
            <div className="space-y-3">
              {activeRequests.map((request) => (
                <ActiveRequestMiniCard key={request.id} request={request} />
              ))}
              {activeRequests.length === 0 && (
                <div className="text-center py-8 text-slate-500">
                  <CheckCircle2 className="w-12 h-12 mx-auto mb-3 text-emerald-600" />
                  <p className="font-medium text-slate-900">All caught up!</p>
                  <p className="text-sm">No active requests right now</p>
                </div>
              )}
            </div>
          ) : (
            <div className="space-y-3">
              {completedRequests.map((request) => (
                <CompletedRequestCard
                  key={request.id}
                  request={request}
                  onRate={handleRate}
                />
              ))}
              {completedRequests.length === 0 && (
                <div className="text-center py-8 text-slate-500">
                  <Archive className="w-12 h-12 mx-auto mb-3 text-slate-400" />
                  <p className="font-medium text-slate-900">No history yet</p>
                  <p className="text-sm">Completed requests will appear here</p>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* New Request FAB */}
      <button
        onClick={() => setShowQuickRequest(true)}
        className="fixed bottom-36 right-4 lg:bottom-8 lg:right-8 flex items-center gap-2 px-5 py-3 bg-emerald-600 text-white font-medium rounded-full shadow-lg hover:bg-emerald-700 transition-colors z-40"
      >
        <Plus className="w-5 h-5" />
        <span className="hidden sm:inline">I need...</span>
      </button>

      {/* Quick Request Modal */}
      {showQuickRequest && (
        <QuickRequestModal
          onClose={() => setShowQuickRequest(false)}
          onSubmit={handleSubmitRequest}
        />
      )}

      {/* Success Toast */}
      {showSuccess && <SuccessToast onClose={() => setShowSuccess(false)} />}
    </div>
  );
}
