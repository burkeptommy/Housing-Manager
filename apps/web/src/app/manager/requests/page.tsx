'use client';

import { useState } from 'react';
import {
  Inbox,
  AlertTriangle,
  Clock,
  Camera,
  MapPin,
  User,
  Sparkles,
  Star,
  Wrench,
  ClipboardList,
  MessageCircle,
  Eye,
  Phone,
  X,
  Send,
  ChevronRight,
  ArrowUpDown,
  CheckCircle2,
  HelpCircle,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface RequestPhoto {
  id: string;
  url: string;
  caption?: string;
}

interface AISuggestion {
  category: string;
  recommendation: string;
  estimatedCost: string;
  suggestedVendor?: {
    name: string;
    rating: number;
    usageCount: number;
  };
}

interface ServiceRequest {
  id: string;
  householdId: string;
  householdName: string;
  address: string;
  title: string;
  description: string;
  priority: 'urgent' | 'high' | 'medium' | 'low';
  status: 'needs_triage' | 'awaiting_info' | 'triaged' | 'assigned' | 'in_progress' | 'completed';
  category?: string;
  location?: string;
  submittedBy: string;
  submittedAt: string;
  photos: RequestPhoto[];
  aiSuggestion?: AISuggestion;
}

type TriageAction = 'handyman' | 'vendor' | 'self' | 'more_info';

// ============================================================================
// MOCK DATA
// ============================================================================

const mockRequests: ServiceRequest[] = [
  {
    id: 'r1',
    householdId: 'hh1',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    title: 'Pipe burst under kitchen sink - water everywhere!',
    description: 'Pipe burst under kitchen sink - water everywhere! We\'ve turned off the water main but there\'s water damage to the cabinet.',
    priority: 'urgent',
    status: 'needs_triage',
    location: 'Kitchen',
    submittedBy: 'Bob',
    submittedAt: '2 minutes ago',
    photos: [{ id: 'p1', url: '/photos/leak1.jpg' }, { id: 'p2', url: '/photos/leak2.jpg' }, { id: 'p3', url: '/photos/leak3.jpg' }],
    aiSuggestion: {
      category: 'Plumbing - Emergency',
      recommendation: 'Dispatch emergency plumber immediately',
      estimatedCost: '$200-500 (emergency call)',
      suggestedVendor: { name: "Mike's Plumbing", rating: 4.9, usageCount: 47 },
    },
  },
  {
    id: 'r2',
    householdId: 'hh1',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    title: 'Kitchen faucet dripping',
    description: 'Faucet in main kitchen has been dripping for 2 days. Getting worse.',
    priority: 'medium',
    status: 'needs_triage',
    location: 'Kitchen',
    submittedBy: 'Alice',
    submittedAt: '45 minutes ago',
    photos: [{ id: 'p4', url: '/photos/faucet1.jpg' }, { id: 'p5', url: '/photos/faucet2.jpg' }],
    aiSuggestion: {
      category: 'Plumbing - Minor',
      recommendation: 'Handyman can likely fix - washer replacement',
      estimatedCost: '$0 (included service)',
      suggestedVendor: { name: "Mike's Plumbing", rating: 4.9, usageCount: 47 },
    },
  },
  {
    id: 'r3',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    address: '789 Maple Drive',
    title: 'AC not cooling properly',
    description: 'House won\'t get below 78 even with AC running all day. Filter was changed last month.',
    priority: 'high',
    status: 'needs_triage',
    location: 'HVAC System',
    submittedBy: 'Tom',
    submittedAt: '1 hour ago',
    photos: [],
    aiSuggestion: {
      category: 'HVAC - Service',
      recommendation: 'Schedule HVAC technician - possible refrigerant issue',
      estimatedCost: '$150-400',
      suggestedVendor: { name: 'CoolAir HVAC', rating: 4.8, usageCount: 23 },
    },
  },
  {
    id: 'r4',
    householdId: 'hh3',
    householdName: 'Garcia Residence',
    address: '321 Cedar Street',
    title: 'Garage door opener not working',
    description: 'Remote stopped working, tried new batteries. Wall button works fine.',
    priority: 'low',
    status: 'needs_triage',
    location: 'Garage',
    submittedBy: 'Maria',
    submittedAt: '2 hours ago',
    photos: [],
    aiSuggestion: {
      category: 'Garage Door',
      recommendation: 'Handyman can reprogram remote or replace',
      estimatedCost: '$0-50 (remote if needed)',
    },
  },
  {
    id: 'r5',
    householdId: 'hh1',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    title: 'Which paint color for dining room?',
    description: 'We want to repaint the dining room. Can you help us choose between these samples?',
    priority: 'low',
    status: 'awaiting_info',
    submittedBy: 'Alice',
    submittedAt: '1 day ago',
    photos: [{ id: 'p6', url: '/photos/paint1.jpg' }],
  },
  {
    id: 'r6',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    address: '789 Maple Drive',
    title: 'Need smoke detector batteries replaced',
    description: 'All smoke detectors chirping, need batteries replaced throughout house.',
    priority: 'medium',
    status: 'awaiting_info',
    submittedBy: 'Sarah',
    submittedAt: '3 hours ago',
    photos: [],
  },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const priorityConfig = {
  urgent: { label: 'URGENT', bgColor: 'bg-red-50', textColor: 'text-red-700', borderColor: 'border-l-red-500', dotColor: 'bg-red-500' },
  high: { label: 'HIGH', bgColor: 'bg-amber-50', textColor: 'text-amber-700', borderColor: 'border-l-amber-500', dotColor: 'bg-amber-500' },
  medium: { label: 'MEDIUM', bgColor: 'bg-blue-50', textColor: 'text-blue-700', borderColor: 'border-l-blue-500', dotColor: 'bg-blue-500' },
  low: { label: 'LOW', bgColor: 'bg-slate-50', textColor: 'text-slate-600', borderColor: 'border-l-slate-300', dotColor: 'bg-slate-400' },
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function RequestTriagePage() {
  const [requests] = useState<ServiceRequest[]>(mockRequests);
  const [selectedRequest, setSelectedRequest] = useState<ServiceRequest | null>(null);
  const [showTriageModal, setShowTriageModal] = useState(false);
  const [sortBy, setSortBy] = useState('newest');
  const [filterPriority, setFilterPriority] = useState('all');

  const needsTriage = requests.filter(r => r.status === 'needs_triage');
  const awaitingInfo = requests.filter(r => r.status === 'awaiting_info');

  const handleTriage = (request: ServiceRequest) => {
    setSelectedRequest(request);
    setShowTriageModal(true);
  };

  // Filter and sort
  let filteredRequests = [...needsTriage];
  if (filterPriority !== 'all') {
    filteredRequests = filteredRequests.filter(r => r.priority === filterPriority);
  }
  if (sortBy === 'priority') {
    const priorityOrder = { urgent: 0, high: 1, medium: 2, low: 3 };
    filteredRequests.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
  }

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <Inbox className="w-8 h-8 text-indigo-600" />
              <h1 className="text-2xl font-bold text-slate-900">Request Triage</h1>
            </div>
            <div className="flex items-center gap-3">
              <select
                value={filterPriority}
                onChange={(e) => setFilterPriority(e.target.value)}
                className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="all">All Priorities</option>
                <option value="urgent">Urgent</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
              <div className="flex items-center gap-1 text-sm text-slate-500">
                <ArrowUpDown className="w-4 h-4" />
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="px-2 py-2 border-0 bg-transparent focus:outline-none"
                >
                  <option value="newest">Sort: Newest</option>
                  <option value="priority">Sort: Priority</option>
                </select>
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="bg-red-50 rounded-lg p-4 border border-red-100">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-red-600" />
                <p className="text-xs font-medium text-red-600 uppercase tracking-wide">Urgent</p>
              </div>
              <p className="text-2xl font-bold text-red-700 mt-1">{needsTriage.filter(r => r.priority === 'urgent').length}</p>
            </div>
            <div className="bg-amber-50 rounded-lg p-4 border border-amber-100">
              <p className="text-xs font-medium text-amber-600 uppercase tracking-wide">Needs Triage</p>
              <p className="text-2xl font-bold text-amber-700 mt-1">{needsTriage.length}</p>
            </div>
            <div className="bg-blue-50 rounded-lg p-4 border border-blue-100">
              <p className="text-xs font-medium text-blue-600 uppercase tracking-wide">Awaiting Info</p>
              <p className="text-2xl font-bold text-blue-700 mt-1">{awaitingInfo.length}</p>
            </div>
            <div className="bg-emerald-50 rounded-lg p-4 border border-emerald-100">
              <p className="text-xs font-medium text-emerald-600 uppercase tracking-wide">Triaged Today</p>
              <p className="text-2xl font-bold text-emerald-700 mt-1">7</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Needs Triage Column */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
                <Clock className="w-5 h-5 text-amber-500" />
                Needs Triage ({filteredRequests.length})
              </h2>
            </div>

            {filteredRequests.length === 0 ? (
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8 text-center">
                <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto mb-3" />
                <h3 className="font-medium text-slate-900">All caught up!</h3>
                <p className="text-sm text-slate-500">No requests need triage right now.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredRequests.map(request => {
                  const priority = priorityConfig[request.priority];

                  return (
                    <div
                      key={request.id}
                      className={`bg-white rounded-xl shadow-sm border border-slate-200 border-l-4 ${priority.borderColor} overflow-hidden`}
                    >
                      {/* Header */}
                      <div className="p-4">
                        <div className="flex items-start justify-between mb-2">
                          <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-xs font-bold ${priority.bgColor} ${priority.textColor}`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${priority.dotColor}`} />
                            {priority.label}
                          </span>
                          <span className="text-xs text-slate-400">{request.submittedAt}</span>
                        </div>

                        <div className="flex items-start justify-between">
                          <div>
                            <h3 className="font-semibold text-slate-900">{request.householdName}</h3>
                            <p className="text-sm text-slate-500">{request.address}</p>
                          </div>
                        </div>

                        <div className="mt-3 p-3 bg-slate-50 rounded-lg">
                          <p className="text-slate-700 text-sm">&ldquo;{request.description}&rdquo;</p>
                        </div>

                        {/* Meta */}
                        <div className="flex flex-wrap items-center gap-3 mt-3 text-xs text-slate-500">
                          {request.photos.length > 0 && (
                            <span className="flex items-center gap-1">
                              <Camera className="w-3.5 h-3.5" />
                              {request.photos.length} photos
                            </span>
                          )}
                          {request.location && (
                            <span className="flex items-center gap-1">
                              <MapPin className="w-3.5 h-3.5" />
                              {request.location}
                            </span>
                          )}
                          <span className="flex items-center gap-1">
                            <User className="w-3.5 h-3.5" />
                            Submitted by: {request.submittedBy}
                          </span>
                        </div>

                        {/* AI Suggestion */}
                        {request.aiSuggestion && (
                          <div className="mt-4 bg-indigo-50 border border-indigo-200 rounded-lg p-4">
                            <div className="flex items-center gap-2 mb-2">
                              <Sparkles className="w-4 h-4 text-indigo-600" />
                              <span className="text-xs font-medium text-indigo-700 uppercase tracking-wide">AI Triage Suggestion</span>
                            </div>
                            <div className="space-y-1 text-sm">
                              <p><span className="text-indigo-600 font-medium">Category:</span> <span className="text-indigo-900">{request.aiSuggestion.category}</span></p>
                              <p><span className="text-indigo-600 font-medium">Recommended:</span> <span className="text-indigo-900">{request.aiSuggestion.recommendation}</span></p>
                              <p><span className="text-indigo-600 font-medium">Estimated cost:</span> <span className="text-indigo-900">{request.aiSuggestion.estimatedCost}</span></p>
                              {request.aiSuggestion.suggestedVendor && (
                                <p>
                                  <span className="text-indigo-600 font-medium">Suggested vendor:</span>{' '}
                                  <span className="text-indigo-900">
                                    {request.aiSuggestion.suggestedVendor.name} ({request.aiSuggestion.suggestedVendor.rating}
                                    <Star className="w-3 h-3 inline text-amber-400 ml-0.5" />, used {request.aiSuggestion.suggestedVendor.usageCount}x)
                                  </span>
                                </p>
                              )}
                            </div>
                          </div>
                        )}

                        {/* Actions */}
                        <div className="flex flex-wrap items-center gap-2 mt-4 pt-4 border-t border-slate-100">
                          {request.priority === 'urgent' && (
                            <button
                              onClick={() => handleTriage(request)}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700 transition-colors"
                            >
                              <AlertTriangle className="w-4 h-4" />
                              Emergency Dispatch
                            </button>
                          )}
                          <button
                            onClick={() => handleTriage(request)}
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
                          >
                            <Wrench className="w-4 h-4" />
                            Assign Handyman
                          </button>
                          <button
                            onClick={() => handleTriage(request)}
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors"
                          >
                            <ClipboardList className="w-4 h-4" />
                            Create Work Order
                          </button>
                          <button className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                            <MessageCircle className="w-4 h-4" />
                            Ask for More Info
                          </button>
                          <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-slate-500 text-sm font-medium hover:text-indigo-600 transition-colors">
                            <Eye className="w-4 h-4" />
                            View Household
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Awaiting Info Column */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
              <HelpCircle className="w-5 h-5 text-blue-500" />
              Awaiting Info ({awaitingInfo.length})
            </h2>

            {awaitingInfo.map(request => (
              <div
                key={request.id}
                className="bg-white rounded-xl shadow-sm border border-slate-200 p-4"
              >
                <div className="flex items-start justify-between mb-2">
                  <span className="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-0.5 rounded">AWAITING INFO</span>
                  <span className="text-xs text-slate-400">{request.submittedAt}</span>
                </div>
                <h3 className="font-medium text-slate-900 text-sm">{request.householdName}</h3>
                <p className="text-sm text-slate-600 mt-1">{request.title}</p>
                <div className="flex items-center gap-2 mt-3">
                  <button className="flex-1 inline-flex items-center justify-center gap-1.5 px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors">
                    <Send className="w-4 h-4" />
                    Send Reminder
                  </button>
                  <button className="px-3 py-1.5 border border-slate-200 text-slate-600 text-sm rounded-lg hover:bg-slate-50">
                    <Phone className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Triage Modal */}
      {showTriageModal && selectedRequest && (
        <TriageModal
          request={selectedRequest}
          onClose={() => {
            setShowTriageModal(false);
            setSelectedRequest(null);
          }}
        />
      )}
    </div>
  );
}

// ============================================================================
// TRIAGE MODAL
// ============================================================================

function TriageModal({ request, onClose }: { request: ServiceRequest; onClose: () => void }) {
  const [action, setAction] = useState<TriageAction>('handyman');
  const [message, setMessage] = useState(
    "Got it! I'm assigning this to our handyman Mike. He can come by tomorrow morning around 9am. Does that work?"
  );
  const [moreInfoQuestion, setMoreInfoQuestion] = useState('');
  const [messageOption, setMessageOption] = useState<'send' | 'edit' | 'none'>('send');

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-200">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Triage Request</h2>
            <p className="text-sm text-slate-500">{request.householdName} - {request.title.slice(0, 50)}...</p>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-4 space-y-4">
          {/* Request Summary */}
          <div className="bg-slate-50 rounded-lg p-4">
            <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Request</p>
            <p className="text-slate-700">&ldquo;{request.description}&rdquo;</p>
            {request.photos.length > 0 && (
              <button className="mt-2 text-sm text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                <Camera className="w-4 h-4" />
                View {request.photos.length} photos
              </button>
            )}
          </div>

          {/* Action Options */}
          <div>
            <p className="text-sm font-medium text-slate-700 mb-3">How will this be handled?</p>
            <div className="space-y-2">
              {/* Handyman Option */}
              <label
                className={`block p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                  action === 'handyman'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="radio"
                    name="action"
                    value="handyman"
                    checked={action === 'handyman'}
                    onChange={() => setAction('handyman')}
                    className="mt-1 text-indigo-600 focus:ring-indigo-500"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-slate-900">Handyman can handle</p>
                    <p className="text-sm text-slate-500 mt-1">Mike Rodriguez - Next available: Tomorrow 9am</p>
                    <p className="text-sm text-slate-500">Estimated: 30 min, $0 (included)</p>
                  </div>
                </div>
              </label>

              {/* Vendor Option */}
              <label
                className={`block p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                  action === 'vendor'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="radio"
                    name="action"
                    value="vendor"
                    checked={action === 'vendor'}
                    onChange={() => setAction('vendor')}
                    className="mt-1 text-indigo-600 focus:ring-indigo-500"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-slate-900">Need vendor/specialist</p>
                    <p className="text-sm text-slate-500 mt-1">Create work order → Get quotes</p>
                    {request.aiSuggestion?.suggestedVendor && (
                      <p className="text-sm text-slate-500">
                        Suggested: {request.aiSuggestion.suggestedVendor.name} ({request.aiSuggestion.suggestedVendor.rating}★)
                      </p>
                    )}
                  </div>
                </div>
              </label>

              {/* Self Option */}
              <label
                className={`block p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                  action === 'self'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="radio"
                    name="action"
                    value="self"
                    checked={action === 'self'}
                    onChange={() => setAction('self')}
                    className="mt-1 text-indigo-600 focus:ring-indigo-500"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-slate-900">I&apos;ll handle directly</p>
                    <p className="text-sm text-slate-500 mt-1">Add to my task list</p>
                  </div>
                </div>
              </label>

              {/* More Info Option */}
              <label
                className={`block p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                  action === 'more_info'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="radio"
                    name="action"
                    value="more_info"
                    checked={action === 'more_info'}
                    onChange={() => setAction('more_info')}
                    className="mt-1 text-indigo-600 focus:ring-indigo-500"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-slate-900">Need more information</p>
                    {action === 'more_info' && (
                      <input
                        type="text"
                        value={moreInfoQuestion}
                        onChange={(e) => setMoreInfoQuestion(e.target.value)}
                        placeholder="Which faucet? Main sink or prep sink?"
                        className="mt-2 w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                    )}
                  </div>
                </div>
              </label>
            </div>
          </div>

          {/* Message to Homeowner */}
          {action !== 'more_info' && (
            <div>
              <p className="text-sm font-medium text-slate-700 mb-2">Message to Homeowner</p>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={3}
                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <div className="flex items-center gap-4 mt-2">
                <label className="flex items-center gap-2 text-sm text-slate-600">
                  <input
                    type="radio"
                    name="messageOption"
                    checked={messageOption === 'send'}
                    onChange={() => setMessageOption('send')}
                    className="text-indigo-600 focus:ring-indigo-500"
                  />
                  Send after confirmation
                </label>
                <label className="flex items-center gap-2 text-sm text-slate-600">
                  <input
                    type="radio"
                    name="messageOption"
                    checked={messageOption === 'edit'}
                    onChange={() => setMessageOption('edit')}
                    className="text-indigo-600 focus:ring-indigo-500"
                  />
                  Edit first
                </label>
                <label className="flex items-center gap-2 text-sm text-slate-600">
                  <input
                    type="radio"
                    name="messageOption"
                    checked={messageOption === 'none'}
                    onChange={() => setMessageOption('none')}
                    className="text-indigo-600 focus:ring-indigo-500"
                  />
                  Don&apos;t send
                </label>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 bg-slate-50">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800"
          >
            Cancel
          </button>
          <button
            onClick={onClose}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            Triage & Send
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
