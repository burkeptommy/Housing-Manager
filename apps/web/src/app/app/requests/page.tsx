'use client';

import { useState, useEffect, useCallback } from 'react';
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
  FileText,
  Sparkles,
  AlertTriangle,
  Phone,
  Camera,
  Video,
  ChevronRight,
  MessageSquare,
  Clock,
  CheckCircle2,
  User,
  DollarSign,
  Send,
  LayoutList,
  LayoutGrid,
  Archive,
  ArrowLeft,
  Zap,
  Home,
  Shield,
  Package,
  Utensils,
  Car,
  PawPrint,
  Leaf,
  Receipt,
  HelpCircle,
  ExternalLink,
  Loader2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type RequestCategory = 'repair' | 'service' | 'concierge' | 'admin';
type RequestPriority = 'low' | 'medium' | 'high' | 'emergency';
type RequestStatus = 'received' | 'reviewing' | 'scheduled' | 'in_progress' | 'resolved';
type ViewMode = 'active' | 'history';
type DisplayMode = 'list' | 'kanban';

interface RequestTicket {
  id: string;
  ticketNumber: string;
  title: string;
  description: string;
  category: RequestCategory;
  subcategory: string;
  priority: RequestPriority;
  status: RequestStatus;
  createdAt: string;
  updatedAt: string;
  resolvedAt?: string;
  resolutionTime?: string;
  vendor?: {
    id: string;
    name: string;
    avatar: string;
    phone: string;
  };
  mediaUrls: string[];
  allowEntry: boolean;
  rating?: number;
  quote?: {
    amount: number;
    approved: boolean;
  };
  timeline: TimelineEvent[];
  messages: ChatMessage[];
}

interface TimelineEvent {
  id: string;
  type: 'created' | 'updated' | 'assigned' | 'scheduled' | 'started' | 'completed' | 'message';
  description: string;
  timestamp: string;
  actor?: string;
}

interface ChatMessage {
  id: string;
  senderId: string;
  senderName: string;
  senderRole: 'user' | 'manager' | 'vendor';
  senderAvatar?: string;
  content: string;
  timestamp: string;
  attachments?: string[];
}

interface CategoryOption {
  id: RequestCategory;
  label: string;
  description: string;
  icon: typeof Wrench;
  color: string;
  subcategories: string[];
}

interface FormData {
  category: RequestCategory;
  subcategory: string;
  title: string;
  description: string;
  priority: RequestPriority;
  allowEntry: boolean;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const categoryOptions: CategoryOption[] = [
  {
    id: 'repair',
    label: 'Something is Broken',
    description: 'Repairs, maintenance, and fixes',
    icon: Wrench,
    color: 'bg-orange-100 text-orange-600',
    subcategories: ['Plumbing', 'Electrical', 'HVAC', 'Appliances', 'Structural', 'Other'],
  },
  {
    id: 'service',
    label: 'I Need a Pro',
    description: 'Housekeeping, landscaping, specialists',
    icon: Star,
    color: 'bg-blue-100 text-blue-600',
    subcategories: ['Housekeeping', 'Landscaping', 'Pool Service', 'Pest Control', 'Window Cleaning', 'Other'],
  },
  {
    id: 'concierge',
    label: 'Life Help',
    description: 'Errands, bookings, personal assistance',
    icon: Sparkles,
    color: 'bg-purple-100 text-purple-600',
    subcategories: ['Package Pickup', 'Grocery Run', 'Restaurant Booking', 'Travel Arrangements', 'Pet Care', 'Other'],
  },
  {
    id: 'admin',
    label: 'Paperwork',
    description: 'Bills, insurance, documents',
    icon: FileText,
    color: 'bg-slate-100 text-slate-600',
    subcategories: ['Bill Question', 'Insurance Claim', 'Document Request', 'Account Update', 'Other'],
  },
];

const priorityOptions: { id: RequestPriority; label: string; description: string; color: string }[] = [
  { id: 'low', label: 'Low', description: 'Whenever convenient', color: 'bg-slate-100 text-slate-600' },
  { id: 'medium', label: 'Medium', description: 'This week', color: 'bg-blue-100 text-blue-600' },
  { id: 'high', label: 'High', description: 'Urgent - Today', color: 'bg-amber-100 text-amber-600' },
  { id: 'emergency', label: 'Emergency', description: 'Stop everything', color: 'bg-red-100 text-red-600' },
];

const MOCK_TICKETS: RequestTicket[] = [
  {
    id: '1',
    ticketNumber: 'REQ-001',
    title: 'Kitchen faucet leaking',
    description: 'The kitchen faucet has been dripping constantly for the past two days. Water is pooling under the sink.',
    category: 'repair',
    subcategory: 'Plumbing',
    priority: 'high',
    status: 'in_progress',
    createdAt: '2024-12-18T09:00:00Z',
    updatedAt: '2024-12-18T14:30:00Z',
    vendor: {
      id: 'v1',
      name: 'Mike\'s Plumbing',
      avatar: getDemoImage('vendor-portrait', 100, 100, 'mike-plumber'),
      phone: '+1 (310) 555-0111',
    },
    mediaUrls: [getDemoImage('bathroom', 400, 300, 'leak-1')],
    allowEntry: true,
    timeline: [
      { id: 't1', type: 'created', description: 'Request submitted', timestamp: '2024-12-18T09:00:00Z', actor: 'Bob Chen' },
      { id: 't2', type: 'updated', description: 'Marked as high priority', timestamp: '2024-12-18T09:05:00Z', actor: 'Steve Manager' },
      { id: 't3', type: 'assigned', description: 'Assigned to Mike\'s Plumbing', timestamp: '2024-12-18T09:30:00Z', actor: 'Steve Manager' },
      { id: 't4', type: 'scheduled', description: 'Scheduled for today 2:00 PM', timestamp: '2024-12-18T10:00:00Z', actor: 'Mike\'s Plumbing' },
      { id: 't5', type: 'started', description: 'Work started', timestamp: '2024-12-18T14:00:00Z', actor: 'Mike\'s Plumbing' },
    ],
    messages: [
      { id: 'm1', senderId: 'u1', senderName: 'Bob Chen', senderRole: 'user', content: 'Here is a photo of the leak under the sink.', timestamp: '2024-12-18T09:02:00Z', attachments: [getDemoImage('bathroom', 400, 300, 'leak-photo')] },
      { id: 'm2', senderId: 's1', senderName: 'Steve Manager', senderRole: 'manager', content: 'Thanks Bob! I\'ve escalated this and Mike is on his way. He should arrive around 2 PM.', timestamp: '2024-12-18T09:35:00Z' },
      { id: 'm3', senderId: 'v1', senderName: 'Mike\'s Plumbing', senderRole: 'vendor', content: 'On my way! I\'ll text when I arrive at the gate.', timestamp: '2024-12-18T13:45:00Z' },
    ],
  },
  {
    id: '2',
    ticketNumber: 'REQ-002',
    title: 'Weekly housekeeping',
    description: 'Schedule regular weekly cleaning service',
    category: 'service',
    subcategory: 'Housekeeping',
    priority: 'low',
    status: 'scheduled',
    createdAt: '2024-12-17T10:00:00Z',
    updatedAt: '2024-12-17T11:00:00Z',
    vendor: {
      id: 'v2',
      name: 'Sparkle Clean Co',
      avatar: getDemoImage('avatar-female', 100, 100, 'maria-cleaner'),
      phone: '+1 (310) 555-0222',
    },
    mediaUrls: [],
    allowEntry: true,
    timeline: [
      { id: 't1', type: 'created', description: 'Request submitted', timestamp: '2024-12-17T10:00:00Z', actor: 'Alice Chen' },
      { id: 't2', type: 'assigned', description: 'Assigned to Sparkle Clean Co', timestamp: '2024-12-17T10:30:00Z', actor: 'Steve Manager' },
      { id: 't3', type: 'scheduled', description: 'Scheduled for every Friday 9:00 AM', timestamp: '2024-12-17T11:00:00Z', actor: 'Sparkle Clean Co' },
    ],
    messages: [
      { id: 'm1', senderId: 's1', senderName: 'Steve Manager', senderRole: 'manager', content: 'I\'ve arranged Maria from Sparkle Clean to come every Friday morning. Does 9 AM work?', timestamp: '2024-12-17T10:45:00Z' },
      { id: 'm2', senderId: 'u1', senderName: 'Alice Chen', senderRole: 'user', content: 'Perfect! 9 AM works great.', timestamp: '2024-12-17T10:50:00Z' },
    ],
  },
  {
    id: '3',
    ticketNumber: 'REQ-003',
    title: 'Smoke detector batteries',
    description: 'Smoke detectors on second floor are beeping - need new batteries',
    category: 'repair',
    subcategory: 'Electrical',
    priority: 'medium',
    status: 'received',
    createdAt: '2024-12-19T08:00:00Z',
    updatedAt: '2024-12-19T08:00:00Z',
    mediaUrls: [],
    allowEntry: true,
    timeline: [
      { id: 't1', type: 'created', description: 'Request submitted', timestamp: '2024-12-19T08:00:00Z', actor: 'Bob Chen' },
    ],
    messages: [],
  },
  {
    id: '4',
    ticketNumber: 'REQ-004',
    title: 'Pick up dry cleaning',
    description: 'Need someone to pick up dry cleaning from Beverly Cleaners on Wilshire',
    category: 'concierge',
    subcategory: 'Package Pickup',
    priority: 'low',
    status: 'reviewing',
    createdAt: '2024-12-18T16:00:00Z',
    updatedAt: '2024-12-18T16:30:00Z',
    mediaUrls: [],
    allowEntry: false,
    timeline: [
      { id: 't1', type: 'created', description: 'Request submitted', timestamp: '2024-12-18T16:00:00Z', actor: 'Alice Chen' },
      { id: 't2', type: 'updated', description: 'Under review', timestamp: '2024-12-18T16:30:00Z', actor: 'Steve Manager' },
    ],
    messages: [
      { id: 'm1', senderId: 's1', senderName: 'Steve Manager', senderRole: 'manager', content: 'I can have someone pick this up tomorrow morning. Is there a ticket number?', timestamp: '2024-12-18T16:35:00Z' },
    ],
  },
  {
    id: '5',
    ticketNumber: 'REQ-005',
    title: 'HVAC filter replacement',
    description: 'Replaced all HVAC filters throughout the house',
    category: 'repair',
    subcategory: 'HVAC',
    priority: 'low',
    status: 'resolved',
    createdAt: '2024-12-10T09:00:00Z',
    updatedAt: '2024-12-12T15:00:00Z',
    resolvedAt: '2024-12-12T15:00:00Z',
    resolutionTime: '2 days',
    vendor: {
      id: 'v3',
      name: 'Cool Air HVAC',
      avatar: getDemoImage('vendor-portrait', 100, 100, 'hvac-tech'),
      phone: '+1 (310) 555-0333',
    },
    mediaUrls: [],
    allowEntry: true,
    rating: 5,
    timeline: [
      { id: 't1', type: 'created', description: 'Request submitted', timestamp: '2024-12-10T09:00:00Z', actor: 'Bob Chen' },
      { id: 't2', type: 'assigned', description: 'Assigned to Cool Air HVAC', timestamp: '2024-12-10T10:00:00Z', actor: 'Steve Manager' },
      { id: 't3', type: 'scheduled', description: 'Scheduled for Dec 12', timestamp: '2024-12-10T11:00:00Z', actor: 'Cool Air HVAC' },
      { id: 't4', type: 'completed', description: 'Work completed', timestamp: '2024-12-12T15:00:00Z', actor: 'Cool Air HVAC' },
    ],
    messages: [],
  },
  {
    id: '6',
    ticketNumber: 'REQ-006',
    title: 'Question about utility bill',
    description: 'The electricity bill seems unusually high this month. Can someone look into it?',
    category: 'admin',
    subcategory: 'Bill Question',
    priority: 'low',
    status: 'resolved',
    createdAt: '2024-12-05T14:00:00Z',
    updatedAt: '2024-12-06T10:00:00Z',
    resolvedAt: '2024-12-06T10:00:00Z',
    resolutionTime: '20 hours',
    mediaUrls: [],
    allowEntry: false,
    rating: 4,
    timeline: [
      { id: 't1', type: 'created', description: 'Request submitted', timestamp: '2024-12-05T14:00:00Z', actor: 'Bob Chen' },
      { id: 't2', type: 'completed', description: 'Issue resolved', timestamp: '2024-12-06T10:00:00Z', actor: 'Steve Manager' },
    ],
    messages: [
      { id: 'm1', senderId: 's1', senderName: 'Steve Manager', senderRole: 'manager', content: 'I checked with the utility company - the spike was due to an estimated reading. They\'ll adjust next month. I\'ve also requested actual meter reads going forward.', timestamp: '2024-12-06T10:00:00Z' },
      { id: 'm2', senderId: 'u1', senderName: 'Bob Chen', senderRole: 'user', content: 'Great, thanks for looking into this!', timestamp: '2024-12-06T10:15:00Z' },
    ],
  },
];

const subcategoryIcons: Record<string, typeof Wrench> = {
  'Plumbing': Wrench,
  'Electrical': Zap,
  'HVAC': Home,
  'Appliances': Home,
  'Housekeeping': Sparkles,
  'Landscaping': Leaf,
  'Pool Service': Home,
  'Pest Control': Shield,
  'Package Pickup': Package,
  'Grocery Run': Utensils,
  'Pet Care': PawPrint,
  'Travel Arrangements': Car,
  'Bill Question': Receipt,
  'Insurance Claim': Shield,
  'Document Request': FileText,
};

// ============================================================================
// DATA MAPPING FUNCTIONS
// ============================================================================

function mapApiStatusToUI(apiStatus: ServiceRequestStatus): RequestStatus {
  switch (apiStatus) {
    case 'DRAFT':
    case 'SUBMITTED':
      return 'received';
    case 'ASSIGNED':
      return 'scheduled';
    case 'IN_PROGRESS':
      return 'in_progress';
    case 'COMPLETED':
      return 'resolved';
    case 'CANCELLED':
      return 'resolved';
    default:
      return 'received';
  }
}

function mapUIPriorityToApi(uiPriority: RequestPriority): ServiceRequestPriority {
  switch (uiPriority) {
    case 'low':
      return 'LOW';
    case 'medium':
      return 'MEDIUM';
    case 'high':
      return 'HIGH';
    case 'emergency':
      return 'URGENT';
    default:
      return 'MEDIUM';
  }
}

function mapApiPriorityToUI(apiPriority: ServiceRequestPriority): RequestPriority {
  switch (apiPriority) {
    case 'LOW':
      return 'low';
    case 'MEDIUM':
      return 'medium';
    case 'HIGH':
      return 'high';
    case 'URGENT':
      return 'emergency';
    default:
      return 'medium';
  }
}

function mapCategoryNameToUI(categoryName?: string): RequestCategory {
  if (!categoryName) return 'repair';
  const lower = categoryName.toLowerCase();
  if (lower.includes('repair') || lower.includes('maintenance') || lower.includes('plumbing') || lower.includes('electrical') || lower.includes('hvac')) {
    return 'repair';
  }
  if (lower.includes('service') || lower.includes('cleaning') || lower.includes('landscape')) {
    return 'service';
  }
  if (lower.includes('concierge') || lower.includes('errand') || lower.includes('booking')) {
    return 'concierge';
  }
  if (lower.includes('admin') || lower.includes('bill') || lower.includes('document') || lower.includes('insurance')) {
    return 'admin';
  }
  return 'repair';
}

function mapApiRequestToTicket(apiReq: ServiceRequestDetail | ServiceRequest): RequestTicket {
  const detail = apiReq as ServiceRequestDetail;
  const createdAtStr = typeof apiReq.createdAt === 'string' ? apiReq.createdAt : new Date(apiReq.createdAt).toISOString();
  const updatedAtStr = typeof apiReq.updatedAt === 'string' ? apiReq.updatedAt : new Date(apiReq.updatedAt).toISOString();

  // Generate a readable ticket number from the ID
  const ticketNumber = `REQ-${apiReq.id.substring(0, 6).toUpperCase()}`;

  // Determine category and subcategory from the service category
  const categoryName = detail.serviceCategory?.name || '';
  const category = mapCategoryNameToUI(categoryName);
  const subcategory = categoryName || 'Other';

  // Calculate resolution time if completed
  let resolutionTime: string | undefined;
  let resolvedAt: string | undefined;
  if (apiReq.completedDate) {
    resolvedAt = typeof apiReq.completedDate === 'string' ? apiReq.completedDate : new Date(apiReq.completedDate).toISOString();
    const created = new Date(apiReq.createdAt);
    const completed = new Date(apiReq.completedDate);
    const diffMs = completed.getTime() - created.getTime();
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays > 0) {
      resolutionTime = `${diffDays} day${diffDays > 1 ? 's' : ''}`;
    } else {
      resolutionTime = `${diffHours} hour${diffHours !== 1 ? 's' : ''}`;
    }
  }

  // Construct basic timeline from createdAt
  const timeline: TimelineEvent[] = [
    {
      id: 't-created',
      type: 'created',
      description: 'Request submitted',
      timestamp: createdAtStr,
      actor: detail.createdBy ? `${detail.createdBy.firstName} ${detail.createdBy.lastName}` : undefined,
    },
  ];

  // Add assigned event if vendor exists
  if (detail.vendor) {
    timeline.push({
      id: 't-assigned',
      type: 'assigned',
      description: `Assigned to ${detail.vendor.companyName}`,
      timestamp: updatedAtStr,
    });
  }

  // Add completed event if resolved
  if (resolvedAt) {
    timeline.push({
      id: 't-completed',
      type: 'completed',
      description: 'Work completed',
      timestamp: resolvedAt,
    });
  }

  return {
    id: apiReq.id,
    ticketNumber,
    title: apiReq.title,
    description: apiReq.description,
    category,
    subcategory,
    priority: mapApiPriorityToUI(apiReq.priority),
    status: mapApiStatusToUI(apiReq.status),
    createdAt: createdAtStr,
    updatedAt: updatedAtStr,
    resolvedAt,
    resolutionTime,
    vendor: detail.vendor ? {
      id: detail.vendor.id,
      name: detail.vendor.companyName,
      avatar: getDemoImage('vendor-portrait', 100, 100, detail.vendor.id),
      phone: '', // API doesn't return phone yet
    } : undefined,
    mediaUrls: [],
    allowEntry: true,
    quote: apiReq.estimatedCost ? {
      amount: apiReq.estimatedCost,
      approved: apiReq.status === 'IN_PROGRESS' || apiReq.status === 'COMPLETED',
    } : undefined,
    timeline,
    messages: [], // Messages loaded separately
  };
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Category Selection Step
function CategoryStep({
  onSelect,
}: {
  onSelect: (category: RequestCategory) => void;
}) {
  return (
    <div className="space-y-4">
      <div className="text-center mb-6">
        <h3 className="text-lg font-semibold text-slate-900">What do you need?</h3>
        <p className="text-sm text-slate-500 mt-1">Select the type of help you need</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {categoryOptions.map((option) => (
          <button
            key={option.id}
            onClick={() => onSelect(option.id)}
            className="flex items-start gap-4 p-4 bg-white rounded-xl border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50 transition-all text-left group"
          >
            <div className={`p-3 rounded-xl ${option.color}`}>
              <option.icon className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <p className="font-semibold text-slate-900 group-hover:text-emerald-700">{option.label}</p>
              <p className="text-sm text-slate-500">{option.description}</p>
            </div>
            <ChevronRight className="w-5 h-5 text-slate-300 group-hover:text-emerald-500 mt-1" />
          </button>
        ))}
      </div>
    </div>
  );
}

// Request Form
function RequestForm({
  category,
  onBack,
  onSubmit,
  isSubmitting,
}: {
  category: RequestCategory;
  onBack: () => void;
  onSubmit: (data: FormData) => void;
  isSubmitting: boolean;
}) {
  const categoryInfo = categoryOptions.find((c) => c.id === category)!;
  const [subcategory, setSubcategory] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<RequestPriority>('medium');
  const [allowEntry, setAllowEntry] = useState(true);
  const [showEmergencyWarning, setShowEmergencyWarning] = useState(false);

  const handlePriorityChange = (p: RequestPriority) => {
    if (p === 'emergency') {
      setShowEmergencyWarning(true);
    } else {
      setPriority(p);
    }
  };

  const confirmEmergency = () => {
    setPriority('emergency');
    setShowEmergencyWarning(false);
  };

  const handleSubmit = () => {
    if (!title.trim()) return;
    onSubmit({
      category,
      subcategory: subcategory || 'Other',
      title,
      description,
      priority,
      allowEntry,
    });
  };

  const suggestedTitles: Record<string, string[]> = {
    'Plumbing': ['Leaking faucet', 'Clogged drain', 'Running toilet', 'Water heater issue'],
    'Electrical': ['Light not working', 'Outlet not working', 'Circuit breaker tripping', 'Smoke detector beeping'],
    'HVAC': ['AC not cooling', 'Heater not working', 'Thermostat issue', 'Air filter replacement'],
    'Housekeeping': ['Deep cleaning', 'Regular cleaning', 'Move-in/out cleaning', 'Post-party cleanup'],
    'Package Pickup': ['Pick up dry cleaning', 'Receive delivery', 'Return package', 'Pick up prescription'],
  };

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button
          onClick={onBack}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          disabled={isSubmitting}
        >
          <ArrowLeft className="w-5 h-5 text-slate-600" />
        </button>
        <div className={`p-2 rounded-lg ${categoryInfo.color}`}>
          <categoryInfo.icon className="w-5 h-5" />
        </div>
        <div>
          <h3 className="font-semibold text-slate-900">{categoryInfo.label}</h3>
          <p className="text-sm text-slate-500">{categoryInfo.description}</p>
        </div>
      </div>

      {/* Subcategory */}
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-2">Type</label>
        <div className="flex flex-wrap gap-2">
          {categoryInfo.subcategories.map((sub) => (
            <button
              key={sub}
              onClick={() => setSubcategory(sub)}
              disabled={isSubmitting}
              className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                subcategory === sub
                  ? 'bg-emerald-600 text-white'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {sub}
            </button>
          ))}
        </div>
      </div>

      {/* Title with suggestions */}
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-2">Title</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Brief description of your request"
          disabled={isSubmitting}
          className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent disabled:bg-slate-50 disabled:text-slate-500"
        />
        {subcategory && suggestedTitles[subcategory] && (
          <div className="flex flex-wrap gap-2 mt-2">
            {suggestedTitles[subcategory].map((suggestion) => (
              <button
                key={suggestion}
                onClick={() => setTitle(suggestion)}
                disabled={isSubmitting}
                className="px-2 py-1 text-xs bg-slate-50 text-slate-600 rounded border border-slate-200 hover:bg-slate-100 disabled:opacity-50"
              >
                {suggestion}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Description */}
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-2">Description</label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Provide more details about what you need..."
          rows={3}
          disabled={isSubmitting}
          className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent resize-none disabled:bg-slate-50 disabled:text-slate-500"
        />
      </div>

      {/* Priority */}
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-2">Priority</label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
          {priorityOptions.map((option) => (
            <button
              key={option.id}
              onClick={() => handlePriorityChange(option.id)}
              disabled={isSubmitting}
              className={`p-3 rounded-lg border text-center transition-all ${
                priority === option.id
                  ? 'border-emerald-500 bg-emerald-50 ring-2 ring-emerald-200'
                  : 'border-slate-200 hover:border-slate-300'
              } disabled:opacity-50`}
            >
              <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium mb-1 ${option.color}`}>
                {option.label}
              </span>
              <p className="text-xs text-slate-500">{option.description}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Media Upload */}
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-2">Add Media</label>
        <div className="flex gap-3">
          <button
            disabled={isSubmitting}
            className="flex-1 flex items-center justify-center gap-2 p-4 border-2 border-dashed border-slate-300 rounded-lg hover:border-emerald-400 hover:bg-emerald-50 transition-colors disabled:opacity-50"
          >
            <Camera className="w-5 h-5 text-slate-400" />
            <span className="text-sm text-slate-600">Photo</span>
          </button>
          <button
            disabled={isSubmitting}
            className="flex-1 flex items-center justify-center gap-2 p-4 border-2 border-dashed border-slate-300 rounded-lg hover:border-emerald-400 hover:bg-emerald-50 transition-colors disabled:opacity-50"
          >
            <Video className="w-5 h-5 text-slate-400" />
            <span className="text-sm text-slate-600">Video</span>
          </button>
        </div>
      </div>

      {/* Entry Permission (for repair/service) */}
      {(category === 'repair' || category === 'service') && (
        <div className="flex items-center justify-between p-4 bg-slate-50 rounded-lg">
          <div>
            <p className="font-medium text-slate-900">Permission to enter if I&apos;m not home?</p>
            <p className="text-sm text-slate-500">Allow service provider access</p>
          </div>
          <button
            onClick={() => setAllowEntry(!allowEntry)}
            disabled={isSubmitting}
            className={`relative w-12 h-6 rounded-full transition-colors ${
              allowEntry ? 'bg-emerald-600' : 'bg-slate-300'
            } disabled:opacity-50`}
          >
            <span
              className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-transform ${
                allowEntry ? 'translate-x-6' : 'translate-x-0'
              }`}
            />
          </button>
        </div>
      )}

      {/* Submit */}
      <button
        onClick={handleSubmit}
        disabled={isSubmitting || !title.trim()}
        className="w-full py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
      >
        {isSubmitting ? (
          <>
            <Loader2 className="w-5 h-5 animate-spin" />
            Submitting...
          </>
        ) : (
          'Submit Request'
        )}
      </button>

      {/* Emergency Warning Modal */}
      {showEmergencyWarning && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowEmergencyWarning(false)} />
          <div className="relative bg-white rounded-xl shadow-xl p-6 max-w-sm w-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-red-100 rounded-lg">
                <AlertTriangle className="w-6 h-6 text-red-600" />
              </div>
              <h4 className="text-lg font-semibold text-slate-900">Emergency Request</h4>
            </div>
            <p className="text-sm text-slate-600 mb-4">
              <strong>For fire or life-safety emergencies, please call 911 immediately.</strong>
              <br /><br />
              This app is for property emergencies only (e.g., burst pipe, gas smell, security breach).
            </p>
            <a
              href="tel:+13105550911"
              className="flex items-center justify-center gap-2 w-full py-3 mb-3 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 transition-colors"
            >
              <Phone className="w-5 h-5" />
              Call 24/7 Emergency Line
            </a>
            <div className="flex gap-3">
              <button
                onClick={() => setShowEmergencyWarning(false)}
                className="flex-1 py-2.5 border border-slate-300 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmEmergency}
                className="flex-1 py-2.5 bg-slate-900 text-white font-medium rounded-lg hover:bg-slate-800 transition-colors"
              >
                Continue as Emergency
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// New Request Modal
function NewRequestModal({
  onClose,
  onSuccess,
  householdId,
}: {
  onClose: () => void;
  onSuccess: (ticket: RequestTicket) => void;
  householdId: string;
}) {
  const [step, setStep] = useState<'category' | 'form'>('category');
  const [selectedCategory, setSelectedCategory] = useState<RequestCategory | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCategorySelect = (category: RequestCategory) => {
    setSelectedCategory(category);
    setStep('form');
  };

  const handleSubmit = async (formData: FormData) => {
    setIsSubmitting(true);
    setError(null);

    try {
      const api = getApiClient();
      const payload: CreateServiceRequestRequest = {
        householdId,
        title: formData.title,
        description: formData.description || formData.title,
        priority: mapUIPriorityToApi(formData.priority),
      };

      const result = await api.createServiceRequest(payload);
      const newTicket = mapApiRequestToTicket(result);

      // Override some fields from form data since API might not have category mapping yet
      newTicket.category = formData.category;
      newTicket.subcategory = formData.subcategory;
      newTicket.allowEntry = formData.allowEntry;

      onSuccess(newTicket);
    } catch (err) {
      console.error('Failed to create request:', err);
      setError('Failed to submit request. Please try again.');
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 lg:p-8">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative w-full max-w-lg max-h-[90vh] bg-white rounded-xl shadow-xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200">
          <h2 className="text-lg font-semibold text-slate-900">New Request</h2>
          <button
            onClick={onClose}
            disabled={isSubmitting}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors disabled:opacity-50"
          >
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        {/* Error */}
        {error && (
          <div className="mx-6 mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-700">{error}</p>
          </div>
        )}

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {step === 'category' && (
            <CategoryStep onSelect={handleCategorySelect} />
          )}
          {step === 'form' && selectedCategory && (
            <RequestForm
              category={selectedCategory}
              onBack={() => setStep('category')}
              onSubmit={handleSubmit}
              isSubmitting={isSubmitting}
            />
          )}
        </div>
      </div>
    </div>
  );
}

// Status Badge
function StatusBadge({ status }: { status: RequestStatus }) {
  const config: Record<RequestStatus, { label: string; color: string }> = {
    received: { label: 'Received', color: 'bg-blue-100 text-blue-700' },
    reviewing: { label: 'Reviewing', color: 'bg-purple-100 text-purple-700' },
    scheduled: { label: 'Scheduled', color: 'bg-amber-100 text-amber-700' },
    in_progress: { label: 'In Progress', color: 'bg-orange-100 text-orange-700' },
    resolved: { label: 'Resolved', color: 'bg-emerald-100 text-emerald-700' },
  };

  const { label, color } = config[status];

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}`}>
      {label}
    </span>
  );
}

// Priority Badge
function PriorityBadge({ priority }: { priority: RequestPriority }) {
  const config: Record<RequestPriority, { label: string; color: string }> = {
    low: { label: 'Low', color: 'bg-slate-100 text-slate-600' },
    medium: { label: 'Medium', color: 'bg-blue-100 text-blue-600' },
    high: { label: 'Urgent', color: 'bg-amber-100 text-amber-700' },
    emergency: { label: 'Emergency', color: 'bg-red-100 text-red-700' },
  };

  const { label, color } = config[priority];

  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${color}`}>
      {label}
    </span>
  );
}

// Status Progress Bar
function StatusProgress({ status }: { status: RequestStatus }) {
  const stages: RequestStatus[] = ['received', 'reviewing', 'scheduled', 'in_progress', 'resolved'];
  const currentIndex = stages.indexOf(status);

  return (
    <div className="flex items-center gap-1">
      {stages.map((stage, index) => (
        <div key={stage} className="flex items-center">
          <div
            className={`w-2 h-2 rounded-full ${
              index <= currentIndex ? 'bg-emerald-500' : 'bg-slate-200'
            }`}
          />
          {index < stages.length - 1 && (
            <div
              className={`w-6 h-0.5 ${
                index < currentIndex ? 'bg-emerald-500' : 'bg-slate-200'
              }`}
            />
          )}
        </div>
      ))}
    </div>
  );
}

// Ticket Card
function TicketCard({
  ticket,
  isSelected,
  onClick,
}: {
  ticket: RequestTicket;
  isSelected: boolean;
  onClick: () => void;
}) {
  const categoryInfo = categoryOptions.find((c) => c.id === ticket.category)!;
  const CategoryIcon = categoryInfo.icon;

  return (
    <button
      onClick={onClick}
      className={`w-full text-left p-4 rounded-xl border transition-all ${
        isSelected
          ? 'bg-emerald-50 border-emerald-300 shadow-sm'
          : 'bg-white border-slate-200 hover:border-slate-300 hover:shadow-sm'
      }`}
    >
      <div className="flex items-start gap-3">
        <div className={`p-2 rounded-lg ${categoryInfo.color}`}>
          <CategoryIcon className="w-4 h-4" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className="text-xs text-slate-500">{ticket.ticketNumber}</span>
            <PriorityBadge priority={ticket.priority} />
          </div>
          <h3 className="font-medium text-slate-900 truncate">{ticket.title}</h3>
          <div className="flex items-center gap-2 mt-2">
            <StatusBadge status={ticket.status} />
            {ticket.vendor && (
              <span className="text-xs text-slate-500 flex items-center gap-1">
                <User className="w-3 h-3" />
                {ticket.vendor.name}
              </span>
            )}
          </div>
          <div className="mt-2">
            <StatusProgress status={ticket.status} />
          </div>
        </div>
      </div>
    </button>
  );
}

// Ticket Detail View
function TicketDetail({
  ticket,
  onClose,
  onRate,
  onMessageSent,
}: {
  ticket: RequestTicket;
  onClose: () => void;
  onRate: (rating: number) => void;
  onMessageSent?: (message: ChatMessage) => void;
}) {
  const [message, setMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [showRating, setShowRating] = useState(ticket.status === 'resolved' && !ticket.rating);
  const [selectedRating, setSelectedRating] = useState(0);
  const [localMessages, setLocalMessages] = useState<ChatMessage[]>(ticket.messages);
  const categoryInfo = categoryOptions.find((c) => c.id === ticket.category)!;
  const SubIcon = subcategoryIcons[ticket.subcategory] ?? HelpCircle;

  // Check if this is a real (non-mock) ticket ID
  const isRealTicket = ticket.id.length > 6; // Mock IDs are '1', '2', etc.

  // Fetch messages for real tickets
  useEffect(() => {
    if (!isRealTicket) return;

    const loadMessages = async () => {
      try {
        // TODO: Implement message fetching when API is available
        // const api = getApiClient();
        // const messages = await api.getServiceRequestMessages(ticket.id);
        // setLocalMessages(messages.map(mapApiMessageToChat));
      } catch (err) {
        console.error('Failed to load messages:', err);
      }
    };

    loadMessages();
  }, [ticket.id, isRealTicket]);

  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const handleSendMessage = async () => {
    if (!message.trim()) return;

    // Optimistically add message to local state
    const optimisticMessage: ChatMessage = {
      id: `temp-${Date.now()}`,
      senderId: 'current-user',
      senderName: 'You',
      senderRole: 'user',
      content: message.trim(),
      timestamp: new Date().toISOString(),
    };

    setLocalMessages(prev => [...prev, optimisticMessage]);
    setMessage('');
    setIsSending(true);

    if (isRealTicket) {
      try {
        // TODO: Implement message sending when API is available
        // const api = getApiClient();
        // await api.createServiceRequestMessage(ticket.id, { body: message });
        onMessageSent?.(optimisticMessage);
      } catch (err) {
        console.error('Failed to send message:', err);
        // Remove optimistic message on failure
        setLocalMessages(prev => prev.filter(m => m.id !== optimisticMessage.id));
      }
    }

    setIsSending(false);
  };

  const handleSubmitRating = () => {
    if (selectedRating > 0) {
      onRate(selectedRating);
      setShowRating(false);
    }
  };

  return (
    <div className="h-full flex flex-col bg-white lg:bg-transparent">
      {/* Mobile Header */}
      <div className="lg:hidden flex items-center gap-3 p-4 border-b border-slate-200 bg-white">
        <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-lg">
          <ArrowLeft className="w-5 h-5 text-slate-600" />
        </button>
        <div className="flex-1">
          <p className="text-sm text-slate-500">{ticket.ticketNumber}</p>
          <h2 className="font-semibold text-slate-900">{ticket.title}</h2>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* Header Section */}
        <div className="p-6 border-b border-slate-200 bg-white lg:rounded-t-xl">
          <div className="hidden lg:flex items-start justify-between mb-4">
            <div>
              <p className="text-sm text-slate-500 mb-1">{ticket.ticketNumber}</p>
              <h2 className="text-xl font-bold text-slate-900">{ticket.title}</h2>
            </div>
            <StatusBadge status={ticket.status} />
          </div>

          <div className="flex flex-wrap gap-3 mb-4">
            <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-50 rounded-lg">
              <div className={`p-1 rounded ${categoryInfo.color}`}>
                <categoryInfo.icon className="w-3 h-3" />
              </div>
              <span className="text-sm text-slate-700">{categoryInfo.label}</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-50 rounded-lg">
              <SubIcon className="w-4 h-4 text-slate-500" />
              <span className="text-sm text-slate-700">{ticket.subcategory}</span>
            </div>
            <PriorityBadge priority={ticket.priority} />
          </div>

          <p className="text-slate-600">{ticket.description}</p>

          {/* Media */}
          {ticket.mediaUrls.length > 0 && (
            <div className="flex gap-2 mt-4">
              {ticket.mediaUrls.map((url, index) => (
                <div key={index} className="relative w-20 h-20 rounded-lg overflow-hidden">
                  <Image src={url} alt="" fill className="object-cover" />
                </div>
              ))}
            </div>
          )}

          {/* Vendor */}
          {ticket.vendor && (
            <div className="flex items-center gap-3 mt-4 p-3 bg-slate-50 rounded-lg">
              <div className="relative w-10 h-10 rounded-full overflow-hidden">
                <Image src={ticket.vendor.avatar} alt="" fill className="object-cover" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-slate-900">{ticket.vendor.name}</p>
                <p className="text-sm text-slate-500">Assigned Vendor</p>
              </div>
              {ticket.vendor.phone && (
                <a
                  href={`tel:${ticket.vendor.phone}`}
                  className="p-2 bg-emerald-100 text-emerald-600 rounded-lg hover:bg-emerald-200"
                >
                  <Phone className="w-5 h-5" />
                </a>
              )}
            </div>
          )}

          {/* Quote Approval */}
          {ticket.quote && !ticket.quote.approved && (
            <div className="mt-4 p-4 bg-amber-50 border border-amber-200 rounded-xl">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-amber-900">Quote Pending Approval</p>
                  <p className="text-2xl font-bold text-amber-700">${ticket.quote.amount.toLocaleString()}</p>
                </div>
                <button className="px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700">
                  Approve Quote
                </button>
              </div>
            </div>
          )}

          {/* Resolution Summary */}
          {ticket.status === 'resolved' && ticket.resolutionTime && (
            <div className="mt-4 p-4 bg-emerald-50 border border-emerald-200 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-100 rounded-lg">
                  <Zap className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-emerald-900">Resolved in {ticket.resolutionTime}!</p>
                  <p className="text-sm text-emerald-700">Thanks for using Haven Concierge</p>
                </div>
              </div>
              {ticket.rating && (
                <div className="flex items-center gap-1 mt-3">
                  <span className="text-sm text-emerald-700 mr-2">Your rating:</span>
                  {[1, 2, 3, 4, 5].map((star) => (
                    <Star
                      key={star}
                      className={`w-5 h-5 ${star <= ticket.rating! ? 'text-amber-400 fill-amber-400' : 'text-slate-300'}`}
                    />
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Rating Prompt */}
        {showRating && (
          <div className="p-4 bg-amber-50 border-b border-amber-200">
            <p className="font-medium text-amber-900 mb-2">How was the service?</p>
            <div className="flex items-center gap-2 mb-3">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  onClick={() => setSelectedRating(star)}
                  className="p-1"
                >
                  <Star
                    className={`w-8 h-8 transition-colors ${
                      star <= selectedRating ? 'text-amber-400 fill-amber-400' : 'text-slate-300 hover:text-amber-300'
                    }`}
                  />
                </button>
              ))}
            </div>
            <button
              onClick={handleSubmitRating}
              disabled={selectedRating === 0}
              className="px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Submit Rating
            </button>
          </div>
        )}

        {/* Timeline */}
        <div className="p-6 bg-white lg:bg-slate-50">
          <h3 className="font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <Clock className="w-5 h-5 text-slate-500" />
            Activity Timeline
          </h3>
          <div className="space-y-4">
            {ticket.timeline.map((event, index) => (
              <div key={event.id} className="flex gap-3">
                <div className="flex flex-col items-center">
                  <div className={`w-3 h-3 rounded-full ${
                    event.type === 'completed' ? 'bg-emerald-500' : 'bg-slate-300'
                  }`} />
                  {index < ticket.timeline.length - 1 && (
                    <div className="w-0.5 h-full bg-slate-200 my-1" />
                  )}
                </div>
                <div className="flex-1 pb-4">
                  <p className="text-sm font-medium text-slate-900">{event.description}</p>
                  <p className="text-xs text-slate-500">
                    {formatDate(event.timestamp)} at {formatTime(event.timestamp)}
                    {event.actor && ` • ${event.actor}`}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Messages */}
        {localMessages.length > 0 && (
          <div className="p-6 bg-white border-t border-slate-200">
            <h3 className="font-semibold text-slate-900 mb-4 flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-slate-500" />
              Conversation
            </h3>
            <div className="space-y-4">
              {localMessages.map((msg) => {
                const isUser = msg.senderRole === 'user';
                return (
                  <div key={msg.id} className={`flex gap-3 ${isUser ? 'flex-row-reverse' : ''}`}>
                    <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center overflow-hidden flex-shrink-0">
                      {msg.senderAvatar ? (
                        <Image src={msg.senderAvatar} alt="" width={32} height={32} className="object-cover" />
                      ) : (
                        <User className="w-4 h-4 text-slate-500" />
                      )}
                    </div>
                    <div className={`max-w-[75%] ${isUser ? 'text-right' : ''}`}>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium text-slate-900">{msg.senderName}</span>
                        <span className="text-xs text-slate-400">{formatTime(msg.timestamp)}</span>
                      </div>
                      <div className={`p-3 rounded-xl ${
                        isUser ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-800'
                      }`}>
                        <p className="text-sm">{msg.content}</p>
                      </div>
                      {msg.attachments && msg.attachments.length > 0 && (
                        <div className="flex gap-2 mt-2">
                          {msg.attachments.map((url, i) => (
                            <div key={i} className="relative w-24 h-24 rounded-lg overflow-hidden">
                              <Image src={url} alt="" fill className="object-cover" />
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Invoice Link */}
        {ticket.quote?.approved && (
          <div className="p-6 bg-white border-t border-slate-200">
            <button className="w-full flex items-center justify-between p-4 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-emerald-100 rounded-lg">
                  <DollarSign className="w-5 h-5 text-emerald-600" />
                </div>
                <div className="text-left">
                  <p className="font-medium text-slate-900">View Invoice</p>
                  <p className="text-sm text-slate-500">${ticket.quote.amount.toLocaleString()}</p>
                </div>
              </div>
              <ExternalLink className="w-5 h-5 text-slate-400" />
            </button>
          </div>
        )}
      </div>

      {/* Message Input */}
      {ticket.status !== 'resolved' && (
        <div className="p-4 border-t border-slate-200 bg-white">
          <div className="flex gap-2">
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Type a message..."
              disabled={isSending}
              className="flex-1 px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent disabled:bg-slate-50"
              onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
            />
            <button
              onClick={handleSendMessage}
              disabled={isSending || !message.trim()}
              className="p-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50"
            >
              {isSending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// Empty State
function EmptyState({ onNewRequest }: { onNewRequest: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
      <div className="w-24 h-24 bg-emerald-100 rounded-full flex items-center justify-center mb-6">
        <CheckCircle2 className="w-12 h-12 text-emerald-600" />
      </div>
      <h3 className="text-xl font-semibold text-slate-900 mb-2">Everything is running perfectly</h3>
      <p className="text-slate-500 mb-6 max-w-sm">
        No active requests right now. Need anything? Your concierge is just one tap away.
      </p>
      <button
        onClick={onNewRequest}
        className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
      >
        <Plus className="w-5 h-5" />
        New Request
      </button>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function RequestsPage() {
  const { currentHousehold } = useAuth();
  const [tickets, setTickets] = useState<RequestTicket[]>(MOCK_TICKETS);
  const [showModal, setShowModal] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>('active');
  const [displayMode, setDisplayMode] = useState<DisplayMode>('list');
  const [selectedTicket, setSelectedTicket] = useState<RequestTicket | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Load service requests from API with hybrid fallback
  const loadRequests = useCallback(async () => {
    if (!currentHousehold?.id) return;

    setIsLoading(true);
    try {
      const api = getApiClient();
      const requests = await api.getServiceRequests(currentHousehold.id);

      if (requests && requests.length > 0) {
        // Map API requests to UI tickets
        const mappedTickets = requests.map(mapApiRequestToTicket);
        setTickets(mappedTickets);
      }
      // If empty or error, keep MOCK_TICKETS (already the default)
    } catch (err) {
      console.error('Failed to load requests:', err);
      // Keep MOCK_TICKETS as fallback
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold?.id]);

  // Fetch data on mount
  useEffect(() => {
    loadRequests();
  }, [loadRequests]);

  const activeTickets = tickets.filter((t) => t.status !== 'resolved');
  const historyTickets = tickets.filter((t) => t.status === 'resolved');
  const displayedTickets = viewMode === 'active' ? activeTickets : historyTickets;

  const handleNewRequestSuccess = (newTicket: RequestTicket) => {
    setTickets(prev => [newTicket, ...prev]);
    setShowModal(false);
    setSelectedTicket(newTicket);
  };

  const handleRate = (ticketId: string, rating: number) => {
    setTickets(tickets.map((t) =>
      t.id === ticketId ? { ...t, rating } : t
    ));
  };

  // Stats
  const stats = {
    active: activeTickets.length,
    pending: activeTickets.filter((t) => t.status === 'received' || t.status === 'reviewing').length,
    inProgress: activeTickets.filter((t) => t.status === 'in_progress' || t.status === 'scheduled').length,
    resolved: historyTickets.length,
  };

  return (
    <div className="pb-32 lg:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold text-slate-900">Concierge Desk</h1>
          <p className="text-slate-500 mt-1">Your personal service hub - we&apos;re here to help</p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="hidden lg:inline-flex items-center gap-2 px-5 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors shadow-sm"
        >
          <Plus className="w-5 h-5" />
          New Request
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Clock className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.active}</p>
              <p className="text-sm text-slate-500">Active</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-100 rounded-lg">
              <MessageSquare className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.pending}</p>
              <p className="text-sm text-slate-500">Pending</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Wrench className="w-5 h-5 text-orange-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.inProgress}</p>
              <p className="text-sm text-slate-500">In Progress</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-emerald-100 rounded-lg">
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.resolved}</p>
              <p className="text-sm text-slate-500">Resolved</p>
            </div>
          </div>
        </div>
      </div>

      {/* View Controls */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex bg-slate-100 rounded-lg p-1">
          <button
            onClick={() => setViewMode('active')}
            className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              viewMode === 'active'
                ? 'bg-white text-slate-900 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Clock className="w-4 h-4" />
            Active
            <span className="ml-1 px-1.5 py-0.5 bg-slate-200 rounded text-xs">{activeTickets.length}</span>
          </button>
          <button
            onClick={() => setViewMode('history')}
            className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              viewMode === 'history'
                ? 'bg-white text-slate-900 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Archive className="w-4 h-4" />
            History
            <span className="ml-1 px-1.5 py-0.5 bg-slate-200 rounded text-xs">{historyTickets.length}</span>
          </button>
        </div>

        <div className="hidden lg:flex items-center gap-2">
          <button
            onClick={() => setDisplayMode('list')}
            className={`p-2 rounded-lg transition-colors ${
              displayMode === 'list' ? 'bg-slate-200 text-slate-900' : 'text-slate-500 hover:bg-slate-100'
            }`}
          >
            <LayoutList className="w-5 h-5" />
          </button>
          <button
            onClick={() => setDisplayMode('kanban')}
            className={`p-2 rounded-lg transition-colors ${
              displayMode === 'kanban' ? 'bg-slate-200 text-slate-900' : 'text-slate-500 hover:bg-slate-100'
            }`}
          >
            <LayoutGrid className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-emerald-600" />
        </div>
      )}

      {/* Content */}
      {!isLoading && displayedTickets.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200">
          <EmptyState onNewRequest={() => setShowModal(true)} />
        </div>
      ) : !isLoading && (
        <div className="lg:grid lg:grid-cols-5 lg:gap-6">
          {/* Ticket List */}
          <div className={`lg:col-span-2 space-y-3 ${selectedTicket ? 'hidden lg:block' : ''}`}>
            {displayedTickets.map((ticket) => (
              <TicketCard
                key={ticket.id}
                ticket={ticket}
                isSelected={selectedTicket?.id === ticket.id}
                onClick={() => setSelectedTicket(ticket)}
              />
            ))}
          </div>

          {/* Ticket Detail */}
          <div className={`lg:col-span-3 ${selectedTicket ? '' : 'hidden lg:block'}`}>
            {selectedTicket ? (
              <div className="fixed inset-0 z-40 bg-white lg:static lg:bg-transparent lg:rounded-xl lg:border lg:border-slate-200 lg:shadow-sm lg:overflow-hidden">
                <TicketDetail
                  ticket={selectedTicket}
                  onClose={() => setSelectedTicket(null)}
                  onRate={(rating) => handleRate(selectedTicket.id, rating)}
                />
              </div>
            ) : (
              <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-12 text-center">
                <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <MessageSquare className="w-8 h-8 text-slate-400" />
                </div>
                <p className="text-slate-500">Select a request to view details</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Mobile FAB - positioned above the global chat FAB */}
      <button
        onClick={() => setShowModal(true)}
        className="lg:hidden fixed bottom-36 right-4 w-12 h-12 bg-emerald-600 text-white rounded-full shadow-lg hover:bg-emerald-700 flex items-center justify-center z-40"
      >
        <Plus className="w-5 h-5" />
      </button>

      {/* New Request Modal */}
      {showModal && currentHousehold && (
        <NewRequestModal
          onClose={() => setShowModal(false)}
          onSuccess={handleNewRequestSuccess}
          householdId={currentHousehold.id}
        />
      )}
    </div>
  );
}
