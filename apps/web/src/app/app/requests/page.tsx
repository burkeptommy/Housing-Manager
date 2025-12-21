'use client';

import { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { getDemoImage } from '@/lib/imageUtils';
import { useAuth } from '@/contexts/auth-context';
import {
  X,
  Wrench,
  Star,
  Camera,
  Mic,
  MicOff,
  ChevronRight,
  MessageSquare,
  Clock,
  CheckCircle2,
  DollarSign,
  Send,
  Archive,
  Shield,
  HelpCircle,
  Loader2,
  AlertCircle,
  Search,
  Headphones,
  ShoppingCart,
  Calendar,
  RefreshCw,
  Bell,
  ThumbsUp,
  ThumbsDown,
  Check,
  Sparkles,
  PartyPopper,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

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
  infoPlaceholder?: string; // For info type - what kind of info is needed
  urgent: boolean;
  createdAt: string;
}

interface ActiveRequest {
  id: string;
  title: string;
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
  photos?: string[];
  summary?: string;
  addedToMaintenance?: boolean;
  acknowledged?: boolean;
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

const QUICK_PICKS = [
  { label: 'Something\'s broken', icon: Wrench },
  { label: 'Schedule service', icon: Calendar },
  { label: 'Need to buy', icon: ShoppingCart },
  { label: 'Question', icon: HelpCircle },
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
  {
    id: 'input-4',
    requestId: 'req-4',
    requestTitle: 'Bedroom paint refresh',
    type: 'info',
    question: 'What paint color would you like?',
    infoPlaceholder: 'e.g., Soft white, light gray, Benjamin Moore Sea Salt...',
    urgent: false,
    createdAt: new Date().toISOString(),
  },
];

const MOCK_ACTIVE_REQUESTS: ActiveRequest[] = [
  {
    id: 'req-5',
    title: 'Pool filter replacement',
    statusMessage: 'Pool Pro is on site now',
    vendor: { name: 'Pool Pro Services', avatar: getDemoImage('vendor-portrait', 100, 100, 'pool-pro') },
    createdAt: '2024-12-18T09:00:00Z',
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'req-6',
    title: 'Weekly housekeeping',
    statusMessage: 'Scheduled for Friday 9am',
    vendor: { name: 'Sparkle Clean', avatar: getDemoImage('avatar-female', 100, 100, 'maria') },
    scheduledDate: '2024-12-20T09:00:00Z',
    createdAt: '2024-12-17T10:00:00Z',
    updatedAt: '2024-12-17T11:00:00Z',
  },
  {
    id: 'req-1',
    title: 'Kitchen faucet replacement',
    statusMessage: 'Finding best options for you',
    createdAt: '2024-12-18T08:00:00Z',
    updatedAt: '2024-12-18T08:30:00Z',
  },
  {
    id: 'req-7',
    title: 'Smoke detector batteries',
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
    photos: [getDemoImage('home-repair', 300, 200, 'hvac-done')],
    summary: 'Replaced HVAC filter and cleaned vents. System running efficiently.',
    acknowledged: false,
  },
  {
    id: 'comp-2',
    title: 'Utility bill inquiry',
    completedAt: '2024-12-06T10:00:00Z',
    summary: 'Contacted power company. Bill was estimated - actual reading shows you\'re owed $47 credit.',
    rating: 4,
    acknowledged: true,
  },
  {
    id: 'comp-3',
    title: 'Tree branch removal',
    completedAt: '2024-12-01T16:00:00Z',
    vendor: 'Green Thumb Landscaping',
    cost: 175,
    photos: [getDemoImage('landscape', 300, 200, 'tree-done')],
    summary: 'Removed overhanging branch from oak tree. Area cleaned up.',
    rating: 5,
    addedToMaintenance: true,
    acknowledged: true,
  },
];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Simple inline request creation - one text input
function QuickRequestInput({
  onSubmit,
  isSubmitting,
}: {
  onSubmit: (description: string) => void;
  isSubmitting: boolean;
}) {
  const [description, setDescription] = useState('');
  const [isListening, setIsListening] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleVoiceInput = () => {
    setIsListening(!isListening);
    if (!isListening) {
      // Simulate voice input
      setTimeout(() => {
        setDescription('Kitchen faucet is dripping');
        setIsListening(false);
      }, 2000);
    }
  };

  const handleSubmit = () => {
    if (description.trim() && !isSubmitting) {
      onSubmit(description.trim());
      setDescription('');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div className="p-4">
        <div className="flex items-center gap-3">
          <input
            ref={inputRef}
            type="text"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="What do you need help with?"
            className="flex-1 text-lg bg-transparent border-none outline-none placeholder:text-slate-400"
            disabled={isSubmitting}
          />
          <button
            onClick={handleVoiceInput}
            className={`p-2 rounded-full transition-colors ${
              isListening
                ? 'bg-red-100 text-red-600 animate-pulse'
                : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
            }`}
            disabled={isSubmitting}
          >
            {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
          </button>
          <button
            className="p-2 bg-slate-100 text-slate-500 rounded-full hover:bg-slate-200 transition-colors"
            disabled={isSubmitting}
          >
            <Camera className="w-5 h-5" />
          </button>
          {description.trim() && (
            <button
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="p-2 bg-emerald-600 text-white rounded-full hover:bg-emerald-700 transition-colors disabled:opacity-50"
            >
              {isSubmitting ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Send className="w-5 h-5" />
              )}
            </button>
          )}
        </div>

        {isListening && (
          <div className="mt-3 flex items-center gap-2 text-red-600">
            <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
            <span className="text-sm">Listening...</span>
          </div>
        )}
      </div>

      {/* Quick picks */}
      <div className="px-4 pb-4 flex flex-wrap gap-2">
        {QUICK_PICKS.map((pick) => (
          <button
            key={pick.label}
            onClick={() => setDescription(pick.label)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-50 text-slate-600 rounded-full text-sm hover:bg-slate-100 transition-colors"
            disabled={isSubmitting}
          >
            <pick.icon className="w-3.5 h-3.5" />
            {pick.label}
          </button>
        ))}
      </div>
    </div>
  );
}

// Sarah is handling summary
function ManagerSummaryCard({
  activeCount,
  needsInputCount,
  onViewDetails,
}: {
  activeCount: number;
  needsInputCount: number;
  onViewDetails: () => void;
}) {
  if (activeCount === 0 && needsInputCount === 0) {
    return (
      <div className="bg-emerald-50 rounded-xl p-4 flex items-center gap-4">
        <div className="p-3 bg-emerald-100 rounded-full">
          <CheckCircle2 className="w-6 h-6 text-emerald-600" />
        </div>
        <div>
          <p className="font-medium text-emerald-900">All caught up!</p>
          <p className="text-sm text-emerald-700">No active requests right now</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-xl p-4 text-white">
      <div className="flex items-center gap-3">
        <div className="relative">
          <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center">
            <Headphones className="w-6 h-6" />
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-emerald-400 rounded-full flex items-center justify-center">
            <Check className="w-2.5 h-2.5 text-white" />
          </div>
        </div>
        <div className="flex-1">
          <p className="font-semibold">
            {HOUSING_MANAGER.name} is handling {activeCount} {activeCount === 1 ? 'request' : 'requests'}
          </p>
          {needsInputCount > 0 && (
            <p className="text-emerald-100 text-sm">
              {needsInputCount} {needsInputCount === 1 ? 'needs' : 'need'} your input
            </p>
          )}
        </div>
        <button
          onClick={onViewDetails}
          className="p-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
        >
          <ChevronRight className="w-5 h-5" />
        </button>
      </div>
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
  const [textResponse, setTextResponse] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    const response = input.type === 'info' ? textResponse : selectedOption;
    if (!response) return;
    setIsSubmitting(true);
    await new Promise((r) => setTimeout(r, 500));
    onRespond(input.id, response);
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
      case 'info':
        return <MessageSquare className="w-5 h-5 text-indigo-600" />;
      default:
        return <MessageSquare className="w-5 h-5 text-slate-600" />;
    }
  };

  const canSubmit = input.type === 'info' ? textResponse.trim() : selectedOption;

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

        {/* Info - Free text response */}
        {input.type === 'info' && (
          <div className="mb-4">
            <textarea
              value={textResponse}
              onChange={(e) => setTextResponse(e.target.value)}
              placeholder={input.infoPlaceholder || 'Type your response...'}
              rows={3}
              className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent resize-none text-sm"
            />
          </div>
        )}

        {/* Submit Button */}
        {canSubmit && (
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

// Completion Acknowledgment Card - Shows when work is done
function CompletionCard({
  request,
  onAcknowledge,
  onRate,
}: {
  request: CompletedRequest;
  onAcknowledge: (id: string) => void;
  onRate: (id: string, rating: number) => void;
}) {
  const [selectedRating, setSelectedRating] = useState(request.rating || 0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleAcknowledge = async () => {
    setIsSubmitting(true);
    if (selectedRating > 0) {
      onRate(request.id, selectedRating);
    }
    await new Promise((r) => setTimeout(r, 500));
    onAcknowledge(request.id);
    setIsSubmitting(false);
  };

  return (
    <div className="bg-white rounded-xl border-2 border-emerald-200 shadow-sm overflow-hidden">
      <div className="bg-emerald-50 px-4 py-3 flex items-center gap-2 border-b border-emerald-200">
        <PartyPopper className="w-5 h-5 text-emerald-600" />
        <span className="font-medium text-emerald-800">Completed!</span>
      </div>

      <div className="p-4">
        <h3 className="font-semibold text-slate-900 text-lg">{request.title}</h3>

        {request.summary && (
          <p className="text-slate-600 text-sm mt-2">{request.summary}</p>
        )}

        {/* Photos */}
        {request.photos && request.photos.length > 0 && (
          <div className="mt-4 flex gap-2 overflow-x-auto pb-2">
            {request.photos.map((photo, i) => (
              <div key={i} className="relative w-32 h-24 flex-shrink-0 rounded-lg overflow-hidden bg-slate-100">
                <Image src={photo} alt="Completion photo" fill className="object-cover" />
              </div>
            ))}
          </div>
        )}

        {/* Cost & Vendor */}
        <div className="mt-4 flex items-center gap-4 text-sm">
          {request.vendor && (
            <span className="text-slate-600">By {request.vendor}</span>
          )}
          {request.cost && (
            <span className="font-medium text-slate-900">${request.cost.toLocaleString()}</span>
          )}
        </div>

        {/* Rating */}
        {!request.rating && (
          <div className="mt-4 pt-4 border-t border-slate-100">
            <p className="text-sm text-slate-600 mb-2">How did we do?</p>
            <div className="flex items-center gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  onClick={() => setSelectedRating(star)}
                  className="p-1"
                >
                  <Star
                    className={`w-7 h-7 transition-colors ${
                      star <= selectedRating
                        ? 'text-amber-400 fill-amber-400'
                        : 'text-slate-200 hover:text-amber-300'
                    }`}
                  />
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Acknowledge Button */}
        <button
          onClick={handleAcknowledge}
          disabled={isSubmitting}
          className="w-full mt-4 py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
        >
          {isSubmitting ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <>
              <CheckCircle2 className="w-4 h-4" />
              Looks good!
            </>
          )}
        </button>
      </div>
    </div>
  );
}

// Active Request Mini Card - Minimal info
function ActiveRequestMiniCard({ request }: { request: ActiveRequest }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
      <div className="flex items-start gap-3">
        <div className="flex-1">
          <h3 className="font-medium text-slate-900">{request.title}</h3>
          <p className="text-sm text-emerald-600 mt-1">{request.statusMessage}</p>

          {request.isRecurring && (
            <div className="mt-2 flex items-center gap-1.5 text-amber-600">
              <RefreshCw className="w-3.5 h-3.5" />
              <span className="text-xs">Recurring issue</span>
            </div>
          )}
        </div>

        {request.vendor && (
          <div className="relative w-10 h-10 rounded-full overflow-hidden bg-slate-100">
            <Image src={request.vendor.avatar} alt={request.vendor.name} fill className="object-cover" />
          </div>
        )}
      </div>
    </div>
  );
}

// Completed Request Card - For history
function CompletedHistoryCard({ request }: { request: CompletedRequest }) {
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

        {request.rating && (
          <div className="flex items-center gap-0.5">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star
                key={star}
                className={`w-4 h-4 ${star <= request.rating! ? 'text-amber-400 fill-amber-400' : 'text-slate-200'}`}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// Details Modal - Shows all active requests
function DetailsModal({
  activeRequests,
  completedRequests,
  onClose,
}: {
  activeRequests: ActiveRequest[];
  completedRequests: CompletedRequest[];
  onClose: () => void;
}) {
  const [viewMode, setViewMode] = useState<'active' | 'history'>('active');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredHistory = completedRequests.filter((r) =>
    r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (r.vendor && r.vendor.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative w-full h-[85vh] sm:max-w-lg sm:h-auto sm:max-h-[80vh] bg-white rounded-t-2xl sm:rounded-2xl shadow-xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200">
          <h2 className="text-lg font-semibold text-slate-900">Request Details</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex bg-slate-100 m-4 rounded-lg p-1">
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
            <span className="px-1.5 py-0.5 bg-emerald-100 text-emerald-700 rounded text-xs">{activeRequests.length}</span>
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
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto px-4 pb-4">
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
            <>
              {/* Search */}
              <div className="relative mb-4">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search history..."
                  className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                />
              </div>

              <div className="space-y-3">
                {filteredHistory.map((request) => (
                  <CompletedHistoryCard key={request.id} request={request} />
                ))}
                {filteredHistory.length === 0 && (
                  <div className="text-center py-8 text-slate-500">
                    <Archive className="w-12 h-12 mx-auto mb-3 text-slate-400" />
                    <p className="font-medium text-slate-900">
                      {searchQuery ? 'No matching requests' : 'No history yet'}
                    </p>
                    <p className="text-sm">
                      {searchQuery ? 'Try a different search' : 'Completed requests will appear here'}
                    </p>
                  </div>
                )}
              </div>
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
        <span className="font-medium">Got it! {HOUSING_MANAGER.name} is on it.</span>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function RequestsPage() {
  useAuth(); // Will use for API calls when connected
  const [showDetails, setShowDetails] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [needsInput, setNeedsInput] = useState<HomeownerInput[]>(MOCK_NEEDS_INPUT);
  const [activeRequests, setActiveRequests] = useState<ActiveRequest[]>(MOCK_ACTIVE_REQUESTS);
  const [completedRequests, setCompletedRequests] = useState<CompletedRequest[]>(MOCK_COMPLETED);

  // Separate unacknowledged completions
  const unacknowledgedCompletions = completedRequests.filter((r) => !r.acknowledged);
  const acknowledgedHistory = completedRequests.filter((r) => r.acknowledged);

  const handleSubmitRequest = async (description: string) => {
    setIsSubmitting(true);
    await new Promise((r) => setTimeout(r, 800));

    const newRequest: ActiveRequest = {
      id: `req-${Date.now()}`,
      title: description,
      statusMessage: `${HOUSING_MANAGER.name} is reviewing`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setActiveRequests((prev) => [newRequest, ...prev]);
    setShowSuccess(true);
    setIsSubmitting(false);
  };

  const handleInputRespond = (inputId: string, _response: string) => {
    // In real app, would send response to API
    setNeedsInput((prev) => prev.filter((i) => i.id !== inputId));
  };

  const handleAcknowledge = (requestId: string) => {
    setCompletedRequests((prev) =>
      prev.map((r) => (r.id === requestId ? { ...r, acknowledged: true } : r))
    );
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
      <div className="mb-6">
        <h1 className="text-2xl lg:text-3xl font-bold text-slate-900">Help Requests</h1>
        <p className="text-slate-500 mt-1">Tell us what you need. {HOUSING_MANAGER.name} handles the rest.</p>
      </div>

      {/* Quick Request Input - Always visible at top */}
      <QuickRequestInput onSubmit={handleSubmitRequest} isSubmitting={isSubmitting} />

      {/* Manager Summary - Shows if there are active requests */}
      {(activeCount > 0 || needsInputCount > 0) && (
        <div className="mt-6">
          <ManagerSummaryCard
            activeCount={activeCount}
            needsInputCount={needsInputCount}
            onViewDetails={() => setShowDetails(true)}
          />
        </div>
      )}

      {/* Needs Your Input Section */}
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

      {/* Recently Completed - Needs Acknowledgment */}
      {unacknowledgedCompletions.length > 0 && (
        <div className="mt-6">
          <div className="flex items-center gap-2 mb-4">
            <Sparkles className="w-5 h-5 text-emerald-600" />
            <h2 className="text-lg font-semibold text-slate-900">Just Finished</h2>
          </div>
          <div className="space-y-4">
            {unacknowledgedCompletions.map((request) => (
              <CompletionCard
                key={request.id}
                request={request}
                onAcknowledge={handleAcknowledge}
                onRate={handleRate}
              />
            ))}
          </div>
        </div>
      )}

      {/* Details Modal */}
      {showDetails && (
        <DetailsModal
          activeRequests={activeRequests}
          completedRequests={acknowledgedHistory}
          onClose={() => setShowDetails(false)}
        />
      )}

      {/* Success Toast */}
      {showSuccess && <SuccessToast onClose={() => setShowSuccess(false)} />}
    </div>
  );
}
