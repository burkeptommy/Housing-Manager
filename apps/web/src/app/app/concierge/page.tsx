'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { Conversation, ConversationDetail, SupportMessage } from '@haven/core';

type ConversationType = 'all' | 'manager' | 'handyman' | 'vendor' | 'travel';

const CONVERSATION_TYPES: { value: ConversationType; label: string; icon: React.ReactNode }[] = [
  {
    value: 'all',
    label: 'All Chats',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
    ),
  },
  {
    value: 'manager',
    label: 'Home Manager',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    ),
  },
  {
    value: 'handyman',
    label: 'Handyman',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      </svg>
    ),
  },
  {
    value: 'vendor',
    label: 'Vendors',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      </svg>
    ),
  },
  {
    value: 'travel',
    label: 'Travel',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
];

const STATUS_COLORS: Record<string, string> = {
  OPEN: 'bg-green-500',
  PENDING: 'bg-yellow-500',
  CLOSED: 'bg-slate-400',
};

export default function ConciergePage() {
  const { selectedHouseholdId, user } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<ConversationDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<ConversationType>('all');
  const [showNewChat, setShowNewChat] = useState(false);
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // New chat form state
  const [newChatSubject, setNewChatSubject] = useState('');
  const [newChatMessage, setNewChatMessage] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [selectedConversation?.messages]);

  const loadConversations = useCallback(async () => {
    if (!selectedHouseholdId) {
      setIsLoading(false);
      return;
    }

    try {
      const api = getApiClient();
      const data = await api.getConversations();
      setConversations(data);
      setError(null);
    } catch (err) {
      console.error('Failed to load conversations:', err);
      setError('Failed to load conversations. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [selectedHouseholdId]);

  const loadConversationDetail = useCallback(async (conversationId: string) => {
    try {
      const api = getApiClient();
      const detail = await api.getConversation(conversationId);
      setSelectedConversation(detail);
    } catch (err) {
      console.error('Failed to load conversation:', err);
    }
  }, []);

  useEffect(() => {
    loadConversations();
  }, [loadConversations]);

  // Poll for new messages when a conversation is selected
  useEffect(() => {
    if (!selectedConversation) return;

    const interval = setInterval(() => {
      loadConversationDetail(selectedConversation.id);
    }, 10000);

    return () => clearInterval(interval);
  }, [selectedConversation, loadConversationDetail]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedConversation || !newMessage.trim()) return;

    setIsSending(true);
    try {
      const api = getApiClient();
      await api.sendConversationMessage(selectedConversation.id, {
        body: newMessage.trim(),
      });
      setNewMessage('');
      await loadConversationDetail(selectedConversation.id);
    } catch (err) {
      console.error('Failed to send message:', err);
    } finally {
      setIsSending(false);
    }
  };

  const handleCreateConversation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newChatMessage.trim()) return;

    setIsCreating(true);
    try {
      const api = getApiClient();
      const newConv = await api.createConversation({
        subject: newChatSubject.trim() || undefined,
        body: newChatMessage.trim(),
      });
      setShowNewChat(false);
      setNewChatSubject('');
      setNewChatMessage('');
      await loadConversations();
      await loadConversationDetail(newConv.id);
    } catch (err) {
      console.error('Failed to create conversation:', err);
    } finally {
      setIsCreating(false);
    }
  };

  const getConversationLabel = (conv: Conversation): string => {
    // Determine the type based on subject or assignments
    const subject = conv.subject?.toLowerCase() || '';
    if (subject.includes('handyman') || subject.includes('maintenance')) return 'Handyman';
    if (subject.includes('vendor') || subject.includes('contractor')) return 'Vendor';
    if (subject.includes('travel') || subject.includes('trip')) return 'Travel';
    return 'Home Manager';
  };

  const getConversationIcon = (conv: Conversation) => {
    const label = getConversationLabel(conv);
    const type = CONVERSATION_TYPES.find(t => t.label === label);
    return type?.icon || CONVERSATION_TYPES[1].icon;
  };

  const filteredConversations = conversations.filter(conv => {
    if (activeFilter === 'all') return true;
    const label = getConversationLabel(conv).toLowerCase();
    if (activeFilter === 'manager') return label === 'home manager';
    if (activeFilter === 'handyman') return label === 'handyman';
    if (activeFilter === 'vendor') return label === 'vendor';
    if (activeFilter === 'travel') return label === 'travel';
    return true;
  });

  const formatTime = (dateStr: string) => {
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
  };

  if (!selectedHouseholdId) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-slate-600 dark:text-slate-400">Please select a household to view messages.</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <p className="text-red-600 dark:text-red-400">{error}</p>
        <button
          onClick={loadConversations}
          className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Concierge</h1>
          <p className="text-slate-600 dark:text-slate-400">
            Chat with your home manager, handyman, and vendors
          </p>
        </div>
        <button
          onClick={() => setShowNewChat(true)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Chat
        </button>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 mb-4 overflow-x-auto pb-2">
        {CONVERSATION_TYPES.map(type => (
          <button
            key={type.value}
            onClick={() => setActiveFilter(type.value)}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-colors whitespace-nowrap ${
              activeFilter === type.value
                ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600'
            }`}
          >
            {type.icon}
            {type.label}
          </button>
        ))}
      </div>

      {/* Main Content - Chat Interface */}
      <div className="flex-1 flex bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden min-h-0">
        {/* Conversation List */}
        <div className="w-80 border-r border-slate-200 dark:border-slate-700 flex flex-col">
          <div className="p-3 border-b border-slate-200 dark:border-slate-700">
            <div className="relative">
              <input
                type="text"
                placeholder="Search conversations..."
                className="w-full pl-10 pr-4 py-2 text-sm border border-slate-300 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-slate-900 dark:text-white placeholder-slate-400"
              />
              <svg className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </div>

          <div className="flex-1 overflow-y-auto">
            {filteredConversations.length === 0 ? (
              <div className="p-6 text-center">
                <svg className="w-12 h-12 mx-auto text-slate-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
                <p className="text-slate-600 dark:text-slate-400 text-sm">No conversations yet</p>
                <button
                  onClick={() => setShowNewChat(true)}
                  className="mt-3 text-sm text-emerald-600 dark:text-emerald-400 hover:underline"
                >
                  Start a new chat
                </button>
              </div>
            ) : (
              filteredConversations.map(conv => (
                <button
                  key={conv.id}
                  onClick={() => loadConversationDetail(conv.id)}
                  className={`w-full p-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors border-b border-slate-100 dark:border-slate-700 ${
                    selectedConversation?.id === conv.id ? 'bg-emerald-50 dark:bg-emerald-900/20' : ''
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center text-slate-600 dark:text-slate-400 flex-shrink-0">
                      {getConversationIcon(conv)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-2">
                        <span className="font-medium text-slate-900 dark:text-white truncate">
                          {conv.subject || getConversationLabel(conv)}
                        </span>
                        <span className="text-xs text-slate-500 dark:text-slate-400 flex-shrink-0">
                          {formatTime(conv.updatedAt)}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 mt-1">
                        <span className={`w-2 h-2 rounded-full ${STATUS_COLORS[conv.status]}`} />
                        <span className="text-xs text-slate-500 dark:text-slate-400">
                          {getConversationLabel(conv)}
                        </span>
                      </div>
                      {conv.lastMessage && (
                        <p className="text-sm text-slate-600 dark:text-slate-400 truncate mt-1">
                          {conv.lastMessage.body}
                        </p>
                      )}
                      {conv.homeownerUnreadCount > 0 && (
                        <span className="inline-flex items-center justify-center min-w-5 h-5 px-1.5 rounded-full bg-emerald-600 text-white text-xs font-medium mt-1">
                          {conv.homeownerUnreadCount}
                        </span>
                      )}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>

        {/* Message Panel */}
        <div className="flex-1 flex flex-col min-w-0">
          {selectedConversation ? (
            <>
              {/* Conversation Header */}
              <div className="p-4 border-b border-slate-200 dark:border-slate-700 flex items-center gap-4">
                <div className="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center text-slate-600 dark:text-slate-400">
                  {getConversationIcon(selectedConversation)}
                </div>
                <div className="flex-1">
                  <h2 className="font-semibold text-slate-900 dark:text-white">
                    {selectedConversation.subject || getConversationLabel(selectedConversation)}
                  </h2>
                  <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
                    <span className={`w-2 h-2 rounded-full ${STATUS_COLORS[selectedConversation.status]}`} />
                    <span>{selectedConversation.status}</span>
                    {selectedConversation.assignments && selectedConversation.assignments.length > 0 && (
                      <>
                        <span>•</span>
                        <span>
                          {selectedConversation.assignments[0].homeManager?.firstName || 'Assigned'}
                        </span>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {selectedConversation.messages.map((msg) => {
                  const isOwn = msg.senderRole === 'HOMEOWNER';
                  return (
                    <div
                      key={msg.id}
                      className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}
                    >
                      <div
                        className={`max-w-[70%] rounded-2xl px-4 py-2 ${
                          isOwn
                            ? 'bg-emerald-600 text-white'
                            : msg.senderRole === 'SYSTEM'
                            ? 'bg-slate-200 dark:bg-slate-600 text-slate-700 dark:text-slate-200 italic'
                            : 'bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-white'
                        }`}
                      >
                        {!isOwn && msg.sender && (
                          <p className={`text-xs font-medium mb-1 ${isOwn ? 'text-emerald-200' : 'text-slate-500 dark:text-slate-400'}`}>
                            {msg.sender.firstName || 'Manager'}
                          </p>
                        )}
                        <p className="text-sm whitespace-pre-wrap">{msg.body}</p>
                        <p className={`text-xs mt-1 ${isOwn ? 'text-emerald-200' : 'text-slate-400'}`}>
                          {formatTime(msg.createdAt)}
                        </p>
                      </div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* Message Input */}
              <form onSubmit={handleSendMessage} className="p-4 border-t border-slate-200 dark:border-slate-700">
                <div className="flex gap-3">
                  <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Type a message..."
                    className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-full bg-white dark:bg-slate-700 text-slate-900 dark:text-white placeholder-slate-400"
                    disabled={isSending}
                  />
                  <button
                    type="submit"
                    disabled={isSending || !newMessage.trim()}
                    className="px-4 py-2 bg-emerald-600 text-white rounded-full hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSending ? (
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    ) : (
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                      </svg>
                    )}
                  </button>
                </div>
              </form>
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
              <div className="w-16 h-16 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
                Select a conversation
              </h3>
              <p className="text-slate-600 dark:text-slate-400 mb-4">
                Choose from the list or start a new chat with your home management team
              </p>
              <button
                onClick={() => setShowNewChat(true)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Start New Chat
              </button>
            </div>
          )}
        </div>
      </div>

      {/* New Chat Modal */}
      {showNewChat && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-slate-900 dark:text-white">New Conversation</h2>
                <button
                  onClick={() => setShowNewChat(false)}
                  className="p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <form onSubmit={handleCreateConversation} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Subject (Optional)
                  </label>
                  <input
                    type="text"
                    value={newChatSubject}
                    onChange={(e) => setNewChatSubject(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                    placeholder="e.g., Question about home maintenance"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Message
                  </label>
                  <textarea
                    value={newChatMessage}
                    onChange={(e) => setNewChatMessage(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                    rows={4}
                    placeholder="How can we help you today?"
                    required
                  />
                </div>

                <div className="p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
                  <div className="flex items-start gap-3">
                    <svg className="w-5 h-5 text-emerald-600 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <div>
                      <p className="text-sm font-medium text-emerald-800 dark:text-emerald-300">
                        Your home manager will respond
                      </p>
                      <p className="text-sm text-emerald-700 dark:text-emerald-400 mt-1">
                        Messages are typically answered within a few hours during business hours.
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowNewChat(false)}
                    className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isCreating || !newChatMessage.trim()}
                    className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isCreating ? 'Sending...' : 'Start Conversation'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
