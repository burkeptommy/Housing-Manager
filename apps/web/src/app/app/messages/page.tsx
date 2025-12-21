'use client';

import { useState, useRef, useEffect, useMemo } from 'react';
import Image from 'next/image';
import { getDemoImage } from '@/lib/imageUtils';
import {
  Search,
  Phone,
  Video,
  Info,
  Send,
  Paperclip,
  Camera,
  Calendar,
  X,
  ChevronDown,
  ChevronRight,
  ArrowLeft,
  Check,
  CheckCheck,
  Star,
  Download,
  FileText,
  Users,
  Home,
  Wrench,
  Plane,
  Building2,
  Bell,
  BellOff,
  MoreVertical,
  MapPin,
  Mail,
  ShoppingCart,
  HelpCircle,
  ClipboardList,
  CalendarPlus,
  ListPlus,
  Settings,
  MessageCircle,
  Shield,
  Clock,
  CheckCircle2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ChannelType = 'team' | 'family' | 'vendors' | 'forwarded';
type MessageSender = 'me' | 'them' | 'system' | 'manager';
type FilterType = 'all' | 'unread' | 'needs_response' | 'manager' | 'family';

interface Participant {
  id: string;
  name: string;
  avatar: string;
  role?: string;
  isOnline?: boolean;
  responseTime?: string;
  isManager?: boolean;
}

interface MessageAttachment {
  id: string;
  type: 'image' | 'file' | 'action' | 'forwarded_email';
  url?: string;
  name?: string;
  size?: string;
  actionType?: 'estimate' | 'calendar' | 'flight' | 'hotel';
  actionData?: Record<string, unknown>;
  emailData?: {
    from: string;
    subject: string;
    receivedAt: string;
    handled: boolean;
    handledMessage?: string;
  };
}

interface Message {
  id: string;
  sender: MessageSender;
  senderId?: string;
  senderName?: string;
  content: string;
  timestamp: string;
  status?: 'sent' | 'delivered' | 'read';
  attachments?: MessageAttachment[];
  canConvert?: boolean; // Can be converted to request/calendar/shopping
  convertedTo?: { type: 'request' | 'calendar' | 'shopping'; id: string };
}

interface Conversation {
  id: string;
  channelType: ChannelType;
  title: string;
  subtitle?: string;
  avatar: string;
  participants: Participant[];
  messages: Message[];
  unreadCount: number;
  isPinned?: boolean;
  isManager?: boolean;
  isHandyman?: boolean;
  lastActivity: string;
  isMuted?: boolean;
  managedByManager?: boolean; // For vendor conversations
  managerStatus?: string; // e.g., "Sarah replied", "Sarah handling"
  needsResponse?: boolean;
}

interface ChannelGroup {
  type: ChannelType;
  label: string;
  icon: typeof Users;
  isExpanded: boolean;
  description?: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockParticipants: Record<string, Participant> = {
  manager: {
    id: 'p1',
    name: 'Sarah Harrison',
    avatar: getDemoImage('avatar-female', 100, 100, 'sarah-manager'),
    role: 'Your Home Manager',
    isOnline: true,
    responseTime: 'Replies in ~5m',
    isManager: true,
  },
  handyman: {
    id: 'p2',
    name: 'Mike Rodriguez',
    avatar: getDemoImage('avatar-male', 100, 100, 'mike-handyman'),
    role: 'Your Handyman',
    isOnline: false,
    responseTime: 'Replies in ~1h',
  },
  alice: {
    id: 'p4',
    name: 'Alice Chen',
    avatar: getDemoImage('avatar-female', 100, 100, 'alice-wife'),
    role: 'Family',
    isOnline: true,
  },
  plumber: {
    id: 'p5',
    name: "Mike's Plumbing",
    avatar: getDemoImage('vendor-portrait', 100, 100, 'mikes-plumbing'),
    role: 'Vendor',
    isOnline: false,
  },
  hvac: {
    id: 'p6',
    name: 'AirFlow HVAC',
    avatar: getDemoImage('vendor-portrait', 100, 100, 'airflow-hvac'),
    role: 'Vendor',
    isOnline: false,
  },
};

const mockConversations: Conversation[] = [
  {
    id: 'c1',
    channelType: 'team',
    title: 'Sarah Harrison',
    subtitle: 'Your Home Manager',
    avatar: mockParticipants.manager!.avatar,
    participants: [mockParticipants.manager!],
    unreadCount: 2,
    isPinned: true,
    isManager: true,
    lastActivity: '2024-12-19T10:30:00Z',
    needsResponse: true,
    messages: [
      { id: 'm1', sender: 'them', senderName: 'Sarah', content: 'Good morning! Just wanted to let you know the landscaping crew will be there tomorrow at 9 AM.', timestamp: '2024-12-19T09:00:00Z' },
      { id: 'm2', sender: 'me', content: 'Perfect, thanks for the heads up!', timestamp: '2024-12-19T09:05:00Z', status: 'read' },
      { id: 'm3', sender: 'them', senderName: 'Sarah', content: "Also, I got a quote from the HVAC company for the annual service.", timestamp: '2024-12-19T10:00:00Z', attachments: [{ id: 'a1', type: 'action', actionType: 'estimate', actionData: { vendor: 'AirFlow HVAC', amount: 299, description: 'Annual HVAC maintenance and inspection', validUntil: '2024-12-26' } }] },
      { id: 'm4', sender: 'them', senderName: 'Sarah', content: 'Do you want me to go ahead and schedule this?', timestamp: '2024-12-19T10:30:00Z' },
    ],
  },
  {
    id: 'c2',
    channelType: 'team',
    title: 'Mike Rodriguez',
    subtitle: 'Your Handyman',
    avatar: mockParticipants.handyman!.avatar,
    participants: [mockParticipants.handyman!],
    unreadCount: 0,
    isPinned: true,
    isHandyman: true,
    lastActivity: '2024-12-18T16:00:00Z',
    messages: [
      { id: 'm1', sender: 'me', content: 'Hi Mike, the kitchen faucet is still dripping after your visit.', timestamp: '2024-12-18T14:00:00Z', status: 'read' },
      { id: 'm2', sender: 'them', senderName: 'Mike', content: "I'll swing by tomorrow morning to take another look. The washer might need a full replacement.", timestamp: '2024-12-18T14:30:00Z' },
      { id: 'm3', sender: 'me', content: "Sounds good, I'll be home until noon.", timestamp: '2024-12-18T14:35:00Z', status: 'read' },
      { id: 'm4', sender: 'them', senderName: 'Mike', content: "Great, I'll be there around 9. See you then!", timestamp: '2024-12-18T16:00:00Z' },
    ],
  },
  {
    id: 'c3',
    channelType: 'family',
    title: 'Chen Family',
    subtitle: 'Alice, Emma, Jake',
    avatar: getDemoImage('avatar-female', 100, 100, 'family-group'),
    participants: [mockParticipants.alice!],
    unreadCount: 5,
    lastActivity: '2024-12-19T09:30:00Z',
    messages: [
      { id: 'm1', sender: 'them', senderId: 'p4', senderName: 'Alice', content: "Don't forget Emma has soccer practice at 4!", timestamp: '2024-12-19T08:00:00Z', canConvert: true },
      { id: 'm2', sender: 'me', content: 'Got it! I can pick her up.', timestamp: '2024-12-19T08:05:00Z', status: 'read' },
      { id: 'm3', sender: 'them', senderId: 'p4', senderName: 'Alice', content: 'Perfect. Also, Jake needs his science project supplies.', timestamp: '2024-12-19T09:00:00Z', canConvert: true },
      { id: 'm4', sender: 'them', senderId: 'p4', senderName: 'Alice', content: 'Can you pick up: poster board, glue sticks, and markers', timestamp: '2024-12-19T09:30:00Z', canConvert: true },
    ],
  },
  {
    id: 'c4',
    channelType: 'vendors',
    title: "Mike's Plumbing",
    subtitle: 'Kitchen faucet repair',
    avatar: mockParticipants.plumber!.avatar,
    participants: [mockParticipants.plumber!],
    unreadCount: 0,
    lastActivity: '2024-12-17T12:00:00Z',
    managedByManager: true,
    managerStatus: 'Sarah replied',
    messages: [
      { id: 'm1', sender: 'system', content: "Work order #WO-001 assigned to Mike's Plumbing", timestamp: '2024-12-16T10:00:00Z' },
      { id: 'm2', sender: 'them', senderName: "Mike's Plumbing", content: "We'll be there tomorrow between 2-4 PM.", timestamp: '2024-12-16T11:00:00Z' },
      { id: 'm3', sender: 'manager', senderName: 'Sarah', content: 'Confirmed. The homeowner will be available. Gate code is 1234.', timestamp: '2024-12-16T11:30:00Z' },
      { id: 'm4', sender: 'them', senderName: "Mike's Plumbing", content: 'Job completed. Here\'s the photo of the repaired faucet:', timestamp: '2024-12-17T12:00:00Z', attachments: [{ id: 'a1', type: 'image', url: getDemoImage('kitchen', 400, 300, 'repaired-faucet') }] },
      { id: 'm5', sender: 'manager', senderName: 'Sarah', content: 'Perfect, thank you! Invoice received and processed.', timestamp: '2024-12-17T12:30:00Z' },
    ],
  },
  {
    id: 'c5',
    channelType: 'vendors',
    title: 'AirFlow HVAC',
    subtitle: 'Annual maintenance scheduling',
    avatar: mockParticipants.hvac!.avatar,
    participants: [mockParticipants.hvac!],
    unreadCount: 1,
    lastActivity: '2024-12-19T09:00:00Z',
    managedByManager: true,
    managerStatus: 'Sarah handling',
    messages: [
      { id: 'm1', sender: 'manager', senderName: 'Sarah', content: "Hi, I'd like to schedule the annual HVAC maintenance for the Chen residence.", timestamp: '2024-12-18T14:00:00Z' },
      { id: 'm2', sender: 'them', senderName: 'AirFlow HVAC', content: "We have availability next week. Here's our quote for the service.", timestamp: '2024-12-18T15:00:00Z', attachments: [{ id: 'a1', type: 'action', actionType: 'estimate', actionData: { vendor: 'AirFlow HVAC', amount: 299, description: 'Annual HVAC maintenance', validUntil: '2024-12-26' } }] },
      { id: 'm3', sender: 'manager', senderName: 'Sarah', content: "Thank you. I'll confirm with the homeowner and get back to you.", timestamp: '2024-12-19T09:00:00Z' },
    ],
  },
  {
    id: 'c6',
    channelType: 'forwarded',
    title: 'ConEd',
    subtitle: 'December Bill',
    avatar: getDemoImage('vendor-portrait', 100, 100, 'coned-logo'),
    participants: [],
    unreadCount: 0,
    lastActivity: '2024-12-19T08:00:00Z',
    managedByManager: true,
    managerStatus: 'Handled',
    messages: [
      {
        id: 'm1',
        sender: 'system',
        content: 'Email forwarded to Haven',
        timestamp: '2024-12-19T07:00:00Z',
        attachments: [{
          id: 'e1',
          type: 'forwarded_email',
          emailData: {
            from: 'billing@coned.com',
            subject: 'Your December Bill is Ready',
            receivedAt: '2024-12-19T07:00:00Z',
            handled: true,
            handledMessage: "$187.43 electric bill. I'll add it to your December statement and pay it.",
          },
        }],
      },
      { id: 'm2', sender: 'manager', senderName: 'Sarah', content: "Got it - $187.43 electric bill. I'll add it to your December statement and pay it by the due date.", timestamp: '2024-12-19T08:00:00Z' },
    ],
  },
  {
    id: 'c7',
    channelType: 'forwarded',
    title: 'Home Warranty Co',
    subtitle: 'Warranty Renewal',
    avatar: getDemoImage('vendor-portrait', 100, 100, 'warranty-logo'),
    participants: [],
    unreadCount: 1,
    lastActivity: '2024-12-18T14:00:00Z',
    managedByManager: true,
    managerStatus: 'Sarah reviewing',
    needsResponse: true,
    messages: [
      {
        id: 'm1',
        sender: 'system',
        content: 'Email forwarded to Haven',
        timestamp: '2024-12-18T10:00:00Z',
        attachments: [{
          id: 'e1',
          type: 'forwarded_email',
          emailData: {
            from: 'renewals@homewarranty.com',
            subject: 'Your Home Warranty Expires in 30 Days',
            receivedAt: '2024-12-18T10:00:00Z',
            handled: false,
          },
        }],
      },
      { id: 'm2', sender: 'manager', senderName: 'Sarah', content: "I've reviewed the renewal options. Your current plan is $450/year. They're offering a 3-year lock at $399/year. Given the age of your HVAC, I recommend renewing. Should I proceed?", timestamp: '2024-12-18T14:00:00Z' },
    ],
  },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function formatTime(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  } else if (diffDays === 1) {
    return 'Yesterday';
  } else if (diffDays < 7) {
    return date.toLocaleDateString('en-US', { weekday: 'short' });
  } else {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Online Indicator
function OnlineIndicator({ isOnline }: { isOnline: boolean }) {
  return (
    <div className={`absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full border-2 border-white ${
      isOnline ? 'bg-emerald-500' : 'bg-slate-400'
    }`} />
  );
}

// Manager Badge
function ManagerBadge() {
  return (
    <div className="absolute -top-1 -right-1 w-5 h-5 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center shadow-sm">
      <Star className="w-3 h-3 text-white fill-white" />
    </div>
  );
}

// Managed By Sarah Label
function ManagedLabel({ status }: { status: string }) {
  const isHandled = status === 'Handled' || status === 'Sarah replied';
  return (
    <span className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full ${
      isHandled ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
    }`}>
      {isHandled ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
      {status}
    </span>
  );
}

// Filter Tabs
function FilterTabs({
  activeFilter,
  onFilterChange,
  counts,
}: {
  activeFilter: FilterType;
  onFilterChange: (filter: FilterType) => void;
  counts: Record<FilterType, number>;
}) {
  const filters: { type: FilterType; label: string }[] = [
    { type: 'all', label: 'All' },
    { type: 'unread', label: 'Unread' },
    { type: 'needs_response', label: 'Needs Response' },
    { type: 'manager', label: 'Sarah' },
    { type: 'family', label: 'Family' },
  ];

  return (
    <div className="flex gap-1 overflow-x-auto pb-2 -mx-4 px-4">
      {filters.map(({ type, label }) => (
        <button
          key={type}
          onClick={() => onFilterChange(type)}
          className={`flex-shrink-0 px-3 py-1.5 text-sm font-medium rounded-full transition-colors ${
            activeFilter === type
              ? 'bg-emerald-600 text-white'
              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
          }`}
        >
          {label}
          {counts[type] > 0 && type !== 'all' && (
            <span className={`ml-1.5 px-1.5 py-0.5 text-xs rounded-full ${
              activeFilter === type ? 'bg-white/20' : 'bg-slate-200'
            }`}>
              {counts[type]}
            </span>
          )}
        </button>
      ))}
    </div>
  );
}

// Conversation List Item
function ConversationItem({
  conversation,
  isSelected,
  onClick,
}: {
  conversation: Conversation;
  isSelected: boolean;
  onClick: () => void;
}) {
  const lastMessage = conversation.messages[conversation.messages.length - 1];
  const participant = conversation.participants[0];
  const isManagerChat = conversation.isManager;
  const showManagedLabel = conversation.managedByManager && conversation.managerStatus;

  return (
    <button
      onClick={onClick}
      className={`w-full flex items-start gap-3 p-3 text-left transition-colors ${
        isSelected
          ? 'bg-emerald-50 border-l-4 border-l-emerald-600'
          : isManagerChat
          ? 'bg-gradient-to-r from-emerald-50/50 to-transparent hover:from-emerald-50 border-l-4 border-l-emerald-400'
          : 'hover:bg-slate-50 border-l-4 border-l-transparent'
      }`}
    >
      <div className="relative flex-shrink-0">
        <div className={`w-12 h-12 rounded-full overflow-hidden ${isManagerChat ? 'ring-2 ring-emerald-400 ring-offset-2' : 'bg-slate-200'}`}>
          <Image src={conversation.avatar} alt="" width={48} height={48} className="object-cover" />
        </div>
        {isManagerChat && <ManagerBadge />}
        {participant && <OnlineIndicator isOnline={participant.isOnline ?? false} />}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 min-w-0">
            <span className={`font-medium truncate ${conversation.unreadCount > 0 ? 'text-slate-900' : 'text-slate-700'}`}>
              {isManagerChat && <MessageCircle className="w-3.5 h-3.5 inline mr-1 text-emerald-600" />}
              {conversation.title}
            </span>
            {participant?.isOnline && isManagerChat && (
              <span className="text-xs text-emerald-600 font-medium">Online</span>
            )}
          </div>
          <span className="text-xs text-slate-500 flex-shrink-0">
            {formatTime(conversation.lastActivity)}
          </span>
        </div>

        {conversation.subtitle && (
          <p className="text-xs text-slate-500 truncate">{conversation.subtitle}</p>
        )}

        {showManagedLabel && (
          <div className="mt-1">
            <ManagedLabel status={conversation.managerStatus!} />
          </div>
        )}

        {lastMessage && !showManagedLabel && (
          <p className={`text-sm truncate mt-0.5 ${conversation.unreadCount > 0 ? 'text-slate-900 font-medium' : 'text-slate-500'}`}>
            {lastMessage.sender === 'me' && <span className="text-slate-400">You: </span>}
            {lastMessage.sender === 'manager' && <span className="text-emerald-600">Sarah: </span>}
            {lastMessage.content}
          </p>
        )}
      </div>

      {conversation.unreadCount > 0 && !conversation.managedByManager && (
        <div className="flex-shrink-0 w-5 h-5 bg-emerald-600 rounded-full flex items-center justify-center">
          <span className="text-xs text-white font-medium">{conversation.unreadCount}</span>
        </div>
      )}

      {conversation.needsResponse && (
        <div className="flex-shrink-0 w-2 h-2 bg-amber-500 rounded-full animate-pulse" />
      )}
    </button>
  );
}

// Channel Group Header
function ChannelGroupHeader({
  group,
  count,
  onToggle,
}: {
  group: ChannelGroup;
  count: number;
  onToggle: () => void;
}) {
  const Icon = group.icon;
  return (
    <div>
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50"
      >
        {group.isExpanded ? (
          <ChevronDown className="w-4 h-4" />
        ) : (
          <ChevronRight className="w-4 h-4" />
        )}
        <Icon className="w-4 h-4" />
        <span>{group.label}</span>
        <span className="ml-auto text-xs text-slate-400">{count}</span>
      </button>
      {group.description && !group.isExpanded && (
        <p className="px-9 pb-2 text-xs text-slate-500">{group.description}</p>
      )}
    </div>
  );
}

// Vendor Section Header (collapsed view)
function VendorSectionHeader({
  conversations,
  isExpanded,
  onToggle,
}: {
  conversations: Conversation[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const handledCount = conversations.filter(c => c.managerStatus === 'Handled' || c.managerStatus === 'Sarah replied').length;

  return (
    <div className="bg-slate-50 border-y border-slate-200">
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-2 px-3 py-3 text-left"
      >
        <div className="flex items-center gap-2 flex-1">
          <Shield className="w-4 h-4 text-emerald-600" />
          <div>
            <p className="text-sm font-medium text-slate-700">Vendor Updates</p>
            <p className="text-xs text-slate-500">Managed by Sarah</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
            {handledCount}/{conversations.length} handled
          </span>
          {isExpanded ? (
            <ChevronDown className="w-4 h-4 text-slate-400" />
          ) : (
            <ChevronRight className="w-4 h-4 text-slate-400" />
          )}
        </div>
      </button>

      {!isExpanded && (
        <div className="px-3 pb-3">
          <p className="text-xs text-slate-500 bg-white rounded-lg p-2 border border-slate-200">
            These conversations are handled by your manager. You'll only see messages that need your input.
          </p>
        </div>
      )}
    </div>
  );
}

// Forwarded Email Card
function ForwardedEmailCard({ attachment }: { attachment: MessageAttachment }) {
  if (attachment.type !== 'forwarded_email' || !attachment.emailData) return null;
  const { from, subject, handled, handledMessage } = attachment.emailData;

  return (
    <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 my-2">
      <div className="flex items-start gap-3">
        <div className="p-2 bg-blue-100 rounded-lg">
          <Mail className="w-4 h-4 text-blue-600" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-blue-900">Forwarded Email</p>
          <p className="text-xs text-blue-700 truncate">From: {from}</p>
          <p className="text-xs text-blue-700 truncate">Subject: {subject}</p>

          {handled && handledMessage && (
            <div className="mt-2 pt-2 border-t border-blue-200">
              <p className="text-xs text-emerald-700 font-medium flex items-center gap-1">
                <CheckCircle2 className="w-3 h-3" />
                Sarah: "{handledMessage}"
              </p>
            </div>
          )}
        </div>
        {handled && (
          <span className="flex-shrink-0 text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded-full font-medium flex items-center gap-1">
            <Check className="w-3 h-3" />
            Handled
          </span>
        )}
      </div>
    </div>
  );
}

// Quick Request Buttons (for manager chat)
function QuickRequestButtons({
  onRequest,
}: {
  onRequest: (type: 'broken' | 'schedule' | 'buy' | 'question') => void;
}) {
  const buttons = [
    { type: 'broken' as const, icon: Wrench, label: "Something's broken" },
    { type: 'schedule' as const, icon: Calendar, label: 'Schedule something' },
    { type: 'buy' as const, icon: ShoppingCart, label: 'Buy something' },
    { type: 'question' as const, icon: HelpCircle, label: 'Question' },
  ];

  return (
    <div className="border-t border-slate-100 pt-2 pb-1">
      <p className="text-xs text-slate-500 mb-2 px-1">Quick requests:</p>
      <div className="flex flex-wrap gap-1.5">
        {buttons.map(({ type, icon: Icon, label }) => (
          <button
            key={type}
            onClick={() => onRequest(type)}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-slate-100 text-slate-700 rounded-full hover:bg-emerald-100 hover:text-emerald-700 transition-colors"
          >
            <Icon className="w-3.5 h-3.5" />
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}

// Message Action Menu (convert to task)
function MessageActionMenu({
  message,
  onConvert,
  onClose,
}: {
  message: Message;
  onConvert: (type: 'request' | 'calendar' | 'shopping') => void;
  onClose: () => void;
}) {
  if (message.convertedTo) {
    return (
      <div className="absolute top-full left-0 mt-1 bg-white rounded-lg shadow-lg border border-slate-200 p-2 z-10">
        <p className="text-xs text-emerald-600 flex items-center gap-1">
          <CheckCircle2 className="w-3 h-3" />
          Added to {message.convertedTo.type}
        </p>
      </div>
    );
  }

  return (
    <div className="absolute top-full left-0 mt-1 bg-white rounded-lg shadow-lg border border-slate-200 py-1 z-10 min-w-[160px]">
      <button
        onClick={() => { onConvert('request'); onClose(); }}
        className="w-full flex items-center gap-2 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
      >
        <ClipboardList className="w-4 h-4 text-slate-500" />
        Make this a request
      </button>
      <button
        onClick={() => { onConvert('calendar'); onClose(); }}
        className="w-full flex items-center gap-2 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
      >
        <CalendarPlus className="w-4 h-4 text-slate-500" />
        Add to calendar
      </button>
      <button
        onClick={() => { onConvert('shopping'); onClose(); }}
        className="w-full flex items-center gap-2 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
      >
        <ListPlus className="w-4 h-4 text-slate-500" />
        Add to shopping list
      </button>
    </div>
  );
}

// Message Bubble
function MessageBubble({
  message,
  showSender,
  onConvert,
}: {
  message: Message;
  showSender: boolean;
  onConvert?: (messageId: string, type: 'request' | 'calendar' | 'shopping') => void;
}) {
  const [showActionMenu, setShowActionMenu] = useState(false);
  const isMe = message.sender === 'me';
  const isSystem = message.sender === 'system';
  const isManager = message.sender === 'manager';

  if (isSystem) {
    // Check for forwarded email
    const emailAttachment = message.attachments?.find(a => a.type === 'forwarded_email');
    if (emailAttachment) {
      return <ForwardedEmailCard attachment={emailAttachment} />;
    }

    return (
      <div className="flex justify-center my-4">
        <span className="text-xs text-slate-500 bg-slate-100 px-3 py-1.5 rounded-full">
          {message.content}
        </span>
      </div>
    );
  }

  return (
    <div className={`flex ${isMe ? 'justify-end' : 'justify-start'} group relative`}>
      <div className={`max-w-[70%] ${isMe ? 'order-2' : 'order-1'}`}>
        {showSender && !isMe && message.senderName && (
          <p className={`text-xs font-medium mb-1 ml-3 ${isManager ? 'text-emerald-600' : 'text-slate-600'}`}>
            {isManager && <Star className="w-3 h-3 inline mr-1" />}
            {message.senderName}
          </p>
        )}
        <div
          className={`px-4 py-2.5 ${
            isMe
              ? 'bg-emerald-600 text-white rounded-2xl rounded-tr-sm'
              : isManager
              ? 'bg-emerald-50 border border-emerald-200 text-slate-800 rounded-2xl rounded-tl-sm'
              : 'bg-white border border-slate-200 text-slate-800 rounded-2xl rounded-tl-sm shadow-sm'
          }`}
        >
          <p className="text-sm whitespace-pre-wrap">{message.content}</p>

          {/* Attachments */}
          {message.attachments?.map((attachment) => (
            <div key={attachment.id} className="mt-2">
              {attachment.type === 'image' && attachment.url && (
                <div className="relative w-full max-w-xs rounded-lg overflow-hidden">
                  <Image
                    src={attachment.url}
                    alt=""
                    width={300}
                    height={200}
                    className="object-cover"
                  />
                </div>
              )}

              {attachment.type === 'file' && (
                <div className={`flex items-center gap-3 p-3 rounded-lg ${isMe ? 'bg-emerald-700' : 'bg-slate-50'}`}>
                  <FileText className="w-8 h-8 text-slate-400" />
                  <div className="flex-1 min-w-0">
                    <p className={`text-sm font-medium truncate ${isMe ? 'text-white' : 'text-slate-900'}`}>
                      {attachment.name}
                    </p>
                    <p className={`text-xs ${isMe ? 'text-emerald-200' : 'text-slate-500'}`}>
                      {attachment.size}
                    </p>
                  </div>
                  <Download className={`w-5 h-5 ${isMe ? 'text-white' : 'text-slate-400'}`} />
                </div>
              )}

              {attachment.type === 'action' && attachment.actionType === 'estimate' && (
                <div className="bg-white border border-slate-200 rounded-xl p-4 mt-2 shadow-sm">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 bg-amber-100 rounded-lg">
                      <FileText className="w-4 h-4 text-amber-600" />
                    </div>
                    <span className="font-medium text-slate-900">Estimate</span>
                  </div>
                  <p className="text-sm text-slate-600 mb-2">
                    {(attachment.actionData?.description as string) || 'Service estimate'}
                  </p>
                  <p className="text-2xl font-bold text-slate-900 mb-3">
                    ${((attachment.actionData?.amount as number) || 0).toLocaleString()}
                  </p>
                  <div className="flex gap-2">
                    <button className="flex-1 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                      Approve
                    </button>
                    <button className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors">
                      Decline
                    </button>
                  </div>
                </div>
              )}

              {attachment.type === 'action' && attachment.actionType === 'flight' && (
                <div className="bg-white border border-slate-200 rounded-xl p-4 mt-2 shadow-sm">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 bg-blue-100 rounded-lg">
                      <Plane className="w-4 h-4 text-blue-600" />
                    </div>
                    <span className="font-medium text-slate-900">Flight Option</span>
                  </div>
                  <p className="text-sm font-medium text-slate-900 mb-1">
                    {attachment.actionData?.airline as string}
                  </p>
                  <div className="flex items-center gap-2 text-sm text-slate-600 mb-2">
                    <span>{attachment.actionData?.departure as string}</span>
                    <span>→</span>
                    <span>{attachment.actionData?.arrival as string}</span>
                  </div>
                  <p className="text-xs text-slate-500 mb-3">
                    {attachment.actionData?.departDate as string} - {attachment.actionData?.returnDate as string} • {attachment.actionData?.passengers as number} passengers
                  </p>
                  <div className="flex items-center justify-between">
                    <p className="text-xl font-bold text-slate-900">
                      ${((attachment.actionData?.price as number) || 0).toLocaleString()}
                    </p>
                    <button className="px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors">
                      Book Flight
                    </button>
                  </div>
                </div>
              )}

              {attachment.type === 'action' && attachment.actionType === 'hotel' && (
                <div className="bg-white border border-slate-200 rounded-xl p-4 mt-2 shadow-sm">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 bg-purple-100 rounded-lg">
                      <Building2 className="w-4 h-4 text-purple-600" />
                    </div>
                    <span className="font-medium text-slate-900">Hotel Recommendation</span>
                  </div>
                  <p className="text-sm font-medium text-slate-900 mb-1">
                    {attachment.actionData?.name as string}
                  </p>
                  <div className="flex items-center gap-2 text-sm text-slate-600 mb-2">
                    <MapPin className="w-3 h-3" />
                    <span>{attachment.actionData?.location as string}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-slate-500 mb-3">
                    <span>{attachment.actionData?.checkIn as string} - {attachment.actionData?.checkOut as string}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
                      {attachment.actionData?.rating as number}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-xl font-bold text-slate-900">
                        ${((attachment.actionData?.pricePerNight as number) || 0).toLocaleString()}
                      </p>
                      <p className="text-xs text-slate-500">per night</p>
                    </div>
                    <button className="px-4 py-2 bg-purple-600 text-white font-medium rounded-lg hover:bg-purple-700 transition-colors">
                      Book Hotel
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className={`flex items-center gap-1 mt-1 ${isMe ? 'justify-end' : 'justify-start'} px-3`}>
          <span className="text-xs text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity">
            {formatTime(message.timestamp)}
          </span>
          {isMe && message.status && (
            <span className="text-xs text-slate-400">
              {message.status === 'read' ? (
                <CheckCheck className="w-3.5 h-3.5 text-emerald-500" />
              ) : (
                <Check className="w-3.5 h-3.5" />
              )}
            </span>
          )}

          {/* Convert action */}
          {message.canConvert && onConvert && (
            <button
              onClick={() => setShowActionMenu(!showActionMenu)}
              className="ml-2 p-1 hover:bg-slate-100 rounded opacity-0 group-hover:opacity-100 transition-opacity"
            >
              <MoreVertical className="w-3.5 h-3.5 text-slate-400" />
            </button>
          )}
        </div>

        {showActionMenu && message.canConvert && onConvert && (
          <MessageActionMenu
            message={message}
            onConvert={(type) => onConvert(message.id, type)}
            onClose={() => setShowActionMenu(false)}
          />
        )}
      </div>
    </div>
  );
}

// Info Drawer
function InfoDrawer({
  conversation,
  onClose,
  onCall,
  onVideoCall,
  onMuteToggle,
  onNotificationSettings,
}: {
  conversation: Conversation;
  onClose: () => void;
  onCall?: () => void;
  onVideoCall?: () => void;
  onMuteToggle?: () => void;
  onNotificationSettings?: () => void;
}) {
  const participant = conversation.participants[0];
  const allImages = conversation.messages
    .flatMap((m) => m.attachments?.filter((a) => a.type === 'image') || []);

  return (
    <div className="w-80 border-l border-slate-200 bg-white flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-slate-200 flex items-center justify-between">
        <h3 className="font-semibold text-slate-900">Details</h3>
        <button onClick={onClose} className="p-1 hover:bg-slate-100 rounded-lg">
          <X className="w-5 h-5 text-slate-500" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* Profile */}
        <div className="p-6 text-center border-b border-slate-200">
          <div className="relative w-20 h-20 mx-auto mb-3">
            <div className={`w-20 h-20 rounded-full overflow-hidden ${conversation.isManager ? 'ring-2 ring-emerald-400 ring-offset-2' : 'bg-slate-200'}`}>
              <Image src={conversation.avatar} alt="" width={80} height={80} className="object-cover" />
            </div>
            {conversation.isManager && (
              <div className="absolute -top-1 -right-1 w-6 h-6 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center">
                <Star className="w-3.5 h-3.5 text-white fill-white" />
              </div>
            )}
          </div>
          <h4 className="font-semibold text-slate-900">{conversation.title}</h4>
          {participant?.role && (
            <p className="text-sm text-slate-500">{participant.role}</p>
          )}
          {participant?.responseTime && (
            <p className="text-xs text-emerald-600 mt-1">{participant.responseTime}</p>
          )}

          {conversation.managedByManager && (
            <div className="mt-3">
              <ManagedLabel status={conversation.managerStatus || 'Sarah handling'} />
            </div>
          )}
        </div>

        {/* Actions */}
        {!conversation.managedByManager && (
          <div className="p-4 border-b border-slate-200">
            <div className="flex justify-center gap-4">
              <button
                onClick={onCall}
                className="flex flex-col items-center gap-1 p-3 hover:bg-slate-50 rounded-xl transition-colors"
              >
                <div className="p-2 bg-emerald-100 rounded-full">
                  <Phone className="w-5 h-5 text-emerald-600" />
                </div>
                <span className="text-xs text-slate-600">Call</span>
              </button>
              <button
                onClick={onVideoCall}
                className="flex flex-col items-center gap-1 p-3 hover:bg-slate-50 rounded-xl transition-colors"
              >
                <div className="p-2 bg-blue-100 rounded-full">
                  <Video className="w-5 h-5 text-blue-600" />
                </div>
                <span className="text-xs text-slate-600">Video</span>
              </button>
              <button className="flex flex-col items-center gap-1 p-3 hover:bg-slate-50 rounded-xl transition-colors">
                <div className="p-2 bg-slate-100 rounded-full">
                  <MoreVertical className="w-5 h-5 text-slate-600" />
                </div>
                <span className="text-xs text-slate-600">More</span>
              </button>
            </div>
          </div>
        )}

        {/* Shared Media */}
        {allImages.length > 0 && (
          <div className="p-4 border-b border-slate-200">
            <h5 className="text-sm font-medium text-slate-900 mb-3 flex items-center gap-2">
              <Camera className="w-4 h-4 text-slate-500" />
              Shared Photos ({allImages.length})
            </h5>
            <div className="grid grid-cols-3 gap-2">
              {allImages.slice(0, 6).map((img) => (
                <div key={img.id} className="aspect-square rounded-lg overflow-hidden bg-slate-100">
                  <Image src={img.url!} alt="" width={100} height={100} className="object-cover w-full h-full" />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Participants */}
        {conversation.participants.length > 0 && (
          <div className="p-4 border-b border-slate-200">
            <h5 className="text-sm font-medium text-slate-900 mb-3 flex items-center gap-2">
              <Users className="w-4 h-4 text-slate-500" />
              Participants
            </h5>
            <div className="space-y-2">
              {conversation.participants.map((p) => (
                <div key={p.id} className="flex items-center gap-3 p-2">
                  <div className="relative w-8 h-8 rounded-full overflow-hidden bg-slate-200">
                    <Image src={p.avatar} alt="" width={32} height={32} className="object-cover" />
                  </div>
                  <div className="flex-1">
                    <span className="text-sm text-slate-900">{p.name}</span>
                    {p.role && <p className="text-xs text-slate-500">{p.role}</p>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Notifications */}
        <div className="p-4">
          <h5 className="text-sm font-medium text-slate-900 mb-3">Notifications</h5>
          <div className="space-y-2">
            <button
              onClick={onMuteToggle}
              className="w-full flex items-center gap-3 p-3 text-left hover:bg-slate-50 rounded-lg transition-colors"
            >
              {conversation.isMuted ? (
                <BellOff className="w-5 h-5 text-slate-500" />
              ) : (
                <Bell className="w-5 h-5 text-slate-500" />
              )}
              <span className="text-sm text-slate-700">
                {conversation.isMuted ? 'Unmute Notifications' : 'Mute Notifications'}
              </span>
            </button>
            <button
              onClick={onNotificationSettings}
              className="w-full flex items-center gap-3 p-3 text-left hover:bg-slate-50 rounded-lg transition-colors"
            >
              <Settings className="w-5 h-5 text-slate-500" />
              <span className="text-sm text-slate-700">Notification Preferences</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Notification Preferences Modal
function NotificationPreferencesModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: () => void;
}) {
  const [prefs, setPrefs] = useState({
    manager: 'always',
    handyman: 'scheduled',
    vendors: 'mentioned',
    family: 'always',
  });

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-md shadow-xl">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <h2 className="text-lg font-bold text-slate-900">Notification Preferences</h2>
          <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-lg">
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        <div className="p-4 space-y-4">
          <p className="text-sm text-slate-600">What should you be notified about?</p>

          {[
            { key: 'manager', label: 'Manager messages', icon: Star, recommended: 'Always' },
            { key: 'handyman', label: 'Handyman updates', icon: Wrench, recommended: 'When scheduled at your home' },
            { key: 'vendors', label: 'Vendor updates', icon: Building2, recommended: 'Only when mentioned' },
            { key: 'family', label: 'Family messages', icon: Home, recommended: 'Always' },
          ].map(({ key, label, icon: Icon, recommended }) => (
            <div key={key} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center gap-3">
                <Icon className="w-5 h-5 text-slate-500" />
                <div>
                  <p className="text-sm font-medium text-slate-900">{label}</p>
                  <p className="text-xs text-slate-500">Recommended: {recommended}</p>
                </div>
              </div>
              <select
                value={prefs[key as keyof typeof prefs]}
                onChange={(e) => setPrefs({ ...prefs, [key]: e.target.value })}
                className="text-sm border border-slate-200 rounded-lg px-2 py-1"
              >
                <option value="always">Always</option>
                <option value="scheduled">When scheduled</option>
                <option value="mentioned">When mentioned</option>
                <option value="never">Never</option>
              </select>
            </div>
          ))}
        </div>

        <div className="p-4 border-t border-slate-200 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 font-medium rounded-lg hover:bg-slate-50"
          >
            Cancel
          </button>
          <button
            onClick={() => { onSave(); onClose(); }}
            className="flex-1 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700"
          >
            Save Preferences
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function MessagesPage() {
  const [conversations, setConversations] = useState(mockConversations);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [showInfoDrawer, setShowInfoDrawer] = useState(false);
  const [messageInput, setMessageInput] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');
  const [showVendors, setShowVendors] = useState(false);
  const [showNotificationPrefs, setShowNotificationPrefs] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Toast helper
  const showToast = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 3000);
  };

  const [channelGroups, setChannelGroups] = useState<ChannelGroup[]>([
    { type: 'family', label: 'Family', icon: Home, isExpanded: true },
    { type: 'forwarded', label: 'Forwarded Emails', icon: Mail, isExpanded: true, description: 'Emails you forwarded to Haven' },
  ]);

  // Computed values
  const teamConversations = useMemo(() =>
    conversations.filter((c) => c.channelType === 'team'),
  [conversations]);

  const vendorConversations = useMemo(() =>
    conversations.filter((c) => c.channelType === 'vendors'),
  [conversations]);

  const getConversationsByType = (type: ChannelType) =>
    conversations.filter((c) => c.channelType === type);

  // Filter counts (smart unread - only count manager/family for badge)
  const filterCounts = useMemo(() => ({
    all: conversations.length,
    unread: conversations.filter(c => c.unreadCount > 0 && !c.managedByManager).length,
    needs_response: conversations.filter(c => c.needsResponse).length,
    manager: teamConversations.filter(c => c.isManager).length,
    family: getConversationsByType('family').length,
  }), [conversations, teamConversations]);

  // Filtered conversations
  const filteredConversations = useMemo(() => {
    let result = conversations;

    if (searchQuery) {
      result = result.filter(
        (c) =>
          c.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.subtitle?.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    switch (activeFilter) {
      case 'unread':
        result = result.filter(c => c.unreadCount > 0);
        break;
      case 'needs_response':
        result = result.filter(c => c.needsResponse);
        break;
      case 'manager':
        result = result.filter(c => c.isManager);
        break;
      case 'family':
        result = result.filter(c => c.channelType === 'family');
        break;
    }

    return result;
  }, [conversations, searchQuery, activeFilter]);

  const toggleChannelGroup = (type: ChannelType) => {
    setChannelGroups((groups) =>
      groups.map((g) => (g.type === type ? { ...g, isExpanded: !g.isExpanded } : g))
    );
  };

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [selectedConversation?.messages]);

  const handleSend = () => {
    if (!messageInput.trim() || !selectedConversation) return;

    const newMessage: Message = {
      id: `msg-${Date.now()}`,
      sender: 'me',
      content: messageInput.trim(),
      timestamp: new Date().toISOString(),
      status: 'sent',
    };

    const updatedConversation = {
      ...selectedConversation,
      messages: [...selectedConversation.messages, newMessage],
      lastActivity: new Date().toISOString(),
      needsResponse: false,
    };

    setConversations(prev =>
      prev.map(c => c.id === selectedConversation.id ? updatedConversation : c)
    );
    setSelectedConversation(updatedConversation);
    setMessageInput('');

    // Simulate delivery
    setTimeout(() => {
      setConversations(prev =>
        prev.map(c => {
          if (c.id === selectedConversation.id) {
            const msgs = c.messages.map(m =>
              m.id === newMessage.id ? { ...m, status: 'delivered' as const } : m
            );
            return { ...c, messages: msgs };
          }
          return c;
        })
      );
    }, 1000);
  };

  // Quick request handler
  const handleQuickRequest = (type: 'broken' | 'schedule' | 'buy' | 'question') => {
    const messages: Record<typeof type, string> = {
      broken: "Something in my home needs fixing...",
      schedule: "I need to schedule...",
      buy: "I need you to buy...",
      question: "I have a question about...",
    };
    setMessageInput(messages[type]);
  };

  // Convert message to task
  const handleConvertMessage = (messageId: string, type: 'request' | 'calendar' | 'shopping') => {
    if (!selectedConversation) return;

    const updatedMessages = selectedConversation.messages.map(m =>
      m.id === messageId ? { ...m, convertedTo: { type, id: `${type}-${Date.now()}` } } : m
    );

    const updatedConversation = { ...selectedConversation, messages: updatedMessages };
    setConversations(prev =>
      prev.map(c => c.id === selectedConversation.id ? updatedConversation : c)
    );
    setSelectedConversation(updatedConversation);

    const typeLabels = { request: 'Help Requests', calendar: 'Calendar', shopping: 'Shopping List' };
    showToast(`Added to ${typeLabels[type]}`);
  };

  // Handle call
  const handleCall = (participant?: Participant) => {
    const name = participant?.name || selectedConversation?.title || 'Contact';
    showToast(`Calling ${name}...`);
  };

  // Handle video call
  const handleVideoCall = (participant?: Participant) => {
    const name = participant?.name || selectedConversation?.title || 'Contact';
    showToast(`Starting video call with ${name}...`);
  };

  // Handle mute toggle
  const handleMuteToggle = () => {
    if (!selectedConversation) return;
    const isMuted = !selectedConversation.isMuted;
    setConversations(prev =>
      prev.map(c => c.id === selectedConversation.id ? { ...c, isMuted } : c)
    );
    setSelectedConversation(prev => prev ? { ...prev, isMuted } : null);
    showToast(isMuted ? 'Notifications muted' : 'Notifications enabled');
  };

  const participant = selectedConversation?.participants[0];
  const isManagerChat = selectedConversation?.isManager;

  return (
    <div className="h-[calc(100vh-theme(spacing.32))] lg:h-[calc(100vh-theme(spacing.24))] flex flex-col -mx-4 lg:-mx-8 -mt-6 lg:-mt-8">
      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar - Thread List */}
        <div className={`w-full lg:w-80 flex-shrink-0 bg-white border-r border-slate-200 flex flex-col ${
          selectedConversation ? 'hidden lg:flex' : 'flex'
        }`}>
          {/* Sidebar Header */}
          <div className="p-4 border-b border-slate-200">
            <div className="flex items-center justify-between mb-4">
              <h1 className="text-xl font-bold text-slate-900">Messages</h1>
              <button
                onClick={() => setShowNotificationPrefs(true)}
                className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <Settings className="w-5 h-5 text-slate-500" />
              </button>
            </div>

            {/* Search */}
            <div className="relative mb-3">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search messages..."
                className="w-full pl-10 pr-4 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              />
            </div>

            {/* Filter Tabs */}
            <FilterTabs
              activeFilter={activeFilter}
              onFilterChange={setActiveFilter}
              counts={filterCounts}
            />
          </div>

          {/* Conversation List */}
          <div className="flex-1 overflow-y-auto">
            {searchQuery || activeFilter !== 'all' ? (
              // Filtered Results
              <div>
                <p className="px-3 py-2 text-xs text-slate-500">
                  {filteredConversations.length} {filteredConversations.length === 1 ? 'result' : 'results'}
                </p>
                {filteredConversations.map((conv) => (
                  <ConversationItem
                    key={conv.id}
                    conversation={conv}
                    isSelected={selectedConversation?.id === conv.id}
                    onClick={() => setSelectedConversation(conv)}
                  />
                ))}
              </div>
            ) : (
              <>
                {/* Your Haven Team */}
                <div className="py-2">
                  <p className="px-3 py-2 text-xs font-medium text-emerald-700 uppercase tracking-wider flex items-center gap-1 bg-emerald-50">
                    <Star className="w-3 h-3 text-emerald-600 fill-emerald-600" />
                    Your Haven Team
                  </p>
                  {teamConversations.map((conv) => (
                    <ConversationItem
                      key={conv.id}
                      conversation={conv}
                      isSelected={selectedConversation?.id === conv.id}
                      onClick={() => setSelectedConversation(conv)}
                    />
                  ))}
                </div>

                {/* Family */}
                {channelGroups
                  .filter(g => g.type === 'family')
                  .map((group) => {
                    const groupConversations = getConversationsByType(group.type);
                    if (groupConversations.length === 0) return null;
                    return (
                      <div key={group.type} className="border-t border-slate-100">
                        <ChannelGroupHeader
                          group={group}
                          count={groupConversations.length}
                          onToggle={() => toggleChannelGroup(group.type)}
                        />
                        {group.isExpanded &&
                          groupConversations.map((conv) => (
                            <ConversationItem
                              key={conv.id}
                              conversation={conv}
                              isSelected={selectedConversation?.id === conv.id}
                              onClick={() => setSelectedConversation(conv)}
                            />
                          ))}
                      </div>
                    );
                  })}

                {/* Vendor Updates (Managed by Sarah) */}
                {vendorConversations.length > 0 && (
                  <VendorSectionHeader
                    conversations={vendorConversations}
                    isExpanded={showVendors}
                    onToggle={() => setShowVendors(!showVendors)}
                  />
                )}
                {showVendors && vendorConversations.map((conv) => (
                  <ConversationItem
                    key={conv.id}
                    conversation={conv}
                    isSelected={selectedConversation?.id === conv.id}
                    onClick={() => setSelectedConversation(conv)}
                  />
                ))}

                {/* Forwarded Emails */}
                {channelGroups
                  .filter(g => g.type === 'forwarded')
                  .map((group) => {
                    const groupConversations = getConversationsByType(group.type);
                    if (groupConversations.length === 0) return null;
                    return (
                      <div key={group.type} className="border-t border-slate-100">
                        <ChannelGroupHeader
                          group={group}
                          count={groupConversations.length}
                          onToggle={() => toggleChannelGroup(group.type)}
                        />
                        {group.isExpanded &&
                          groupConversations.map((conv) => (
                            <ConversationItem
                              key={conv.id}
                              conversation={conv}
                              isSelected={selectedConversation?.id === conv.id}
                              onClick={() => setSelectedConversation(conv)}
                            />
                          ))}
                      </div>
                    );
                  })}
              </>
            )}
          </div>
        </div>

        {/* Main Chat Area */}
        <div className={`flex-1 flex flex-col bg-slate-50 min-w-0 ${
          !selectedConversation ? 'hidden lg:flex' : 'flex'
        }`}>
          {selectedConversation ? (
            <>
              {/* Chat Header */}
              <div className={`border-b border-slate-200 px-4 py-3 flex items-center gap-3 ${
                isManagerChat ? 'bg-gradient-to-r from-emerald-50 to-white' : 'bg-white'
              }`}>
                <button
                  onClick={() => setSelectedConversation(null)}
                  className="lg:hidden p-2 hover:bg-slate-100 rounded-lg"
                >
                  <ArrowLeft className="w-5 h-5 text-slate-600" />
                </button>

                <div className="relative flex-shrink-0">
                  <div className={`w-10 h-10 rounded-full overflow-hidden ${isManagerChat ? 'ring-2 ring-emerald-400 ring-offset-2' : 'bg-slate-200'}`}>
                    <Image
                      src={selectedConversation.avatar}
                      alt=""
                      width={40}
                      height={40}
                      className="object-cover"
                    />
                  </div>
                  {participant && <OnlineIndicator isOnline={participant.isOnline ?? false} />}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h2 className="font-semibold text-slate-900 truncate">{selectedConversation.title}</h2>
                    {selectedConversation.managedByManager && selectedConversation.managerStatus && (
                      <ManagedLabel status={selectedConversation.managerStatus} />
                    )}
                  </div>
                  <p className="text-xs text-slate-500">
                    {participant?.isOnline ? (
                      <span className="text-emerald-600 font-medium">Online now</span>
                    ) : participant?.responseTime ? (
                      participant.responseTime
                    ) : selectedConversation.subtitle ? (
                      selectedConversation.subtitle
                    ) : (
                      'Offline'
                    )}
                  </p>
                </div>

                {!selectedConversation.managedByManager && (
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleCall(participant)}
                      className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Phone className="w-5 h-5 text-slate-600" />
                    </button>
                    <button
                      onClick={() => handleVideoCall(participant)}
                      className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Video className="w-5 h-5 text-slate-600" />
                    </button>
                  </div>
                )}

                <button
                  onClick={() => setShowInfoDrawer(!showInfoDrawer)}
                  className={`p-2 rounded-lg transition-colors ${
                    showInfoDrawer ? 'bg-emerald-100 text-emerald-600' : 'hover:bg-slate-100 text-slate-600'
                  }`}
                >
                  <Info className="w-5 h-5" />
                </button>
              </div>

              {/* Messages Area */}
              <div className="flex-1 overflow-y-auto p-4 space-y-3" style={{
                backgroundImage: `radial-gradient(circle, #e2e8f0 1px, transparent 1px)`,
                backgroundSize: '20px 20px',
              }}>
                {selectedConversation.messages.map((msg, index) => {
                  const prevMsg = selectedConversation.messages[index - 1];
                  const showSender =
                    msg.sender !== 'me' &&
                    msg.sender !== 'system' &&
                    (!prevMsg || prevMsg.senderId !== msg.senderId || prevMsg.sender === 'system' || prevMsg.sender !== msg.sender);
                  return (
                    <MessageBubble
                      key={msg.id}
                      message={msg}
                      showSender={showSender}
                      onConvert={handleConvertMessage}
                    />
                  );
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* Input Zone */}
              <div className="bg-white border-t border-slate-200 p-4">
                {/* Quick Request Buttons (only in manager chat) */}
                {isManagerChat && (
                  <QuickRequestButtons onRequest={handleQuickRequest} />
                )}

                <div className="flex items-end gap-2 mt-2">
                  <div className="flex gap-1">
                    <button
                      onClick={() => showToast('Attach files coming soon!')}
                      className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Paperclip className="w-5 h-5 text-slate-500" />
                    </button>
                    <button
                      onClick={() => showToast('Camera capture coming soon!')}
                      className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Camera className="w-5 h-5 text-slate-500" />
                    </button>
                  </div>
                  <div className="flex-1">
                    <textarea
                      value={messageInput}
                      onChange={(e) => setMessageInput(e.target.value)}
                      placeholder={isManagerChat ? "Ask Sarah anything..." : "Type a message..."}
                      rows={1}
                      className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl resize-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                      style={{ maxHeight: '120px' }}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          handleSend();
                        }
                      }}
                    />
                  </div>
                  <button
                    onClick={handleSend}
                    disabled={!messageInput.trim()}
                    className="p-3 bg-emerald-600 text-white rounded-full hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    <Send className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </>
          ) : (
            // Empty State
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
              <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mb-6">
                <MessageCircle className="w-10 h-10 text-emerald-600" />
              </div>
              <h2 className="text-xl font-semibold text-slate-900 mb-2">Your Communication Hub</h2>
              <p className="text-slate-500 max-w-sm mb-6">
                Chat with Sarah, your home manager. She handles vendor communications so you don't have to.
              </p>
              <button
                onClick={() => {
                  const managerConvo = conversations.find(c => c.isManager);
                  if (managerConvo) setSelectedConversation(managerConvo);
                }}
                className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
              >
                <MessageCircle className="w-5 h-5" />
                Message Sarah
              </button>
            </div>
          )}
        </div>

        {/* Info Drawer */}
        {selectedConversation && showInfoDrawer && (
          <div className="hidden lg:block">
            <InfoDrawer
              conversation={selectedConversation}
              onClose={() => setShowInfoDrawer(false)}
              onCall={() => handleCall(participant)}
              onVideoCall={() => handleVideoCall(participant)}
              onMuteToggle={handleMuteToggle}
              onNotificationSettings={() => setShowNotificationPrefs(true)}
            />
          </div>
        )}
      </div>

      {/* Toast Notification */}
      {toast && (
        <div className="fixed top-4 right-4 z-50">
          <div className="flex items-center gap-3 px-4 py-3 bg-slate-800 text-white rounded-lg shadow-lg">
            <Check className="w-5 h-5" />
            <span className="font-medium">{toast}</span>
          </div>
        </div>
      )}

      {/* Notification Preferences Modal */}
      {showNotificationPrefs && (
        <NotificationPreferencesModal
          onClose={() => setShowNotificationPrefs(false)}
          onSave={() => showToast('Notification preferences saved')}
        />
      )}
    </div>
  );
}
