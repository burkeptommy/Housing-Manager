'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import {
  Search,
  Send,
  ArrowLeft,
  CheckCheck,
  MessageCircle,
  Clock,
  User,
  Home,
  Filter,
} from 'lucide-react';
import { useAuth } from '@/contexts/auth-context';

// ============================================================================
// TYPES
// ============================================================================

interface Message {
  id: string;
  conversationId: string;
  senderUserId: string | null;
  senderRole: 'HOMEOWNER' | 'HOME_MANAGER' | 'SYSTEM';
  body: string;
  attachmentUrl?: string;
  createdAt: string;
  sender?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
}

interface Conversation {
  id: string;
  householdId: string;
  createdByUserId: string;
  subject: string | null;
  status: 'OPEN' | 'PENDING' | 'CLOSED';
  homeownerUnreadCount: number;
  homeManagerUnreadCount: number;
  createdAt: string;
  updatedAt: string;
  createdBy?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
  household?: {
    id: string;
    name: string;
  };
  lastMessage?: Message;
  assignments?: Array<{
    id: string;
    homeManager: {
      id: string;
      firstName: string;
      lastName: string;
      email: string;
    };
  }>;
  messages?: Message[];
}

type FilterType = 'all' | 'open' | 'pending' | 'closed';

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function formatTime(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function formatMessageTime(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function getHomeownerName(conversation: Conversation): string {
  if (conversation.createdBy) {
    return conversation.createdBy.firstName || conversation.createdBy.email.split('@')[0];
  }
  return 'Homeowner';
}

function getHouseholdName(conversation: Conversation): string {
  return conversation.household?.name || 'Household';
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function ManagerConversationsPage() {
  const { getIdToken } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [messageInput, setMessageInput] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev';

  // Fetch conversations
  const fetchConversations = useCallback(async () => {
    try {
      const token = await getIdToken();
      const params = new URLSearchParams();
      if (filter !== 'all') {
        params.set('status', filter.toUpperCase());
      }
      const res = await fetch(`${apiUrl}/internal/conversations/queue?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error('Failed to fetch conversations');
      const data = await res.json();
      setConversations(data);
    } catch (err) {
      console.error('Error fetching conversations:', err);
      setError('Failed to load conversations');
    } finally {
      setLoading(false);
    }
  }, [apiUrl, getIdToken, filter]);

  // Fetch single conversation with messages
  const fetchConversationDetail = useCallback(async (id: string) => {
    try {
      const token = await getIdToken();
      const res = await fetch(`${apiUrl}/internal/conversations/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error('Failed to fetch conversation');
      const data = await res.json();
      setSelectedConversation(data);
    } catch (err) {
      console.error('Error fetching conversation:', err);
    }
  }, [apiUrl, getIdToken]);

  // Send message
  const sendMessage = async () => {
    if (!messageInput.trim() || !selectedConversation || sending) return;

    setSending(true);
    try {
      const token = await getIdToken();
      const res = await fetch(`${apiUrl}/internal/conversations/${selectedConversation.id}/messages`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ body: messageInput.trim() }),
      });

      if (!res.ok) throw new Error('Failed to send message');

      const newMessage = await res.json();

      // Update local state with new message
      setSelectedConversation(prev => prev ? {
        ...prev,
        messages: [...(prev.messages || []), newMessage],
      } : null);

      setMessageInput('');

      // Refresh conversations list
      fetchConversations();
    } catch (err) {
      console.error('Error sending message:', err);
      setError('Failed to send message');
    } finally {
      setSending(false);
    }
  };

  // Update conversation status
  const updateStatus = async (status: 'OPEN' | 'PENDING' | 'CLOSED') => {
    if (!selectedConversation) return;

    try {
      const token = await getIdToken();
      const res = await fetch(`${apiUrl}/internal/conversations/${selectedConversation.id}/status`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status }),
      });

      if (!res.ok) throw new Error('Failed to update status');

      // Refresh both the detail and list
      fetchConversationDetail(selectedConversation.id);
      fetchConversations();
    } catch (err) {
      console.error('Error updating status:', err);
      setError('Failed to update status');
    }
  };

  // Initial fetch
  useEffect(() => {
    fetchConversations();
  }, [fetchConversations]);

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [selectedConversation?.messages]);

  // Poll for new messages when a conversation is selected
  useEffect(() => {
    if (!selectedConversation) return;

    const interval = setInterval(() => {
      fetchConversationDetail(selectedConversation.id);
    }, 5000); // Poll every 5 seconds

    return () => clearInterval(interval);
  }, [selectedConversation?.id, fetchConversationDetail]);

  // Filter conversations by search
  const filteredConversations = conversations.filter(c =>
    !searchQuery ||
    c.subject?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.household?.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.createdBy?.firstName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.createdBy?.lastName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.lastMessage?.body.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Count by status
  const counts = {
    all: conversations.length,
    open: conversations.filter(c => c.status === 'OPEN').length,
    pending: conversations.filter(c => c.status === 'PENDING').length,
    closed: conversations.filter(c => c.status === 'CLOSED').length,
  };

  if (loading) {
    return (
      <div className="h-[calc(100vh-theme(spacing.32))] flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full mx-auto mb-4" />
          <p className="text-slate-500">Loading conversations...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-[calc(100vh-theme(spacing.32))] lg:h-[calc(100vh-theme(spacing.24))] flex flex-col -mx-4 lg:-mx-8 -mt-6 lg:-mt-8">
      {error && (
        <div className="bg-red-50 border-b border-red-200 px-4 py-2 text-red-700 text-sm">
          {error}
          <button onClick={() => setError(null)} className="ml-2 underline">Dismiss</button>
        </div>
      )}

      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar - Conversation List */}
        <div className={`w-full lg:w-96 flex-shrink-0 bg-white border-r border-slate-200 flex flex-col ${
          selectedConversation ? 'hidden lg:flex' : 'flex'
        }`}>
          {/* Header */}
          <div className="p-4 border-b border-slate-200">
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
            </div>

            {/* Search */}
            <div className="relative mb-3">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search conversations..."
                className="w-full pl-10 pr-4 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-600 focus:border-transparent"
              />
            </div>

            {/* Filters */}
            <div className="flex gap-2">
              {(['all', 'open', 'pending', 'closed'] as FilterType[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
                    filter === f
                      ? 'bg-indigo-600 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)} ({counts[f]})
                </button>
              ))}
            </div>
          </div>

          {/* Conversation List */}
          <div className="flex-1 overflow-y-auto">
            {filteredConversations.length === 0 ? (
              <div className="p-8 text-center text-slate-500">
                <MessageCircle className="w-12 h-12 mx-auto mb-4 text-slate-300" />
                <p className="font-medium">No conversations</p>
                <p className="text-sm mt-1">No conversations match your filters</p>
              </div>
            ) : (
              filteredConversations.map((conv) => (
                <button
                  key={conv.id}
                  onClick={() => fetchConversationDetail(conv.id)}
                  className={`w-full flex items-start gap-3 p-4 text-left border-b border-slate-100 transition-colors ${
                    selectedConversation?.id === conv.id
                      ? 'bg-indigo-50 border-l-4 border-l-indigo-600'
                      : conv.homeManagerUnreadCount > 0
                        ? 'bg-indigo-50/50 hover:bg-indigo-50 border-l-4 border-l-indigo-400'
                        : 'hover:bg-slate-50 border-l-4 border-l-transparent'
                  }`}
                >
                  <div className="relative flex-shrink-0">
                    <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center">
                      <Home className="w-6 h-6 text-slate-600" />
                    </div>
                    {conv.homeManagerUnreadCount > 0 && (
                      <div className="absolute -top-1 -right-1 w-5 h-5 bg-indigo-600 rounded-full flex items-center justify-center">
                        <span className="text-xs text-white font-medium">{conv.homeManagerUnreadCount}</span>
                      </div>
                    )}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className={`font-medium truncate ${conv.homeManagerUnreadCount > 0 ? 'text-slate-900' : 'text-slate-700'}`}>
                        {getHouseholdName(conv)}
                      </span>
                      <span className="text-xs text-slate-500 flex-shrink-0">
                        {formatTime(conv.updatedAt)}
                      </span>
                    </div>

                    <p className="text-sm text-slate-600 truncate">
                      {getHomeownerName(conv)}: {conv.subject}
                    </p>

                    {conv.lastMessage && (
                      <p className={`text-sm truncate mt-0.5 ${conv.homeManagerUnreadCount > 0 ? 'text-slate-900 font-medium' : 'text-slate-500'}`}>
                        {conv.lastMessage.senderRole === 'HOME_MANAGER' && <span className="text-indigo-600">You: </span>}
                        {conv.lastMessage.body}
                      </p>
                    )}

                    <div className="mt-1 flex items-center gap-2">
                      <span className={`text-xs px-2 py-0.5 rounded-full ${
                        conv.status === 'OPEN' ? 'bg-emerald-100 text-emerald-700' :
                        conv.status === 'PENDING' ? 'bg-amber-100 text-amber-700' :
                        'bg-slate-100 text-slate-600'
                      }`}>
                        {conv.status}
                      </span>
                    </div>
                  </div>
                </button>
              ))
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
              <div className="bg-white border-b border-slate-200 px-4 py-3">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => setSelectedConversation(null)}
                    className="lg:hidden p-2 hover:bg-slate-100 rounded-lg"
                  >
                    <ArrowLeft className="w-5 h-5 text-slate-600" />
                  </button>

                  <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center">
                    <Home className="w-5 h-5 text-slate-600" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <h2 className="font-semibold text-slate-900 truncate">
                      {getHouseholdName(selectedConversation)}
                    </h2>
                    <p className="text-xs text-slate-500">
                      {getHomeownerName(selectedConversation)} • {selectedConversation.subject || 'Support Request'}
                    </p>
                  </div>

                  {/* Status Actions */}
                  <div className="flex items-center gap-2">
                    {selectedConversation.status !== 'CLOSED' && (
                      <button
                        onClick={() => updateStatus('CLOSED')}
                        className="px-3 py-1.5 text-sm font-medium bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors"
                      >
                        Close
                      </button>
                    )}
                    {selectedConversation.status === 'CLOSED' && (
                      <button
                        onClick={() => updateStatus('OPEN')}
                        className="px-3 py-1.5 text-sm font-medium bg-emerald-100 text-emerald-700 rounded-lg hover:bg-emerald-200 transition-colors"
                      >
                        Reopen
                      </button>
                    )}
                    <span className={`text-xs px-2 py-1 rounded-full ${
                      selectedConversation.status === 'OPEN' ? 'bg-emerald-100 text-emerald-700' :
                      selectedConversation.status === 'PENDING' ? 'bg-amber-100 text-amber-700' :
                      'bg-slate-100 text-slate-600'
                    }`}>
                      {selectedConversation.status}
                    </span>
                  </div>
                </div>
              </div>

              {/* Messages Area */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {selectedConversation.messages?.map((msg) => {
                  const isMe = msg.senderRole === 'HOME_MANAGER';
                  const isSystem = msg.senderRole === 'SYSTEM';

                  if (isSystem) {
                    return (
                      <div key={msg.id} className="flex justify-center">
                        <span className="text-xs text-slate-500 bg-slate-100 px-3 py-1.5 rounded-full">
                          {msg.body}
                        </span>
                      </div>
                    );
                  }

                  return (
                    <div key={msg.id} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                      <div className={`max-w-[80%] ${isMe ? 'order-2' : 'order-1'}`}>
                        {!isMe && (
                          <p className="text-xs text-slate-600 font-medium mb-1 ml-3">
                            {msg.sender?.firstName || getHomeownerName(selectedConversation)}
                          </p>
                        )}
                        <div
                          className={`px-4 py-2.5 ${
                            isMe
                              ? 'bg-indigo-600 text-white rounded-2xl rounded-tr-sm'
                              : 'bg-white border border-slate-200 text-slate-800 rounded-2xl rounded-tl-sm shadow-sm'
                          }`}
                        >
                          <p className="text-sm whitespace-pre-wrap">{msg.body}</p>
                        </div>
                        <div className={`flex items-center gap-1 mt-1 px-3 ${isMe ? 'justify-end' : 'justify-start'}`}>
                          <span className="text-xs text-slate-400">
                            {formatMessageTime(msg.createdAt)}
                          </span>
                          {isMe && (
                            <CheckCheck className="w-3.5 h-3.5 text-indigo-400" />
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* Input Zone */}
              <div className="bg-white border-t border-slate-200 p-4">
                <div className="flex items-end gap-2">
                  <div className="flex-1">
                    <textarea
                      value={messageInput}
                      onChange={(e) => setMessageInput(e.target.value)}
                      placeholder="Type a reply..."
                      rows={1}
                      className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl resize-none focus:ring-2 focus:ring-indigo-600 focus:border-transparent"
                      style={{ maxHeight: '120px' }}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          sendMessage();
                        }
                      }}
                    />
                  </div>
                  <button
                    onClick={sendMessage}
                    disabled={!messageInput.trim() || sending}
                    className="p-3 bg-indigo-600 text-white rounded-full hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    {sending ? (
                      <Clock className="w-5 h-5 animate-spin" />
                    ) : (
                      <Send className="w-5 h-5" />
                    )}
                  </button>
                </div>
              </div>
            </>
          ) : (
            // Empty State
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
              <div className="w-20 h-20 bg-indigo-100 rounded-full flex items-center justify-center mb-6">
                <MessageCircle className="w-10 h-10 text-indigo-600" />
              </div>
              <h2 className="text-xl font-semibold text-slate-900 mb-2">Select a Conversation</h2>
              <p className="text-slate-500 max-w-sm">
                Choose a conversation from the list to view messages and respond to homeowners.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
