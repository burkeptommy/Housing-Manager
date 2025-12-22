'use client';

import { useState } from 'react';
import {
  ClipboardList,
  Plus,
  Calendar,
  CheckCircle2,
  AlertCircle,
  X,
  Phone,
  MapPin,
  DollarSign,
  User,
  Truck,
  ChevronRight,
  ChevronDown,
  Search,
  Home,
  ExternalLink,
  Camera,
  FileText,
  Send,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface WorkOrder {
  id: string;
  orderNumber: string;
  title: string;
  description: string;
  householdId: string;
  householdName: string;
  address: string;
  status: 'new' | 'assigned' | 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  category: string;
  vendor?: {
    id: string;
    name: string;
    contactName: string;
    phone: string;
  };
  scheduledDate?: string;
  scheduledTime?: string;
  estimatedCost?: number;
  actualCost?: number;
  linkedRequestId?: string;
  linkedRequestTitle?: string;
  technicianStatus?: string;
  createdAt: string;
  updatedAt: string;
  notes: WorkOrderNote[];
  photos: string[];
}

interface WorkOrderNote {
  id: string;
  content: string;
  author: string;
  createdAt: string;
  type: 'internal' | 'vendor' | 'homeowner';
}

type TabType = 'all' | 'scheduled_today' | 'in_progress' | 'waiting_approval' | 'completed';

// ============================================================================
// MOCK DATA
// ============================================================================

const mockWorkOrders: WorkOrder[] = [
  {
    id: 'wo1',
    orderNumber: 'WO-1892',
    title: 'HVAC Annual Service',
    description: 'Annual maintenance and inspection of HVAC system. Check refrigerant levels, clean coils, replace filter.',
    householdId: 'hh1',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    status: 'in_progress',
    priority: 'medium',
    category: 'HVAC',
    vendor: {
      id: 'v1',
      name: 'AirFlow HVAC',
      contactName: 'John',
      phone: '(512) 555-0101',
    },
    scheduledDate: 'Today',
    scheduledTime: '9:00 AM',
    estimatedCost: 150,
    technicianStatus: 'Technician en route (ETA 8:45am)',
    createdAt: '2024-12-18',
    updatedAt: '2024-12-21',
    linkedRequestId: 'r1',
    linkedRequestTitle: 'Annual HVAC maintenance due',
    notes: [
      { id: 'n1', content: 'Homeowner prefers morning appointments', author: 'Sarah', createdAt: '2024-12-18', type: 'internal' },
      { id: 'n2', content: 'Confirmed for Dec 21 at 9am', author: 'John (AirFlow)', createdAt: '2024-12-19', type: 'vendor' },
    ],
    photos: [],
  },
  {
    id: 'wo2',
    orderNumber: 'WO-1891',
    title: 'Kitchen Faucet Repair',
    description: 'Repair dripping kitchen faucet. Likely washer replacement.',
    householdId: 'hh1',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    status: 'scheduled',
    priority: 'medium',
    category: 'Plumbing',
    vendor: {
      id: 'v2',
      name: "Mike's Plumbing",
      contactName: 'Mike',
      phone: '(512) 555-0102',
    },
    scheduledDate: 'Tomorrow',
    scheduledTime: '10:00 AM',
    estimatedCost: 75,
    createdAt: '2024-12-19',
    updatedAt: '2024-12-20',
    linkedRequestId: 'r2',
    linkedRequestTitle: 'Kitchen faucet dripping',
    notes: [],
    photos: [],
  },
  {
    id: 'wo3',
    orderNumber: 'WO-1890',
    title: 'Roof Leak Repair',
    description: 'Investigate and repair leak near chimney flashing. Water stains visible in attic.',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    address: '789 Maple Drive',
    status: 'completed',
    priority: 'high',
    category: 'Roofing',
    vendor: {
      id: 'v3',
      name: 'Ace Roofing',
      contactName: 'Steve',
      phone: '(512) 555-0103',
    },
    scheduledDate: 'Dec 19',
    scheduledTime: '8:00 AM',
    estimatedCost: 350,
    actualCost: 425,
    createdAt: '2024-12-15',
    updatedAt: '2024-12-19',
    notes: [
      { id: 'n3', content: 'Additional flashing work needed - approved by homeowner', author: 'Sarah', createdAt: '2024-12-19', type: 'internal' },
    ],
    photos: ['before1.jpg', 'after1.jpg'],
  },
  {
    id: 'wo4',
    orderNumber: 'WO-1889',
    title: 'Pool Heater Inspection',
    description: 'Pool heater not warming properly. Inspect and diagnose issue.',
    householdId: 'hh1',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    status: 'assigned',
    priority: 'low',
    category: 'Pool',
    vendor: {
      id: 'v4',
      name: 'Pool Pros',
      contactName: 'Dave',
      phone: '(512) 555-0104',
    },
    estimatedCost: 100,
    createdAt: '2024-12-20',
    updatedAt: '2024-12-20',
    notes: [],
    photos: [],
  },
  {
    id: 'wo5',
    orderNumber: 'WO-1888',
    title: 'Garage Door Spring Replacement',
    description: 'Replace broken torsion spring on garage door.',
    householdId: 'hh3',
    householdName: 'Garcia Residence',
    address: '321 Cedar Street',
    status: 'new',
    priority: 'high',
    category: 'Garage Door',
    createdAt: '2024-12-21',
    updatedAt: '2024-12-21',
    notes: [],
    photos: [],
  },
  {
    id: 'wo6',
    orderNumber: 'WO-1887',
    title: 'AC Compressor Replacement Quote',
    description: 'Get quotes for AC compressor replacement. Unit is 15 years old.',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    address: '789 Maple Drive',
    status: 'scheduled',
    priority: 'medium',
    category: 'HVAC',
    vendor: {
      id: 'v1',
      name: 'AirFlow HVAC',
      contactName: 'John',
      phone: '(512) 555-0101',
    },
    scheduledDate: 'Today',
    scheduledTime: '2:00 PM',
    estimatedCost: 0,
    technicianStatus: 'Quote visit - no cost',
    createdAt: '2024-12-20',
    updatedAt: '2024-12-21',
    notes: [],
    photos: [],
  },
];

const households = [
  { id: 'hh1', name: 'Smith Family' },
  { id: 'hh2', name: 'Johnson Family' },
  { id: 'hh3', name: 'Garcia Residence' },
  { id: 'hh4', name: 'Williams Estate' },
];

const vendors = [
  { id: 'v1', name: 'AirFlow HVAC' },
  { id: 'v2', name: "Mike's Plumbing" },
  { id: 'v3', name: 'Ace Roofing' },
  { id: 'v4', name: 'Pool Pros' },
];

const categories = ['All', 'HVAC', 'Plumbing', 'Electrical', 'Roofing', 'Pool', 'Garage Door', 'Appliance'];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const statusConfig: Record<WorkOrder['status'], { label: string; bgColor: string; textColor: string }> = {
  new: { label: 'New', bgColor: 'bg-slate-100', textColor: 'text-slate-600' },
  assigned: { label: 'Assigned', bgColor: 'bg-blue-100', textColor: 'text-blue-600' },
  scheduled: { label: 'Scheduled', bgColor: 'bg-indigo-100', textColor: 'text-indigo-600' },
  in_progress: { label: 'In Progress', bgColor: 'bg-amber-100', textColor: 'text-amber-600' },
  completed: { label: 'Completed', bgColor: 'bg-emerald-100', textColor: 'text-emerald-600' },
  cancelled: { label: 'Cancelled', bgColor: 'bg-red-100', textColor: 'text-red-600' },
};

const priorityConfig: Record<WorkOrder['priority'], { label: string; color: string }> = {
  low: { label: 'Low', color: 'text-slate-500' },
  medium: { label: 'Medium', color: 'text-blue-600' },
  high: { label: 'High', color: 'text-amber-600' },
  urgent: { label: 'Urgent', color: 'text-red-600' },
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function WorkOrdersPage() {
  const [workOrders] = useState<WorkOrder[]>(mockWorkOrders);
  const [activeTab, setActiveTab] = useState<TabType>('all');
  const [showNewOrderModal, setShowNewOrderModal] = useState(false);
  const [expandedOrders, setExpandedOrders] = useState<string[]>([]);

  // Filters
  const [householdFilter, setHouseholdFilter] = useState('all');
  const [vendorFilter, setVendorFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  // Stats
  const stats = {
    scheduledToday: workOrders.filter(wo => wo.scheduledDate === 'Today').length,
    inProgress: workOrders.filter(wo => wo.status === 'in_progress').length,
    needsAssignment: workOrders.filter(wo => wo.status === 'new').length,
    completedThisWeek: workOrders.filter(wo => wo.status === 'completed').length,
  };

  // Filter work orders
  let filteredOrders = [...workOrders];

  // Tab filter
  if (activeTab === 'scheduled_today') {
    filteredOrders = filteredOrders.filter(wo => wo.scheduledDate === 'Today');
  } else if (activeTab === 'in_progress') {
    filteredOrders = filteredOrders.filter(wo => wo.status === 'in_progress');
  } else if (activeTab === 'waiting_approval') {
    filteredOrders = filteredOrders.filter(wo => wo.status === 'new' || wo.status === 'assigned');
  } else if (activeTab === 'completed') {
    filteredOrders = filteredOrders.filter(wo => wo.status === 'completed');
  }

  // Additional filters
  if (householdFilter !== 'all') {
    filteredOrders = filteredOrders.filter(wo => wo.householdId === householdFilter);
  }
  if (vendorFilter !== 'all') {
    filteredOrders = filteredOrders.filter(wo => wo.vendor?.id === vendorFilter);
  }
  if (categoryFilter !== 'All') {
    filteredOrders = filteredOrders.filter(wo => wo.category === categoryFilter);
  }
  if (searchQuery) {
    filteredOrders = filteredOrders.filter(wo =>
      wo.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      wo.orderNumber.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }

  const toggleExpanded = (id: string) => {
    setExpandedOrders(prev =>
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  const tabs: { id: TabType; label: string; count?: number }[] = [
    { id: 'all', label: 'All', count: workOrders.length },
    { id: 'scheduled_today', label: 'Scheduled Today', count: stats.scheduledToday },
    { id: 'in_progress', label: 'In Progress', count: stats.inProgress },
    { id: 'waiting_approval', label: 'Needs Assignment', count: stats.needsAssignment },
    { id: 'completed', label: 'Completed' },
  ];

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <ClipboardList className="w-8 h-8 text-indigo-600" />
              <h1 className="text-2xl font-bold text-slate-900">Work Orders</h1>
            </div>
            <button
              onClick={() => setShowNewOrderModal(true)}
              className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Work Order
            </button>
          </div>

          {/* Tabs */}
          <div className="flex items-center gap-1 border-b border-slate-200 -mb-px">
            {tabs.map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'text-indigo-600 border-indigo-600'
                    : 'text-slate-500 border-transparent hover:text-slate-700'
                }`}
              >
                {tab.label}
                {tab.count !== undefined && (
                  <span className={`ml-2 px-2 py-0.5 rounded-full text-xs ${
                    activeTab === tab.id ? 'bg-indigo-100 text-indigo-600' : 'bg-slate-100 text-slate-500'
                  }`}>
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search work orders..."
                className="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <select
              value={householdFilter}
              onChange={(e) => setHouseholdFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="all">All Households</option>
              {households.map(h => (
                <option key={h.id} value={h.id}>{h.name}</option>
              ))}
            </select>
            <select
              value={vendorFilter}
              onChange={(e) => setVendorFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="all">All Vendors</option>
              {vendors.map(v => (
                <option key={v.id} value={v.id}>{v.name}</option>
              ))}
            </select>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {categories.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-indigo-50 rounded-lg p-4 border border-indigo-100">
            <div className="flex items-center gap-2">
              <Calendar className="w-5 h-5 text-indigo-600" />
              <p className="text-xs font-medium text-indigo-600 uppercase tracking-wide">Today</p>
            </div>
            <p className="text-2xl font-bold text-indigo-700 mt-1">{stats.scheduledToday}</p>
          </div>
          <div className="bg-amber-50 rounded-lg p-4 border border-amber-100">
            <div className="flex items-center gap-2">
              <Truck className="w-5 h-5 text-amber-600" />
              <p className="text-xs font-medium text-amber-600 uppercase tracking-wide">In Progress</p>
            </div>
            <p className="text-2xl font-bold text-amber-700 mt-1">{stats.inProgress}</p>
          </div>
          <div className="bg-red-50 rounded-lg p-4 border border-red-100">
            <div className="flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-red-600" />
              <p className="text-xs font-medium text-red-600 uppercase tracking-wide">Needs Assignment</p>
            </div>
            <p className="text-2xl font-bold text-red-700 mt-1">{stats.needsAssignment}</p>
          </div>
          <div className="bg-emerald-50 rounded-lg p-4 border border-emerald-100">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              <p className="text-xs font-medium text-emerald-600 uppercase tracking-wide">Completed</p>
            </div>
            <p className="text-2xl font-bold text-emerald-700 mt-1">{stats.completedThisWeek}</p>
          </div>
        </div>

        {/* Work Order Cards */}
        {filteredOrders.length === 0 ? (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8 text-center">
            <ClipboardList className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <h3 className="font-medium text-slate-900">No work orders found</h3>
            <p className="text-sm text-slate-500">No work orders match your current filters.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredOrders.map(order => {
              const status = statusConfig[order.status];
              const isExpanded = expandedOrders.includes(order.id);
              const isToday = order.scheduledDate === 'Today';

              return (
                <div
                  key={order.id}
                  className={`bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden ${
                    order.status === 'in_progress' ? 'ring-2 ring-amber-200' : ''
                  }`}
                >
                  {/* Card Header */}
                  <div className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-4">
                        <div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="text-sm font-medium text-slate-500">{order.orderNumber}</span>
                            <h3 className="font-semibold text-slate-900">{order.title}</h3>
                          </div>
                          <div className="flex items-center gap-2 text-sm text-slate-500">
                            <Home className="w-4 h-4" />
                            <span>{order.householdName}</span>
                            <span>•</span>
                            <span>{order.address}</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {isToday && order.scheduledTime && (
                          <span className="inline-flex items-center gap-1 px-2 py-1 bg-indigo-100 text-indigo-700 text-sm font-medium rounded">
                            <Calendar className="w-4 h-4" />
                            TODAY {order.scheduledTime}
                          </span>
                        )}
                        <span className={`px-2 py-1 rounded text-xs font-medium ${status.bgColor} ${status.textColor}`}>
                          {status.label}
                        </span>
                      </div>
                    </div>

                    {/* Vendor & Status Row */}
                    <div className="flex items-center justify-between mt-3 pt-3 border-t border-slate-100">
                      <div className="flex items-center gap-4 text-sm">
                        {order.vendor ? (
                          <span className="flex items-center gap-1 text-slate-600">
                            <User className="w-4 h-4" />
                            <span className="font-medium">{order.vendor.name}</span>
                            <span className="text-slate-400">({order.vendor.contactName})</span>
                          </span>
                        ) : (
                          <span className="text-amber-600 font-medium">Unassigned</span>
                        )}
                        {order.estimatedCost !== undefined && order.estimatedCost > 0 && (
                          <span className="flex items-center gap-1 text-slate-600">
                            <DollarSign className="w-4 h-4" />
                            Est: ${order.estimatedCost}
                          </span>
                        )}
                        {order.actualCost !== undefined && (
                          <span className="flex items-center gap-1 text-emerald-600">
                            <DollarSign className="w-4 h-4" />
                            Actual: ${order.actualCost}
                          </span>
                        )}
                      </div>
                      {order.technicianStatus && (
                        <span className="text-sm text-slate-500">
                          Status: {order.technicianStatus}
                        </span>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 mt-3 pt-3 border-t border-slate-100">
                      {order.status === 'in_progress' && (
                        <button className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors">
                          <MapPin className="w-4 h-4" />
                          Track
                        </button>
                      )}
                      {order.vendor && (
                        <>
                          <button className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                            <Phone className="w-4 h-4" />
                            Call Tech
                          </button>
                          <button className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                            <Phone className="w-4 h-4" />
                            Call Homeowner
                          </button>
                        </>
                      )}
                      <button
                        onClick={() => toggleExpanded(order.id)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors"
                      >
                        <FileText className="w-4 h-4" />
                        Details
                        {isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                      </button>
                      {order.status !== 'completed' && order.status !== 'cancelled' && (
                        <button className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                          <CheckCircle2 className="w-4 h-4" />
                          Complete
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Expanded Details */}
                  {isExpanded && (
                    <div className="px-4 pb-4 space-y-4 border-t border-slate-100 pt-4 bg-slate-50">
                      {/* Description */}
                      <div>
                        <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">Description</h4>
                        <p className="text-sm text-slate-700">{order.description}</p>
                      </div>

                      {/* Linked Request */}
                      {order.linkedRequestTitle && (
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">Linked Request</h4>
                          <button className="text-sm text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                            {order.linkedRequestTitle}
                            <ExternalLink className="w-3 h-3" />
                          </button>
                        </div>
                      )}

                      {/* Schedule Info */}
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">Scheduled</h4>
                          <p className="text-sm text-slate-700">
                            {order.scheduledDate || 'Not scheduled'}
                            {order.scheduledTime && ` at ${order.scheduledTime}`}
                          </p>
                        </div>
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">Category</h4>
                          <p className="text-sm text-slate-700">{order.category}</p>
                        </div>
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">Priority</h4>
                          <p className={`text-sm font-medium ${priorityConfig[order.priority].color}`}>
                            {priorityConfig[order.priority].label}
                          </p>
                        </div>
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">Created</h4>
                          <p className="text-sm text-slate-700">{order.createdAt}</p>
                        </div>
                      </div>

                      {/* Photos */}
                      {order.photos.length > 0 && (
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Photos</h4>
                          <div className="flex gap-2">
                            {order.photos.map((_, i) => (
                              <div key={i} className="w-20 h-20 bg-slate-200 rounded-lg flex items-center justify-center">
                                <Camera className="w-6 h-6 text-slate-400" />
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Notes */}
                      {order.notes.length > 0 && (
                        <div>
                          <h4 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Notes</h4>
                          <div className="space-y-2">
                            {order.notes.map(note => (
                              <div key={note.id} className="bg-white rounded-lg p-3 border border-slate-200">
                                <p className="text-sm text-slate-700">{note.content}</p>
                                <p className="text-xs text-slate-400 mt-1">
                                  {note.author} • {note.createdAt}
                                </p>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Add Note */}
                      <div className="flex items-center gap-2">
                        <input
                          type="text"
                          placeholder="Add a note..."
                          className="flex-1 px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        />
                        <button className="p-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">
                          <Send className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* New Work Order Modal */}
      {showNewOrderModal && (
        <NewWorkOrderModal onClose={() => setShowNewOrderModal(false)} />
      )}
    </div>
  );
}

// ============================================================================
// NEW WORK ORDER MODAL
// ============================================================================

function NewWorkOrderModal({ onClose }: { onClose: () => void }) {
  const [formData, setFormData] = useState({
    householdId: '',
    title: '',
    description: '',
    category: '',
    priority: 'medium',
    vendorId: '',
    scheduledDate: '',
    scheduledTime: '',
    estimatedCost: '',
    notifyHomeowner: true,
  });

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-200">
          <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
            <Plus className="w-5 h-5 text-indigo-600" />
            New Work Order
          </h2>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <div className="p-4 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Household <span className="text-red-500">*</span>
              </label>
              <select
                value={formData.householdId}
                onChange={(e) => setFormData(prev => ({ ...prev, householdId: e.target.value }))}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">Select...</option>
                {households.map(h => (
                  <option key={h.id} value={h.id}>{h.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Category <span className="text-red-500">*</span>
              </label>
              <select
                value={formData.category}
                onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">Select...</option>
                {categories.filter(c => c !== 'All').map(c => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Title <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              placeholder="e.g., HVAC Annual Service"
              className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Detailed scope of work..."
              rows={3}
              className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Assign Vendor
              </label>
              <select
                value={formData.vendorId}
                onChange={(e) => setFormData(prev => ({ ...prev, vendorId: e.target.value }))}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">Select vendor...</option>
                {vendors.map(v => (
                  <option key={v.id} value={v.id}>{v.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Priority
              </label>
              <select
                value={formData.priority}
                onChange={(e) => setFormData(prev => ({ ...prev, priority: e.target.value }))}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="low">Low</option>
                <option value="medium">Medium</option>
                <option value="high">High</option>
                <option value="urgent">Urgent</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Scheduled Date
              </label>
              <input
                type="date"
                value={formData.scheduledDate}
                onChange={(e) => setFormData(prev => ({ ...prev, scheduledDate: e.target.value }))}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Scheduled Time
              </label>
              <input
                type="time"
                value={formData.scheduledTime}
                onChange={(e) => setFormData(prev => ({ ...prev, scheduledTime: e.target.value }))}
                className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Estimated Cost
              </label>
              <div className="relative">
                <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="number"
                  value={formData.estimatedCost}
                  onChange={(e) => setFormData(prev => ({ ...prev, estimatedCost: e.target.value }))}
                  placeholder="0.00"
                  className="w-full pl-8 pr-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="notifyHomeowner"
              checked={formData.notifyHomeowner}
              onChange={(e) => setFormData(prev => ({ ...prev, notifyHomeowner: e.target.checked }))}
              className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
            />
            <label htmlFor="notifyHomeowner" className="text-sm text-slate-700">
              Notify homeowner when scheduled
            </label>
          </div>
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
            disabled={!formData.householdId || !formData.title || !formData.category}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Create Work Order
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
