'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import {
  Settings,
  CreditCard,
  Link2,
  Shield,
  HelpCircle,
  ChevronRight,
  ChevronLeft,
  Sun,
  Moon,
  Monitor,
  Maximize2,
  Minimize2,
  Home,
  MapPin,
  Check,
  Crown,
  Download,
  FileText,
  Calendar,
  Building,
  Map,
  Mail,
  Copy,
  ExternalLink,
  Eye,
  EyeOff,
  Trash2,
  AlertTriangle,
  MessageCircle,
  BookOpen,
  CircleHelp,
  Info,
  X,
  CheckCircle2,
  Plus,
  RefreshCw,
} from 'lucide-react';

// Types
type SettingsSection = 'general' | 'subscription' | 'integrations' | 'privacy' | 'support';
type Theme = 'system' | 'light' | 'dark';
type Density = 'comfortable' | 'compact';

interface Invoice {
  id: string;
  date: Date;
  amount: number;
  status: 'paid' | 'pending';
  downloadUrl: string;
}

interface Integration {
  id: string;
  name: string;
  description: string;
  icon: typeof Calendar;
  status: 'connected' | 'disconnected' | 'active';
  lastSync?: Date;
  details?: string;
}

// Mock Data
const mockInvoices: Invoice[] = [
  { id: '1', date: new Date(2024, 11, 15), amount: 299, status: 'paid', downloadUrl: '/invoices/dec-2024.pdf' },
  { id: '2', date: new Date(2024, 10, 15), amount: 299, status: 'paid', downloadUrl: '/invoices/nov-2024.pdf' },
  { id: '3', date: new Date(2024, 9, 15), amount: 299, status: 'paid', downloadUrl: '/invoices/oct-2024.pdf' },
  { id: '4', date: new Date(2024, 8, 15), amount: 299, status: 'paid', downloadUrl: '/invoices/sep-2024.pdf' },
];

const mockIntegrations: Integration[] = [
  {
    id: 'google-calendar',
    name: 'Google Calendar',
    description: 'Sync family events to Haven Calendar',
    icon: Calendar,
    status: 'connected',
    lastSync: new Date(Date.now() - 2 * 60 * 60 * 1000),
    details: 'miller.family@gmail.com',
  },
  {
    id: 'plaid',
    name: 'Plaid',
    description: 'Financial data for House Wallet',
    icon: Building,
    status: 'connected',
    lastSync: new Date(Date.now() - 30 * 60 * 1000),
    details: 'Chase •••• 4242',
  },
  {
    id: 'mapbox',
    name: 'Mapbox',
    description: 'Maps and location services',
    icon: Map,
    status: 'active',
  },
  {
    id: 'email-forwarding',
    name: 'Email Forwarding',
    description: 'Forward bills to your Manager',
    icon: Mail,
    status: 'connected',
    details: 'miller-house@haven-mail.com',
  },
];

// Navigation Items
const navItems = [
  { id: 'general' as const, label: 'General', icon: Settings, description: 'App appearance and household' },
  { id: 'subscription' as const, label: 'Subscription', icon: CreditCard, description: 'Plan and billing' },
  { id: 'integrations' as const, label: 'Integrations', icon: Link2, description: 'Connected services' },
  { id: 'privacy' as const, label: 'Data & Privacy', icon: Shield, description: 'Export and privacy controls' },
  { id: 'support' as const, label: 'Support', icon: HelpCircle, description: 'Help and resources' },
];

export default function SettingsPage() {
  const { currentHousehold } = useAuth();

  // State
  const [activeSection, setActiveSection] = useState<SettingsSection>('general');
  const [mobileView, setMobileView] = useState<'nav' | 'content'>('nav');
  const [theme, setTheme] = useState<Theme>('system');
  const [density, setDensity] = useState<Density>('comfortable');
  const [homeName, setHomeName] = useState('The Miller Residence');
  const [privacyMode, setPrivacyMode] = useState(false);
  const [invoices] = useState<Invoice[]>(mockInvoices);
  const [integrations] = useState<Integration[]>(mockIntegrations);

  // Modal States
  const [showUpdateCardModal, setShowUpdateCardModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');

  // Toast State
  const [toast, setToast] = useState<{ message: string; visible: boolean }>({ message: '', visible: false });

  // Check if mobile
  const [isMobile, setIsMobile] = useState(false);
  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 768);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Show toast notification
  const showToast = (message: string) => {
    setToast({ message, visible: true });
    setTimeout(() => setToast({ message: '', visible: false }), 3000);
  };

  // Handle section change
  const handleSectionChange = (section: SettingsSection) => {
    setActiveSection(section);
    if (isMobile) {
      setMobileView('content');
    }
  };

  // Format helpers
  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const getTimeSince = (date: Date) => {
    const minutes = Math.floor((Date.now() - date.getTime()) / 60000);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return formatDate(date);
  };

  // Render Navigation
  const renderNav = () => (
    <nav className="space-y-1">
      {navItems.map((item) => {
        const Icon = item.icon;
        const isActive = activeSection === item.id;
        return (
          <button
            key={item.id}
            onClick={() => handleSectionChange(item.id)}
            className={`w-full flex items-center justify-between px-4 py-3 rounded-lg text-left transition-colors ${
              isActive
                ? 'bg-emerald-50 text-emerald-700 border-l-4 border-emerald-600 pl-3'
                : 'text-slate-700 hover:bg-slate-100'
            }`}
          >
            <div className="flex items-center gap-3">
              <Icon className={`w-5 h-5 ${isActive ? 'text-emerald-600' : 'text-slate-400'}`} />
              <div>
                <p className={`font-medium ${isActive ? 'text-emerald-700' : 'text-slate-900'}`}>{item.label}</p>
                {isMobile && (
                  <p className="text-sm text-slate-500">{item.description}</p>
                )}
              </div>
            </div>
            {isMobile && <ChevronRight className="w-5 h-5 text-slate-400" />}
          </button>
        );
      })}
    </nav>
  );

  // Render General Section
  const renderGeneralSection = () => (
    <div className="space-y-6">
      {/* App Experience */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">App Experience</h3>

        {/* Theme */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-slate-700 mb-2">Theme</label>
          <div className="flex bg-slate-100 rounded-lg p-1">
            {[
              { value: 'system', label: 'System', icon: Monitor },
              { value: 'light', label: 'Light', icon: Sun },
              { value: 'dark', label: 'Dark', icon: Moon },
            ].map((option) => {
              const Icon = option.icon;
              return (
                <button
                  key={option.value}
                  onClick={() => {
                    setTheme(option.value as Theme);
                    showToast('Theme preference saved');
                  }}
                  className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    theme === option.value
                      ? 'bg-white text-slate-900 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {option.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Density */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">Display Density</label>
          <div className="flex bg-slate-100 rounded-lg p-1">
            {[
              { value: 'comfortable', label: 'Comfortable', icon: Maximize2 },
              { value: 'compact', label: 'Compact', icon: Minimize2 },
            ].map((option) => {
              const Icon = option.icon;
              return (
                <button
                  key={option.value}
                  onClick={() => {
                    setDensity(option.value as Density);
                    showToast('Display density saved');
                  }}
                  className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    density === option.value
                      ? 'bg-white text-slate-900 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {option.label}
                </button>
              );
            })}
          </div>
          <p className="text-xs text-slate-500 mt-2">Adjusts spacing in tables and lists</p>
        </div>
      </div>

      {/* Household Meta */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Household Information</h3>

        <div className="space-y-4">
          {/* Home Name */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Home Name</label>
            <div className="flex items-center gap-2">
              <div className="relative flex-1">
                <Home className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                <input
                  type="text"
                  value={homeName}
                  onChange={(e) => setHomeName(e.target.value)}
                  onBlur={() => showToast('Home name saved')}
                  className="w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  placeholder="Enter home name"
                />
              </div>
            </div>
            <p className="text-xs text-slate-500 mt-1">This name appears in your dashboard and reports</p>
          </div>

          {/* Address */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Address</label>
            <div className="flex items-start gap-3 p-4 bg-slate-50 rounded-lg border border-slate-200">
              <MapPin className="w-5 h-5 text-slate-400 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="font-medium text-slate-900">
                  {currentHousehold?.name || '123 Oak Street'}
                </p>
                <p className="text-sm text-slate-500">Austin, TX 78701</p>
              </div>
              <div className="relative group">
                <button className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors">
                  <Info className="w-4 h-4" />
                </button>
                <div className="absolute right-0 top-full mt-1 w-48 p-2 bg-slate-900 text-white text-xs rounded-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                  Contact support to change your address
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  // Render Subscription Section
  const renderSubscriptionSection = () => (
    <div className="space-y-6">
      {/* Current Plan */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-start justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
              <Crown className="w-6 h-6 text-emerald-600" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-semibold text-slate-900">Haven Premium</h3>
                <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                  Active
                </span>
              </div>
              <p className="text-sm text-slate-500">Full-service home management</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
          <div className="p-4 bg-slate-50 rounded-lg">
            <p className="text-sm text-slate-500">Next billing date</p>
            <p className="font-semibold text-slate-900">January 15, 2026</p>
          </div>
          <div className="p-4 bg-slate-50 rounded-lg">
            <p className="text-sm text-slate-500">Monthly amount</p>
            <p className="font-semibold text-slate-900">$299.00</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => showToast('Plan options coming soon')}
            className="px-4 py-2 bg-slate-100 text-slate-700 font-medium rounded-lg hover:bg-slate-200 transition-colors"
          >
            Change Plan
          </button>
          <button
            onClick={() => showToast('Please contact support to cancel')}
            className="text-sm text-slate-500 hover:text-slate-700 transition-colors"
          >
            Cancel Subscription
          </button>
        </div>
      </div>

      {/* Payment Method */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Payment Method</h3>
        <p className="text-sm text-slate-500 mb-4">
          This card is used for your Haven subscription (separate from House Wallet)
        </p>

        <div className="flex items-center justify-between p-4 bg-slate-50 rounded-lg border border-slate-200 mb-4">
          <div className="flex items-center gap-4">
            <div className="w-12 h-8 bg-gradient-to-r from-blue-600 to-blue-800 rounded flex items-center justify-center">
              <span className="text-white text-xs font-bold">VISA</span>
            </div>
            <div>
              <p className="font-medium text-slate-900">Visa ending in 4242</p>
              <p className="text-sm text-slate-500">Expires 12/26</p>
            </div>
          </div>
          <span className="text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded">Default</span>
        </div>

        <button
          onClick={() => setShowUpdateCardModal(true)}
          className="px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
        >
          Update Card
        </button>
      </div>

      {/* Invoice History */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Invoice History</h3>

        <div className="space-y-3">
          {invoices.map((invoice) => (
            <div
              key={invoice.id}
              className="flex items-center justify-between p-4 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-white rounded-lg border border-slate-200 flex items-center justify-center">
                  <FileText className="w-5 h-5 text-slate-400" />
                </div>
                <div>
                  <p className="font-medium text-slate-900">{formatDate(invoice.date)}</p>
                  <p className="text-sm text-slate-500">Haven Premium</p>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <span className="font-medium text-slate-900">{formatCurrency(invoice.amount)}</span>
                <span className={`text-xs px-2 py-0.5 rounded-full ${
                  invoice.status === 'paid'
                    ? 'bg-green-100 text-green-700'
                    : 'bg-yellow-100 text-yellow-700'
                }`}>
                  {invoice.status === 'paid' ? 'Paid' : 'Pending'}
                </span>
                <button
                  onClick={() => showToast('Downloading invoice...')}
                  className="p-2 text-slate-400 hover:text-emerald-600 rounded-lg hover:bg-white transition-colors"
                >
                  <Download className="w-5 h-5" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  // Render Integrations Section
  const renderIntegrationsSection = () => (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-2">Connected Services</h3>
        <p className="text-sm text-slate-500 mb-6">
          Manage third-party connections that power your Haven experience
        </p>

        <div className="space-y-4">
          {integrations.map((integration) => {
            const Icon = integration.icon;
            return (
              <div
                key={integration.id}
                className="flex items-center justify-between p-4 bg-slate-50 rounded-lg border border-slate-200"
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-white rounded-xl border border-slate-200 flex items-center justify-center">
                    <Icon className="w-6 h-6 text-slate-600" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-slate-900">{integration.name}</p>
                      <span className={`text-xs px-2 py-0.5 rounded-full ${
                        integration.status === 'connected'
                          ? 'bg-green-100 text-green-700'
                          : integration.status === 'active'
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-slate-100 text-slate-600'
                      }`}>
                        {integration.status.charAt(0).toUpperCase() + integration.status.slice(1)}
                      </span>
                    </div>
                    <p className="text-sm text-slate-500">{integration.description}</p>
                    {integration.details && (
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-xs text-slate-400">{integration.details}</span>
                        {integration.id === 'email-forwarding' && (
                          <button
                            onClick={() => {
                              navigator.clipboard.writeText(integration.details || '');
                              showToast('Email address copied');
                            }}
                            className="p-1 text-slate-400 hover:text-slate-600 transition-colors"
                          >
                            <Copy className="w-3 h-3" />
                          </button>
                        )}
                      </div>
                    )}
                    {integration.lastSync && (
                      <p className="text-xs text-slate-400 mt-1">
                        Last synced: {getTimeSince(integration.lastSync)}
                      </p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {integration.status === 'connected' && (
                    <button
                      onClick={() => showToast(`Syncing ${integration.name}...`)}
                      className="p-2 text-slate-400 hover:text-emerald-600 rounded-lg hover:bg-white transition-colors"
                    >
                      <RefreshCw className="w-5 h-5" />
                    </button>
                  )}
                  <button
                    onClick={() => {
                      if (integration.status === 'disconnected') {
                        showToast(`Connecting to ${integration.name}...`);
                      } else {
                        showToast(`Opening ${integration.name} settings`);
                      }
                    }}
                    className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                      integration.status === 'disconnected'
                        ? 'bg-emerald-600 text-white hover:bg-emerald-700'
                        : 'bg-white border border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    {integration.status === 'disconnected' ? 'Connect' : 'Manage'}
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        {/* Add Integration */}
        <button
          onClick={() => showToast('Browse integrations coming soon!')}
          className="w-full mt-4 flex items-center justify-center gap-2 py-3 border-2 border-dashed border-slate-300 rounded-lg text-slate-600 hover:border-emerald-500 hover:text-emerald-600 transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span className="font-medium">Add Integration</span>
        </button>
      </div>
    </div>
  );

  // Render Privacy Section
  const renderPrivacySection = () => (
    <div className="space-y-6">
      {/* Export Data */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-2">Export Your Data</h3>
        <p className="text-sm text-slate-500 mb-4">
          Download a complete archive of your household data
        </p>

        <div className="p-4 bg-slate-50 rounded-lg border border-slate-200 mb-4">
          <p className="font-medium text-slate-900 mb-2">Your archive includes:</p>
          <ul className="space-y-1 text-sm text-slate-600">
            <li className="flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-600" />
              Transaction history (CSV)
            </li>
            <li className="flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-600" />
              Receipt documents (PDF)
            </li>
            <li className="flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-600" />
              Home profile data (JSON)
            </li>
            <li className="flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-600" />
              Maintenance records (CSV)
            </li>
          </ul>
        </div>

        <button
          onClick={() => showToast('Preparing archive... This may take a few minutes.')}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <Download className="w-5 h-5" />
          Download Full Archive
        </button>
      </div>

      {/* Privacy Mode */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-slate-100 rounded-xl flex items-center justify-center">
              {privacyMode ? (
                <EyeOff className="w-6 h-6 text-slate-600" />
              ) : (
                <Eye className="w-6 h-6 text-slate-600" />
              )}
            </div>
            <div>
              <h3 className="font-semibold text-slate-900">Privacy Mode</h3>
              <p className="text-sm text-slate-500 mt-1">
                Hide financial information on the dashboard. Useful when guests are visiting.
              </p>
            </div>
          </div>
          <button
            onClick={() => {
              setPrivacyMode(!privacyMode);
              showToast(privacyMode ? 'Privacy mode disabled' : 'Privacy mode enabled');
            }}
            className={`relative w-14 h-7 rounded-full transition-colors ${
              privacyMode ? 'bg-emerald-600' : 'bg-slate-200'
            }`}
          >
            <span
              className={`absolute top-1 w-5 h-5 bg-white rounded-full shadow-sm transition-transform ${
                privacyMode ? 'left-8' : 'left-1'
              }`}
            />
          </button>
        </div>
      </div>

      {/* Danger Zone */}
      <div className="bg-white rounded-xl shadow-sm border border-red-200 p-6">
        <div className="flex items-center gap-2 mb-4">
          <AlertTriangle className="w-5 h-5 text-red-600" />
          <h3 className="font-semibold text-red-600">Danger Zone</h3>
        </div>

        <div className="p-4 bg-red-50 rounded-lg border border-red-200 mb-4">
          <p className="font-medium text-red-900 mb-1">Delete Household</p>
          <p className="text-sm text-red-700">
            Permanently delete this household and all associated data. This action cannot be undone.
          </p>
        </div>

        <button
          onClick={() => setShowDeleteModal(true)}
          className="px-4 py-2 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 transition-colors"
        >
          Delete Household
        </button>
      </div>
    </div>
  );

  // Render Support Section
  const renderSupportSection = () => (
    <div className="space-y-6">
      {/* Concierge Status */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Your Home Manager</h3>

        <div className="flex items-center gap-4 p-4 bg-emerald-50 rounded-lg border border-emerald-200">
          <div className="relative">
            <div className="w-14 h-14 bg-emerald-100 rounded-full flex items-center justify-center">
              <span className="text-lg font-semibold text-emerald-700">SH</span>
            </div>
            <span className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-green-500 rounded-full border-2 border-white" />
          </div>
          <div className="flex-1">
            <p className="font-semibold text-slate-900">Sarah Harrison</p>
            <p className="text-sm text-emerald-700">Online - Available now</p>
          </div>
          <button
            onClick={() => {
              window.location.href = '/app/messages';
            }}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
          >
            <MessageCircle className="w-5 h-5" />
            Message
          </button>
        </div>
      </div>

      {/* Resources */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Resources</h3>

        <div className="space-y-3">
          {[
            { icon: BookOpen, label: 'User Guide', description: 'Learn how to use Haven', action: () => showToast('Opening User Guide...') },
            { icon: CircleHelp, label: 'FAQs', description: 'Common questions answered', action: () => showToast('Opening FAQs...') },
            { icon: MessageCircle, label: 'Contact Support', description: 'Get help from our team', action: () => { window.location.href = '/app/messages'; } },
          ].map((item, index) => {
            const Icon = item.icon;
            return (
              <button
                key={index}
                onClick={item.action}
                className="w-full flex items-center justify-between p-4 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors text-left"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-white rounded-lg border border-slate-200 flex items-center justify-center">
                    <Icon className="w-5 h-5 text-slate-600" />
                  </div>
                  <div>
                    <p className="font-medium text-slate-900">{item.label}</p>
                    <p className="text-sm text-slate-500">{item.description}</p>
                  </div>
                </div>
                <ExternalLink className="w-5 h-5 text-slate-400" />
              </button>
            );
          })}
        </div>
      </div>

      {/* App Info */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">About Haven</h3>

        <div className="space-y-3">
          <div className="flex items-center justify-between py-2">
            <span className="text-slate-600">Version</span>
            <span className="font-medium text-slate-900">v2.4.0</span>
          </div>
          <div className="flex items-center justify-between py-2 border-t border-slate-100">
            <span className="text-slate-600">Build</span>
            <span className="font-medium text-slate-900">#2024.12.19</span>
          </div>
          <div className="flex items-center justify-between py-2 border-t border-slate-100">
            <span className="text-slate-600">Account ID</span>
            <span className="font-mono text-sm text-slate-900">HH-{currentHousehold?.id?.slice(0, 8) || 'MILLER01'}</span>
          </div>
        </div>

        <div className="mt-4 pt-4 border-t border-slate-200 flex items-center justify-center gap-4 text-sm text-slate-500">
          <a href="#" className="hover:text-emerald-600 transition-colors">Terms of Service</a>
          <span>•</span>
          <a href="#" className="hover:text-emerald-600 transition-colors">Privacy Policy</a>
        </div>
      </div>
    </div>
  );

  // Get active section content
  const renderSectionContent = () => {
    switch (activeSection) {
      case 'general':
        return renderGeneralSection();
      case 'subscription':
        return renderSubscriptionSection();
      case 'integrations':
        return renderIntegrationsSection();
      case 'privacy':
        return renderPrivacySection();
      case 'support':
        return renderSupportSection();
      default:
        return renderGeneralSection();
    }
  };

  return (
    <div className="space-y-6 pb-20">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Settings</h1>
        <p className="text-slate-600 mt-1">Manage your Haven app and household preferences</p>
      </div>

      {/* Desktop Layout */}
      <div className="hidden md:flex gap-6">
        {/* Left Sidebar */}
        <div className="w-64 flex-shrink-0">
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 sticky top-6">
            {renderNav()}
          </div>
        </div>

        {/* Right Content */}
        <div className="flex-1">
          {renderSectionContent()}
        </div>
      </div>

      {/* Mobile Layout */}
      <div className="md:hidden">
        {mobileView === 'nav' ? (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            {renderNav()}
          </div>
        ) : (
          <div>
            {/* Back Button */}
            <button
              onClick={() => setMobileView('nav')}
              className="flex items-center gap-2 text-slate-600 hover:text-slate-900 mb-4"
            >
              <ChevronLeft className="w-5 h-5" />
              <span className="font-medium">Back to Settings</span>
            </button>

            {/* Section Title */}
            <h2 className="text-lg font-semibold text-slate-900 mb-4">
              {navItems.find((item) => item.id === activeSection)?.label}
            </h2>

            {/* Content */}
            {renderSectionContent()}
          </div>
        )}
      </div>

      {/* Toast Notification */}
      {toast.visible && (
        <div className="fixed bottom-6 right-6 flex items-center gap-2 px-4 py-3 bg-slate-900 text-white rounded-lg shadow-lg z-50 animate-slide-up">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span className="font-medium">{toast.message}</span>
        </div>
      )}

      {/* Update Card Modal */}
      {showUpdateCardModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowUpdateCardModal(false)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Update Payment Method</h3>
                  <button
                    onClick={() => setShowUpdateCardModal(false)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Card Number</label>
                  <input
                    type="text"
                    placeholder="1234 5678 9012 3456"
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">Expiry Date</label>
                    <input
                      type="text"
                      placeholder="MM/YY"
                      className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">CVC</label>
                    <input
                      type="text"
                      placeholder="123"
                      className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Name on Card</label>
                  <input
                    type="text"
                    placeholder="John Miller"
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
              </div>

              <div className="p-6 border-t border-slate-200">
                <button
                  onClick={() => {
                    setShowUpdateCardModal(false);
                    showToast('Payment method updated');
                  }}
                  className="w-full py-3 bg-emerald-600 text-white font-semibold rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Save Card
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Household Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowDeleteModal(false)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                    <AlertTriangle className="w-5 h-5 text-red-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-slate-900">Delete Household</h3>
                    <p className="text-sm text-slate-500">This action is permanent</p>
                  </div>
                </div>
              </div>

              <div className="p-6 space-y-4">
                <p className="text-slate-600">
                  This will permanently delete <span className="font-semibold text-slate-900">{homeName}</span> and all associated data including:
                </p>
                <ul className="space-y-2 text-sm text-slate-600">
                  <li className="flex items-center gap-2">
                    <Trash2 className="w-4 h-4 text-red-500" />
                    All transaction history
                  </li>
                  <li className="flex items-center gap-2">
                    <Trash2 className="w-4 h-4 text-red-500" />
                    Home profile and systems
                  </li>
                  <li className="flex items-center gap-2">
                    <Trash2 className="w-4 h-4 text-red-500" />
                    Calendar events and requests
                  </li>
                  <li className="flex items-center gap-2">
                    <Trash2 className="w-4 h-4 text-red-500" />
                    All receipts and documents
                  </li>
                </ul>

                <div className="pt-4">
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Type <span className="font-semibold">{homeName}</span> to confirm
                  </label>
                  <input
                    type="text"
                    value={deleteConfirmText}
                    onChange={(e) => setDeleteConfirmText(e.target.value)}
                    placeholder={homeName}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setDeleteConfirmText('');
                  }}
                  className="flex-1 py-3 border border-slate-200 text-slate-700 font-semibold rounded-lg hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  disabled={deleteConfirmText !== homeName}
                  className={`flex-1 py-3 font-semibold rounded-lg transition-colors ${
                    deleteConfirmText === homeName
                      ? 'bg-red-600 text-white hover:bg-red-700'
                      : 'bg-slate-100 text-slate-400 cursor-not-allowed'
                  }`}
                >
                  Delete Permanently
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* CSS for toast animation */}
      <style jsx>{`
        @keyframes slide-up {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        .animate-slide-up {
          animation: slide-up 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
