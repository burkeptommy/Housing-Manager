'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  Home,
  Phone,
  Mail,
  Key,
  Wifi,
  Shield,
  Dog,
  MessageCircle,
  Plus,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Send,
  ChevronRight,
  User,
  Briefcase,
  GraduationCap,
  Thermometer,
  Droplets,
  Zap,
  Wind,
  FileText,
  Upload,
  Download,
  Filter,
  Search,
  MoreVertical,
  Edit,
  DollarSign,
  Receipt,
  CheckSquare,
  Square,
  Building,
  MapPin,
  Users,
  PawPrint,
  Wrench,
  ClipboardList,
  History,
  StickyNote,
  Waves,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface Contact {
  id: string;
  name: string;
  role: string;
  phone: string;
  email: string;
  isPrimary: boolean;
}

interface PropertyAccess {
  type: 'gate' | 'wifi' | 'alarm' | 'garage' | 'lockbox';
  label: string;
  value: string;
  password?: string;
  notes?: string;
  updatedAt: string;
}

interface FamilyMember {
  id: string;
  name: string;
  role: 'adult' | 'child' | 'pet' | 'staff';
  type?: string;
  status: string;
  statusTime?: string;
  age?: number;
  notes?: string;
}

interface CalendarEvent {
  id: string;
  date: string;
  title: string;
  time?: string;
  type: string;
  emoji?: string;
}

interface Task {
  id: string;
  title: string;
  dueDate: string;
  status: 'pending' | 'in_progress' | 'completed';
  source: 'homeowner' | 'system' | 'manager';
}

interface Message {
  id: string;
  content: string;
  sender: 'homeowner' | 'manager';
  senderName: string;
  timestamp: string;
  isRead: boolean;
}

interface ServiceRequest {
  id: string;
  title: string;
  description: string;
  status: 'submitted' | 'triaged' | 'assigned' | 'in_progress' | 'completed';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  createdAt: string;
  assignedTo?: string;
  category: string;
}

interface Bill {
  id: string;
  vendor: string;
  category: string;
  amount: number;
  dueDate: string;
  status: 'pending' | 'scheduled' | 'paid' | 'overdue';
  isRecurring: boolean;
  frequency?: string;
}

interface HomeSystem {
  id: string;
  name: string;
  type: string;
  lastService: string;
  nextDue: string;
  vendor?: string;
  status: 'good' | 'due_soon' | 'overdue';
}

interface ManagerNote {
  id: string;
  content: string;
  createdAt: string;
  createdBy: string;
}

interface HistoryEvent {
  id: string;
  type: 'request' | 'bill' | 'message' | 'task' | 'system';
  title: string;
  description: string;
  timestamp: string;
  actor: string;
}

interface Household {
  id: string;
  name: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  memberSince: string;
  plan: string;
  planPrice: number;
  balance: number;
  autoPayEnabled: boolean;
  healthScore: number;
  contacts: Contact[];
  access: PropertyAccess[];
  familyMembers: FamilyMember[];
  upcomingEvents: CalendarEvent[];
  tasks: Task[];
  messages: Message[];
  requests: ServiceRequest[];
  bills: Bill[];
  systems: HomeSystem[];
  notes: ManagerNote[];
  history: HistoryEvent[];
  property: {
    built: number;
    sqft: number;
    beds: number;
    baths: number;
    lotSize: string;
    hasPool: boolean;
    poolHeated: boolean;
  };
  monthlyStats: {
    requestsTotal: number;
    requestsCompleted: number;
    workOrdersTotal: number;
    workOrdersInProgress: number;
    billsPaid: number;
    messagesExchanged: number;
  };
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockHousehold: Household = {
  id: 'hh-001',
  name: 'Smith Family Residence',
  address: '456 Oak Lane',
  city: 'Austin',
  state: 'TX',
  zip: '78701',
  memberSince: 'Mar 2023',
  plan: 'Concierge',
  planPrice: 149,
  balance: 847,
  autoPayEnabled: true,
  healthScore: 94,
  contacts: [
    { id: 'c1', name: 'Bob Smith', role: 'Homeowner', phone: '(512) 555-0123', email: 'bob@example.com', isPrimary: true },
    { id: 'c2', name: 'Alice Smith', role: 'Homeowner', phone: '(512) 555-0124', email: 'alice@example.com', isPrimary: false },
  ],
  access: [
    { type: 'gate', label: 'Gate Code', value: '1247', updatedAt: 'Dec 1' },
    { type: 'wifi', label: 'WiFi', value: 'SmithFamily24', password: 'p@ssw0rd', updatedAt: 'Nov 15' },
    { type: 'alarm', label: 'Alarm', value: '4521# (arm) / 4521* (disarm)', updatedAt: 'Oct 20' },
    { type: 'garage', label: 'Garage Keypad', value: '8472', updatedAt: 'Sep 1' },
    { type: 'lockbox', label: 'Lockbox (side door)', value: '1234', updatedAt: 'Aug 15' },
  ],
  familyMembers: [
    { id: 'f1', name: 'Bob', role: 'adult', status: 'At Work', type: 'Homeowner' },
    { id: 'f2', name: 'Alice', role: 'adult', status: 'Home', type: 'Homeowner' },
    { id: 'f3', name: 'Emma', role: 'child', status: 'School', statusTime: '3:30 PM', age: 12 },
    { id: 'f4', name: 'Jake', role: 'child', status: 'School', statusTime: '3:00 PM', age: 9 },
    { id: 'f5', name: 'Max', role: 'pet', status: 'Home', type: 'Golden Retriever', notes: 'Friendly' },
    { id: 'f6', name: 'Maria', role: 'staff', status: 'On Duty', type: 'Housekeeper', notes: 'Mon/Wed/Fri' },
  ],
  upcomingEvents: [
    { id: 'e1', date: 'Dec 24', title: 'Emma Soccer', time: '4pm', type: 'sports' },
    { id: 'e2', date: 'Dec 25', title: 'Christmas', type: 'holiday', emoji: '🎄' },
    { id: 'e3', date: 'Dec 26', title: 'Tuition due', type: 'bill' },
    { id: 'e4', date: 'Dec 28', title: 'Jake Dentist', time: '10am', type: 'health' },
    { id: 'e5', date: 'Jan 2', title: 'HVAC Inspection', time: '9am', type: 'maintenance' },
  ],
  tasks: [
    { id: 't1', title: 'Research summer camps', dueDate: 'Dec 28', status: 'pending', source: 'homeowner' },
    { id: 't2', title: 'Schedule HVAC service', dueDate: 'Dec 26', status: 'pending', source: 'system' },
    { id: 't3', title: 'Get driveway quotes', dueDate: 'Dec 30', status: 'in_progress', source: 'homeowner' },
    { id: 't4', title: 'Review insurance renewal', dueDate: 'Jan 5', status: 'pending', source: 'manager' },
    { id: 't5', title: 'Update emergency contacts', dueDate: 'Jan 10', status: 'pending', source: 'system' },
  ],
  messages: [
    { id: 'm1', content: 'Hi Sarah, could you look into summer camps for the kids? Emma wants something with swimming.', sender: 'homeowner', senderName: 'Alice', timestamp: '2 hours ago', isRead: true },
    { id: 'm2', content: 'Of course! I\'ll research options and send you a comparison by Friday. Any budget range in mind?', sender: 'manager', senderName: 'Sarah', timestamp: '1 hour ago', isRead: true },
    { id: 'm3', content: 'Probably around $500-800/week per kid. Thanks!', sender: 'homeowner', senderName: 'Alice', timestamp: '45 mins ago', isRead: true },
    { id: 'm4', content: 'Perfect, I\'ll include that in my search. Also, the HVAC tech confirmed for Jan 2nd.', sender: 'manager', senderName: 'Sarah', timestamp: '30 mins ago', isRead: false },
  ],
  requests: [
    { id: 'r1', title: 'Kitchen faucet dripping', description: 'The kitchen faucet has been dripping for a few days. Getting worse.', status: 'assigned', priority: 'medium', createdAt: '2 days ago', assignedTo: 'Mike\'s Plumbing', category: 'Plumbing' },
    { id: 'r2', title: 'Research summer camps', description: 'Need options for Emma (12) and Jake (9) for summer break.', status: 'in_progress', priority: 'low', createdAt: '3 days ago', category: 'Concierge' },
    { id: 'r3', title: 'Get driveway sealing quotes', description: 'Driveway needs resealing. Get 3 quotes.', status: 'in_progress', priority: 'low', createdAt: '1 week ago', category: 'Home Improvement' },
    { id: 'r4', title: 'Garage door squeaking', description: 'Garage door makes loud squeaking noise when opening.', status: 'completed', priority: 'medium', createdAt: '2 weeks ago', category: 'Maintenance' },
  ],
  bills: [
    { id: 'b1', vendor: 'Austin Energy', category: 'Electric', amount: 287.45, dueDate: 'Dec 28', status: 'scheduled', isRecurring: true, frequency: 'Monthly' },
    { id: 'b2', vendor: 'Texas Gas', category: 'Gas', amount: 78.20, dueDate: 'Dec 30', status: 'pending', isRecurring: true, frequency: 'Monthly' },
    { id: 'b3', vendor: 'AT&T', category: 'Internet', amount: 89.99, dueDate: 'Jan 5', status: 'scheduled', isRecurring: true, frequency: 'Monthly' },
    { id: 'b4', vendor: 'Greenscape Lawn', category: 'Lawn', amount: 150.00, dueDate: 'Jan 1', status: 'pending', isRecurring: true, frequency: 'Weekly' },
    { id: 'b5', vendor: 'State Farm', category: 'Insurance', amount: 412.00, dueDate: 'Jan 15', status: 'pending', isRecurring: true, frequency: 'Monthly' },
    { id: 'b6', vendor: 'Pool Pros', category: 'Pool', amount: 175.00, dueDate: 'Dec 22', status: 'paid', isRecurring: true, frequency: 'Weekly' },
  ],
  systems: [
    { id: 's1', name: 'HVAC System', type: 'Trane XR15', lastService: 'Jun 2024', nextDue: 'Jan 2025', vendor: 'Cool Air Co', status: 'due_soon' },
    { id: 's2', name: 'Water Heater', type: 'Rheem 50gal', lastService: 'Mar 2024', nextDue: 'Mar 2025', vendor: 'Mike\'s Plumbing', status: 'good' },
    { id: 's3', name: 'Roof', type: 'Composition Shingle', lastService: 'Installed 2018', nextDue: 'Inspection 2028', status: 'good' },
    { id: 's4', name: 'Pool Equipment', type: 'Pentair', lastService: 'Nov 2024', nextDue: 'May 2025', vendor: 'Pool Pros', status: 'good' },
    { id: 's5', name: 'Electrical Panel', type: '200A Main', lastService: 'Dec 2023', nextDue: 'Dec 2025', status: 'good' },
    { id: 's6', name: 'Irrigation System', type: 'Rachio Smart', lastService: 'Oct 2024', nextDue: 'Apr 2025', vendor: 'Greenscape', status: 'good' },
  ],
  notes: [
    { id: 'n1', content: 'Alice prefers text over calls. Bob is fine with either.', createdAt: 'Nov 15, 2024', createdBy: 'Sarah' },
    { id: 'n2', content: 'Max (dog) is friendly but barks at strangers initially. Give him a minute.', createdAt: 'Oct 20, 2024', createdBy: 'Sarah' },
    { id: 'n3', content: 'Maria (housekeeper) has keys. Coordinate with her for service visits.', createdAt: 'Sep 5, 2024', createdBy: 'Sarah' },
    { id: 'n4', content: 'They prefer eco-friendly products when possible.', createdAt: 'Aug 1, 2024', createdBy: 'Sarah' },
  ],
  history: [
    { id: 'h1', type: 'message', title: 'Message sent', description: 'HVAC confirmation sent to Alice', timestamp: '30 mins ago', actor: 'Sarah' },
    { id: 'h2', type: 'task', title: 'Task updated', description: 'Driveway quotes: received 2 of 3', timestamp: '2 hours ago', actor: 'Sarah' },
    { id: 'h3', type: 'bill', title: 'Bill paid', description: 'Pool Pros - $175.00', timestamp: 'Yesterday', actor: 'System' },
    { id: 'h4', type: 'request', title: 'Request assigned', description: 'Kitchen faucet → Mike\'s Plumbing', timestamp: '2 days ago', actor: 'Sarah' },
    { id: 'h5', type: 'system', title: 'Auto-pay processed', description: 'Monthly subscription $149.00', timestamp: '5 days ago', actor: 'System' },
  ],
  property: {
    built: 2018,
    sqft: 3200,
    beds: 4,
    baths: 3.5,
    lotSize: '0.25 acres',
    hasPool: true,
    poolHeated: true,
  },
  monthlyStats: {
    requestsTotal: 3,
    requestsCompleted: 2,
    workOrdersTotal: 2,
    workOrdersInProgress: 1,
    billsPaid: 4247.23,
    messagesExchanged: 12,
  },
};

// ============================================================================
// COMPONENT HELPERS
// ============================================================================

const accessIcons = {
  gate: Key,
  wifi: Wifi,
  alarm: Shield,
  garage: Home,
  lockbox: Key,
};

const roleIcons = {
  adult: User,
  child: GraduationCap,
  pet: PawPrint,
  staff: Briefcase,
};

const statusColors = {
  good: 'text-emerald-600 bg-emerald-50',
  due_soon: 'text-amber-600 bg-amber-50',
  overdue: 'text-red-600 bg-red-50',
};

const priorityColors = {
  low: 'bg-slate-100 text-slate-600',
  medium: 'bg-blue-100 text-blue-600',
  high: 'bg-amber-100 text-amber-700',
  urgent: 'bg-red-100 text-red-700',
};

const requestStatusColors = {
  submitted: 'bg-slate-100 text-slate-600',
  triaged: 'bg-blue-100 text-blue-600',
  assigned: 'bg-indigo-100 text-indigo-600',
  in_progress: 'bg-amber-100 text-amber-700',
  completed: 'bg-emerald-100 text-emerald-600',
};

const billStatusColors = {
  pending: 'text-slate-600',
  scheduled: 'text-blue-600',
  paid: 'text-emerald-600',
  overdue: 'text-red-600',
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

type TabType = 'overview' | 'family' | 'property' | 'requests' | 'bills' | 'tasks' | 'messages' | 'history';

export default function HouseholdDetailPage() {
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [completedTasks, setCompletedTasks] = useState<string[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [requestFilter, setRequestFilter] = useState<'all' | 'active' | 'completed'>('all');
  const [historyFilter, setHistoryFilter] = useState<string>('all');
  const [historySearch, setHistorySearch] = useState('');

  const household = mockHousehold;

  const handleTaskToggle = (taskId: string) => {
    setCompletedTasks(prev =>
      prev.includes(taskId) ? prev.filter(id => id !== taskId) : [...prev, taskId]
    );
  };

  const tabs: { id: TabType; label: string; icon: React.ElementType }[] = [
    { id: 'overview', label: 'Overview', icon: Home },
    { id: 'family', label: 'Family', icon: Users },
    { id: 'property', label: 'Property', icon: Building },
    { id: 'requests', label: 'Requests', icon: ClipboardList },
    { id: 'bills', label: 'Bills', icon: Receipt },
    { id: 'tasks', label: 'Tasks', icon: CheckSquare },
    { id: 'messages', label: 'Messages', icon: MessageCircle },
    { id: 'history', label: 'History', icon: History },
  ];

  // Needs attention items
  const needsAttention = [
    ...household.requests.filter(r => r.priority === 'urgent' || r.priority === 'high'),
    ...household.bills.filter(b => b.status === 'overdue'),
    ...household.systems.filter(s => s.status === 'overdue'),
  ];

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Back Navigation */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3">
          <Link
            href="/manager/households"
            className="inline-flex items-center gap-2 text-sm text-slate-600 hover:text-indigo-600 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Households
          </Link>
        </div>
      </div>

      {/* Header Card */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          {/* Top Row: Name and Since */}
          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4 mb-6">
            <div>
              <div className="flex items-center gap-3 mb-1">
                <Home className="w-6 h-6 text-indigo-600" />
                <h1 className="text-2xl font-bold text-slate-900">{household.name}</h1>
                <span className="text-sm text-slate-500">Since {household.memberSince}</span>
              </div>
              <p className="text-slate-600 flex items-center gap-1">
                <MapPin className="w-4 h-4" />
                {household.address}, {household.city}, {household.state} {household.zip}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                household.healthScore >= 90 ? 'bg-emerald-100 text-emerald-700' :
                household.healthScore >= 70 ? 'bg-amber-100 text-amber-700' :
                'bg-red-100 text-red-700'
              }`}>
                Health: {household.healthScore}%
              </span>
            </div>
          </div>

          <div className="border-t border-slate-100 pt-6">
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Primary Contacts */}
              <div>
                <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-3">Primary Contacts</h3>
                <div className="space-y-2">
                  {household.contacts.map(contact => (
                    <div key={contact.id} className="flex items-center gap-3">
                      <User className="w-4 h-4 text-slate-400" />
                      <span className="text-sm font-medium text-slate-900">{contact.name}</span>
                      <a href={`tel:${contact.phone}`} className="text-sm text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                        <Phone className="w-3 h-3" />
                        {contact.phone}
                      </a>
                    </div>
                  ))}
                  <div className="flex items-center gap-3 text-sm text-slate-500">
                    <Mail className="w-4 h-4 text-slate-400" />
                    haven+smith@...
                  </div>
                </div>
              </div>

              {/* Property Access */}
              <div>
                <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-3">Property Access</h3>
                <div className="flex flex-wrap gap-2">
                  {household.access.slice(0, 4).map(access => {
                    const Icon = accessIcons[access.type];
                    return (
                      <span key={access.type} className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-slate-100 rounded-lg text-sm">
                        <Icon className="w-3.5 h-3.5 text-slate-500" />
                        <span className="font-medium text-slate-700">{access.label}:</span>
                        <span className="text-slate-600">{access.value.split(' ')[0]}</span>
                      </span>
                    );
                  })}
                  {household.familyMembers.filter(m => m.role === 'pet').map(pet => (
                    <span key={pet.id} className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-amber-50 rounded-lg text-sm">
                      <Dog className="w-3.5 h-3.5 text-amber-600" />
                      <span className="text-amber-700">{pet.name} ({pet.notes})</span>
                    </span>
                  ))}
                </div>
              </div>

              {/* Account + Quick Actions */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-3">Account</h3>
                  <div className="space-y-1 text-sm">
                    <p><span className="text-slate-500">Plan:</span> <span className="font-medium text-slate-900">{household.plan} (${household.planPrice}/mo)</span></p>
                    <p><span className="text-slate-500">Balance:</span> <span className="font-medium text-emerald-600">${household.balance} credit</span></p>
                    <p><span className="text-slate-500">Auto-pay:</span> <span className="font-medium text-slate-900">{household.autoPayEnabled ? '✓ Enabled' : '✗ Disabled'}</span></p>
                  </div>
                </div>
                <div>
                  <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-3">Quick Actions</h3>
                  <div className="flex flex-wrap gap-2">
                    <button className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors">
                      <MessageCircle className="w-4 h-4" />
                      Message
                    </button>
                    <button className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                      <Phone className="w-4 h-4" />
                      Call
                    </button>
                    <button className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                      <Plus className="w-4 h-4" />
                      Request
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Tab Navigation */}
          <div className="flex items-center gap-1 border-t border-slate-200 mt-6 pt-4 overflow-x-auto">
            {tabs.map(tab => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium whitespace-nowrap transition-colors ${
                    activeTab === tab.id
                      ? 'text-indigo-600 border-b-2 border-indigo-600'
                      : 'text-slate-500 hover:text-slate-700'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Tab Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-8">
        {/* OVERVIEW TAB */}
        {activeTab === 'overview' && (
          <div className="space-y-6">
            {/* Needs Attention */}
            {needsAttention.length > 0 && (
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
                <h2 className="text-sm font-medium text-amber-800 uppercase tracking-wide mb-3 flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4" />
                  Needs Attention
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {household.requests.filter(r => r.priority === 'urgent' || r.priority === 'high').map(request => (
                    <div key={request.id} className="bg-white rounded-lg p-4 shadow-sm">
                      <div className="flex items-start justify-between">
                        <div>
                          <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${priorityColors[request.priority]} mb-1`}>
                            {request.priority.toUpperCase()}
                          </span>
                          <h4 className="font-medium text-slate-900">{request.title}</h4>
                          <p className="text-sm text-slate-500">{request.category} • {request.createdAt}</p>
                        </div>
                        <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium">
                          View
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* 2x2 Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Family at a Glance */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide">Family at a Glance</h3>
                  <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                    View All <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
                <div className="space-y-2">
                  {household.familyMembers.map(member => {
                    const Icon = roleIcons[member.role];
                    return (
                      <div key={member.id} className="flex items-center justify-between py-2 border-b border-slate-50 last:border-0">
                        <div className="flex items-center gap-3">
                          <Icon className="w-4 h-4 text-slate-400" />
                          <span className="font-medium text-slate-900">{member.name}</span>
                          {member.type && <span className="text-xs text-slate-500">({member.type})</span>}
                        </div>
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                          <span>{member.status}</span>
                          {member.statusTime && <span className="text-slate-400">→ {member.statusTime}</span>}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* This Month's Activity */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide">This Month&apos;s Activity</h3>
                  <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                    View Full History <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="text-2xl font-bold text-slate-900">{household.monthlyStats.requestsTotal}</p>
                    <p className="text-sm text-slate-500">Requests ({household.monthlyStats.requestsCompleted} completed)</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="text-2xl font-bold text-slate-900">{household.monthlyStats.workOrdersTotal}</p>
                    <p className="text-sm text-slate-500">Work Orders ({household.monthlyStats.workOrdersInProgress} in progress)</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="text-2xl font-bold text-emerald-600">${household.monthlyStats.billsPaid.toLocaleString()}</p>
                    <p className="text-sm text-slate-500">Bills Paid</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg">
                    <p className="text-2xl font-bold text-slate-900">{household.monthlyStats.messagesExchanged}</p>
                    <p className="text-sm text-slate-500">Messages Exchanged</p>
                  </div>
                </div>
              </div>

              {/* Upcoming */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide">Upcoming</h3>
                  <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                    View Calendar <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
                <div className="space-y-2">
                  {household.upcomingEvents.slice(0, 4).map(event => (
                    <div key={event.id} className="flex items-center gap-3 py-2 border-b border-slate-50 last:border-0">
                      <div className="w-12 text-center">
                        <p className="text-xs text-slate-500">{event.date.split(' ')[0]}</p>
                        <p className="text-lg font-bold text-slate-900">{event.date.split(' ')[1]}</p>
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-slate-900">
                          {event.emoji && <span className="mr-1">{event.emoji}</span>}
                          {event.title}
                        </p>
                        {event.time && <p className="text-sm text-slate-500">{event.time}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* My Tasks for This Household */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide">My Tasks for This Household</h3>
                  <div className="flex items-center gap-2">
                    <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                      <Plus className="w-4 h-4" /> Add
                    </button>
                    <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                      View All <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
                <div className="space-y-2">
                  {household.tasks.filter(t => t.status !== 'completed').slice(0, 4).map(task => (
                    <div key={task.id} className="flex items-center gap-3 py-2 border-b border-slate-50 last:border-0">
                      <button
                        onClick={() => handleTaskToggle(task.id)}
                        className="text-slate-400 hover:text-indigo-600"
                      >
                        {completedTasks.includes(task.id) ? (
                          <CheckSquare className="w-5 h-5 text-emerald-600" />
                        ) : (
                          <Square className="w-5 h-5" />
                        )}
                      </button>
                      <div className="flex-1">
                        <p className={`font-medium ${completedTasks.includes(task.id) ? 'text-slate-400 line-through' : 'text-slate-900'}`}>
                          {task.title}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-slate-500">Due: {task.dueDate.split(' ')[1]}</span>
                        {task.source === 'homeowner' && (
                          <span className="w-2 h-2 rounded-full bg-indigo-500" title="Homeowner request" />
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Recent Messages + Compose */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide">Recent Messages</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  View All <ChevronRight className="w-4 h-4" />
                </button>
              </div>
              <div className="space-y-3 mb-4">
                {household.messages.slice(-4).map(message => (
                  <div
                    key={message.id}
                    className={`flex ${message.sender === 'manager' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`max-w-[70%] rounded-lg p-3 ${
                      message.sender === 'manager' ? 'bg-indigo-100 text-indigo-900' : 'bg-slate-100 text-slate-900'
                    }`}>
                      <p className="text-sm">{message.content}</p>
                      <p className="text-xs text-slate-500 mt-1">{message.senderName} • {message.timestamp}</p>
                    </div>
                  </div>
                ))}
              </div>
              <div className="flex items-center gap-2 border-t border-slate-100 pt-4">
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="Type a message..."
                  className="flex-1 px-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
                <button className="p-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors">
                  <Send className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Manager Notes Sidebar */}
            <div className="bg-amber-50 rounded-xl border border-amber-200 p-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-xs font-medium text-amber-800 uppercase tracking-wide flex items-center gap-2">
                  <StickyNote className="w-4 h-4" />
                  Manager Notes
                </h3>
                <button className="text-amber-700 hover:text-amber-800 text-sm font-medium flex items-center gap-1">
                  <Plus className="w-4 h-4" /> Add
                </button>
              </div>
              <ul className="space-y-2">
                {household.notes.map(note => (
                  <li key={note.id} className="text-sm text-amber-900 flex items-start gap-2">
                    <span className="text-amber-600 mt-1">•</span>
                    <span>{note.content}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}

        {/* FAMILY TAB */}
        {activeTab === 'family' && (
          <div className="space-y-6">
            {/* Adults */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Adults</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  <Edit className="w-4 h-4" /> Edit
                </button>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {household.familyMembers.filter(m => m.role === 'adult').map(member => (
                  <div key={member.id} className="flex items-start gap-4 p-4 bg-slate-50 rounded-lg">
                    <div className="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center">
                      <User className="w-6 h-6 text-indigo-600" />
                    </div>
                    <div>
                      <h4 className="font-medium text-slate-900">{member.name}</h4>
                      <p className="text-sm text-slate-500">{member.type}</p>
                      <p className="text-sm text-slate-600 mt-1">Status: {member.status}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Children */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Children</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  <Edit className="w-4 h-4" /> Edit
                </button>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {household.familyMembers.filter(m => m.role === 'child').map(member => (
                  <div key={member.id} className="flex items-start gap-4 p-4 bg-slate-50 rounded-lg">
                    <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                      <GraduationCap className="w-6 h-6 text-blue-600" />
                    </div>
                    <div>
                      <h4 className="font-medium text-slate-900">{member.name}</h4>
                      <p className="text-sm text-slate-500">Age {member.age}</p>
                      <p className="text-sm text-slate-600 mt-1">Status: {member.status}</p>
                      {member.statusTime && <p className="text-sm text-slate-500">Pickup: {member.statusTime}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Pets */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Pets</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  <Edit className="w-4 h-4" /> Edit
                </button>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {household.familyMembers.filter(m => m.role === 'pet').map(member => (
                  <div key={member.id} className="flex items-start gap-4 p-4 bg-slate-50 rounded-lg">
                    <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center">
                      <PawPrint className="w-6 h-6 text-amber-600" />
                    </div>
                    <div>
                      <h4 className="font-medium text-slate-900">{member.name}</h4>
                      <p className="text-sm text-slate-500">{member.type}</p>
                      {member.notes && <p className="text-sm text-slate-600 mt-1">Notes: {member.notes}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Staff */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Household Staff</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  <Edit className="w-4 h-4" /> Edit
                </button>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {household.familyMembers.filter(m => m.role === 'staff').map(member => (
                  <div key={member.id} className="flex items-start gap-4 p-4 bg-slate-50 rounded-lg">
                    <div className="w-12 h-12 bg-emerald-100 rounded-full flex items-center justify-center">
                      <Briefcase className="w-6 h-6 text-emerald-600" />
                    </div>
                    <div>
                      <h4 className="font-medium text-slate-900">{member.name}</h4>
                      <p className="text-sm text-slate-500">{member.type}</p>
                      {member.notes && <p className="text-sm text-slate-600 mt-1">Schedule: {member.notes}</p>}
                      <p className="text-sm text-slate-600">Status: {member.status}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* PROPERTY TAB */}
        {activeTab === 'property' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Property Info */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-4">Property Info</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-slate-500">Built</p>
                    <p className="font-medium text-slate-900">{household.property.built}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500">Square Feet</p>
                    <p className="font-medium text-slate-900">{household.property.sqft.toLocaleString()}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500">Bedrooms</p>
                    <p className="font-medium text-slate-900">{household.property.beds}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500">Bathrooms</p>
                    <p className="font-medium text-slate-900">{household.property.baths}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500">Lot Size</p>
                    <p className="font-medium text-slate-900">{household.property.lotSize}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500">Pool</p>
                    <p className="font-medium text-slate-900">
                      {household.property.hasPool ? `Yes${household.property.poolHeated ? ' (heated)' : ''}` : 'No'}
                    </p>
                  </div>
                </div>
              </div>

              {/* Access Codes */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-slate-900">Access Codes</h3>
                  <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                    <Edit className="w-4 h-4" /> Edit Codes
                  </button>
                </div>
                <div className="space-y-3">
                  {household.access.map(access => {
                    const Icon = accessIcons[access.type];
                    return (
                      <div key={access.type} className="flex items-center justify-between py-2 border-b border-slate-50 last:border-0">
                        <div className="flex items-center gap-3">
                          <Icon className="w-5 h-5 text-slate-400" />
                          <div>
                            <p className="font-medium text-slate-900">{access.label}</p>
                            <p className="text-sm text-slate-600">{access.value}</p>
                            {access.password && <p className="text-xs text-slate-400">Password: {access.password}</p>}
                          </div>
                        </div>
                        <span className="text-xs text-slate-400">Updated {access.updatedAt}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Home Systems */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Home Systems</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  View All <ChevronRight className="w-4 h-4" />
                </button>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {household.systems.map(system => {
                  const systemIcons: Record<string, React.ElementType> = {
                    'HVAC System': Thermometer,
                    'Water Heater': Droplets,
                    'Roof': Home,
                    'Pool Equipment': Waves,
                    'Electrical Panel': Zap,
                    'Irrigation System': Wind,
                  };
                  const Icon = systemIcons[system.name] || Wrench;
                  return (
                    <div key={system.id} className="p-4 border border-slate-200 rounded-lg">
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <Icon className="w-5 h-5 text-slate-400" />
                          <h4 className="font-medium text-slate-900">{system.name}</h4>
                        </div>
                        <span className={`px-2 py-0.5 rounded text-xs font-medium ${statusColors[system.status]}`}>
                          {system.status === 'good' ? 'Good' : system.status === 'due_soon' ? 'Due Soon' : 'Overdue'}
                        </span>
                      </div>
                      <p className="text-sm text-slate-500">{system.type}</p>
                      <div className="mt-2 text-sm">
                        <p className="text-slate-600">Last: {system.lastService}</p>
                        <p className="text-slate-600">Next: {system.nextDue}</p>
                        {system.vendor && <p className="text-slate-500">Vendor: {system.vendor}</p>}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Documents */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Documents</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  <Upload className="w-4 h-4" /> Upload Document
                </button>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {['Deed (recorded 2023)', 'Insurance Policy', 'HOA Docs', 'Manuals'].map((doc, i) => (
                  <div key={i} className="p-4 border border-slate-200 rounded-lg hover:border-indigo-300 hover:bg-indigo-50 transition-colors cursor-pointer">
                    <FileText className="w-8 h-8 text-slate-400 mb-2" />
                    <p className="text-sm font-medium text-slate-900">{doc}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* REQUESTS TAB */}
        {activeTab === 'requests' && (
          <div className="space-y-6">
            {/* Filter Bar */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {(['all', 'active', 'completed'] as const).map(filter => (
                    <button
                      key={filter}
                      onClick={() => setRequestFilter(filter)}
                      className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                        requestFilter === filter
                          ? 'bg-indigo-600 text-white'
                          : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                      }`}
                    >
                      {filter.charAt(0).toUpperCase() + filter.slice(1)}
                    </button>
                  ))}
                </div>
                <button className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors">
                  <Plus className="w-4 h-4" />
                  New Request
                </button>
              </div>
            </div>

            {/* Request Cards */}
            <div className="space-y-4">
              {household.requests
                .filter(r => {
                  if (requestFilter === 'active') return r.status !== 'completed';
                  if (requestFilter === 'completed') return r.status === 'completed';
                  return true;
                })
                .map(request => (
                  <div key={request.id} className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <span className={`px-2 py-0.5 rounded text-xs font-medium ${priorityColors[request.priority]}`}>
                            {request.priority.toUpperCase()}
                          </span>
                          <span className={`px-2 py-0.5 rounded text-xs font-medium ${requestStatusColors[request.status]}`}>
                            {request.status.replace('_', ' ').toUpperCase()}
                          </span>
                          <span className="text-xs text-slate-500">{request.category}</span>
                        </div>
                        <h4 className="text-lg font-medium text-slate-900">{request.title}</h4>
                        <p className="text-sm text-slate-600 mt-1">{request.description}</p>
                        <div className="flex items-center gap-4 mt-2 text-sm text-slate-500">
                          <span>Created {request.createdAt}</span>
                          {request.assignedTo && <span>Assigned to {request.assignedTo}</span>}
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button className="p-2 text-slate-400 hover:text-slate-600">
                          <MoreVertical className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                    {request.status !== 'completed' && (
                      <div className="flex items-center gap-2 mt-4 pt-4 border-t border-slate-100">
                        <button className="px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                          Triage
                        </button>
                        <button className="px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                          Assign
                        </button>
                        <button className="px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                          Convert to WO
                        </button>
                        <button className="px-3 py-1.5 text-sm font-medium text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors">
                          Mark Complete
                        </button>
                      </div>
                    )}
                  </div>
                ))}
            </div>
          </div>
        )}

        {/* BILLS TAB */}
        {activeTab === 'bills' && (
          <div className="space-y-6">
            {/* Due This Week */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h3 className="text-lg font-semibold text-slate-900 mb-4">Due This Week</h3>
              <div className="space-y-3">
                {household.bills.filter(b => b.status !== 'paid').slice(0, 3).map(bill => (
                  <div key={bill.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center border border-slate-200">
                        <DollarSign className="w-5 h-5 text-slate-400" />
                      </div>
                      <div>
                        <p className="font-medium text-slate-900">{bill.vendor}</p>
                        <p className="text-sm text-slate-500">{bill.category} • Due {bill.dueDate}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="text-right">
                        <p className="font-semibold text-slate-900">${bill.amount.toFixed(2)}</p>
                        <p className={`text-sm ${billStatusColors[bill.status]}`}>
                          {bill.status === 'scheduled' ? 'Scheduled' : 'Pending'}
                        </p>
                      </div>
                      <button className="px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700">
                        Pay Now
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Monthly Recurring */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h3 className="text-lg font-semibold text-slate-900 mb-4">Monthly Recurring</h3>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-slate-200">
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wide pb-3">Vendor</th>
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wide pb-3">Category</th>
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wide pb-3">Amount</th>
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wide pb-3">Frequency</th>
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wide pb-3">Next Due</th>
                      <th className="text-left text-xs font-medium text-slate-500 uppercase tracking-wide pb-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {household.bills.filter(b => b.isRecurring).map(bill => (
                      <tr key={bill.id}>
                        <td className="py-3 font-medium text-slate-900">{bill.vendor}</td>
                        <td className="py-3 text-slate-600">{bill.category}</td>
                        <td className="py-3 text-slate-900">${bill.amount.toFixed(2)}</td>
                        <td className="py-3 text-slate-600">{bill.frequency}</td>
                        <td className="py-3 text-slate-600">{bill.dueDate}</td>
                        <td className="py-3">
                          <span className={`inline-flex items-center gap-1 ${billStatusColors[bill.status]}`}>
                            {bill.status === 'paid' && <CheckCircle2 className="w-4 h-4" />}
                            {bill.status === 'scheduled' && <Clock className="w-4 h-4" />}
                            {bill.status.charAt(0).toUpperCase() + bill.status.slice(1)}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Payment History */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-slate-900">Payment History</h3>
                <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center gap-1">
                  <Download className="w-4 h-4" /> Export
                </button>
              </div>
              <div className="space-y-3">
                {household.bills.filter(b => b.status === 'paid').map(bill => (
                  <div key={bill.id} className="flex items-center justify-between py-2 border-b border-slate-50 last:border-0">
                    <div className="flex items-center gap-3">
                      <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                      <div>
                        <p className="font-medium text-slate-900">{bill.vendor}</p>
                        <p className="text-sm text-slate-500">{bill.category}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-medium text-slate-900">${bill.amount.toFixed(2)}</p>
                      <p className="text-sm text-emerald-600">Paid {bill.dueDate}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* TASKS TAB */}
        {activeTab === 'tasks' && (
          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-semibold text-slate-900">All Tasks</h3>
                <button className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors">
                  <Plus className="w-4 h-4" />
                  Add Task
                </button>
              </div>
              <div className="space-y-2">
                {household.tasks.map(task => {
                  const isCompleted = completedTasks.includes(task.id) || task.status === 'completed';
                  return (
                    <div key={task.id} className="flex items-center gap-4 p-3 bg-slate-50 rounded-lg">
                      <button
                        onClick={() => handleTaskToggle(task.id)}
                        className="text-slate-400 hover:text-indigo-600"
                      >
                        {isCompleted ? (
                          <CheckSquare className="w-5 h-5 text-emerald-600" />
                        ) : (
                          <Square className="w-5 h-5" />
                        )}
                      </button>
                      <div className="flex-1">
                        <p className={`font-medium ${isCompleted ? 'text-slate-400 line-through' : 'text-slate-900'}`}>
                          {task.title}
                        </p>
                        <div className="flex items-center gap-3 mt-1">
                          <span className="text-xs text-slate-500">Due: {task.dueDate}</span>
                          <span className={`text-xs px-2 py-0.5 rounded ${
                            task.source === 'homeowner' ? 'bg-indigo-100 text-indigo-600' :
                            task.source === 'system' ? 'bg-slate-100 text-slate-600' :
                            'bg-emerald-100 text-emerald-600'
                          }`}>
                            {task.source === 'homeowner' ? 'Homeowner' : task.source === 'system' ? 'System' : 'Manager'}
                          </span>
                          <span className={`text-xs px-2 py-0.5 rounded ${
                            task.status === 'pending' ? 'bg-slate-100 text-slate-600' :
                            task.status === 'in_progress' ? 'bg-blue-100 text-blue-600' :
                            'bg-emerald-100 text-emerald-600'
                          }`}>
                            {task.status.replace('_', ' ')}
                          </span>
                        </div>
                      </div>
                      <button className="p-2 text-slate-400 hover:text-slate-600">
                        <MoreVertical className="w-4 h-4" />
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* MESSAGES TAB */}
        {activeTab === 'messages' && (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="p-4 border-b border-slate-200">
              <h3 className="text-lg font-semibold text-slate-900">Conversation History</h3>
            </div>
            <div className="h-[500px] overflow-y-auto p-4 space-y-4">
              {household.messages.map(message => (
                <div
                  key={message.id}
                  className={`flex ${message.sender === 'manager' ? 'justify-end' : 'justify-start'}`}
                >
                  <div className={`max-w-[70%] rounded-lg p-4 ${
                    message.sender === 'manager' ? 'bg-indigo-100 text-indigo-900' : 'bg-slate-100 text-slate-900'
                  }`}>
                    <p className="text-sm">{message.content}</p>
                    <p className="text-xs text-slate-500 mt-2">{message.senderName} • {message.timestamp}</p>
                  </div>
                </div>
              ))}
            </div>
            <div className="p-4 border-t border-slate-200 bg-slate-50">
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="Type a message..."
                  className="flex-1 px-4 py-3 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
                <button className="p-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors">
                  <Send className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* HISTORY TAB */}
        {activeTab === 'history' && (
          <div className="space-y-6">
            {/* Filter Bar */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
              <div className="flex flex-col md:flex-row md:items-center gap-4">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-slate-400" />
                  <input
                    type="text"
                    value={historySearch}
                    onChange={(e) => setHistorySearch(e.target.value)}
                    placeholder="Search history..."
                    className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div className="flex items-center gap-2">
                  <Filter className="w-5 h-5 text-slate-400" />
                  <select
                    value={historyFilter}
                    onChange={(e) => setHistoryFilter(e.target.value)}
                    className="px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="all">All Types</option>
                    <option value="request">Requests</option>
                    <option value="bill">Bills</option>
                    <option value="message">Messages</option>
                    <option value="task">Tasks</option>
                    <option value="system">System</option>
                  </select>
                  <button className="px-4 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 flex items-center gap-2">
                    <Download className="w-4 h-4" />
                    Export
                  </button>
                </div>
              </div>
            </div>

            {/* History Timeline */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <div className="space-y-4">
                {household.history
                  .filter(h => historyFilter === 'all' || h.type === historyFilter)
                  .filter(h => historySearch === '' || h.title.toLowerCase().includes(historySearch.toLowerCase()) || h.description.toLowerCase().includes(historySearch.toLowerCase()))
                  .map(event => {
                    const typeColors: Record<string, string> = {
                      request: 'bg-blue-100 text-blue-600',
                      bill: 'bg-emerald-100 text-emerald-600',
                      message: 'bg-indigo-100 text-indigo-600',
                      task: 'bg-amber-100 text-amber-600',
                      system: 'bg-slate-100 text-slate-600',
                    };
                    const getIcon = (type: string) => {
                      switch (type) {
                        case 'request': return <ClipboardList className="w-5 h-5" />;
                        case 'bill': return <Receipt className="w-5 h-5" />;
                        case 'message': return <MessageCircle className="w-5 h-5" />;
                        case 'task': return <CheckSquare className="w-5 h-5" />;
                        case 'system': return <Zap className="w-5 h-5" />;
                        default: return <ClipboardList className="w-5 h-5" />;
                      }
                    };
                    return (
                      <div key={event.id} className="flex items-start gap-4">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center ${typeColors[event.type]}`}>
                          {getIcon(event.type)}
                        </div>
                        <div className="flex-1 py-1">
                          <p className="font-medium text-slate-900">{event.title}</p>
                          <p className="text-sm text-slate-600">{event.description}</p>
                          <p className="text-xs text-slate-400 mt-1">{event.timestamp} • {event.actor}</p>
                        </div>
                      </div>
                    );
                  })}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
