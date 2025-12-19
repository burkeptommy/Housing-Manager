'use client';

import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import { getDemoImage } from '@/lib/imageUtils';
import {
  Search,
  Plus,
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
  Image as ImageIcon,
  Users,
  Home,
  Wrench,
  Plane,
  Building2,
  Bell,
  BellOff,
  Ban,
  MoreVertical,
  MapPin,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ChannelType = 'vip' | 'family' | 'vendors' | 'neighbors';
type MessageSender = 'me' | 'them' | 'system';

interface Participant {
  id: string;
  name: string;
  avatar: string;
  role?: string;
  isOnline?: boolean;
  responseTime?: string;
}

interface MessageAttachment {
  id: string;
  type: 'image' | 'file' | 'action';
  url?: string;
  name?: string;
  size?: string;
  actionType?: 'estimate' | 'calendar' | 'flight' | 'hotel';
  actionData?: Record<string, unknown>;
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
  isVip?: boolean;
  lastActivity: string;
  isMuted?: boolean;
}

interface ChannelGroup {
  type: ChannelType;
  label: string;
  icon: typeof Users;
  isExpanded: boolean;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockParticipants: Record<string, Participant> = {
  manager: {
    id: 'p1',
    name: 'Steve Harrison',
    avatar: getDemoImage('avatar-male', 100, 100, 'steve-manager'),
    role: 'Home Manager',
    isOnline: true,
    responseTime: 'Replies in ~5m',
  },
  handyman: {
    id: 'p2',
    name: 'Mike Rodriguez',
    avatar: getDemoImage('avatar-male', 100, 100, 'mike-handyman'),
    role: 'Dedicated Handyman',
    isOnline: false,
    responseTime: 'Replies in ~1h',
  },
  travel: {
    id: 'p3',
    name: 'Sarah Chen',
    avatar: getDemoImage('avatar-female', 100, 100, 'sarah-travel'),
    role: 'Travel Concierge',
    isOnline: true,
    responseTime: 'Replies in ~15m',
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
    name: 'Mike\'s Plumbing',
    avatar: getDemoImage('vendor-portrait', 100, 100, 'mikes-plumbing'),
    role: 'Vendor',
    isOnline: false,
  },
  neighbor: {
    id: 'p6',
    name: 'Jennifer Walsh',
    avatar: getDemoImage('avatar-female', 100, 100, 'jennifer-neighbor'),
    role: 'Neighbor',
    isOnline: true,
  },
};

const mockConversations: Conversation[] = [
  {
    id: 'c1',
    channelType: 'vip',
    title: 'Home Manager',
    subtitle: 'Steve Harrison',
    avatar: mockParticipants.manager!.avatar,
    participants: [mockParticipants.manager!],
    unreadCount: 2,
    isPinned: true,
    isVip: true,
    lastActivity: '2024-12-19T10:30:00Z',
    messages: [
      { id: 'm1', sender: 'them', senderName: 'Steve', content: 'Good morning! Just wanted to let you know the landscaping crew will be there tomorrow at 9 AM.', timestamp: '2024-12-19T09:00:00Z' },
      { id: 'm2', sender: 'me', content: 'Perfect, thanks for the heads up!', timestamp: '2024-12-19T09:05:00Z', status: 'read' },
      { id: 'm3', sender: 'them', senderName: 'Steve', content: 'Also, I got a quote from the HVAC company for the annual service.', timestamp: '2024-12-19T10:00:00Z', attachments: [{ id: 'a1', type: 'action', actionType: 'estimate', actionData: { vendor: 'Cool Air HVAC', amount: 299, description: 'Annual HVAC maintenance and inspection', validUntil: '2024-12-26' } }] },
      { id: 'm4', sender: 'them', senderName: 'Steve', content: 'Let me know if you want to proceed with this.', timestamp: '2024-12-19T10:30:00Z' },
    ],
  },
  {
    id: 'c2',
    channelType: 'vip',
    title: 'Handyman',
    subtitle: 'Mike Rodriguez',
    avatar: mockParticipants.handyman!.avatar,
    participants: [mockParticipants.handyman!],
    unreadCount: 0,
    isPinned: true,
    isVip: true,
    lastActivity: '2024-12-18T16:00:00Z',
    messages: [
      { id: 'm1', sender: 'me', content: 'Hi Mike, the kitchen faucet is still dripping after your visit.', timestamp: '2024-12-18T14:00:00Z', status: 'read' },
      { id: 'm2', sender: 'them', senderName: 'Mike', content: 'I\'ll swing by tomorrow morning to take another look. The washer might need a full replacement.', timestamp: '2024-12-18T14:30:00Z' },
      { id: 'm3', sender: 'me', content: 'Sounds good, I\'ll be home until noon.', timestamp: '2024-12-18T14:35:00Z', status: 'read' },
      { id: 'm4', sender: 'them', senderName: 'Mike', content: 'Great, I\'ll be there around 9. See you then!', timestamp: '2024-12-18T16:00:00Z' },
    ],
  },
  {
    id: 'c3',
    channelType: 'vip',
    title: 'Travel Concierge',
    subtitle: 'Sarah Chen',
    avatar: mockParticipants.travel!.avatar,
    participants: [mockParticipants.travel!],
    unreadCount: 1,
    isPinned: true,
    isVip: true,
    lastActivity: '2024-12-19T11:00:00Z',
    messages: [
      { id: 'm1', sender: 'me', content: 'Hi Sarah, we\'re thinking about a spring break trip to Hawaii for the family.', timestamp: '2024-12-18T10:00:00Z', status: 'read' },
      { id: 'm2', sender: 'them', senderName: 'Sarah', content: 'That sounds wonderful! I\'ve got some great options for you. Here\'s a flight I found:', timestamp: '2024-12-18T11:00:00Z', attachments: [{ id: 'a1', type: 'action', actionType: 'flight', actionData: { airline: 'Hawaiian Airlines', departure: 'LAX', arrival: 'HNL', departDate: '2025-03-15', returnDate: '2025-03-22', price: 2400, passengers: 4 } }] },
      { id: 'm3', sender: 'them', senderName: 'Sarah', content: 'And here\'s a beautiful resort I recommend:', timestamp: '2024-12-18T11:05:00Z', attachments: [{ id: 'a2', type: 'action', actionType: 'hotel', actionData: { name: 'Four Seasons Resort Maui', location: 'Wailea, Maui', checkIn: '2025-03-15', checkOut: '2025-03-22', pricePerNight: 850, rating: 4.9 } }] },
      { id: 'm4', sender: 'them', senderName: 'Sarah', content: 'Let me know what you think!', timestamp: '2024-12-19T11:00:00Z' },
    ],
  },
  {
    id: 'c4',
    channelType: 'family',
    title: 'Chen Family',
    subtitle: 'Alice, Emma, Jake',
    avatar: getDemoImage('avatar-female', 100, 100, 'family-group'),
    participants: [mockParticipants.alice!],
    unreadCount: 5,
    lastActivity: '2024-12-19T09:30:00Z',
    messages: [
      { id: 'm1', sender: 'them', senderId: 'p4', senderName: 'Alice', content: 'Don\'t forget Emma has soccer practice at 4!', timestamp: '2024-12-19T08:00:00Z' },
      { id: 'm2', sender: 'me', content: 'Got it! I can pick her up.', timestamp: '2024-12-19T08:05:00Z', status: 'read' },
      { id: 'm3', sender: 'them', senderId: 'p4', senderName: 'Alice', content: 'Perfect. Also, Jake needs his science project supplies.', timestamp: '2024-12-19T09:00:00Z' },
      { id: 'm4', sender: 'them', senderId: 'p4', senderName: 'Alice', content: 'Here\'s the list:', timestamp: '2024-12-19T09:30:00Z', attachments: [{ id: 'a1', type: 'image', url: getDemoImage('blueprint', 400, 300, 'science-list') }] },
    ],
  },
  {
    id: 'c5',
    channelType: 'vendors',
    title: 'Mike\'s Plumbing',
    subtitle: 'Kitchen faucet repair',
    avatar: mockParticipants.plumber!.avatar,
    participants: [mockParticipants.plumber!],
    unreadCount: 0,
    lastActivity: '2024-12-17T12:00:00Z',
    messages: [
      { id: 'm1', sender: 'system', content: 'Work order #WO-001 assigned to Mike\'s Plumbing', timestamp: '2024-12-16T10:00:00Z' },
      { id: 'm2', sender: 'them', senderName: 'Mike\'s Plumbing', content: 'We\'ll be there tomorrow between 2-4 PM.', timestamp: '2024-12-16T11:00:00Z' },
      { id: 'm3', sender: 'me', content: 'Sounds good, the gate code is 1234.', timestamp: '2024-12-16T11:30:00Z', status: 'read' },
      { id: 'm4', sender: 'them', senderName: 'Mike\'s Plumbing', content: 'Job completed. Here\'s the photo of the repaired faucet:', timestamp: '2024-12-17T12:00:00Z', attachments: [{ id: 'a1', type: 'image', url: getDemoImage('kitchen', 400, 300, 'repaired-faucet') }] },
    ],
  },
  {
    id: 'c6',
    channelType: 'neighbors',
    title: 'Jennifer Walsh',
    subtitle: '123 Oak Lane',
    avatar: mockParticipants.neighbor!.avatar,
    participants: [mockParticipants.neighbor!],
    unreadCount: 0,
    lastActivity: '2024-12-15T18:00:00Z',
    messages: [
      { id: 'm1', sender: 'them', senderName: 'Jennifer', content: 'Hey! Love what you did with the front yard. Who did your landscaping?', timestamp: '2024-12-15T16:00:00Z' },
      { id: 'm2', sender: 'me', content: 'Thanks! It was Green Thumb Landscaping. They did an amazing job.', timestamp: '2024-12-15T16:30:00Z', status: 'read' },
      { id: 'm3', sender: 'them', senderName: 'Jennifer', content: 'Great, I\'ll reach out to them. Thanks!', timestamp: '2024-12-15T18:00:00Z' },
    ],
  },
];

// ============================================================================
// COMPONENTS
// ============================================================================

// VIP Badge
function VipBadge() {
  return (
    <div className="absolute -top-1 -right-1 w-5 h-5 bg-gradient-to-br from-amber-400 to-amber-600 rounded-full flex items-center justify-center shadow-sm">
      <Star className="w-3 h-3 text-white fill-white" />
    </div>
  );
}

// Online Indicator
function OnlineIndicator({ isOnline }: { isOnline: boolean }) {
  return (
    <div className={`absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full border-2 border-white ${
      isOnline ? 'bg-emerald-500' : 'bg-slate-400'
    }`} />
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
  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    } else if (diffDays === 1) {
      return 'Yesterday';
    } else {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
  };

  const lastMessage = conversation.messages[conversation.messages.length - 1];
  const participant = conversation.participants[0];

  return (
    <button
      onClick={onClick}
      className={`w-full flex items-start gap-3 p-3 text-left transition-colors ${
        isSelected
          ? 'bg-emerald-50 border-l-4 border-l-emerald-600'
          : conversation.isVip
          ? 'bg-slate-50 hover:bg-slate-100 border-l-4 border-l-transparent'
          : 'hover:bg-slate-50 border-l-4 border-l-transparent'
      }`}
    >
      <div className="relative flex-shrink-0">
        <div className="w-12 h-12 rounded-full overflow-hidden bg-slate-200">
          <Image src={conversation.avatar} alt="" width={48} height={48} className="object-cover" />
        </div>
        {conversation.isVip && <VipBadge />}
        {participant && <OnlineIndicator isOnline={participant.isOnline ?? false} />}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between gap-2">
          <span className={`font-medium truncate ${conversation.unreadCount > 0 ? 'text-slate-900' : 'text-slate-700'}`}>
            {conversation.title}
          </span>
          <span className="text-xs text-slate-500 flex-shrink-0">
            {formatTime(conversation.lastActivity)}
          </span>
        </div>
        {conversation.subtitle && (
          <p className="text-xs text-slate-500 truncate">{conversation.subtitle}</p>
        )}
        {lastMessage && (
          <p className={`text-sm truncate mt-0.5 ${conversation.unreadCount > 0 ? 'text-slate-900 font-medium' : 'text-slate-500'}`}>
            {lastMessage.sender === 'me' && <span className="text-slate-400">You: </span>}
            {lastMessage.content}
          </p>
        )}
      </div>

      {conversation.unreadCount > 0 && (
        <div className="flex-shrink-0 w-5 h-5 bg-emerald-600 rounded-full flex items-center justify-center">
          <span className="text-xs text-white font-medium">{conversation.unreadCount}</span>
        </div>
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
  );
}

// Message Bubble
function MessageBubble({ message, showSender }: { message: Message; showSender: boolean }) {
  const isMe = message.sender === 'me';
  const isSystem = message.sender === 'system';

  const formatTime = (dateStr: string) => {
    return new Date(dateStr).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  if (isSystem) {
    return (
      <div className="flex justify-center my-4">
        <span className="text-xs text-slate-500 bg-slate-100 px-3 py-1.5 rounded-full">
          {message.content}
        </span>
      </div>
    );
  }

  return (
    <div className={`flex ${isMe ? 'justify-end' : 'justify-start'} group`}>
      <div className={`max-w-[70%] ${isMe ? 'order-2' : 'order-1'}`}>
        {showSender && !isMe && message.senderName && (
          <p className="text-xs font-medium text-slate-600 mb-1 ml-3">{message.senderName}</p>
        )}
        <div
          className={`px-4 py-2.5 ${
            isMe
              ? 'bg-emerald-600 text-white rounded-2xl rounded-tr-sm'
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

              {attachment.type === 'action' && attachment.actionType === 'calendar' && (
                <div className="bg-white border border-slate-200 rounded-xl p-4 mt-2 shadow-sm">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="p-2 bg-emerald-100 rounded-lg">
                      <Calendar className="w-4 h-4 text-emerald-600" />
                    </div>
                    <span className="font-medium text-slate-900">Proposed Time</span>
                  </div>
                  <div className="flex gap-2">
                    <button className="flex-1 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700">
                      Accept
                    </button>
                    <button className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 font-medium rounded-lg hover:bg-slate-50">
                      Suggest Another
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
        </div>
      </div>
    </div>
  );
}

// Info Drawer
function InfoDrawer({
  conversation,
  onClose,
}: {
  conversation: Conversation;
  onClose: () => void;
}) {
  const participant = conversation.participants[0];
  const allImages = conversation.messages
    .flatMap((m) => m.attachments?.filter((a) => a.type === 'image') || []);
  const allFiles = conversation.messages
    .flatMap((m) => m.attachments?.filter((a) => a.type === 'file') || []);

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
            <div className="w-20 h-20 rounded-full overflow-hidden bg-slate-200">
              <Image src={conversation.avatar} alt="" width={80} height={80} className="object-cover" />
            </div>
            {conversation.isVip && (
              <div className="absolute -top-1 -right-1 w-6 h-6 bg-gradient-to-br from-amber-400 to-amber-600 rounded-full flex items-center justify-center">
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
        </div>

        {/* Actions */}
        <div className="p-4 border-b border-slate-200">
          <div className="flex justify-center gap-4">
            <button className="flex flex-col items-center gap-1 p-3 hover:bg-slate-50 rounded-xl transition-colors">
              <div className="p-2 bg-emerald-100 rounded-full">
                <Phone className="w-5 h-5 text-emerald-600" />
              </div>
              <span className="text-xs text-slate-600">Call</span>
            </button>
            <button className="flex flex-col items-center gap-1 p-3 hover:bg-slate-50 rounded-xl transition-colors">
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

        {/* Shared Media */}
        {allImages.length > 0 && (
          <div className="p-4 border-b border-slate-200">
            <h5 className="text-sm font-medium text-slate-900 mb-3 flex items-center gap-2">
              <ImageIcon className="w-4 h-4 text-slate-500" />
              Shared Photos ({allImages.length})
            </h5>
            <div className="grid grid-cols-3 gap-2">
              {allImages.slice(0, 6).map((img) => (
                <div key={img.id} className="aspect-square rounded-lg overflow-hidden bg-slate-100">
                  <Image src={img.url!} alt="" width={100} height={100} className="object-cover w-full h-full" />
                </div>
              ))}
            </div>
            {allImages.length > 6 && (
              <button className="w-full text-sm text-emerald-600 font-medium mt-2 hover:underline">
                View All
              </button>
            )}
          </div>
        )}

        {/* Shared Files */}
        {allFiles.length > 0 && (
          <div className="p-4 border-b border-slate-200">
            <h5 className="text-sm font-medium text-slate-900 mb-3 flex items-center gap-2">
              <FileText className="w-4 h-4 text-slate-500" />
              Shared Documents ({allFiles.length})
            </h5>
            <div className="space-y-2">
              {allFiles.map((file) => (
                <div key={file.id} className="flex items-center gap-3 p-2 bg-slate-50 rounded-lg">
                  <FileText className="w-5 h-5 text-slate-400" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-slate-900 truncate">{file.name}</p>
                    <p className="text-xs text-slate-500">{file.size}</p>
                  </div>
                  <Download className="w-4 h-4 text-slate-400" />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Participants */}
        <div className="p-4 border-b border-slate-200">
          <h5 className="text-sm font-medium text-slate-900 mb-3 flex items-center gap-2">
            <Users className="w-4 h-4 text-slate-500" />
            Participants ({conversation.participants.length + 1})
          </h5>
          <div className="space-y-2">
            <div className="flex items-center gap-3 p-2">
              <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center">
                <span className="text-sm font-medium text-emerald-700">You</span>
              </div>
              <span className="text-sm text-slate-900">You</span>
            </div>
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

        {/* Privacy */}
        <div className="p-4">
          <h5 className="text-sm font-medium text-slate-900 mb-3">Privacy</h5>
          <div className="space-y-2">
            <button className="w-full flex items-center gap-3 p-3 text-left hover:bg-slate-50 rounded-lg transition-colors">
              {conversation.isMuted ? (
                <BellOff className="w-5 h-5 text-slate-500" />
              ) : (
                <Bell className="w-5 h-5 text-slate-500" />
              )}
              <span className="text-sm text-slate-700">
                {conversation.isMuted ? 'Unmute Notifications' : 'Mute Notifications'}
              </span>
            </button>
            <button className="w-full flex items-center gap-3 p-3 text-left hover:bg-red-50 rounded-lg transition-colors text-red-600">
              <Ban className="w-5 h-5" />
              <span className="text-sm">Block</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function MessagesPage() {
  const [conversations] = useState(mockConversations);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [showInfoDrawer, setShowInfoDrawer] = useState(false);
  const [messageInput, setMessageInput] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const [channelGroups, setChannelGroups] = useState<ChannelGroup[]>([
    { type: 'family', label: 'Family', icon: Home, isExpanded: true },
    { type: 'vendors', label: 'Vendors', icon: Wrench, isExpanded: true },
    { type: 'neighbors', label: 'Neighbors', icon: Users, isExpanded: true },
  ]);

  const vipConversations = conversations.filter((c) => c.isVip);
  const getConversationsByType = (type: ChannelType) =>
    conversations.filter((c) => c.channelType === type && !c.isVip);

  const filteredConversations = searchQuery
    ? conversations.filter(
        (c) =>
          c.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.subtitle?.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : null;

  const toggleChannelGroup = (type: ChannelType) => {
    setChannelGroups((groups) =>
      groups.map((g) => (g.type === type ? { ...g, isExpanded: !g.isExpanded } : g))
    );
  };

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [selectedConversation?.messages]);

  const handleSend = () => {
    if (!messageInput.trim()) return;
    // In real app, would send via API
    setMessageInput('');
  };

  const participant = selectedConversation?.participants[0];

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
              <button className="p-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                <Plus className="w-5 h-5" />
              </button>
            </div>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search messages..."
                className="w-full pl-10 pr-4 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              />
            </div>
          </div>

          {/* Conversation List */}
          <div className="flex-1 overflow-y-auto">
            {filteredConversations ? (
              // Search Results
              <div>
                <p className="px-3 py-2 text-xs text-slate-500">
                  {filteredConversations.length} results
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
                {/* VIP Pinned */}
                <div className="py-2">
                  <p className="px-3 py-2 text-xs font-medium text-slate-500 uppercase tracking-wider flex items-center gap-1">
                    <Star className="w-3 h-3 text-amber-500" />
                    Your Team
                  </p>
                  {vipConversations.map((conv) => (
                    <ConversationItem
                      key={conv.id}
                      conversation={conv}
                      isSelected={selectedConversation?.id === conv.id}
                      onClick={() => setSelectedConversation(conv)}
                    />
                  ))}
                </div>

                {/* Channel Groups */}
                {channelGroups.map((group) => {
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
              <div className="bg-white border-b border-slate-200 px-4 py-3 flex items-center gap-3">
                <button
                  onClick={() => setSelectedConversation(null)}
                  className="lg:hidden p-2 hover:bg-slate-100 rounded-lg"
                >
                  <ArrowLeft className="w-5 h-5 text-slate-600" />
                </button>

                <div className="relative flex-shrink-0">
                  <div className="w-10 h-10 rounded-full overflow-hidden bg-slate-200">
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
                  <h2 className="font-semibold text-slate-900 truncate">{selectedConversation.title}</h2>
                  <p className="text-xs text-slate-500">
                    {participant?.isOnline ? (
                      <span className="text-emerald-600">Online</span>
                    ) : participant?.responseTime ? (
                      participant.responseTime
                    ) : (
                      'Offline'
                    )}
                  </p>
                </div>

                <div className="flex items-center gap-1">
                  <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <Phone className="w-5 h-5 text-slate-600" />
                  </button>
                  <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <Video className="w-5 h-5 text-slate-600" />
                  </button>
                  <button
                    onClick={() => setShowInfoDrawer(!showInfoDrawer)}
                    className={`p-2 rounded-lg transition-colors ${
                      showInfoDrawer ? 'bg-emerald-100 text-emerald-600' : 'hover:bg-slate-100 text-slate-600'
                    }`}
                  >
                    <Info className="w-5 h-5" />
                  </button>
                </div>
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
                    (!prevMsg || prevMsg.senderId !== msg.senderId || prevMsg.sender === 'system');
                  return <MessageBubble key={msg.id} message={msg} showSender={showSender} />;
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* Input Zone */}
              <div className="bg-white border-t border-slate-200 p-4">
                <div className="flex items-end gap-2">
                  <div className="flex gap-1">
                    <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                      <Paperclip className="w-5 h-5 text-slate-500" />
                    </button>
                    <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                      <Camera className="w-5 h-5 text-slate-500" />
                    </button>
                    <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                      <Calendar className="w-5 h-5 text-slate-500" />
                    </button>
                  </div>
                  <div className="flex-1">
                    <textarea
                      value={messageInput}
                      onChange={(e) => setMessageInput(e.target.value)}
                      placeholder="Type a message..."
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
                <Send className="w-10 h-10 text-emerald-600" />
              </div>
              <h2 className="text-xl font-semibold text-slate-900 mb-2">Your Messages</h2>
              <p className="text-slate-500 max-w-sm mb-6">
                Stay connected with your home team, family, vendors, and neighbors all in one place.
              </p>
              <button className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                <Plus className="w-5 h-5" />
                Start a Conversation
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
            />
          </div>
        )}
      </div>
    </div>
  );
}
