'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/contexts/auth-context';
import type {
  Conversation,
  ConversationDetail,
  SupportMessage,
  ConversationStatus,
} from '@haven/core';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

// Fetch helper with auth
async function authFetch(path: string, options: RequestInit = {}, token: string | null) {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  if (token) {
    (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
  }
  return fetch(`${API_BASE_URL}${path}`, { ...options, headers });
}

// Format time helper
function formatTime(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));

  if (days > 0) {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  }

  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

// Get sender display name
function getSenderName(message: SupportMessage): string {
  if (message.senderRole === 'SYSTEM') return 'System';
  if (message.sender) {
    const firstName = message.sender.firstName || '';
    const lastName = message.sender.lastName || '';
    if (firstName || lastName) return `${firstName} ${lastName}`.trim();
    return message.sender.email;
  }
  return message.senderRole === 'HOME_MANAGER' ? 'You' : 'Homeowner';
}

// Status badge component
function StatusBadge({ status }: { status: ConversationStatus }) {
  const styles: Record<ConversationStatus, string> = {
    OPEN: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
    PENDING: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
    CLOSED: 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-400',
  };

  return (
    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${styles[status]}`}>
      {status}
    </span>
  );
}

// Conversation list item
function ConversationListItem({
  conversation,
  isSelected,
  onClick,
}: {
  conversation: Conversation;
  isSelected: boolean;
  onClick: () => void;
}) {
  const hasUnread = conversation.homeManagerUnreadCount > 0;

  return (
    <button
      onClick={onClick}
      className={`w-full text-left p-4 border-b border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors ${
        isSelected ? 'bg-emerald-50 dark:bg-emerald-900/20 border-l-2 border-l-emerald-600' : ''
      }`}
    >
      <div className="flex items-start justify-between mb-1">
        <div className="flex items-center gap-2">
          <span className={`font-medium text-slate-900 dark:text-white ${hasUnread ? 'font-semibold' : ''}`}>
            {conversation.subject || 'Support Request'}
          </span>
          {hasUnread && (
            <span className="flex items-center justify-center w-5 h-5 text-xs font-bold text-white bg-emerald-600 rounded-full">
              {conversation.homeManagerUnreadCount}
            </span>
          )}
        </div>
        <StatusBadge status={conversation.status} />
      </div>
      <div className="flex items-center justify-between text-sm">
        <span className="text-slate-500 dark:text-slate-400">
          {conversation.createdBy?.firstName} {conversation.createdBy?.lastName || conversation.createdBy?.email}
        </span>
        <span className="text-slate-400 dark:text-slate-500">{formatTime(conversation.updatedAt)}</span>
      </div>
      {conversation.lastMessage && (
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400 line-clamp-1">
          {conversation.lastMessage.body}
        </p>
      )}
    </button>
  );
}

// Message bubble component
function MessageBubble({
  message,
  isOwn,
}: {
  message: SupportMessage;
  isOwn: boolean;
}) {
  const senderName = getSenderName(message);
  const isSystem = message.senderRole === 'SYSTEM';

  if (isSystem) {
    return (
      <div className="flex justify-center my-4">
        <div className="px-4 py-2 text-sm text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 rounded-full">
          {message.body}
        </div>
      </div>
    );
  }

  return (
    <div className={`flex ${isOwn ? 'justify-end' : 'justify-start'} mb-4`}>
      {!isOwn && (
        <div className="flex-shrink-0 mr-3">
          <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center">
            <span className="text-sm font-medium text-white">
              {senderName.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>
      )}
      <div className={`max-w-[70%] ${isOwn ? 'order-1' : ''}`}>
        {!isOwn && (
          <p className="text-xs text-slate-500 dark:text-slate-400 mb-1">{senderName}</p>
        )}
        <div
          className={`px-4 py-2 rounded-2xl ${
            isOwn
              ? 'bg-emerald-600 text-white rounded-br-sm'
              : 'bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white rounded-bl-sm'
          }`}
        >
          <p className="text-sm whitespace-pre-wrap">{message.body}</p>
        </div>
        <p className={`text-xs mt-1 ${isOwn ? 'text-right' : ''} text-slate-400 dark:text-slate-500`}>
          {formatTime(message.createdAt)}
        </p>
      </div>
    </div>
  );
}

// Chat view component
function ChatView({
  conversation,
  token,
  userId,
  onRefresh,
  onStatusChange,
  onAssign,
}: {
  conversation: ConversationDetail;
  token: string | null;
  userId: string;
  onRefresh: () => void;
  onStatusChange: (status: ConversationStatus) => void;
  onAssign: () => void;
}) {
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [conversation.messages]);

  const handleSend = async () => {
    if (!newMessage.trim() || isSending) return;

    setIsSending(true);
    try {
      const response = await authFetch(
        `/internal/conversations/${conversation.id}/messages`,
        {
          method: 'POST',
          body: JSON.stringify({ body: newMessage.trim() }),
        },
        token
      );

      if (response.ok) {
        setNewMessage('');
        onRefresh();
      }
    } catch (error) {
      console.error('Failed to send message:', error);
    } finally {
      setIsSending(false);
    }
  };

  const isAssigned = conversation.assignments && conversation.assignments.length > 0;
  const isAssignedToMe = conversation.assignments?.some((a) => a.homeManagerUserId === userId);

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900">
        <div>
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
            {conversation.subject || 'Support Request'}
          </h2>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-sm text-slate-500 dark:text-slate-400">
              {conversation.household?.name} • {conversation.createdBy?.firstName} {conversation.createdBy?.lastName}
            </span>
            <StatusBadge status={conversation.status} />
          </div>
        </div>
        <div className="flex items-center gap-2">
          {!isAssigned && (
            <button
              onClick={onAssign}
              className="px-3 py-1.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg transition-colors"
            >
              Assign to Me
            </button>
          )}
          {conversation.status !== 'CLOSED' && (
            <select
              value={conversation.status}
              onChange={(e) => onStatusChange(e.target.value as ConversationStatus)}
              className="px-3 py-1.5 text-sm font-medium border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
            >
              <option value="OPEN">Open</option>
              <option value="PENDING">Pending</option>
              <option value="CLOSED">Close</option>
            </select>
          )}
          {conversation.status === 'CLOSED' && (
            <button
              onClick={() => onStatusChange('OPEN')}
              className="px-3 py-1.5 text-sm font-medium text-emerald-600 border border-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-900/20 rounded-lg transition-colors"
            >
              Reopen
            </button>
          )}
        </div>
      </div>

      {/* Assignment info */}
      {isAssigned && (
        <div className="px-4 py-2 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
          <p className="text-sm text-slate-600 dark:text-slate-400">
            Assigned to: {isAssignedToMe ? 'You' : conversation.assignments?.[0]?.homeManager?.firstName + ' ' + conversation.assignments?.[0]?.homeManager?.lastName}
          </p>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 bg-slate-50 dark:bg-slate-900">
        {conversation.messages.map((message) => (
          <MessageBubble
            key={message.id}
            message={message}
            isOwn={message.senderRole === 'HOME_MANAGER' && message.senderUserId === userId}
          />
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Composer */}
      {conversation.status !== 'CLOSED' && (
        <div className="p-4 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-700">
          <div className="flex gap-2">
            <input
              type="text"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
              placeholder="Type your reply..."
              className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <button
              onClick={handleSend}
              disabled={!newMessage.trim() || isSending}
              className="px-4 py-2 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 disabled:bg-slate-300 disabled:cursor-not-allowed rounded-lg transition-colors"
            >
              {isSending ? 'Sending...' : 'Send'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// Main page component
export default function ManagerConversationsPage() {
  const { user, firebaseUser } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<ConversationDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'unassigned' | 'mine'>('all');
  const [statusFilter, setStatusFilter] = useState<ConversationStatus | ''>('');
  const [token, setToken] = useState<string | null>(null);

  // Get Firebase token
  useEffect(() => {
    const getToken = async () => {
      if (firebaseUser) {
        const t = await firebaseUser.getIdToken();
        setToken(t);
      }
    };
    getToken();
  }, [firebaseUser]);

  // Fetch conversations
  const fetchConversations = useCallback(async () => {
    if (!token) return;

    try {
      const params = new URLSearchParams();
      if (statusFilter) params.set('status', statusFilter);
      if (filter === 'unassigned') params.set('unassigned', 'true');
      if (filter === 'mine') params.set('assignedToMe', 'true');

      const response = await authFetch(`/internal/conversations?${params}`, {}, token);
      if (response.ok) {
        const data = await response.json();
        setConversations(data);
      }
    } catch (error) {
      console.error('Failed to fetch conversations:', error);
    } finally {
      setIsLoading(false);
    }
  }, [token, filter, statusFilter]);

  // Fetch single conversation
  const fetchConversation = useCallback(
    async (id: string) => {
      if (!token) return;

      try {
        const response = await authFetch(`/internal/conversations/${id}`, {}, token);
        if (response.ok) {
          const data = await response.json();
          setSelectedConversation(data);
        }
      } catch (error) {
        console.error('Failed to fetch conversation:', error);
      }
    },
    [token]
  );

  // Initial load
  useEffect(() => {
    fetchConversations();
  }, [fetchConversations]);

  // Poll for updates
  useEffect(() => {
    const interval = setInterval(() => {
      fetchConversations();
      if (selectedConversation) {
        fetchConversation(selectedConversation.id);
      }
    }, 10000);
    return () => clearInterval(interval);
  }, [fetchConversations, fetchConversation, selectedConversation]);

  // Handle status change
  const handleStatusChange = async (status: ConversationStatus) => {
    if (!selectedConversation || !token) return;

    try {
      const response = await authFetch(
        `/internal/conversations/${selectedConversation.id}/status`,
        {
          method: 'PATCH',
          body: JSON.stringify({ status }),
        },
        token
      );

      if (response.ok) {
        fetchConversation(selectedConversation.id);
        fetchConversations();
      }
    } catch (error) {
      console.error('Failed to update status:', error);
    }
  };

  // Handle assign
  const handleAssign = async () => {
    if (!selectedConversation || !token || !user) return;

    try {
      const response = await authFetch(
        `/internal/conversations/${selectedConversation.id}/assign`,
        {
          method: 'POST',
          body: JSON.stringify({ homeManagerUserId: user.id }),
        },
        token
      );

      if (response.ok) {
        fetchConversation(selectedConversation.id);
        fetchConversations();
      }
    } catch (error) {
      console.error('Failed to assign conversation:', error);
    }
  };

  // Calculate stats
  const stats = {
    total: conversations.length,
    open: conversations.filter((c) => c.status === 'OPEN').length,
    pending: conversations.filter((c) => c.status === 'PENDING').length,
    unread: conversations.reduce((sum, c) => sum + c.homeManagerUnreadCount, 0),
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  return (
    <div className="h-[calc(100vh-8rem)]">
      {/* Header */}
      <div className="mb-4">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Conversations</h1>
        <p className="text-slate-600 dark:text-slate-400">
          Manage support conversations with homeowners
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4 mb-4">
        <div className="card py-3">
          <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.total}</p>
          <p className="text-sm text-slate-500 dark:text-slate-400">Total</p>
        </div>
        <div className="card py-3">
          <p className="text-2xl font-bold text-green-600">{stats.open}</p>
          <p className="text-sm text-slate-500 dark:text-slate-400">Open</p>
        </div>
        <div className="card py-3">
          <p className="text-2xl font-bold text-yellow-600">{stats.pending}</p>
          <p className="text-sm text-slate-500 dark:text-slate-400">Pending</p>
        </div>
        <div className="card py-3">
          <p className="text-2xl font-bold text-emerald-600">{stats.unread}</p>
          <p className="text-sm text-slate-500 dark:text-slate-400">Unread</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-4 mb-4">
        <div className="flex gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
              filter === 'all'
                ? 'bg-emerald-600 text-white'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('unassigned')}
            className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
              filter === 'unassigned'
                ? 'bg-emerald-600 text-white'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            Unassigned
          </button>
          <button
            onClick={() => setFilter('mine')}
            className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
              filter === 'mine'
                ? 'bg-emerald-600 text-white'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            Assigned to Me
          </button>
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as ConversationStatus | '')}
          className="px-3 py-1.5 text-sm font-medium border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
        >
          <option value="">All Statuses</option>
          <option value="OPEN">Open</option>
          <option value="PENDING">Pending</option>
          <option value="CLOSED">Closed</option>
        </select>
      </div>

      {/* Main content */}
      <div className="flex gap-4 h-[calc(100%-12rem)]">
        {/* Conversation list */}
        <div className="w-96 flex-shrink-0 bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden">
          <div className="overflow-y-auto h-full">
            {conversations.length > 0 ? (
              conversations.map((conversation) => (
                <ConversationListItem
                  key={conversation.id}
                  conversation={conversation}
                  isSelected={selectedConversation?.id === conversation.id}
                  onClick={() => fetchConversation(conversation.id)}
                />
              ))
            ) : (
              <div className="flex items-center justify-center h-full text-slate-500 dark:text-slate-400">
                No conversations found
              </div>
            )}
          </div>
        </div>

        {/* Chat view */}
        <div className="flex-1 bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden">
          {selectedConversation && user ? (
            <ChatView
              conversation={selectedConversation}
              token={token}
              userId={user.id}
              onRefresh={() => fetchConversation(selectedConversation.id)}
              onStatusChange={handleStatusChange}
              onAssign={handleAssign}
            />
          ) : (
            <div className="flex items-center justify-center h-full text-slate-500 dark:text-slate-400">
              <div className="text-center">
                <svg
                  className="w-16 h-16 mx-auto mb-4 text-slate-300 dark:text-slate-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                  />
                </svg>
                <p>Select a conversation to view</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
