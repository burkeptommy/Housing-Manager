'use client';

import { useState } from 'react';
import {
  MessageCircle,
  Phone,
  Video,
  Check,
  X,
  Clock,
  CheckCircle2,
  AlertCircle,
  Calendar,
  DollarSign,
  Wrench,
  FileText,
  Send,
  Paperclip,
  Mic,
  Users,
  Home,
  Car,
  Heart,
  Package,
  Bell,
  Sparkles,
  Timer,
  BadgeCheck,
  ExternalLink,
  ListChecks,
} from 'lucide-react';
import { ManagerAvatar } from '@/components/ui/avatar';

// ============================================================================
// TYPES
// ============================================================================

type RequestStatus = 'pending' | 'approved' | 'denied';
type RequestPriority = 'urgent' | 'high' | 'normal' | 'low';
type RequestType = 'expense' | 'scheduling' | 'question' | 'recommendation' | 'approval' | 'info';

interface ManagerProfile {
  id: string;
  name: string;
  firstName: string;
  role: string;
  phone: string;
  email: string;
  avatar?: string;
  isOnline: boolean;
  lastActive: string;
  startDate: string;
  stats: {
    tasksCompletedThisMonth: number;
    hoursManaged: number;
    vendorsCoordinated: number;
    billsPaid: number;
    moneyManaged: number;
  };
}

interface PendingRequest {
  id: string;
  type: RequestType;
  title: string;
  description: string;
  priority: RequestPriority;
  createdAt: string;
  amount?: number;
  vendor?: string;
  options?: { id: string; label: string; description?: string; recommended?: boolean; cost?: number }[];
  attachments?: { name: string; type: string; url: string }[];
  dueBy?: string;
  category: string;
}

interface InProgressItem {
  id: string;
  title: string;
  description: string;
  status: 'scheduled' | 'in-progress' | 'waiting' | 'on-hold';
  category: string;
  startedAt?: string;
  estimatedCompletion?: string;
  vendor?: string;
  updates?: { time: string; message: string }[];
}

interface CompletedItem {
  id: string;
  title: string;
  description: string;
  completedAt: string;
  category: string;
  result?: string;
  cost?: number;
  savedAmount?: number;
}

interface UpcomingItem {
  id: string;
  title: string;
  description: string;
  scheduledFor: string;
  category: string;
  vendor?: string;
  location?: string;
  duration?: string;
}

interface Message {
  id: string;
  sender: 'manager' | 'homeowner';
  content: string;
  timestamp: string;
  read: boolean;
}

// ============================================================================
// MOCK DATA - THE MANAGER
// ============================================================================

const MANAGER: ManagerProfile = {
  id: 'mgr-sarah',
  name: 'Sarah Chen',
  firstName: 'Sarah',
  role: 'Home Manager',
  phone: '(203) 555-0150',
  email: 'sarah.chen@havenhome.com',
  isOnline: true,
  lastActive: 'Now',
  startDate: 'June 2023',
  stats: {
    tasksCompletedThisMonth: 47,
    hoursManaged: 32,
    vendorsCoordinated: 12,
    billsPaid: 8,
    moneyManaged: 14850,
  },
};

// ============================================================================
// MOCK DATA - PENDING REQUESTS (Needs Your Input)
// ============================================================================

const PENDING_REQUESTS: PendingRequest[] = [
  {
    id: 'req-1',
    type: 'expense',
    title: 'Approve plumber invoice',
    description: "Mike's Plumbing completed the guest bathroom faucet repair yesterday. Work was excellent - I inspected it this morning. Invoice attached for your approval.",
    priority: 'urgent',
    createdAt: '2 hours ago',
    amount: 385,
    vendor: "Mike's Plumbing",
    category: 'Home Maintenance',
    attachments: [
      { name: 'Invoice_MikesPlumbing_Dec2024.pdf', type: 'pdf', url: '#' }
    ],
    dueBy: 'Today',
  },
  {
    id: 'req-2',
    type: 'scheduling',
    title: 'HVAC maintenance - pick a date',
    description: "It's time for the quarterly HVAC service. Comfort Zone has three slots available next week. I recommend the Tuesday morning slot so I can be there to let them in.",
    priority: 'high',
    createdAt: '5 hours ago',
    category: 'Home Maintenance',
    vendor: 'Comfort Zone HVAC',
    options: [
      { id: 'slot-1', label: 'Tuesday, Jan 7', description: '9:00 AM - 11:00 AM', recommended: true, cost: 189 },
      { id: 'slot-2', label: 'Wednesday, Jan 8', description: '2:00 PM - 4:00 PM', cost: 189 },
      { id: 'slot-3', label: 'Friday, Jan 10', description: '10:00 AM - 12:00 PM', cost: 189 },
    ],
  },
  {
    id: 'req-3',
    type: 'question',
    title: 'Kitchen backsplash tile selection',
    description: "I've been researching tiles for the backsplash project. Based on your style preferences and the existing countertops, I've narrowed it down to three options. I had samples delivered - they're on the kitchen counter for you to see in person.",
    priority: 'normal',
    createdAt: 'Yesterday',
    category: 'Projects',
    options: [
      { id: 'tile-1', label: 'Carrara Marble Subway', description: 'Classic, timeless look. Matches your counters beautifully.', recommended: true, cost: 2800 },
      { id: 'tile-2', label: 'White Ceramic Herringbone', description: 'Modern pattern, very popular in Greenwich homes.', cost: 2200 },
      { id: 'tile-3', label: 'Glass Mosaic Blend', description: 'Contemporary, adds color dimension.', cost: 3400 },
    ],
    attachments: [
      { name: 'Tile_Options_Photos.pdf', type: 'pdf', url: '#' }
    ],
  },
  {
    id: 'req-4',
    type: 'recommendation',
    title: 'Generator installation proposal',
    description: "After last month's 6-hour outage, I strongly recommend installing a whole-home generator. I've gotten quotes from three vendors - Tesla Certified Electricians came in best. This would cover the entire house including the pool equipment.",
    priority: 'normal',
    createdAt: 'Yesterday',
    category: 'Home Improvement',
    amount: 14500,
    vendor: 'Tesla Certified Electricians',
    options: [
      { id: 'gen-approve', label: 'Approve - Schedule Installation', recommended: true },
      { id: 'gen-quote', label: 'Get Additional Quotes' },
      { id: 'gen-defer', label: 'Defer to Spring' },
    ],
  },
  {
    id: 'req-5',
    type: 'approval',
    title: "Emma's piano recital flowers",
    description: "Emma's winter recital is this Saturday at 3pm. Would you like me to order a congratulations bouquet? I found a lovely arrangement at Palmer's that matches her favorite colors.",
    priority: 'low',
    createdAt: '2 days ago',
    category: 'Family',
    amount: 65,
    vendor: "Palmer's Flowers",
  },
];

// ============================================================================
// MOCK DATA - IN PROGRESS (What Sarah's Working On)
// ============================================================================

const IN_PROGRESS_ITEMS: InProgressItem[] = [
  {
    id: 'prog-1',
    title: 'Master bathroom renovation coordination',
    description: 'Overseeing tile installation, coordinating with plumber for fixture install next week',
    status: 'in-progress',
    category: 'Projects',
    vendor: 'Tile Masters CT',
    startedAt: 'Dec 15',
    estimatedCompletion: 'Jan 10',
    updates: [
      { time: '10:30 AM', message: 'Tile crew arrived, starting west wall today' },
      { time: 'Yesterday', message: 'Waterproofing membrane inspection passed' },
    ],
  },
  {
    id: 'prog-2',
    title: 'January bill payments',
    description: 'Processing monthly bills - utilities, subscriptions, club memberships',
    status: 'in-progress',
    category: 'Financial',
    startedAt: 'Today',
    updates: [
      { time: '9:15 AM', message: 'Eversource and Aquarion paid' },
      { time: '9:00 AM', message: 'Started processing 8 bills totaling $4,250' },
    ],
  },
  {
    id: 'prog-3',
    title: 'Pool winterization follow-up',
    description: 'Scheduled inspection with Pool Paradise to verify all equipment properly stored',
    status: 'scheduled',
    category: 'Home Maintenance',
    vendor: 'Pool Paradise CT',
    estimatedCompletion: 'Tomorrow 2pm',
  },
  {
    id: 'prog-4',
    title: "Tesla Model S service appointment",
    description: "Scheduled tire rotation and annual service at Tesla Greenwich",
    status: 'scheduled',
    category: 'Vehicles',
    vendor: 'Tesla Service Center',
    estimatedCompletion: 'Jan 8, 10am',
  },
  {
    id: 'prog-5',
    title: 'Researching spring landscaping options',
    description: 'Getting proposals from three landscapers for the backyard refresh project',
    status: 'waiting',
    category: 'Projects',
    updates: [
      { time: 'Yesterday', message: 'Sent RFP to Greenwich Landscaping, awaiting response' },
    ],
  },
];

// ============================================================================
// MOCK DATA - COMPLETED (This Week's Activity)
// ============================================================================

const COMPLETED_ITEMS: CompletedItem[] = [
  {
    id: 'done-1',
    title: 'Scheduled annual chimney inspection',
    description: 'Booked with Fairfield Chimney for January 15th',
    completedAt: 'Today, 11:30 AM',
    category: 'Home Maintenance',
  },
  {
    id: 'done-2',
    title: 'Paid December utility bills',
    description: 'Eversource, Aquarion, and gas - all paid on time',
    completedAt: 'Today, 9:45 AM',
    category: 'Financial',
    cost: 892,
  },
  {
    id: 'done-3',
    title: 'Negotiated better rate with lawn service',
    description: 'Renewed contract with Greenwich Landscaping at 15% discount',
    completedAt: 'Yesterday',
    category: 'Financial',
    savedAmount: 1200,
    result: 'Annual savings of $1,200',
  },
  {
    id: 'done-4',
    title: 'Coordinated emergency furnace repair',
    description: 'Comfort Zone responded within 2 hours, heat restored by 4pm',
    completedAt: 'Dec 20',
    category: 'Home Maintenance',
    cost: 450,
    result: 'Emergency resolved same-day',
  },
  {
    id: 'done-5',
    title: 'Organized holiday package deliveries',
    description: 'Received and secured 12 packages while you were traveling',
    completedAt: 'Dec 19',
    category: 'Errands',
  },
  {
    id: 'done-6',
    title: "Scheduled Max's vet appointment",
    description: 'Annual checkup with Dr. Williams on January 12th',
    completedAt: 'Dec 18',
    category: 'Family',
  },
  {
    id: 'done-7',
    title: 'Researched and hired snow removal service',
    description: 'Contracted with Pro Snow CT for season - better response time than previous company',
    completedAt: 'Dec 15',
    category: 'Home Maintenance',
    cost: 1800,
    result: 'Season contract secured',
  },
];

// ============================================================================
// MOCK DATA - UPCOMING
// ============================================================================

const UPCOMING_ITEMS: UpcomingItem[] = [
  {
    id: 'up-1',
    title: 'HVAC Quarterly Service',
    description: 'Pending your date selection',
    scheduledFor: 'Next week',
    category: 'Home Maintenance',
    vendor: 'Comfort Zone HVAC',
    duration: '2 hours',
  },
  {
    id: 'up-2',
    title: 'Tesla Service Appointment',
    description: 'Tire rotation and annual inspection',
    scheduledFor: 'Jan 8, 10:00 AM',
    category: 'Vehicles',
    vendor: 'Tesla Greenwich',
    location: '123 W Putnam Ave',
    duration: '3 hours',
  },
  {
    id: 'up-3',
    title: 'Chimney Inspection',
    description: 'Annual safety inspection and cleaning',
    scheduledFor: 'Jan 15, 9:00 AM',
    category: 'Home Maintenance',
    vendor: 'Fairfield Chimney',
    duration: '1.5 hours',
  },
  {
    id: 'up-4',
    title: "Max's Vet Checkup",
    description: 'Annual exam and vaccinations',
    scheduledFor: 'Jan 12, 2:00 PM',
    category: 'Family',
    vendor: 'Westlake Animal Hospital',
    location: '456 Post Road',
    duration: '1 hour',
  },
  {
    id: 'up-5',
    title: 'Bathroom Renovation Complete',
    description: 'Final inspection and walkthrough',
    scheduledFor: 'Jan 10',
    category: 'Projects',
    vendor: 'Tile Masters CT',
  },
];

// ============================================================================
// MOCK DATA - RECENT MESSAGES
// ============================================================================

const RECENT_MESSAGES: Message[] = [
  {
    id: 'msg-1',
    sender: 'manager',
    content: "Good morning! Just a heads up - the tile crew is here and starting on the bathroom. I'll send photos when the first wall is done.",
    timestamp: '10:32 AM',
    read: true,
  },
  {
    id: 'msg-2',
    sender: 'homeowner',
    content: 'Perfect, thanks Sarah!',
    timestamp: '10:45 AM',
    read: true,
  },
  {
    id: 'msg-3',
    sender: 'manager',
    content: "Also, I noticed the front porch light is flickering. Want me to have the electrician look at it while they're here for the generator quote?",
    timestamp: '11:15 AM',
    read: false,
  },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const getCategoryIcon = (category: string) => {
  switch (category.toLowerCase()) {
    case 'home maintenance': return Wrench;
    case 'financial': return DollarSign;
    case 'projects': return ListChecks;
    case 'vehicles': return Car;
    case 'family': return Heart;
    case 'errands': return Package;
    case 'home improvement': return Home;
    default: return CheckCircle2;
  }
};

const getCategoryColor = (category: string) => {
  switch (category.toLowerCase()) {
    case 'home maintenance': return 'bg-blue-100 text-blue-600';
    case 'financial': return 'bg-green-100 text-green-600';
    case 'projects': return 'bg-purple-100 text-purple-600';
    case 'vehicles': return 'bg-cyan-100 text-cyan-600';
    case 'family': return 'bg-pink-100 text-pink-600';
    case 'errands': return 'bg-amber-100 text-amber-600';
    case 'home improvement': return 'bg-indigo-100 text-indigo-600';
    default: return 'bg-warm-100 text-warm-600';
  }
};

const getPriorityStyles = (priority: RequestPriority) => {
  switch (priority) {
    case 'urgent': return { bg: 'bg-red-50', border: 'border-red-200', badge: 'bg-red-100 text-red-700' };
    case 'high': return { bg: 'bg-amber-50', border: 'border-amber-200', badge: 'bg-amber-100 text-amber-700' };
    case 'normal': return { bg: 'bg-white', border: 'border-warm-200', badge: 'bg-warm-100 text-warm-600' };
    case 'low': return { bg: 'bg-white', border: 'border-warm-100', badge: 'bg-warm-100 text-warm-500' };
  }
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function ManagerHubPage() {
  const [requests, setRequests] = useState(PENDING_REQUESTS);
  const [selectedRequest, setSelectedRequest] = useState<PendingRequest | null>(null);
  const [messageInput, setMessageInput] = useState('');
  const [showAllCompleted, setShowAllCompleted] = useState(false);

  const pendingCount = requests.length;

  const handleApprove = (requestId: string, optionId?: string) => {
    setRequests(prev => prev.filter(r => r.id !== requestId));
    setSelectedRequest(null);
  };

  const handleDeny = (requestId: string) => {
    setRequests(prev => prev.filter(r => r.id !== requestId));
    setSelectedRequest(null);
  };

  const handleSendMessage = () => {
    if (!messageInput.trim()) return;
    setMessageInput('');
  };

  return (
    <div className="min-h-screen bg-warm-50 pb-24 lg:pb-8">
      {/* HEADER - Manager Profile Card */}
      <div className="bg-white border-b border-warm-200">
        <div className="max-w-6xl mx-auto px-4 py-6">
          <div className="flex flex-col sm:flex-row sm:items-center gap-4">
            {/* Manager Avatar & Status */}
            <div className="relative">
              <ManagerAvatar size="2xl" />
              {MANAGER.isOnline && (
                <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-green-500 rounded-full border-3 border-white flex items-center justify-center">
                  <div className="w-2 h-2 bg-white rounded-full" />
                </div>
              )}
            </div>

            {/* Manager Info */}
            <div className="flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h1 className="text-xl sm:text-2xl font-bold text-warm-900">{MANAGER.name}</h1>
                <span className="px-2 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded-full flex items-center gap-1">
                  <BadgeCheck className="w-3 h-3" />
                  Your Home Manager
                </span>
              </div>
              <p className="text-sm text-warm-500 mt-0.5">
                Managing your home since {MANAGER.startDate} {MANAGER.isOnline ? (
                  <span className="text-green-600 font-medium">Online now</span>
                ) : (
                  <span>Last active {MANAGER.lastActive}</span>
                )}
              </p>

              {/* Quick Contact Buttons */}
              <div className="flex items-center gap-2 mt-3">
                <button className="flex items-center gap-2 px-4 py-2 bg-haven-700 text-white text-sm font-medium rounded-xl hover:bg-haven-800 transition-colors">
                  <MessageCircle className="w-4 h-4" />
                  Message
                </button>
                <a
                  href={`tel:${MANAGER.phone}`}
                  className="flex items-center gap-2 px-4 py-2 border border-warm-200 text-warm-700 text-sm font-medium rounded-xl hover:bg-warm-50 transition-colors"
                >
                  <Phone className="w-4 h-4" />
                  <span className="hidden sm:inline">Call</span>
                </a>
                <button className="flex items-center gap-2 px-4 py-2 border border-warm-200 text-warm-700 text-sm font-medium rounded-xl hover:bg-warm-50 transition-colors">
                  <Video className="w-4 h-4" />
                  <span className="hidden sm:inline">Video</span>
                </button>
              </div>
            </div>

            {/* Stats - Desktop */}
            <div className="hidden lg:grid grid-cols-4 gap-4">
              <div className="text-center px-4 py-2 bg-warm-50 rounded-xl">
                <p className="text-2xl font-bold text-warm-900">{MANAGER.stats.tasksCompletedThisMonth}</p>
                <p className="text-xs text-warm-500">Tasks This Month</p>
              </div>
              <div className="text-center px-4 py-2 bg-warm-50 rounded-xl">
                <p className="text-2xl font-bold text-warm-900">{MANAGER.stats.hoursManaged}h</p>
                <p className="text-xs text-warm-500">Hours Managed</p>
              </div>
              <div className="text-center px-4 py-2 bg-warm-50 rounded-xl">
                <p className="text-2xl font-bold text-warm-900">{MANAGER.stats.vendorsCoordinated}</p>
                <p className="text-xs text-warm-500">Vendors Coordinated</p>
              </div>
              <div className="text-center px-4 py-2 bg-warm-50 rounded-xl">
                <p className="text-2xl font-bold text-haven-700">${(MANAGER.stats.moneyManaged / 1000).toFixed(1)}k</p>
                <p className="text-xs text-warm-500">Money Managed</p>
              </div>
            </div>
          </div>

          {/* Stats - Mobile */}
          <div className="lg:hidden grid grid-cols-4 gap-2 mt-4">
            <div className="text-center py-2 bg-warm-50 rounded-lg">
              <p className="text-lg font-bold text-warm-900">{MANAGER.stats.tasksCompletedThisMonth}</p>
              <p className="text-xs text-warm-500">Tasks</p>
            </div>
            <div className="text-center py-2 bg-warm-50 rounded-lg">
              <p className="text-lg font-bold text-warm-900">{MANAGER.stats.hoursManaged}h</p>
              <p className="text-xs text-warm-500">Hours</p>
            </div>
            <div className="text-center py-2 bg-warm-50 rounded-lg">
              <p className="text-lg font-bold text-warm-900">{MANAGER.stats.vendorsCoordinated}</p>
              <p className="text-xs text-warm-500">Vendors</p>
            </div>
            <div className="text-center py-2 bg-warm-50 rounded-lg">
              <p className="text-lg font-bold text-haven-700">${(MANAGER.stats.moneyManaged / 1000).toFixed(1)}k</p>
              <p className="text-xs text-warm-500">Managed</p>
            </div>
          </div>
        </div>
      </div>

      {/* MAIN CONTENT */}
      <div className="max-w-6xl mx-auto px-4 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          {/* LEFT COLUMN - Requests & Activity (2/3 width on desktop) */}
          <div className="lg:col-span-2 space-y-6">

            {/* NEEDS YOUR INPUT - Priority Section */}
            <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-red-100 flex items-center justify-center">
                    <Bell className="w-5 h-5 text-red-600" />
                  </div>
                  <div>
                    <h2 className="font-semibold text-warm-900">Needs Your Input</h2>
                    <p className="text-sm text-warm-500">{pendingCount} item{pendingCount !== 1 ? 's' : ''} waiting</p>
                  </div>
                </div>
                {pendingCount > 0 && (
                  <span className="px-3 py-1 bg-red-100 text-red-700 text-sm font-bold rounded-full">
                    {pendingCount}
                  </span>
                )}
              </div>

              <div className="divide-y divide-warm-100">
                {requests.length === 0 ? (
                  <div className="p-8 text-center">
                    <CheckCircle2 className="w-12 h-12 text-green-300 mx-auto mb-3" />
                    <p className="font-medium text-warm-900">All caught up!</p>
                    <p className="text-sm text-warm-500 mt-1">{MANAGER.firstName} will let you know when she needs your input</p>
                  </div>
                ) : (
                  requests.map((request) => {
                    const priorityStyles = getPriorityStyles(request.priority);
                    const CategoryIcon = getCategoryIcon(request.category);

                    return (
                      <div
                        key={request.id}
                        className={`p-4 ${priorityStyles.bg} hover:bg-warm-50 transition-colors cursor-pointer`}
                        onClick={() => setSelectedRequest(request)}
                      >
                        <div className="flex items-start gap-3">
                          {/* Category Icon */}
                          <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${getCategoryColor(request.category)}`}>
                            <CategoryIcon className="w-5 h-5" />
                          </div>

                          {/* Content */}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-2 flex-wrap">
                                  <h3 className="font-medium text-warm-900">{request.title}</h3>
                                  {request.priority === 'urgent' && (
                                    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${priorityStyles.badge}`}>
                                      Urgent
                                    </span>
                                  )}
                                </div>
                                <p className="text-sm text-warm-600 mt-1 line-clamp-2">{request.description}</p>
                              </div>

                              {request.amount && (
                                <span className="font-semibold text-warm-900 flex-shrink-0">
                                  ${request.amount.toLocaleString()}
                                </span>
                              )}
                            </div>

                            {/* Meta Info */}
                            <div className="flex items-center gap-3 mt-2 text-xs text-warm-500">
                              {request.vendor && (
                                <span className="flex items-center gap-1">
                                  <Wrench className="w-3 h-3" />
                                  {request.vendor}
                                </span>
                              )}
                              <span>{request.createdAt}</span>
                              {request.dueBy && (
                                <span className="text-red-600 font-medium">Due {request.dueBy}</span>
                              )}
                            </div>

                            {/* Quick Actions (for simple approve/deny) */}
                            {!request.options && (
                              <div className="flex gap-2 mt-3">
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleApprove(request.id);
                                  }}
                                  className="flex items-center gap-1.5 px-4 py-2 bg-haven-700 text-white text-sm font-medium rounded-lg hover:bg-haven-800 transition-colors"
                                >
                                  <Check className="w-4 h-4" />
                                  Approve
                                </button>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleDeny(request.id);
                                  }}
                                  className="flex items-center gap-1.5 px-4 py-2 border border-warm-200 text-warm-600 text-sm font-medium rounded-lg hover:bg-warm-50 transition-colors"
                                >
                                  <X className="w-4 h-4" />
                                  Deny
                                </button>
                              </div>
                            )}

                            {/* Options (for scheduling/questions) */}
                            {request.options && (
                              <div className="mt-3 space-y-2">
                                {request.options.slice(0, 2).map((option) => (
                                  <button
                                    key={option.id}
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleApprove(request.id, option.id);
                                    }}
                                    className={`w-full flex items-center justify-between p-3 rounded-lg border text-left transition-colors ${
                                      option.recommended
                                        ? 'border-haven-300 bg-haven-50 hover:bg-haven-100'
                                        : 'border-warm-200 hover:bg-warm-50'
                                    }`}
                                  >
                                    <div>
                                      <p className="text-sm font-medium text-warm-900">{option.label}</p>
                                      {option.description && (
                                        <p className="text-xs text-warm-500 mt-0.5">{option.description}</p>
                                      )}
                                    </div>
                                    <div className="flex items-center gap-2">
                                      {option.cost && (
                                        <span className="text-sm text-warm-600">${option.cost}</span>
                                      )}
                                      {option.recommended && (
                                        <span className="px-2 py-0.5 bg-haven-200 text-haven-700 text-xs font-medium rounded-full">
                                          Recommended
                                        </span>
                                      )}
                                    </div>
                                  </button>
                                ))}
                                {request.options.length > 2 && (
                                  <button
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      setSelectedRequest(request);
                                    }}
                                    className="w-full text-sm text-haven-700 font-medium hover:text-haven-800 py-2"
                                  >
                                    View all {request.options.length} options
                                  </button>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>

            {/* WHAT SARAH'S WORKING ON */}
            <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
                    <Timer className="w-5 h-5 text-blue-600" />
                  </div>
                  <div>
                    <h2 className="font-semibold text-warm-900">What {MANAGER.firstName}&apos;s Working On</h2>
                    <p className="text-sm text-warm-500">{IN_PROGRESS_ITEMS.length} active items</p>
                  </div>
                </div>
              </div>

              <div className="divide-y divide-warm-100">
                {IN_PROGRESS_ITEMS.map((item) => {
                  const CategoryIcon = getCategoryIcon(item.category);
                  return (
                    <div key={item.id} className="p-4 hover:bg-warm-50 transition-colors">
                      <div className="flex items-start gap-3">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${getCategoryColor(item.category)}`}>
                          <CategoryIcon className="w-5 h-5" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <h3 className="font-medium text-warm-900">{item.title}</h3>
                            <span className={`px-2 py-0.5 text-xs font-medium rounded-full flex-shrink-0 ${
                              item.status === 'in-progress' ? 'bg-blue-100 text-blue-700' :
                              item.status === 'scheduled' ? 'bg-purple-100 text-purple-700' :
                              item.status === 'waiting' ? 'bg-amber-100 text-amber-700' :
                              'bg-warm-100 text-warm-600'
                            }`}>
                              {item.status === 'in-progress' ? 'In Progress' :
                               item.status === 'scheduled' ? 'Scheduled' :
                               item.status === 'waiting' ? 'Waiting' : 'On Hold'}
                            </span>
                          </div>
                          <p className="text-sm text-warm-600 mt-1">{item.description}</p>

                          {/* Latest Update */}
                          {item.updates && item.updates[0] && (
                            <div className="mt-2 p-2 bg-warm-50 rounded-lg">
                              <p className="text-xs text-warm-500">
                                <span className="font-medium">{item.updates[0].time}:</span> {item.updates[0].message}
                              </p>
                            </div>
                          )}

                          <div className="flex items-center gap-3 mt-2 text-xs text-warm-500">
                            {item.vendor && <span>{item.vendor}</span>}
                            {item.estimatedCompletion && (
                              <span className="flex items-center gap-1">
                                <Calendar className="w-3 h-3" />
                                {item.estimatedCompletion}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* THIS WEEK'S ACTIVITY - Completed */}
            <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
                    <CheckCircle2 className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <h2 className="font-semibold text-warm-900">This Week&apos;s Activity</h2>
                    <p className="text-sm text-warm-500">{COMPLETED_ITEMS.length} items completed</p>
                  </div>
                </div>
                <button
                  onClick={() => setShowAllCompleted(!showAllCompleted)}
                  className="text-sm text-haven-700 font-medium hover:text-haven-800"
                >
                  {showAllCompleted ? 'Show Less' : 'View All'}
                </button>
              </div>

              <div className="divide-y divide-warm-100">
                {(showAllCompleted ? COMPLETED_ITEMS : COMPLETED_ITEMS.slice(0, 4)).map((item) => {
                  return (
                    <div key={item.id} className="p-4 hover:bg-warm-50 transition-colors">
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 rounded-lg bg-green-100 flex items-center justify-center flex-shrink-0">
                          <Check className="w-4 h-4 text-green-600" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <div>
                              <h3 className="font-medium text-warm-900 text-sm">{item.title}</h3>
                              <p className="text-xs text-warm-500 mt-0.5">{item.description}</p>
                            </div>
                            {item.savedAmount && (
                              <span className="text-sm font-medium text-green-600 flex-shrink-0">
                                Saved ${item.savedAmount.toLocaleString()}
                              </span>
                            )}
                            {item.cost && !item.savedAmount && (
                              <span className="text-sm text-warm-600 flex-shrink-0">
                                ${item.cost.toLocaleString()}
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="text-xs text-warm-400">{item.completedAt}</span>
                            {item.result && (
                              <>
                                <span className="text-warm-300"></span>
                                <span className="text-xs text-green-600 font-medium">{item.result}</span>
                              </>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* RIGHT COLUMN - Upcoming & Quick Message (1/3 width on desktop) */}
          <div className="space-y-6">

            {/* UPCOMING */}
            <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
                    <Calendar className="w-5 h-5 text-purple-600" />
                  </div>
                  <div>
                    <h2 className="font-semibold text-warm-900">Upcoming</h2>
                    <p className="text-sm text-warm-500">What&apos;s scheduled</p>
                  </div>
                </div>
              </div>

              <div className="divide-y divide-warm-100">
                {UPCOMING_ITEMS.map((item) => {
                  const CategoryIcon = getCategoryIcon(item.category);
                  return (
                    <div key={item.id} className="p-4 hover:bg-warm-50 transition-colors">
                      <div className="flex items-start gap-3">
                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${getCategoryColor(item.category)}`}>
                          <CategoryIcon className="w-4 h-4" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <h3 className="font-medium text-warm-900 text-sm">{item.title}</h3>
                          <p className="text-xs text-warm-500 mt-0.5">{item.description}</p>
                          <div className="flex items-center gap-2 mt-1.5 text-xs text-warm-500">
                            <Calendar className="w-3 h-3" />
                            <span className="font-medium text-warm-700">{item.scheduledFor}</span>
                            {item.duration && (
                              <>
                                <span className="text-warm-300"></span>
                                <span>{item.duration}</span>
                              </>
                            )}
                          </div>
                          {item.vendor && (
                            <p className="text-xs text-warm-500 mt-1">{item.vendor}</p>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>

              <div className="p-3 border-t border-warm-100">
                <button className="w-full text-sm text-haven-700 font-medium hover:text-haven-800 py-2">
                  View Full Calendar
                </button>
              </div>
            </div>

            {/* QUICK MESSAGE */}
            <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
              <div className="p-4 border-b border-warm-100">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-haven-100 flex items-center justify-center">
                      <MessageCircle className="w-5 h-5 text-haven-700" />
                    </div>
                    <div>
                      <h2 className="font-semibold text-warm-900">Quick Message</h2>
                      <p className="text-sm text-warm-500">Chat with {MANAGER.firstName}</p>
                    </div>
                  </div>
                  <button className="text-sm text-haven-700 font-medium hover:text-haven-800">
                    Full Chat
                  </button>
                </div>
              </div>

              {/* Recent Messages Preview */}
              <div className="p-4 space-y-3 max-h-64 overflow-y-auto bg-warm-50">
                {RECENT_MESSAGES.map((msg) => (
                  <div
                    key={msg.id}
                    className={`flex ${msg.sender === 'homeowner' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`max-w-[85%] rounded-2xl px-4 py-2 ${
                      msg.sender === 'homeowner'
                        ? 'bg-haven-700 text-white rounded-br-md'
                        : 'bg-white text-warm-900 rounded-bl-md shadow-sm'
                    }`}>
                      <p className="text-sm">{msg.content}</p>
                      <p className={`text-xs mt-1 ${
                        msg.sender === 'homeowner' ? 'text-haven-200' : 'text-warm-400'
                      }`}>
                        {msg.timestamp}
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              {/* Message Input */}
              <div className="p-3 border-t border-warm-200 bg-white">
                <div className="flex items-center gap-2">
                  <button className="p-2 text-warm-400 hover:text-warm-600 transition-colors">
                    <Paperclip className="w-5 h-5" />
                  </button>
                  <input
                    type="text"
                    value={messageInput}
                    onChange={(e) => setMessageInput(e.target.value)}
                    placeholder={`Message ${MANAGER.firstName}...`}
                    className="flex-1 px-4 py-2 bg-warm-50 border-0 rounded-xl text-sm focus:ring-2 focus:ring-haven-600"
                    onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                  />
                  <button className="p-2 text-warm-400 hover:text-warm-600 transition-colors">
                    <Mic className="w-5 h-5" />
                  </button>
                  <button
                    onClick={handleSendMessage}
                    disabled={!messageInput.trim()}
                    className="p-2 bg-haven-700 text-white rounded-xl hover:bg-haven-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Send className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>

            {/* VALUE SUMMARY */}
            <div className="bg-gradient-to-br from-haven-700 to-haven-700 rounded-2xl p-5 text-white">
              <div className="flex items-center gap-2 mb-4">
                <Sparkles className="w-5 h-5" />
                <h3 className="font-semibold text-white">Your Haven Value</h3>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-haven-200">Time saved this month</span>
                  <span className="font-bold">~{MANAGER.stats.hoursManaged} hours</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-haven-200">Vendors managed</span>
                  <span className="font-bold">{MANAGER.stats.vendorsCoordinated}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-haven-200">Tasks handled</span>
                  <span className="font-bold">{MANAGER.stats.tasksCompletedThisMonth}</span>
                </div>
                <div className="h-px bg-haven-600 my-2" />
                <div className="flex items-center justify-between">
                  <span className="text-haven-200">Money managed</span>
                  <span className="font-bold text-lg">${MANAGER.stats.moneyManaged.toLocaleString()}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* REQUEST DETAIL MODAL */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-end sm:items-center justify-center p-0 sm:p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setSelectedRequest(null)} />
            <div className="relative bg-white w-full sm:max-w-lg sm:rounded-2xl overflow-hidden max-h-[90vh] overflow-y-auto rounded-t-2xl">
              {/* Modal Header */}
              <div className="sticky top-0 bg-white border-b border-warm-200 p-4 flex items-center justify-between">
                <h3 className="font-semibold text-warm-900">Request Details</h3>
                <button
                  onClick={() => setSelectedRequest(null)}
                  className="p-2 hover:bg-warm-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-warm-400" />
                </button>
              </div>

              {/* Modal Content */}
              <div className="p-4 space-y-4">
                {/* Title & Priority */}
                <div>
                  <div className="flex items-start gap-2">
                    <h2 className="text-lg font-semibold text-warm-900 flex-1">{selectedRequest.title}</h2>
                    {selectedRequest.priority === 'urgent' && (
                      <span className="px-2 py-1 bg-red-100 text-red-700 text-xs font-medium rounded-full">
                        Urgent
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 mt-2 text-sm text-warm-500">
                    <span className={`px-2 py-0.5 rounded-full text-xs ${getCategoryColor(selectedRequest.category)}`}>
                      {selectedRequest.category}
                    </span>
                    <span></span>
                    <span>{selectedRequest.createdAt}</span>
                    {selectedRequest.vendor && (
                      <>
                        <span></span>
                        <span>{selectedRequest.vendor}</span>
                      </>
                    )}
                  </div>
                </div>

                {/* Description */}
                <div className="bg-warm-50 rounded-xl p-4">
                  <p className="text-warm-700 text-sm leading-relaxed">{selectedRequest.description}</p>
                </div>

                {/* Amount */}
                {selectedRequest.amount && (
                  <div className="flex items-center justify-between p-4 bg-green-50 rounded-xl">
                    <span className="text-green-700 font-medium">Amount</span>
                    <span className="text-2xl font-bold text-green-700">
                      ${selectedRequest.amount.toLocaleString()}
                    </span>
                  </div>
                )}

                {/* Attachments */}
                {selectedRequest.attachments && selectedRequest.attachments.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-warm-700 mb-2">Attachments</h4>
                    <div className="space-y-2">
                      {selectedRequest.attachments.map((attachment, idx) => (
                        <a
                          key={idx}
                          href={attachment.url}
                          className="flex items-center gap-3 p-3 bg-warm-50 rounded-lg hover:bg-warm-100 transition-colors"
                        >
                          <FileText className="w-5 h-5 text-warm-500" />
                          <span className="text-sm text-warm-700 flex-1">{attachment.name}</span>
                          <ExternalLink className="w-4 h-4 text-warm-400" />
                        </a>
                      ))}
                    </div>
                  </div>
                )}

                {/* Options */}
                {selectedRequest.options && (
                  <div>
                    <h4 className="text-sm font-medium text-warm-700 mb-2">Your Options</h4>
                    <div className="space-y-2">
                      {selectedRequest.options.map((option) => (
                        <button
                          key={option.id}
                          onClick={() => handleApprove(selectedRequest.id, option.id)}
                          className={`w-full text-left p-4 rounded-xl border transition-colors ${
                            option.recommended
                              ? 'border-haven-300 bg-haven-50 hover:bg-haven-100'
                              : 'border-warm-200 hover:bg-warm-50'
                          }`}
                        >
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <p className="font-medium text-warm-900">{option.label}</p>
                              {option.description && (
                                <p className="text-sm text-warm-500 mt-1">{option.description}</p>
                              )}
                            </div>
                            <div className="flex flex-col items-end gap-1 ml-3">
                              {option.cost && (
                                <span className="font-semibold text-warm-900">${option.cost.toLocaleString()}</span>
                              )}
                              {option.recommended && (
                                <span className="px-2 py-0.5 bg-haven-200 text-haven-700 text-xs font-medium rounded-full">
                                  Recommended
                                </span>
                              )}
                            </div>
                          </div>
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Modal Footer - Actions */}
              {!selectedRequest.options && (
                <div className="sticky bottom-0 bg-white border-t border-warm-200 p-4 flex gap-3">
                  <button
                    onClick={() => handleDeny(selectedRequest.id)}
                    className="flex-1 py-3 border border-warm-200 text-warm-700 font-medium rounded-xl hover:bg-warm-50 transition-colors"
                  >
                    Deny
                  </button>
                  <button
                    onClick={() => handleApprove(selectedRequest.id)}
                    className="flex-1 py-3 bg-haven-700 text-white font-medium rounded-xl hover:bg-haven-800 transition-colors"
                  >
                    Approve
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
