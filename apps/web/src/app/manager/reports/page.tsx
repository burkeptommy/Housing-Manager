'use client';

import { useState } from 'react';
import {
  BarChart3,
  FileText,
  Download,
  Send,
  ChevronRight,
  Calendar,
  Clock,
  Star,
  Users,
  ClipboardList,
  TrendingUp,
  TrendingDown,
  Home,
  Zap,
  Shield,
  Car,
  Wifi,
  X,
  Edit,
  Check,
  CreditCard,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type HouseholdId = 'smith' | 'johnson' | 'miller' | 'williams' | 'chen' | 'davis';

interface Statement {
  id: string;
  householdId: HouseholdId;
  householdName: string;
  address: string;
  month: string;
  year: number;
  generatedDate: string;
  totalDue: number;
  status: 'draft' | 'sent' | 'paid';
  dueDate: string;
}

interface BillItem {
  id: string;
  description: string;
  vendor: string;
  date: string;
  amount: number;
  included?: boolean;
}

interface ServiceItem {
  id: string;
  description: string;
  date: string;
  amount: number;
  included?: boolean;
}

interface StatementDetail {
  id: string;
  householdId: HouseholdId;
  householdName: string;
  address: string;
  month: string;
  year: number;
  membershipFee: number;
  bills: {
    category: string;
    icon: React.ReactNode;
    items: BillItem[];
    subtotal: number;
  }[];
  services: ServiceItem[];
  totalDue: number;
  dueDate: string;
  autoPayEnabled: boolean;
  paymentMethod?: string;
}

interface PerformanceMetric {
  label: string;
  value: string | number;
  subLabel: string;
  icon: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
  trendValue?: string;
}

// ============================================================================
// CONFIGURATIONS
// ============================================================================

const householdNames: Record<HouseholdId, { name: string; address: string }> = {
  smith: { name: 'Smith Family', address: '456 Oak Lane' },
  johnson: { name: 'Johnson Family', address: '789 Maple Ave' },
  miller: { name: 'Miller Family', address: '321 Pine Street' },
  williams: { name: 'Williams Family', address: '890 Birch Road' },
  chen: { name: 'Chen Family', address: '567 Cedar Blvd' },
  davis: { name: 'Davis Family', address: '234 Elm Way' },
};

const months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

// ============================================================================
// MOCK DATA
// ============================================================================

const mockStatements: Statement[] = [
  {
    id: 's1',
    householdId: 'smith',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    month: 'December',
    year: 2024,
    generatedDate: 'Dec 20, 2024',
    totalDue: 8247.23,
    status: 'sent',
    dueDate: 'Jan 1, 2025',
  },
  {
    id: 's2',
    householdId: 'johnson',
    householdName: 'Johnson Family',
    address: '789 Maple Ave',
    month: 'December',
    year: 2024,
    generatedDate: 'Dec 20, 2024',
    totalDue: 6892.50,
    status: 'sent',
    dueDate: 'Jan 1, 2025',
  },
  {
    id: 's3',
    householdId: 'miller',
    householdName: 'Miller Family',
    address: '321 Pine Street',
    month: 'December',
    year: 2024,
    generatedDate: 'Dec 19, 2024',
    totalDue: 5421.00,
    status: 'paid',
    dueDate: 'Jan 1, 2025',
  },
  {
    id: 's4',
    householdId: 'smith',
    householdName: 'Smith Family',
    address: '456 Oak Lane',
    month: 'November',
    year: 2024,
    generatedDate: 'Nov 20, 2024',
    totalDue: 7892.15,
    status: 'paid',
    dueDate: 'Dec 1, 2024',
  },
  {
    id: 's5',
    householdId: 'williams',
    householdName: 'Williams Family',
    address: '890 Birch Road',
    month: 'December',
    year: 2024,
    generatedDate: 'Dec 18, 2024',
    totalDue: 9150.00,
    status: 'draft',
    dueDate: 'Jan 1, 2025',
  },
];

const mockStatementDetail: StatementDetail = {
  id: 's1',
  householdId: 'smith',
  householdName: 'Smith Family',
  address: '456 Oak Lane',
  month: 'December',
  year: 2024,
  membershipFee: 149.00,
  bills: [
    {
      category: 'Mortgage & Housing',
      icon: <Home className="w-4 h-4" />,
      items: [
        { id: 'b1', description: 'First National Mortgage', vendor: 'First National Bank', date: 'Dec 1', amount: 2850.00 },
        { id: 'b2', description: 'Property Tax (escrow)', vendor: 'Included', date: 'Dec 1', amount: 350.00, included: true },
      ],
      subtotal: 3200.00,
    },
    {
      category: 'Utilities',
      icon: <Zap className="w-4 h-4" />,
      items: [
        { id: 'b3', description: 'ConEd Electric', vendor: 'ConEd', date: 'Dec 15', amount: 187.43 },
        { id: 'b4', description: 'National Grid Gas', vendor: 'National Grid', date: 'Dec 12', amount: 94.50 },
        { id: 'b5', description: 'Water & Sewer', vendor: 'City Water', date: 'Dec 10', amount: 65.00 },
        { id: 'b6', description: 'Internet & Cable', vendor: 'Spectrum', date: 'Dec 8', amount: 129.99 },
      ],
      subtotal: 476.92,
    },
    {
      category: 'Insurance',
      icon: <Shield className="w-4 h-4" />,
      items: [
        { id: 'b7', description: 'Homeowners Insurance', vendor: 'State Farm', date: 'Dec 1', amount: 185.00 },
        { id: 'b8', description: 'Umbrella Policy', vendor: 'State Farm', date: 'Dec 1', amount: 42.00 },
      ],
      subtotal: 227.00,
    },
    {
      category: 'Auto & Transportation',
      icon: <Car className="w-4 h-4" />,
      items: [
        { id: 'b9', description: 'Car Payment - BMW X5', vendor: 'BMW Financial', date: 'Dec 5', amount: 687.00 },
        { id: 'b10', description: 'Auto Insurance', vendor: 'Geico', date: 'Dec 1', amount: 245.00 },
      ],
      subtotal: 932.00,
    },
    {
      category: 'Subscriptions & Services',
      icon: <Wifi className="w-4 h-4" />,
      items: [
        { id: 'b11', description: 'Lawn Care Service', vendor: 'Green Thumb', date: 'Dec 15', amount: 150.00 },
        { id: 'b12', description: 'Pool Service', vendor: 'Crystal Clear', date: 'Dec 1', amount: 125.00 },
        { id: 'b13', description: 'Pest Control', vendor: 'Terminix', date: 'Dec 10', amount: 65.00 },
      ],
      subtotal: 340.00,
    },
  ],
  services: [
    { id: 'sv1', description: 'Kitchen faucet repair (handyman)', date: 'Dec 23', amount: 0, included: true },
    { id: 'sv2', description: 'HVAC annual service', date: 'Dec 24', amount: 150.00 },
    { id: 'sv3', description: 'Gutter cleaning', date: 'Dec 18', amount: 0, included: true },
    { id: 'sv4', description: 'Emergency plumbing call', date: 'Dec 5', amount: 275.00 },
  ],
  totalDue: 8247.23,
  dueDate: 'January 1, 2025',
  autoPayEnabled: true,
  paymentMethod: 'Chase ****9876',
};

const performanceMetrics: PerformanceMetric[] = [
  {
    label: '12',
    value: 12,
    subLabel: 'Households managed',
    icon: <Users className="w-5 h-5 text-indigo-600" />,
    trend: 'up',
    trendValue: '+2 this quarter',
  },
  {
    label: '127',
    value: 127,
    subLabel: 'Requests this month',
    icon: <ClipboardList className="w-5 h-5 text-blue-600" />,
    trend: 'up',
    trendValue: '+15% vs last month',
  },
  {
    label: '2.3 hrs',
    value: '2.3 hrs',
    subLabel: 'Avg response time',
    icon: <Clock className="w-5 h-5 text-emerald-600" />,
    trend: 'down',
    trendValue: '-0.5 hrs improvement',
  },
  {
    label: '4.8',
    value: 4.8,
    subLabel: 'Avg rating',
    icon: <Star className="w-5 h-5 text-amber-500" />,
    trend: 'neutral',
    trendValue: 'Consistent',
  },
];

// Chart data
const requestsChartData = [
  { month: 'Jul', value: 85 },
  { month: 'Aug', value: 92 },
  { month: 'Sep', value: 78 },
  { month: 'Oct', value: 110 },
  { month: 'Nov', value: 118 },
  { month: 'Dec', value: 127 },
];

const billsCategoryData = [
  { category: 'Housing', value: 42, color: 'bg-indigo-500' },
  { category: 'Utilities', value: 18, color: 'bg-blue-500' },
  { category: 'Insurance', value: 12, color: 'bg-emerald-500' },
  { category: 'Auto', value: 15, color: 'bg-amber-500' },
  { category: 'Services', value: 13, color: 'bg-purple-500' },
];

// ============================================================================
// COMPONENTS
// ============================================================================

export default function ManagerReportsPage() {
  const [selectedHousehold, setSelectedHousehold] = useState<HouseholdId | ''>('');
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [showStatementPreview, setShowStatementPreview] = useState(false);
  const [previewStatement, setPreviewStatement] = useState<StatementDetail | null>(null);
  const [activeTab, setActiveTab] = useState<'statements' | 'performance'>('statements');

  const handleGenerateStatement = () => {
    if (selectedHousehold) {
      // In real app, would generate statement via API
      setPreviewStatement(mockStatementDetail);
      setShowStatementPreview(true);
    }
  };

  const handleViewStatement = (statement: Statement) => {
    // In real app, would fetch full statement details
    setPreviewStatement({
      ...mockStatementDetail,
      householdId: statement.householdId,
      householdName: statement.householdName,
      address: statement.address,
      month: statement.month,
      year: statement.year,
      totalDue: statement.totalDue,
    });
    setShowStatementPreview(true);
  };

  const getStatusBadge = (status: Statement['status']) => {
    switch (status) {
      case 'draft':
        return <span className="px-2 py-1 text-xs font-medium bg-slate-100 text-slate-600 rounded-full">Draft</span>;
      case 'sent':
        return <span className="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-600 rounded-full">Sent</span>;
      case 'paid':
        return <span className="px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-600 rounded-full">Paid</span>;
    }
  };

  const maxChartValue = Math.max(...requestsChartData.map(d => d.value));

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-6 py-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <BarChart3 className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Reports & Statements</h1>
              <p className="text-sm text-slate-500">Generate statements and track performance</p>
            </div>
          </div>

          {/* Tabs */}
          <div className="flex gap-1 bg-slate-100 rounded-lg p-1 w-fit">
            <button
              onClick={() => setActiveTab('statements')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                activeTab === 'statements'
                  ? 'bg-white text-indigo-600 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Statements
            </button>
            <button
              onClick={() => setActiveTab('performance')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                activeTab === 'performance'
                  ? 'bg-white text-indigo-600 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Performance
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6">
        {activeTab === 'statements' && (
          <>
            {/* Generate Statement Card */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 mb-6">
              <h2 className="text-lg font-semibold text-slate-900 mb-1">Generate Statement</h2>
              <p className="text-sm text-slate-500 mb-4">Create a monthly statement for a household</p>

              <div className="flex flex-wrap items-end gap-4">
                <div className="flex-1 min-w-[200px]">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Household</label>
                  <select
                    value={selectedHousehold}
                    onChange={(e) => setSelectedHousehold(e.target.value as HouseholdId | '')}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  >
                    <option value="">Select household</option>
                    {Object.entries(householdNames).map(([id, info]) => (
                      <option key={id} value={id}>{info.name}</option>
                    ))}
                  </select>
                </div>

                <div className="min-w-[150px]">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Month</label>
                  <select
                    value={selectedMonth}
                    onChange={(e) => setSelectedMonth(parseInt(e.target.value))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  >
                    {months.map((month, i) => (
                      <option key={month} value={i}>{month}</option>
                    ))}
                  </select>
                </div>

                <div className="min-w-[100px]">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Year</label>
                  <select
                    value={selectedYear}
                    onChange={(e) => setSelectedYear(parseInt(e.target.value))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  >
                    <option value={2024}>2024</option>
                    <option value={2025}>2025</option>
                  </select>
                </div>

                <button
                  onClick={handleGenerateStatement}
                  disabled={!selectedHousehold}
                  className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Generate Statement
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Performance Summary */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
              {performanceMetrics.map((metric, index) => (
                <div key={index} className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center">
                      {metric.icon}
                    </div>
                    {metric.trend && (
                      <div className={`flex items-center gap-1 text-xs font-medium ${
                        metric.trend === 'up' ? 'text-emerald-600' :
                        metric.trend === 'down' ? 'text-emerald-600' : 'text-slate-500'
                      }`}>
                        {metric.trend === 'up' && <TrendingUp className="w-3 h-3" />}
                        {metric.trend === 'down' && <TrendingDown className="w-3 h-3" />}
                        {metric.trendValue}
                      </div>
                    )}
                  </div>
                  <div className="text-2xl font-bold text-slate-900">{metric.label}</div>
                  <div className="text-sm text-slate-500">{metric.subLabel}</div>
                </div>
              ))}
            </div>

            {/* Recent Statements */}
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-slate-900">Recent Statements</h2>
                <button className="text-sm font-medium text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                  View All
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>

              <div className="divide-y divide-slate-100">
                {mockStatements.map((statement) => (
                  <div
                    key={statement.id}
                    className="p-4 flex items-center justify-between hover:bg-slate-50 transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                        <FileText className="w-5 h-5 text-indigo-600" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-medium text-slate-900">
                            {statement.month} {statement.year}
                          </h3>
                          {getStatusBadge(statement.status)}
                        </div>
                        <p className="text-sm text-slate-500">
                          {statement.householdName} • {statement.address}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-4">
                      <div className="text-right">
                        <div className="font-semibold text-slate-900">
                          ${statement.totalDue.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                        </div>
                        <div className="text-xs text-slate-500">
                          Generated {statement.generatedDate}
                        </div>
                      </div>

                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleViewStatement(statement)}
                          className="p-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                          title="View Statement"
                        >
                          <FileText className="w-4 h-4" />
                        </button>
                        <button
                          className="p-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                          title="Download PDF"
                        >
                          <Download className="w-4 h-4" />
                        </button>
                        {statement.status !== 'paid' && (
                          <button
                            className="p-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                            title="Send to Homeowner"
                          >
                            <Send className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {activeTab === 'performance' && (
          <>
            {/* Performance Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
              {performanceMetrics.map((metric, index) => (
                <div key={index} className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center">
                      {metric.icon}
                    </div>
                    {metric.trend && (
                      <div className={`flex items-center gap-1 text-xs font-medium ${
                        metric.trend === 'up' ? 'text-emerald-600' :
                        metric.trend === 'down' ? 'text-emerald-600' : 'text-slate-500'
                      }`}>
                        {metric.trend === 'up' && <TrendingUp className="w-3 h-3" />}
                        {metric.trend === 'down' && <TrendingDown className="w-3 h-3" />}
                        {metric.trendValue}
                      </div>
                    )}
                  </div>
                  <div className="text-2xl font-bold text-slate-900">{metric.label}</div>
                  <div className="text-sm text-slate-500">{metric.subLabel}</div>
                </div>
              ))}
            </div>

            {/* Charts Row */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
              {/* Requests Over Time */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-1">Requests Over Time</h3>
                <p className="text-sm text-slate-500 mb-6">Monthly request volume</p>

                <div className="flex items-end justify-between h-48 gap-2">
                  {requestsChartData.map((data, index) => (
                    <div key={index} className="flex-1 flex flex-col items-center">
                      <div className="w-full flex flex-col items-center justify-end h-40">
                        <div className="text-xs font-medium text-slate-600 mb-1">{data.value}</div>
                        <div
                          className="w-full bg-indigo-500 rounded-t-md transition-all hover:bg-indigo-600"
                          style={{ height: `${(data.value / maxChartValue) * 100}%` }}
                        />
                      </div>
                      <div className="text-xs text-slate-500 mt-2">{data.month}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Bills by Category */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-1">Bills by Category</h3>
                <p className="text-sm text-slate-500 mb-6">Distribution of bill payments</p>

                <div className="flex items-center gap-6">
                  {/* Simple pie chart representation */}
                  <div className="relative w-32 h-32 flex-shrink-0">
                    <svg viewBox="0 0 36 36" className="w-full h-full">
                      {/* Create segments */}
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#6366f1"
                        strokeWidth="3"
                        strokeDasharray="42 58"
                        strokeDashoffset="25"
                      />
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#3b82f6"
                        strokeWidth="3"
                        strokeDasharray="18 82"
                        strokeDashoffset="83"
                      />
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#10b981"
                        strokeWidth="3"
                        strokeDasharray="12 88"
                        strokeDashoffset="65"
                      />
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#f59e0b"
                        strokeWidth="3"
                        strokeDasharray="15 85"
                        strokeDashoffset="53"
                      />
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#a855f7"
                        strokeWidth="3"
                        strokeDasharray="13 87"
                        strokeDashoffset="38"
                      />
                    </svg>
                  </div>

                  {/* Legend */}
                  <div className="flex-1 space-y-2">
                    {billsCategoryData.map((item) => (
                      <div key={item.category} className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <div className={`w-3 h-3 rounded-full ${item.color}`} />
                          <span className="text-sm text-slate-600">{item.category}</span>
                        </div>
                        <span className="text-sm font-medium text-slate-900">{item.value}%</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Response Time & Satisfaction */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Response Time Trend */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-1">Response Time Trend</h3>
                <p className="text-sm text-slate-500 mb-4">Average time to first response (hours)</p>

                <div className="space-y-4">
                  {[
                    { month: 'October', value: 3.2, width: '80%' },
                    { month: 'November', value: 2.8, width: '70%' },
                    { month: 'December', value: 2.3, width: '58%' },
                  ].map((item) => (
                    <div key={item.month}>
                      <div className="flex items-center justify-between text-sm mb-1">
                        <span className="text-slate-600">{item.month}</span>
                        <span className="font-medium text-slate-900">{item.value} hrs</span>
                      </div>
                      <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-emerald-500 rounded-full transition-all"
                          style={{ width: item.width }}
                        />
                      </div>
                    </div>
                  ))}
                </div>

                <div className="mt-4 pt-4 border-t border-slate-100 flex items-center gap-2 text-sm">
                  <TrendingDown className="w-4 h-4 text-emerald-500" />
                  <span className="text-emerald-600 font-medium">28% improvement</span>
                  <span className="text-slate-500">over 3 months</span>
                </div>
              </div>

              {/* Tasks Completed */}
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-1">Task Completion</h3>
                <p className="text-sm text-slate-500 mb-4">This month's task status</p>

                <div className="flex items-center gap-4 mb-6">
                  <div className="relative w-24 h-24">
                    <svg viewBox="0 0 36 36" className="w-full h-full">
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#e2e8f0"
                        strokeWidth="3"
                      />
                      <circle
                        cx="18"
                        cy="18"
                        r="15.91549430918954"
                        fill="transparent"
                        stroke="#10b981"
                        strokeWidth="3"
                        strokeDasharray="85 15"
                        strokeDashoffset="25"
                        strokeLinecap="round"
                      />
                    </svg>
                    <div className="absolute inset-0 flex items-center justify-center">
                      <span className="text-lg font-bold text-slate-900">85%</span>
                    </div>
                  </div>

                  <div className="flex-1 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-emerald-500" />
                        <span className="text-sm text-slate-600">Completed</span>
                      </div>
                      <span className="font-medium text-slate-900">108</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Clock className="w-4 h-4 text-amber-500" />
                        <span className="text-sm text-slate-600">In Progress</span>
                      </div>
                      <span className="font-medium text-slate-900">12</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Calendar className="w-4 h-4 text-slate-400" />
                        <span className="text-sm text-slate-600">Pending</span>
                      </div>
                      <span className="font-medium text-slate-900">7</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Statement Preview Modal */}
      {showStatementPreview && previewStatement && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white border-b border-slate-200 p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-indigo-600" />
                <div>
                  <h3 className="font-semibold text-slate-900">
                    {previewStatement.month} {previewStatement.year} Statement
                  </h3>
                  <p className="text-sm text-slate-500">
                    {previewStatement.householdName} - {previewStatement.address}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                  <Edit className="w-4 h-4" />
                  Edit
                </button>
                <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                  <Download className="w-4 h-4" />
                  Download PDF
                </button>
                <button
                  onClick={() => setShowStatementPreview(false)}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Statement Content */}
            <div className="p-6">
              {/* Statement Paper */}
              <div className="bg-slate-50 border border-slate-200 rounded-lg p-8">
                {/* Haven Logo/Header */}
                <div className="text-center mb-8">
                  <h1 className="text-2xl font-bold text-indigo-600">HAVEN</h1>
                  <p className="text-sm text-slate-500">Monthly Statement</p>
                </div>

                {/* Statement Info */}
                <div className="flex justify-between mb-8">
                  <div>
                    <p className="font-medium text-slate-900">{previewStatement.householdName}</p>
                    <p className="text-sm text-slate-500">{previewStatement.address}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium text-slate-900">{previewStatement.month} {previewStatement.year}</p>
                    <p className="text-sm text-slate-500">Due: {previewStatement.dueDate}</p>
                  </div>
                </div>

                {/* Membership Fee */}
                <div className="flex justify-between py-3 border-b border-slate-300">
                  <span className="font-medium text-slate-900">HAVEN MEMBERSHIP</span>
                  <span className="font-medium text-slate-900">
                    ${previewStatement.membershipFee.toFixed(2)}
                  </span>
                </div>

                {/* Bills Section */}
                <div className="mt-6">
                  <h3 className="font-semibold text-slate-900 mb-4 uppercase text-sm tracking-wide">
                    Bills Paid on Your Behalf
                  </h3>

                  {previewStatement.bills.map((category) => (
                    <div key={category.category} className="mb-6">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-slate-500">{category.icon}</span>
                        <span className="font-medium text-slate-700">{category.category}</span>
                      </div>

                      <div className="ml-6 space-y-1">
                        {category.items.map((item) => (
                          <div key={item.id} className="flex justify-between text-sm py-1">
                            <div className="flex-1">
                              <span className="text-slate-600">{item.description}</span>
                              <span className="text-slate-400 ml-2">{item.date}</span>
                            </div>
                            <span className={item.included ? 'text-slate-400' : 'text-slate-900'}>
                              ${item.amount.toFixed(2)}
                            </span>
                          </div>
                        ))}
                        <div className="flex justify-between text-sm py-1 border-t border-slate-200 mt-2">
                          <span className="text-slate-500 italic">Subtotal</span>
                          <span className="font-medium text-slate-700">${category.subtotal.toFixed(2)}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Services Section */}
                <div className="mt-6 pt-4 border-t border-slate-300">
                  <h3 className="font-semibold text-slate-900 mb-4 uppercase text-sm tracking-wide">
                    Services This Month
                  </h3>

                  <div className="space-y-1">
                    {previewStatement.services.map((service) => (
                      <div key={service.id} className="flex justify-between text-sm py-1">
                        <div className="flex-1">
                          <span className="text-slate-600">{service.description}</span>
                          <span className="text-slate-400 ml-2">{service.date}</span>
                        </div>
                        <span className={service.included ? 'text-slate-400 italic' : 'text-slate-900'}>
                          {service.included ? 'Included' : `$${service.amount.toFixed(2)}`}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Total */}
                <div className="mt-8 pt-4 border-t-2 border-slate-400">
                  <div className="flex justify-between items-center">
                    <span className="text-lg font-bold text-slate-900">
                      TOTAL DUE {previewStatement.dueDate.toUpperCase()}
                    </span>
                    <span className="text-2xl font-bold text-slate-900">
                      ${previewStatement.totalDue.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>

                {/* Auto-pay Info */}
                {previewStatement.autoPayEnabled && (
                  <div className="mt-6 bg-emerald-50 border border-emerald-200 rounded-lg p-3 flex items-center gap-2">
                    <CreditCard className="w-4 h-4 text-emerald-600" />
                    <span className="text-sm text-emerald-700">
                      Auto-pay enabled: {previewStatement.paymentMethod}
                    </span>
                  </div>
                )}
              </div>
            </div>

            {/* Modal Footer */}
            <div className="sticky bottom-0 bg-white border-t border-slate-200 p-4 flex justify-end gap-3">
              <button
                onClick={() => setShowStatementPreview(false)}
                className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800 transition-colors"
              >
                Close
              </button>
              <button className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors">
                <Send className="w-4 h-4" />
                Send to Homeowner
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
