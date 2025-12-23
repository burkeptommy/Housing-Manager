'use client';

import { useState } from 'react';
import Image from 'next/image';
import { useAuth } from '@/contexts/auth-context';
import {
  User,
  Mail,
  Phone,
  Camera,
  Edit3,
  Check,
  X,
  Bell,
  DollarSign,
  Shield,
  LogOut,
  Smartphone,
  Monitor,
  Laptop,
  ChevronRight,
  ChevronDown,
  Flame,
  Trophy,
  CheckCircle2,
  AlertTriangle,
  Users,
  Lock,
  Key,
  CreditCard,
  Wallet,
  Globe,
  UserX,
  Crown,
  Zap,
  MessageSquare,
  Home,
  Calendar,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type SettingsTab = 'details' | 'notifications' | 'wallet' | 'security';
type VisibilityLevel = 'public' | 'neighbors' | 'friends';

interface NotificationSetting {
  id: string;
  label: string;
  description: string;
  enabled: boolean;
  threshold?: number;
}

interface LinkedAccount {
  id: string;
  type: 'venmo' | 'zelle' | 'paypal';
  username: string;
  isDefault: boolean;
}

interface ActiveSession {
  id: string;
  device: string;
  deviceType: 'mobile' | 'desktop' | 'tablet';
  location: string;
  lastActive: string;
  isCurrent: boolean;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockUserData = {
  id: 'u1',
  firstName: 'Robert',
  lastName: 'Chen',
  displayName: 'Bob Chen',
  email: 'bob@example.com',
  phone: '+1 (310) 555-0123',
  avatarUrl: null,
  coverUrl: null,
  role: 'admin' as const,
  householdName: 'The Chen Family',
  joinedDate: '2023-06-15',
  contributionScore: 847,
  weekStreak: 7,
  tasksCompleted: 156,
  projectsLed: 4,
};

const mockNotifications: Record<string, NotificationSetting[]> = {
  financial: [
    { id: 'f1', label: 'Bill Payment Reminders', description: 'Get notified before bills are due', enabled: true },
    { id: 'f2', label: 'Budget Threshold Alerts', description: 'Notify when spending exceeds limit', enabled: true, threshold: 500 },
    { id: 'f3', label: 'Expense Approvals', description: 'When a family member requests approval', enabled: true },
  ],
  lifestyle: [
    { id: 'l1', label: 'Service Provider Arrivals', description: 'Nanny, tutor, or cleaner arrival alerts', enabled: true },
    { id: 'l2', label: 'Maintenance Reminders', description: 'Scheduled maintenance coming up', enabled: false },
    { id: 'l3', label: 'Calendar Event Reminders', description: 'Family events and appointments', enabled: true },
  ],
  social: [
    { id: 's1', label: 'Post Interactions', description: 'Likes, comments on your project posts', enabled: true },
    { id: 's2', label: 'Neighbor Replies', description: 'When neighbors respond to your posts', enabled: true },
    { id: 's3', label: 'Community Updates', description: 'Neighborhood announcements and alerts', enabled: false },
  ],
  system: [
    { id: 'y1', label: 'Critical Home Health Alerts', description: 'Security, HVAC, water leak warnings', enabled: true },
    { id: 'y2', label: 'System Updates', description: 'App updates and new features', enabled: true },
  ],
};

const mockLinkedAccounts: LinkedAccount[] = [
  { id: 'la1', type: 'venmo', username: '@bobchen', isDefault: true },
];

const mockSessions: ActiveSession[] = [
  { id: 's1', device: 'iPhone 15 Pro', deviceType: 'mobile', location: 'Beverly Hills, CA', lastActive: 'Now', isCurrent: true },
  { id: 's2', device: 'MacBook Pro', deviceType: 'desktop', location: 'Beverly Hills, CA', lastActive: '2 hours ago', isCurrent: false },
  { id: 's3', device: 'iPad Air', deviceType: 'tablet', location: 'Los Angeles, CA', lastActive: '3 days ago', isCurrent: false },
];

// ============================================================================
// COMPONENTS
// ============================================================================

// Hero Card Component
function HeroCard({
  user,
  onEditAvatar,
}: {
  user: typeof mockUserData;
  onEditAvatar: () => void;
}) {
  const isAdmin = user.role === 'admin';

  return (
    <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
      {/* Cover Photo */}
      <div className="h-32 bg-gradient-to-br from-emerald-600 via-emerald-500 to-teal-400 relative">
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmZmZmYiIGZpbGwtb3BhY2l0eT0iMC4xIj48cGF0aCBkPSJNMzYgMzRjMC0yLjIwOS0xLjc5MS00LTQtNHMtNCAxLjc5MS00IDQgMS43OTEgNCA0IDQgNC0xLjc5MSA0LTRtMC0xNmMwLTIuMjA5LTEuNzkxLTQtNC00cy00IDEuNzkxLTQgNCAxLjc5MSA0IDQgNCA0LTEuNzkxIDQtNG0tMTYgMTZjMC0yLjIwOS0xLjc5MS00LTQtNHMtNCAxLjc5MS00IDQgMS43OTEgNCA0IDQgNC0xLjc5MSA0LTRtMTYgMTZjMC0yLjIwOS0xLjc5MS00LTQtNHMtNCAxLjc5MS00IDQgMS43OTEgNCA0IDQgNC0xLjc5MSA0LTQiLz48L2c+PC9nPjwvc3ZnPg==')] opacity-30" />
        <button className="absolute top-3 right-3 p-2 bg-black/20 hover:bg-black/30 rounded-lg transition-colors">
          <Camera className="w-4 h-4 text-white" />
        </button>
      </div>

      {/* Avatar & Info */}
      <div className="px-6 pb-6">
        <div className="flex items-end -mt-12 mb-4">
          <div className="relative">
            <div className="w-24 h-24 rounded-full border-4 border-white bg-warm-200 flex items-center justify-center overflow-hidden shadow-lg">
              {user.avatarUrl ? (
                <Image src={user.avatarUrl} alt="" fill className="object-cover" />
              ) : (
                <span className="text-4xl font-bold text-warm-400">
                  {user.firstName[0]}{user.lastName[0]}
                </span>
              )}
            </div>
            <button
              onClick={onEditAvatar}
              className="absolute bottom-0 right-0 w-8 h-8 bg-emerald-600 hover:bg-emerald-700 rounded-full flex items-center justify-center shadow-lg transition-colors"
            >
              <Camera className="w-4 h-4 text-white" />
            </button>
          </div>

          {/* Role Badge */}
          <div className="ml-4 mb-2">
            {isAdmin ? (
              <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-amber-100 text-amber-800 rounded-full text-sm font-medium">
                <Crown className="w-4 h-4" />
                Head of Household
              </span>
            ) : (
              <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-warm-100 text-warm-700 rounded-full text-sm font-medium">
                <Users className="w-4 h-4" />
                Family Member
              </span>
            )}
          </div>
        </div>

        <h2 className="text-xl font-bold text-warm-900">{user.displayName}</h2>
        <p className="text-warm-500 text-sm mt-0.5">{user.householdName}</p>

        {/* Gamification Stats */}
        <div className="grid grid-cols-2 gap-4 mt-6">
          <div className="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-xl p-4 border border-emerald-100">
            <div className="flex items-center gap-2 mb-2">
              <div className="p-2 bg-emerald-100 rounded-lg">
                <Trophy className="w-5 h-5 text-emerald-600" />
              </div>
              <span className="text-sm font-medium text-warm-600">Contribution Score</span>
            </div>
            <p className="text-3xl font-bold text-emerald-600">{user.contributionScore}</p>
            <p className="text-xs text-warm-500 mt-1">{user.tasksCompleted} tasks completed</p>
          </div>

          <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-xl p-4 border border-amber-100">
            <div className="flex items-center gap-2 mb-2">
              <div className="p-2 bg-amber-100 rounded-lg">
                <Flame className="w-5 h-5 text-amber-600" />
              </div>
              <span className="text-sm font-medium text-warm-600">Active Streak</span>
            </div>
            <p className="text-3xl font-bold text-amber-600">{user.weekStreak} weeks</p>
            <p className="text-xs text-warm-500 mt-1">Keep it going!</p>
          </div>
        </div>
      </div>
    </div>
  );
}

// Toggle Switch Component
function ToggleSwitch({
  enabled,
  onChange,
  disabled = false,
}: {
  enabled: boolean;
  onChange: (value: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <button
      onClick={() => !disabled && onChange(!enabled)}
      className={`relative w-11 h-6 rounded-full transition-colors ${
        enabled ? 'bg-emerald-600' : 'bg-warm-300'
      } ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
    >
      <span
        className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-transform ${
          enabled ? 'tranwarm-x-5' : 'tranwarm-x-0'
        }`}
      />
    </button>
  );
}

// Personal Details Tab
function PersonalDetailsTab({ user }: { user: typeof mockUserData }) {
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    displayName: user.displayName,
    email: user.email,
    phone: user.phone,
  });
  const [showVerifyPhone, setShowVerifyPhone] = useState(false);

  const handleSave = () => {
    // In real app, would call API
    setIsEditing(false);
    if (formData.phone !== user.phone) {
      setShowVerifyPhone(true);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-warm-900">Personal Information</h3>
        {!isEditing ? (
          <button
            onClick={() => setIsEditing(true)}
            className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors"
          >
            <Edit3 className="w-4 h-4" />
            Edit
          </button>
        ) : (
          <div className="flex gap-2">
            <button
              onClick={() => setIsEditing(false)}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-warm-600 hover:bg-warm-100 rounded-lg transition-colors"
            >
              <X className="w-4 h-4" />
              Cancel
            </button>
            <button
              onClick={handleSave}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium bg-emerald-600 text-white hover:bg-emerald-700 rounded-lg transition-colors"
            >
              <Check className="w-4 h-4" />
              Save
            </button>
          </div>
        )}
      </div>

      <div className="space-y-4">
        {/* Display Name */}
        <div>
          <label className="block text-sm font-medium text-warm-700 mb-1.5">Display Name</label>
          {isEditing ? (
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
              <input
                type="text"
                value={formData.displayName}
                onChange={(e) => setFormData({ ...formData, displayName: e.target.value })}
                className="w-full pl-10 pr-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              />
            </div>
          ) : (
            <div className="flex items-center gap-3 px-4 py-3 bg-warm-50 rounded-lg">
              <User className="w-5 h-5 text-warm-400" />
              <span className="text-warm-900">{user.displayName}</span>
            </div>
          )}
        </div>

        {/* Email */}
        <div>
          <label className="block text-sm font-medium text-warm-700 mb-1.5">Email Address</label>
          {isEditing ? (
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
              <input
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="w-full pl-10 pr-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              />
            </div>
          ) : (
            <div className="flex items-center gap-3 px-4 py-3 bg-warm-50 rounded-lg">
              <Mail className="w-5 h-5 text-warm-400" />
              <span className="text-warm-900">{user.email}</span>
              <span className="ml-auto inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                <CheckCircle2 className="w-3 h-3" />
                Verified
              </span>
            </div>
          )}
        </div>

        {/* Phone */}
        <div>
          <label className="block text-sm font-medium text-warm-700 mb-1.5">Phone Number</label>
          {isEditing ? (
            <div className="relative">
              <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
              <input
                type="tel"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                className="w-full pl-10 pr-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              />
            </div>
          ) : (
            <div className="flex items-center gap-3 px-4 py-3 bg-warm-50 rounded-lg">
              <Phone className="w-5 h-5 text-warm-400" />
              <span className="text-warm-900">{user.phone}</span>
              <span className="ml-auto inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                <CheckCircle2 className="w-3 h-3" />
                Verified
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Phone Verification Modal */}
      {showVerifyPhone && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowVerifyPhone(false)} />
          <div className="relative bg-white rounded-xl shadow-xl p-6 max-w-sm w-full">
            <h4 className="text-lg font-semibold text-warm-900 mb-2">Verify Your Phone</h4>
            <p className="text-sm text-warm-500 mb-4">
              We sent a 6-digit code to {formData.phone}
            </p>
            <div className="flex gap-2 mb-4">
              {[...Array(6)].map((_, i) => (
                <input
                  key={i}
                  type="text"
                  maxLength={1}
                  className="w-10 h-12 text-center text-xl font-bold border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              ))}
            </div>
            <button
              onClick={() => setShowVerifyPhone(false)}
              className="w-full px-4 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
            >
              Verify
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// Notifications Tab
function NotificationsTab() {
  const [notifications, setNotifications] = useState(mockNotifications);
  const [billThreshold, setBillThreshold] = useState(500);

  const toggleNotification = (category: string, id: string) => {
    const categorySettings = notifications[category];
    if (!categorySettings) return;
    setNotifications({
      ...notifications,
      [category]: categorySettings.map((n) =>
        n.id === id ? { ...n, enabled: !n.enabled } : n
      ),
    });
  };

  const categoryIcons: Record<string, typeof DollarSign> = {
    financial: DollarSign,
    lifestyle: Calendar,
    social: MessageSquare,
    system: Zap,
  };

  const categoryLabels: Record<string, string> = {
    financial: 'Financial Alerts',
    lifestyle: 'Lifestyle Reminders',
    social: 'Social Notifications',
    system: 'System Alerts',
  };

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold text-warm-900 mb-1">Notification Preferences</h3>
        <p className="text-sm text-warm-500">Control how and when Haven notifies you</p>
      </div>

      {Object.entries(notifications).map(([category, settings]) => {
        const Icon = categoryIcons[category] ?? DollarSign;
        const isSystem = category === 'system';

        return (
          <div key={category} className="bg-warm-50 rounded-xl overflow-hidden">
            <div className="flex items-center gap-3 px-4 py-3 bg-warm-100">
              <Icon className="w-5 h-5 text-warm-600" />
              <span className="font-medium text-warm-700">{categoryLabels[category]}</span>
              {isSystem && (
                <span className="ml-auto text-xs text-warm-500 flex items-center gap-1">
                  <Lock className="w-3 h-3" />
                  Always On
                </span>
              )}
            </div>
            <div className="divide-y divide-warm-200">
              {settings.map((setting) => (
                <div key={setting.id} className="px-4 py-4 bg-white">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <p className="font-medium text-warm-900">{setting.label}</p>
                      <p className="text-sm text-warm-500 mt-0.5">{setting.description}</p>
                      {setting.threshold !== undefined && setting.enabled && (
                        <div className="mt-3">
                          <label className="text-sm text-warm-600 block mb-2">
                            Notify when spending exceeds: <span className="font-semibold">${billThreshold}</span>
                          </label>
                          <input
                            type="range"
                            min={100}
                            max={2000}
                            step={100}
                            value={billThreshold}
                            onChange={(e) => setBillThreshold(Number(e.target.value))}
                            className="w-full h-2 bg-warm-200 rounded-lg appearance-none cursor-pointer accent-emerald-600"
                          />
                          <div className="flex justify-between text-xs text-warm-400 mt-1">
                            <span>$100</span>
                            <span>$2,000</span>
                          </div>
                        </div>
                      )}
                    </div>
                    <ToggleSwitch
                      enabled={setting.enabled}
                      onChange={() => toggleNotification(category, setting.id)}
                      disabled={isSystem}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// Digital Wallet Tab
function WalletTab() {
  const [accounts, setAccounts] = useState(mockLinkedAccounts);
  const [, setShowAddAccount] = useState(false);

  const accountIcons: Record<string, string> = {
    venmo: '💳',
    zelle: '🏦',
    paypal: '💰',
  };

  const setDefault = (id: string) => {
    setAccounts(accounts.map((a) => ({ ...a, isDefault: a.id === id })));
  };

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold text-warm-900 mb-1">Digital Wallet</h3>
        <p className="text-sm text-warm-500">Manage payment methods for reimbursements and split expenses</p>
      </div>

      {/* Linked Accounts */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h4 className="font-medium text-warm-700">Linked Accounts</h4>
          <button
            onClick={() => setShowAddAccount(true)}
            className="text-sm font-medium text-emerald-600 hover:text-emerald-700"
          >
            + Add Account
          </button>
        </div>

        {accounts.length > 0 ? (
          <div className="space-y-2">
            {accounts.map((account) => (
              <div
                key={account.id}
                className="flex items-center gap-4 p-4 bg-white rounded-xl border border-warm-200"
              >
                <div className="text-2xl">{accountIcons[account.type]}</div>
                <div className="flex-1">
                  <p className="font-medium text-warm-900 capitalize">{account.type}</p>
                  <p className="text-sm text-warm-500">{account.username}</p>
                </div>
                {account.isDefault ? (
                  <span className="px-2 py-1 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                    Default
                  </span>
                ) : (
                  <button
                    onClick={() => setDefault(account.id)}
                    className="text-sm text-warm-500 hover:text-warm-700"
                  >
                    Set as Default
                  </button>
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 bg-warm-50 rounded-xl">
            <Wallet className="w-10 h-10 text-warm-300 mx-auto mb-2" />
            <p className="text-warm-500">No accounts linked yet</p>
          </div>
        )}
      </div>

      {/* Connect Account Buttons */}
      <div className="space-y-3">
        <h4 className="font-medium text-warm-700">Connect a New Account</h4>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {['venmo', 'zelle', 'paypal'].map((type) => (
            <button
              key={type}
              className="flex items-center justify-center gap-2 p-4 bg-white border border-warm-200 rounded-xl hover:border-emerald-300 hover:bg-emerald-50 transition-colors"
            >
              <span className="text-xl">{accountIcons[type]}</span>
              <span className="font-medium text-warm-700 capitalize">Connect {type}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Default Payment Method */}
      <div className="p-4 bg-warm-50 rounded-xl">
        <div className="flex items-center gap-3 mb-3">
          <CreditCard className="w-5 h-5 text-warm-500" />
          <h4 className="font-medium text-warm-700">Default Payment Method</h4>
        </div>
        <p className="text-sm text-warm-500 mb-3">
          Select which account receives reimbursements from household expenses
        </p>
        <div className="flex items-center gap-3 p-3 bg-white rounded-lg border border-warm-200">
          <span className="text-xl">💳</span>
          <div className="flex-1">
            <p className="font-medium text-warm-900">Venmo</p>
            <p className="text-sm text-warm-500">@bobchen</p>
          </div>
          <CheckCircle2 className="w-5 h-5 text-emerald-600" />
        </div>
      </div>
    </div>
  );
}

// Security Tab
function SecurityTab({ user }: { user: typeof mockUserData }) {
  const [sessions, setSessions] = useState(mockSessions);
  const [twoFactorEnabled, setTwoFactorEnabled] = useState(false);
  const [visibility, setVisibility] = useState<VisibilityLevel>('neighbors');
  const [, setShowChangePassword] = useState(false);
  const [showLeaveHousehold, setShowLeaveHousehold] = useState(false);

  const deviceIcons: Record<string, typeof Smartphone> = {
    mobile: Smartphone,
    desktop: Monitor,
    tablet: Laptop,
  };

  const getDeviceIcon = (type: string) => deviceIcons[type] ?? Smartphone;

  const logOutSession = (id: string) => {
    setSessions(sessions.filter((s) => s.id !== id));
  };

  const logOutAll = () => {
    setSessions(sessions.filter((s) => s.isCurrent));
  };

  const isAdmin = user.role === 'admin';

  return (
    <div className="space-y-8">
      {/* Social Privacy */}
      <div>
        <h3 className="text-lg font-semibold text-warm-900 mb-1">Social Privacy</h3>
        <p className="text-sm text-warm-500 mb-4">Control who can see your project posts</p>

        <div className="space-y-2">
          {[
            { value: 'public', label: 'Public', description: 'Anyone can see your posts', icon: Globe },
            { value: 'neighbors', label: 'Neighbors Only', description: 'Only verified neighbors can see', icon: Home },
            { value: 'friends', label: 'Friends Only', description: 'Only people you follow', icon: Users },
          ].map((option) => (
            <button
              key={option.value}
              onClick={() => setVisibility(option.value as VisibilityLevel)}
              className={`w-full flex items-center gap-4 p-4 rounded-xl border transition-colors ${
                visibility === option.value
                  ? 'border-emerald-500 bg-emerald-50'
                  : 'border-warm-200 bg-white hover:bg-warm-50'
              }`}
            >
              <option.icon className={`w-5 h-5 ${visibility === option.value ? 'text-emerald-600' : 'text-warm-400'}`} />
              <div className="flex-1 text-left">
                <p className={`font-medium ${visibility === option.value ? 'text-emerald-900' : 'text-warm-900'}`}>
                  {option.label}
                </p>
                <p className="text-sm text-warm-500">{option.description}</p>
              </div>
              {visibility === option.value && <CheckCircle2 className="w-5 h-5 text-emerald-600" />}
            </button>
          ))}
        </div>
      </div>

      {/* Security Settings */}
      <div>
        <h3 className="text-lg font-semibold text-warm-900 mb-4">Security</h3>

        <div className="space-y-3">
          {/* Change Password */}
          <button
            onClick={() => setShowChangePassword(true)}
            className="w-full flex items-center gap-4 p-4 bg-white rounded-xl border border-warm-200 hover:bg-warm-50 transition-colors"
          >
            <div className="p-2 bg-warm-100 rounded-lg">
              <Key className="w-5 h-5 text-warm-600" />
            </div>
            <div className="flex-1 text-left">
              <p className="font-medium text-warm-900">Change Password</p>
              <p className="text-sm text-warm-500">Update your account password</p>
            </div>
            <ChevronRight className="w-5 h-5 text-warm-400" />
          </button>

          {/* Two-Factor Auth */}
          <div className="flex items-center gap-4 p-4 bg-white rounded-xl border border-warm-200">
            <div className="p-2 bg-warm-100 rounded-lg">
              <Shield className="w-5 h-5 text-warm-600" />
            </div>
            <div className="flex-1">
              <p className="font-medium text-warm-900">Two-Factor Authentication</p>
              <p className="text-sm text-warm-500">Add an extra layer of security</p>
            </div>
            <ToggleSwitch enabled={twoFactorEnabled} onChange={setTwoFactorEnabled} />
          </div>
        </div>
      </div>

      {/* Active Sessions */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-warm-900">Active Sessions</h3>
          {sessions.length > 1 && (
            <button
              onClick={logOutAll}
              className="text-sm font-medium text-red-600 hover:text-red-700"
            >
              Log Out All
            </button>
          )}
        </div>

        <div className="space-y-2">
          {sessions.map((session) => {
            const DeviceIcon = getDeviceIcon(session.deviceType);
            return (
              <div
                key={session.id}
                className="flex items-center gap-4 p-4 bg-white rounded-xl border border-warm-200"
              >
                <div className="p-2 bg-warm-100 rounded-lg">
                  <DeviceIcon className="w-5 h-5 text-warm-600" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-medium text-warm-900">{session.device}</p>
                    {session.isCurrent && (
                      <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                        Current
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-warm-500">
                    {session.location} • {session.lastActive}
                  </p>
                </div>
                {!session.isCurrent && (
                  <button
                    onClick={() => logOutSession(session.id)}
                    className="p-2 text-warm-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <LogOut className="w-5 h-5" />
                  </button>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Danger Zone */}
      <div className="border-t border-warm-200 pt-8">
        <h3 className="text-lg font-semibold text-red-600 mb-4">Danger Zone</h3>

        <div className="space-y-3">
          {isAdmin && (
            <button className="w-full flex items-center gap-4 p-4 bg-white rounded-xl border border-warm-200 hover:bg-amber-50 hover:border-amber-300 transition-colors">
              <div className="p-2 bg-amber-100 rounded-lg">
                <Crown className="w-5 h-5 text-amber-600" />
              </div>
              <div className="flex-1 text-left">
                <p className="font-medium text-warm-900">Transfer Admin Rights</p>
                <p className="text-sm text-warm-500">Give Head of Household role to another adult</p>
              </div>
              <ChevronRight className="w-5 h-5 text-warm-400" />
            </button>
          )}

          <button
            onClick={() => setShowLeaveHousehold(true)}
            className="w-full flex items-center gap-4 p-4 bg-white rounded-xl border border-red-200 hover:bg-red-50 transition-colors"
          >
            <div className="p-2 bg-red-100 rounded-lg">
              <UserX className="w-5 h-5 text-red-600" />
            </div>
            <div className="flex-1 text-left">
              <p className="font-medium text-red-700">Leave Household</p>
              <p className="text-sm text-red-500">Remove yourself from {user.householdName}</p>
            </div>
          </button>
        </div>
      </div>

      {/* Leave Household Modal */}
      {showLeaveHousehold && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowLeaveHousehold(false)} />
          <div className="relative bg-white rounded-xl shadow-xl p-6 max-w-sm w-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-red-100 rounded-lg">
                <AlertTriangle className="w-6 h-6 text-red-600" />
              </div>
              <h4 className="text-lg font-semibold text-warm-900">Leave Household?</h4>
            </div>
            <p className="text-sm text-warm-600 mb-6">
              You will lose access to all household data, shared projects, and billing history. This action cannot be undone.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowLeaveHousehold(false)}
                className="flex-1 px-4 py-2.5 border border-warm-300 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
              >
                Cancel
              </button>
              <button className="flex-1 px-4 py-2.5 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 transition-colors">
                Leave Household
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Mobile Accordion Item
function MobileAccordionItem({
  title,
  icon: Icon,
  isOpen,
  onToggle,
  children,
}: {
  title: string;
  icon: typeof User;
  isOpen: boolean;
  onToggle: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-3 p-4 text-left"
      >
        <div className="p-2 bg-warm-100 rounded-lg">
          <Icon className="w-5 h-5 text-warm-600" />
        </div>
        <span className="flex-1 font-medium text-warm-900">{title}</span>
        <ChevronDown
          className={`w-5 h-5 text-warm-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
        />
      </button>
      {isOpen && <div className="px-4 pb-4 border-t border-warm-100 pt-4">{children}</div>}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function ProfilePage() {
  const { user: authUser } = useAuth();
  const [activeTab, setActiveTab] = useState<SettingsTab>('details');
  const [mobileAccordion, setMobileAccordion] = useState<SettingsTab | null>('details');

  // Use mock data merged with auth user
  const user = {
    ...mockUserData,
    firstName: authUser?.firstName || mockUserData.firstName,
    lastName: authUser?.lastName || mockUserData.lastName,
    displayName: authUser ? `${authUser.firstName} ${authUser.lastName}` : mockUserData.displayName,
    email: authUser?.email || mockUserData.email,
  };

  const tabs = [
    { id: 'details' as const, label: 'Details', icon: User },
    { id: 'notifications' as const, label: 'Notifications', icon: Bell },
    { id: 'wallet' as const, label: 'Wallet', icon: Wallet },
    { id: 'security' as const, label: 'Security', icon: Shield },
  ];

  return (
    <div className="pb-32 lg:pb-8">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl lg:text-3xl font-bold text-warm-900">My Profile</h1>
        <p className="text-warm-500 mt-1">Manage your personal settings and preferences</p>
      </div>

      {/* Desktop Layout */}
      <div className="hidden lg:grid lg:grid-cols-3 gap-6">
        {/* Left Column - Hero Card (Sticky) */}
        <div className="lg:col-span-1">
          <div className="sticky top-6">
            <HeroCard user={user} onEditAvatar={() => console.log('Edit avatar')} />
          </div>
        </div>

        {/* Right Column - Tabbed Interface */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-xl shadow-sm border border-warm-200 overflow-hidden">
            {/* Tab Navigation */}
            <div className="flex border-b border-warm-200">
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-6 py-4 text-sm font-medium border-b-2 -mb-px transition-colors ${
                    activeTab === tab.id
                      ? 'border-emerald-600 text-emerald-600'
                      : 'border-transparent text-warm-600 hover:text-warm-900'
                  }`}
                >
                  <tab.icon className="w-4 h-4" />
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Tab Content */}
            <div className="p-6">
              {activeTab === 'details' && <PersonalDetailsTab user={user} />}
              {activeTab === 'notifications' && <NotificationsTab />}
              {activeTab === 'wallet' && <WalletTab />}
              {activeTab === 'security' && <SecurityTab user={user} />}
            </div>
          </div>
        </div>
      </div>

      {/* Mobile Layout */}
      <div className="lg:hidden space-y-4">
        {/* Hero Card */}
        <HeroCard user={user} onEditAvatar={() => console.log('Edit avatar')} />

        {/* Accordion Sections */}
        <div className="space-y-3">
          <MobileAccordionItem
            title="Personal Details"
            icon={User}
            isOpen={mobileAccordion === 'details'}
            onToggle={() => setMobileAccordion(mobileAccordion === 'details' ? null : 'details')}
          >
            <PersonalDetailsTab user={user} />
          </MobileAccordionItem>

          <MobileAccordionItem
            title="Notifications"
            icon={Bell}
            isOpen={mobileAccordion === 'notifications'}
            onToggle={() => setMobileAccordion(mobileAccordion === 'notifications' ? null : 'notifications')}
          >
            <NotificationsTab />
          </MobileAccordionItem>

          <MobileAccordionItem
            title="Digital Wallet"
            icon={Wallet}
            isOpen={mobileAccordion === 'wallet'}
            onToggle={() => setMobileAccordion(mobileAccordion === 'wallet' ? null : 'wallet')}
          >
            <WalletTab />
          </MobileAccordionItem>

          <MobileAccordionItem
            title="Privacy & Security"
            icon={Shield}
            isOpen={mobileAccordion === 'security'}
            onToggle={() => setMobileAccordion(mobileAccordion === 'security' ? null : 'security')}
          >
            <SecurityTab user={user} />
          </MobileAccordionItem>
        </div>
      </div>
    </div>
  );
}
