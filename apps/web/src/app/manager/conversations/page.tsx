'use client';

import { useState, useEffect, useRef } from 'react';
import {
  MessageCircle,
  Mail,
  Search,
  Plus,
  Check,
  CheckCheck,
  Phone,
  ClipboardList,
  MoreVertical,
  ArrowLeft,
  Paperclip,
  Camera,
  Send,
  X,
  ChevronRight,
  Sparkles,
  Link2,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ConversationType = 'direct' | 'email' | 'vendor' | 'system';
type ConversationTab = 'all' | 'homeowners' | 'vendors' | 'emails' | 'unread';

interface Message {
  id: string;
  senderId: string;
  senderName: string;
  senderRole: 'homeowner' | 'manager' | 'vendor' | 'system';
  content: string;
  timestamp: string;
  isRead: boolean;
  attachments?: { type: 'image' | 'file'; name: string; url?: string }[];
}

interface Conversation {
  id: string;
  type: ConversationType;
  householdId: string;
  householdName: string;
  contactName: string;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
  isRead: boolean;
  relatedWorkOrder?: string;
  // For forwarded emails
  emailSubject?: string;
  emailFrom?: string;
  aiClassification?: {
    type: string;
    vendor?: string;
    amount?: number;
    dueDate?: string;
    confidence: number;
  };
}

interface ForwardedEmail {
  from: string;
  subject: string;
  date: string;
  body: string;
  aiClassification: {
    type: string;
    vendor: string;
    amount: number;
    dueDate: string;
    confidence: number;
  };
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockConversations: Conversation[] = [
  // Unread - Homeowners
  {
    id: 'conv1',
    type: 'direct',
    householdId: 'hh1',
    householdName: 'Smith Family',
    contactName: 'Bob Smith',
    lastMessage: 'Thanks! What time will the HVAC tech arrive?',
    lastMessageTime: '10 min ago',
    unreadCount: 2,
    isRead: false,
    relatedWorkOrder: 'WO-1892',
  },
  {
    id: 'conv2',
    type: 'email',
    householdId: 'hh1',
    householdName: 'Smith Family',
    contactName: 'Forwarded Email',
    lastMessage: 'AI: Electric bill $187.43 due Dec 28',
    lastMessageTime: '1 hour ago',
    unreadCount: 1,
    isRead: false,
    emailSubject: 'Your December Electric Bill',
    emailFrom: 'noreply@coned.com',
    aiClassification: {
      type: 'BILL',
      vendor: 'ConEd',
      amount: 187.43,
      dueDate: 'December 28, 2024',
      confidence: 98,
    },
  },
  {
    id: 'conv3',
    type: 'direct',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    contactName: 'David Johnson',
    lastMessage: 'Can we discuss the landscaping quote?',
    lastMessageTime: '2 hours ago',
    unreadCount: 1,
    isRead: false,
  },
  // Unread - Vendors
  {
    id: 'conv4',
    type: 'vendor',
    householdId: 'hh1',
    householdName: 'Smith Family',
    contactName: 'AirFlow HVAC (John)',
    lastMessage: 'En route now, ETA 15 minutes',
    lastMessageTime: '5 min ago',
    unreadCount: 1,
    isRead: false,
    relatedWorkOrder: 'WO-1892',
  },
  // Read
  {
    id: 'conv5',
    type: 'direct',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    contactName: 'Lisa Johnson',
    lastMessage: 'Perfect, thanks for handling that!',
    lastMessageTime: 'Yesterday',
    unreadCount: 0,
    isRead: true,
  },
  {
    id: 'conv6',
    type: 'vendor',
    householdId: 'hh1',
    householdName: 'Smith Family',
    contactName: "Mike's Plumbing",
    lastMessage: 'Faucet repair completed. See photos attached.',
    lastMessageTime: 'Yesterday',
    unreadCount: 0,
    isRead: true,
    relatedWorkOrder: 'WO-1891',
  },
  {
    id: 'conv7',
    type: 'email',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    contactName: 'Forwarded Email',
    lastMessage: 'AI: Insurance renewal notice',
    lastMessageTime: '2 days ago',
    unreadCount: 0,
    isRead: true,
    emailSubject: 'Your Policy is Renewing Soon',
    emailFrom: 'notifications@statefarm.com',
    aiClassification: {
      type: 'NOTICE',
      vendor: 'State Farm',
      confidence: 92,
    },
  },
];

const mockMessages: Record<string, Message[]> = {
  conv1: [
    {
      id: 'm1',
      senderId: 'bob',
      senderName: 'Bob Smith',
      senderRole: 'homeowner',
      content: 'Kitchen faucet started dripping again. Can someone look?',
      timestamp: '10:15 AM',
      isRead: true,
      attachments: [{ type: 'image', name: 'faucet.jpg' }],
    },
    {
      id: 'm2',
      senderId: 'manager',
      senderName: 'You',
      senderRole: 'manager',
      content: "I see it! I'll have Mike swing by tomorrow at 9am. Does that work?",
      timestamp: '10:22 AM',
      isRead: true,
    },
    {
      id: 'm3',
      senderId: 'bob',
      senderName: 'Bob Smith',
      senderRole: 'homeowner',
      content: 'Perfect, Maria will be here. Thanks!',
      timestamp: '10:25 AM',
      isRead: true,
    },
    {
      id: 'm4',
      senderId: 'system',
      senderName: 'System',
      senderRole: 'system',
      content: 'Work Order WO-1892 created for HVAC service',
      timestamp: '10:30 AM',
      isRead: true,
    },
    {
      id: 'm5',
      senderId: 'bob',
      senderName: 'Bob Smith',
      senderRole: 'homeowner',
      content: 'Thanks! What time will the HVAC tech arrive?',
      timestamp: '10:45 AM',
      isRead: false,
    },
  ],
  conv4: [
    {
      id: 'v1',
      senderId: 'vendor',
      senderName: 'John (AirFlow HVAC)',
      senderRole: 'vendor',
      content: 'Confirming appointment for Smith Family tomorrow at 9am',
      timestamp: '8:00 AM',
      isRead: true,
    },
    {
      id: 'v2',
      senderId: 'manager',
      senderName: 'You',
      senderRole: 'manager',
      content: 'Great, thanks John. They mentioned the AC might need freon.',
      timestamp: '8:15 AM',
      isRead: true,
    },
    {
      id: 'v3',
      senderId: 'vendor',
      senderName: 'John (AirFlow HVAC)',
      senderRole: 'vendor',
      content: "I'll bring a gauge and extra freon just in case.",
      timestamp: '8:20 AM',
      isRead: true,
    },
    {
      id: 'v4',
      senderId: 'vendor',
      senderName: 'John (AirFlow HVAC)',
      senderRole: 'vendor',
      content: 'En route now, ETA 15 minutes',
      timestamp: '8:45 AM',
      isRead: false,
    },
  ],
};

const mockForwardedEmail: ForwardedEmail = {
  from: 'noreply@coned.com',
  subject: 'Your December Electric Bill',
  date: 'Dec 22, 2024',
  body: `Dear Customer,

Your December electric bill is now available.

Account Number: ****4521
Bill Amount: $187.43
Due Date: December 28, 2024

To pay your bill or view your statement, please log in to your account at coned.com.

Thank you for being a valued customer.

ConEd Customer Service`,
  aiClassification: {
    type: 'BILL',
    vendor: 'ConEd (Electric utility)',
    amount: 187.43,
    dueDate: 'December 28, 2024',
    confidence: 98,
  },
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const quickReplies = [
  "I'm on it!",
  'Let me check',
  'All set!',
  "I'll call you",
];

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function ConversationCenterPage() {
  const [conversations] = useState<Conversation[]>(mockConversations);
  const [activeTab, setActiveTab] = useState<ConversationTab>('all');
  const [selectedConversationId, setSelectedConversationId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [newMessage, setNewMessage] = useState('');
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [selectedEmailConv, setSelectedEmailConv] = useState<Conversation | null>(null);
  const [isMobileView, setIsMobileView] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Check for mobile view
  useEffect(() => {
    const checkMobile = () => setIsMobileView(window.innerWidth < 1024);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Scroll to bottom of messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [selectedConversationId]);

  // Filter conversations
  const filteredConversations = conversations.filter(conv => {
    // Tab filter
    if (activeTab === 'homeowners' && conv.type !== 'direct') return false;
    if (activeTab === 'vendors' && conv.type !== 'vendor') return false;
    if (activeTab === 'emails' && conv.type !== 'email') return false;
    if (activeTab === 'unread' && conv.isRead) return false;

    // Search filter
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return (
        conv.householdName.toLowerCase().includes(query) ||
        conv.contactName.toLowerCase().includes(query) ||
        conv.lastMessage.toLowerCase().includes(query)
      );
    }

    return true;
  });

  const unreadConversations = filteredConversations.filter(c => !c.isRead);
  const readConversations = filteredConversations.filter(c => c.isRead);

  const selectedConversation = conversations.find(c => c.id === selectedConversationId);
  const messages = selectedConversationId ? mockMessages[selectedConversationId] || [] : [];

  const unreadCount = conversations.filter(c => !c.isRead).length;

  const handleSelectConversation = (convId: string) => {
    setSelectedConversationId(convId);
  };

  const handleOpenEmailModal = (conv: Conversation) => {
    setSelectedEmailConv(conv);
    setShowEmailModal(true);
  };

  const handleSendMessage = () => {
    if (!newMessage.trim()) return;
    // In real app, would send message to API
    console.log('Sending message:', newMessage);
    setNewMessage('');
  };

  const handleQuickReply = (reply: string) => {
    setNewMessage(reply);
  };

  // Mobile: show only list or only chat
  const showList = !isMobileView || !selectedConversationId;
  const showChat = !isMobileView || selectedConversationId;

  // Conversation List Item
  const ConversationItem = ({ conv }: { conv: Conversation }) => {
    const isSelected = selectedConversationId === conv.id;
    const isEmail = conv.type === 'email';

    return (
      <button
        onClick={() => isEmail ? handleOpenEmailModal(conv) : handleSelectConversation(conv.id)}
        className={`w-full text-left p-4 border-b border-slate-100 transition-colors ${
          isSelected
            ? 'bg-indigo-100 border-l-2 border-l-indigo-600'
            : conv.isRead
            ? 'bg-white hover:bg-slate-50'
            : 'bg-indigo-50 hover:bg-indigo-100'
        }`}
      >
        <div className="flex items-start gap-3">
          {/* Unread indicator */}
          <div className="mt-1.5">
            {!conv.isRead ? (
              <span className="block w-2.5 h-2.5 bg-blue-600 rounded-full" />
            ) : (
              <span className="block w-2.5 h-2.5" />
            )}
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2">
                {isEmail && <Mail className="w-4 h-4 text-amber-600" />}
                <span className={`font-medium text-slate-900 ${!conv.isRead ? 'font-semibold' : ''}`}>
                  {isEmail ? `Forwarded: ${conv.emailSubject}` : conv.householdName}
                </span>
              </div>
              <span className="text-xs text-slate-400">{conv.lastMessageTime}</span>
            </div>

            <p className="text-sm text-slate-600 truncate">
              {isEmail ? conv.householdName : conv.contactName}: {conv.lastMessage}
            </p>

            {conv.relatedWorkOrder && (
              <div className="mt-1 flex items-center gap-1 text-xs text-indigo-600">
                <ClipboardList className="w-3.5 h-3.5" />
                Related: {conv.relatedWorkOrder}
              </div>
            )}

            {isEmail && conv.aiClassification && (
              <div className="mt-2 flex gap-2">
                <button className="px-2 py-1 text-xs font-medium text-amber-700 bg-amber-100 rounded hover:bg-amber-200 transition-colors">
                  Mark Handled
                </button>
                <button className="px-2 py-1 text-xs font-medium text-indigo-700 bg-indigo-100 rounded hover:bg-indigo-200 transition-colors">
                  Add to Bills
                </button>
              </div>
            )}
          </div>
        </div>
      </button>
    );
  };

  return (
    <div className="h-[calc(100vh-7rem)] flex flex-col">
      {/* Header */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-xl flex items-center justify-center">
              <MessageCircle className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-slate-900">Conversations</h1>
              <p className="text-sm text-slate-500">Unified messaging hub</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button className="inline-flex items-center gap-2 px-3 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-colors">
              <Plus className="w-4 h-4" />
              New Message
            </button>
            <button className="px-3 py-2 text-slate-600 hover:bg-slate-100 rounded-lg text-sm font-medium transition-colors">
              <CheckCheck className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 overflow-x-auto">
          {[
            { id: 'all', label: 'All' },
            { id: 'homeowners', label: 'Homeowners' },
            { id: 'vendors', label: 'Vendors' },
            { id: 'emails', label: 'Emails' },
            { id: 'unread', label: `Unread (${unreadCount})` },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as ConversationTab)}
              className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${
                activeTab === tab.id
                  ? 'bg-indigo-600 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex gap-4 min-h-0">
        {/* Conversation List */}
        {showList && (
          <div className={`${isMobileView ? 'w-full' : 'w-96'} flex-shrink-0 bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col`}>
            {/* Search */}
            <div className="p-3 border-b border-slate-100">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search conversations..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>
            </div>

            {/* Conversation List */}
            <div className="flex-1 overflow-y-auto">
              {unreadConversations.length > 0 && (
                <div>
                  <div className="px-4 py-2 bg-slate-50 text-xs font-medium text-slate-500 uppercase tracking-wide">
                    Unread
                  </div>
                  {unreadConversations.map(conv => (
                    <ConversationItem key={conv.id} conv={conv} />
                  ))}
                </div>
              )}

              {readConversations.length > 0 && (
                <div>
                  <div className="px-4 py-2 bg-slate-50 text-xs font-medium text-slate-500 uppercase tracking-wide">
                    Read
                  </div>
                  {readConversations.map(conv => (
                    <ConversationItem key={conv.id} conv={conv} />
                  ))}
                </div>
              )}

              {filteredConversations.length === 0 && (
                <div className="flex items-center justify-center h-full text-slate-500 text-sm">
                  No conversations found
                </div>
              )}
            </div>
          </div>
        )}

        {/* Chat View */}
        {showChat && (
          <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col">
            {selectedConversation ? (
              <>
                {/* Chat Header */}
                <div className="p-4 border-b border-slate-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      {isMobileView && (
                        <button
                          onClick={() => setSelectedConversationId(null)}
                          className="p-2 -ml-2 hover:bg-slate-100 rounded-lg transition-colors"
                        >
                          <ArrowLeft className="w-5 h-5 text-slate-600" />
                        </button>
                      )}
                      <div>
                        <h2 className="font-semibold text-slate-900">{selectedConversation.householdName}</h2>
                        <p className="text-sm text-slate-500">{selectedConversation.contactName}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                        <Phone className="w-5 h-5 text-slate-600" />
                      </button>
                      <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                        <ClipboardList className="w-5 h-5 text-slate-600" />
                      </button>
                      <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                        <MoreVertical className="w-5 h-5 text-slate-600" />
                      </button>
                    </div>
                  </div>

                  {/* Quick Info Bar */}
                  <div className="mt-3 flex items-center gap-2 text-sm text-slate-500">
                    <span>456 Oak Lane</span>
                    <span>•</span>
                    <span>2 requests</span>
                    <span>•</span>
                    <span>Last paid: Dec 15</span>
                    <button className="ml-auto text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
                      View Household <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Messages */}
                <div className="flex-1 overflow-y-auto p-4 bg-slate-50">
                  {/* Date separator */}
                  <div className="text-center mb-4">
                    <span className="px-3 py-1 bg-white rounded-full text-xs text-slate-500 shadow-sm">
                      December 23, 2024
                    </span>
                  </div>

                  {messages.map(message => {
                    const isOwn = message.senderRole === 'manager';
                    const isSystem = message.senderRole === 'system';

                    if (isSystem) {
                      return (
                        <div key={message.id} className="text-center mb-4">
                          <span className="inline-block px-3 py-1 bg-slate-100 rounded-lg text-sm text-slate-500">
                            {message.content}
                          </span>
                        </div>
                      );
                    }

                    return (
                      <div
                        key={message.id}
                        className={`flex mb-4 ${isOwn ? 'justify-end' : 'justify-start'}`}
                      >
                        <div className={`max-w-[80%] ${isOwn ? 'order-1' : ''}`}>
                          {!isOwn && (
                            <p className="text-xs text-slate-500 mb-1">{message.senderName}</p>
                          )}
                          <div
                            className={`p-3 ${
                              isOwn
                                ? 'bg-indigo-600 text-white rounded-2xl rounded-tr-sm'
                                : message.senderRole === 'vendor'
                                ? 'bg-blue-50 text-slate-900 rounded-2xl rounded-tl-sm border border-blue-100'
                                : 'bg-slate-100 text-slate-900 rounded-2xl rounded-tl-sm'
                            }`}
                          >
                            <p className="text-sm">{message.content}</p>
                            {message.attachments && message.attachments.length > 0 && (
                              <div className="mt-2 flex gap-2">
                                {message.attachments.map((att, i) => (
                                  <div
                                    key={i}
                                    className={`flex items-center gap-1 text-xs ${
                                      isOwn ? 'text-indigo-200' : 'text-indigo-600'
                                    }`}
                                  >
                                    <Camera className="w-3.5 h-3.5" />
                                    {att.name}
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                          <p className={`text-xs mt-1 text-slate-400 ${isOwn ? 'text-right' : ''}`}>
                            {message.timestamp}
                            {isOwn && (
                              <Check className="w-3 h-3 inline ml-1" />
                            )}
                          </p>
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>

                {/* Quick Replies */}
                <div className="px-4 py-2 border-t border-slate-100 bg-white">
                  <div className="flex gap-2 overflow-x-auto pb-1">
                    {quickReplies.map(reply => (
                      <button
                        key={reply}
                        onClick={() => handleQuickReply(reply)}
                        className="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm rounded-full whitespace-nowrap transition-colors"
                      >
                        {reply}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Message Input */}
                <div className="p-4 border-t border-slate-200 bg-white">
                  <div className="flex items-center gap-2">
                    <div className="flex-1 relative">
                      <input
                        type="text"
                        placeholder="Type a message..."
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                        className="w-full px-4 py-2.5 pr-20 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                      />
                      <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
                        <button className="p-1.5 text-slate-400 hover:text-slate-600 transition-colors">
                          <Paperclip className="w-5 h-5" />
                        </button>
                        <button className="p-1.5 text-slate-400 hover:text-slate-600 transition-colors">
                          <Camera className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                    <button
                      onClick={handleSendMessage}
                      disabled={!newMessage.trim()}
                      className="px-4 py-2.5 bg-indigo-600 text-white rounded-xl font-medium hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                    >
                      Send
                      <Send className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Action Bar */}
                <div className="px-4 py-3 border-t border-slate-200 bg-slate-50 flex gap-2">
                  <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-200 rounded-lg transition-colors">
                    <Plus className="w-4 h-4" />
                    Create Request
                  </button>
                  <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-200 rounded-lg transition-colors">
                    <Plus className="w-4 h-4" />
                    Create Task
                  </button>
                  <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-200 rounded-lg transition-colors">
                    <Link2 className="w-4 h-4" />
                    Link Work Order
                  </button>
                </div>
              </>
            ) : (
              <div className="flex-1 flex items-center justify-center text-slate-500">
                <div className="text-center">
                  <MessageCircle className="w-16 h-16 mx-auto mb-4 text-slate-300" />
                  <p className="text-lg font-medium text-slate-900">Select a conversation</p>
                  <p className="text-sm text-slate-500">Choose a conversation from the list to view messages</p>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Forwarded Email Modal */}
      {showEmailModal && selectedEmailConv && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Mail className="w-6 h-6 text-amber-600" />
                <div>
                  <h2 className="text-lg font-semibold text-slate-900">Forwarded Email</h2>
                  <p className="text-sm text-slate-500">From: {selectedEmailConv.householdName}</p>
                </div>
              </div>
              <button
                onClick={() => setShowEmailModal(false)}
                className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto max-h-[60vh]">
              {/* Original Email */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">
                  Original Email
                </h3>
                <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">
                  <div className="space-y-1 text-sm mb-4">
                    <p><span className="text-slate-500">From:</span> {mockForwardedEmail.from}</p>
                    <p><span className="text-slate-500">Subject:</span> {mockForwardedEmail.subject}</p>
                    <p><span className="text-slate-500">Date:</span> {mockForwardedEmail.date}</p>
                  </div>
                  <div className="border-t border-slate-200 pt-4">
                    <pre className="text-sm text-slate-700 whitespace-pre-wrap font-sans">
                      {mockForwardedEmail.body}
                    </pre>
                  </div>
                </div>
              </div>

              {/* AI Classification */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-indigo-500" />
                  AI Classification
                </h3>
                <div className="bg-indigo-50 rounded-lg p-4 border border-indigo-100">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="text-slate-500">Type:</span>
                      <span className="ml-2 font-medium text-slate-900">{mockForwardedEmail.aiClassification.type}</span>
                    </div>
                    <div>
                      <span className="text-slate-500">Vendor:</span>
                      <span className="ml-2 font-medium text-slate-900">{mockForwardedEmail.aiClassification.vendor}</span>
                    </div>
                    <div>
                      <span className="text-slate-500">Amount:</span>
                      <span className="ml-2 font-medium text-slate-900">${mockForwardedEmail.aiClassification.amount.toFixed(2)}</span>
                    </div>
                    <div>
                      <span className="text-slate-500">Due Date:</span>
                      <span className="ml-2 font-medium text-slate-900">{mockForwardedEmail.aiClassification.dueDate}</span>
                    </div>
                  </div>
                  <div className="mt-3 flex items-center gap-2">
                    <div className="flex-1 bg-indigo-200 rounded-full h-2">
                      <div
                        className="bg-indigo-600 rounded-full h-2"
                        style={{ width: `${mockForwardedEmail.aiClassification.confidence}%` }}
                      />
                    </div>
                    <span className="text-sm font-medium text-indigo-700">
                      {mockForwardedEmail.aiClassification.confidence}% confidence
                    </span>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">
                  Actions
                </h3>
                <div className="space-y-2">
                  {[
                    { id: 'bills', label: 'Add to Bill Queue', checked: true },
                    { id: 'calendar', label: 'Create Calendar Reminder', checked: false },
                    { id: 'forward', label: 'Forward to Homeowner', checked: false },
                    { id: 'archive', label: 'Archive', checked: false },
                  ].map(action => (
                    <label key={action.id} className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="radio"
                        name="emailAction"
                        defaultChecked={action.checked}
                        className="w-4 h-4 text-indigo-600 focus:ring-indigo-500"
                      />
                      <span className="text-slate-700">{action.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Send Confirmation */}
              <label className="flex items-start gap-3 cursor-pointer p-3 bg-slate-50 rounded-lg border border-slate-200">
                <input
                  type="checkbox"
                  className="mt-0.5 w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span className="text-sm text-slate-700">
                  Send confirmation: &ldquo;Got your ConEd bill - adding to December payments...&rdquo;
                </span>
              </label>
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t border-slate-200 flex justify-end gap-3">
              <button
                onClick={() => setShowEmailModal(false)}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors"
              >
                Cancel
              </button>
              <button className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors flex items-center gap-2">
                Process Email
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
