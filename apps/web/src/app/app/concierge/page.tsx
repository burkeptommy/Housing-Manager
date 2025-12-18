'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { Conversation, ConversationDetail, SupportMessage } from '@haven/core';

// Main tabs for the unified page
type MainTab = 'concierge' | 'support' | 'travel';

// Role type for message tags
type StaffRole = 'Home Manager' | 'Handyman' | 'Vendor' | 'Travel Agent' | 'Support';

const MAIN_TABS: { value: MainTab; label: string; description: string; icon: React.ReactNode }[] = [
  {
    value: 'concierge',
    label: 'Concierge',
    description: 'Your dedicated home management team',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    ),
  },
  {
    value: 'support',
    label: 'Support',
    description: 'Get help with issues and questions',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
    ),
  },
  {
    value: 'travel',
    label: 'Travel Planning',
    description: 'Plan trips and vacations',
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

const ROLE_BADGE_COLORS: Record<StaffRole, { bg: string; text: string }> = {
  'Home Manager': { bg: 'bg-emerald-100 dark:bg-emerald-900/40', text: 'text-emerald-700 dark:text-emerald-400' },
  'Handyman': { bg: 'bg-amber-100 dark:bg-amber-900/40', text: 'text-amber-700 dark:text-amber-400' },
  'Vendor': { bg: 'bg-blue-100 dark:bg-blue-900/40', text: 'text-blue-700 dark:text-blue-400' },
  'Travel Agent': { bg: 'bg-purple-100 dark:bg-purple-900/40', text: 'text-purple-700 dark:text-purple-400' },
  'Support': { bg: 'bg-slate-100 dark:bg-slate-700', text: 'text-slate-600 dark:text-slate-300' },
};

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

export default function UnifiedConciergePage() {
  const { selectedHouseholdId, user, householdInfo } = useAuth();
  const [activeTab, setActiveTab] = useState<MainTab>('concierge');
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<ConversationDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showNewChat, setShowNewChat] = useState(false);
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState<string | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // New chat form state
  const [newChatSubject, setNewChatSubject] = useState('');
  const [newChatMessage, setNewChatMessage] = useState('');
  const [newChatType, setNewChatType] = useState<MainTab>('concierge');
  const [isCreating, setIsCreating] = useState(false);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [selectedConversation?.messages]);

  // Clean up file preview URL
  useEffect(() => {
    return () => {
      if (filePreview) URL.revokeObjectURL(filePreview);
    };
  }, [filePreview]);

  // Determine the staff role from conversation or message
  const getStaffRole = (conv: Conversation | ConversationDetail): StaffRole => {
    const subject = conv.subject?.toLowerCase() || '';
    if (subject.includes('handyman') || subject.includes('maintenance') || subject.includes('repair')) {
      return 'Handyman';
    }
    if (subject.includes('vendor') || subject.includes('contractor') || subject.includes('plumber') || subject.includes('electrician')) {
      return 'Vendor';
    }
    if (subject.includes('travel') || subject.includes('trip') || subject.includes('vacation') || subject.includes('flight')) {
      return 'Travel Agent';
    }
    if (subject.includes('support') || subject.includes('help') || subject.includes('issue') || subject.includes('problem')) {
      return 'Support';
    }
    return 'Home Manager';
  };

  // Filter conversations by tab
  const getFilteredConversations = useCallback(() => {
    return conversations.filter(conv => {
      const role = getStaffRole(conv);
      switch (activeTab) {
        case 'concierge':
          return role === 'Home Manager' || role === 'Handyman' || role === 'Vendor';
        case 'support':
          return role === 'Support';
        case 'travel':
          return role === 'Travel Agent';
        default:
          return true;
      }
    });
  }, [conversations, activeTab]);

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
    }, 5000);

    return () => clearInterval(interval);
  }, [selectedConversation, loadConversationDetail]);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadError(null);

    if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
      setUploadError('Please select an image file (JPEG, PNG, GIF, or WebP)');
      return;
    }

    if (file.size > MAX_FILE_SIZE) {
      setUploadError('File is too large. Maximum size is 10MB.');
      return;
    }

    setSelectedFile(file);
    setFilePreview(URL.createObjectURL(file));
  };

  const clearSelectedFile = () => {
    setSelectedFile(null);
    if (filePreview) URL.revokeObjectURL(filePreview);
    setFilePreview(null);
    setUploadError(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedConversation || (!newMessage.trim() && !selectedFile)) return;

    setIsSending(true);
    let attachmentFileId: string | undefined;

    // Upload file if selected
    if (selectedFile && householdInfo?.id) {
      setIsUploading(true);
      try {
        const api = getApiClient();
        const fileAsset = await api.uploadFileToGcs(selectedFile, {
          householdId: householdInfo.id,
          type: 'ISSUE_PHOTO',
        });
        attachmentFileId = fileAsset.id;
      } catch (err: any) {
        setUploadError(err.message || 'Failed to upload file');
        setIsUploading(false);
        setIsSending(false);
        return;
      }
      setIsUploading(false);
    }

    try {
      const api = getApiClient();
      await api.sendConversationMessage(selectedConversation.id, {
        body: newMessage.trim() || (selectedFile ? 'Sent a photo' : ''),
        attachmentFileId,
      });
      setNewMessage('');
      clearSelectedFile();
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
      // Add a prefix to the subject based on the type for proper categorization
      let subjectPrefix = '';
      if (newChatType === 'travel') subjectPrefix = '[Travel] ';
      else if (newChatType === 'support') subjectPrefix = '[Support] ';

      const newConv = await api.createConversation({
        subject: subjectPrefix + (newChatSubject.trim() || 'New conversation'),
        body: newChatMessage.trim(),
      });
      setShowNewChat(false);
      setNewChatSubject('');
      setNewChatMessage('');
      setNewChatType('concierge');
      await loadConversations();
      await loadConversationDetail(newConv.id);
      // Switch to the appropriate tab
      setActiveTab(newChatType);
    } catch (err) {
      console.error('Failed to create conversation:', err);
    } finally {
      setIsCreating(false);
    }
  };

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

  const filteredConversations = getFilteredConversations();

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
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Messages</h1>
          <p className="text-slate-600 dark:text-slate-400">
            All your conversations in one place
          </p>
        </div>
        <button
          onClick={() => setShowNewChat(true)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Message
        </button>
      </div>

      {/* Main Tabs */}
      <div className="flex border-b border-slate-200 dark:border-slate-700 mb-4">
        {MAIN_TABS.map(tab => (
          <button
            key={tab.value}
            onClick={() => {
              setActiveTab(tab.value);
              setSelectedConversation(null);
            }}
            className={`flex items-center gap-2 px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.value
                ? 'border-emerald-600 text-emerald-600 dark:text-emerald-400'
                : 'border-transparent text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:border-slate-300'
            }`}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Description */}
      <p className="text-sm text-slate-500 dark:text-slate-400 mb-4">
        {MAIN_TABS.find(t => t.value === activeTab)?.description}
      </p>

      {/* Main Content - Chat Interface */}
      <div className="flex-1 flex bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden min-h-0">
        {/* Conversation List */}
        <div className={`w-80 border-r border-slate-200 dark:border-slate-700 flex flex-col ${
          selectedConversation ? 'hidden lg:flex' : 'flex'
        }`}>
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
                <p className="text-slate-600 dark:text-slate-400 text-sm">No conversations in {MAIN_TABS.find(t => t.value === activeTab)?.label}</p>
                <button
                  onClick={() => {
                    setNewChatType(activeTab);
                    setShowNewChat(true);
                  }}
                  className="mt-3 text-sm text-emerald-600 dark:text-emerald-400 hover:underline"
                >
                  Start a new conversation
                </button>
              </div>
            ) : (
              filteredConversations.map(conv => {
                const role = getStaffRole(conv);
                const roleColors = ROLE_BADGE_COLORS[role];
                return (
                  <button
                    key={conv.id}
                    onClick={() => loadConversationDetail(conv.id)}
                    className={`w-full p-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors border-b border-slate-100 dark:border-slate-700 ${
                      selectedConversation?.id === conv.id ? 'bg-emerald-50 dark:bg-emerald-900/20 border-l-4 border-l-emerald-600' : ''
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <div className="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center text-slate-600 dark:text-slate-400 flex-shrink-0">
                        {MAIN_TABS.find(t => t.value === activeTab)?.icon}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-medium text-slate-900 dark:text-white truncate">
                            {conv.subject || 'Conversation'}
                          </span>
                          <span className="text-xs text-slate-500 dark:text-slate-400 flex-shrink-0">
                            {formatTime(conv.updatedAt)}
                          </span>
                        </div>
                        {/* Role Badge */}
                        <div className="flex items-center gap-2 mt-1">
                          <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${roleColors.bg} ${roleColors.text}`}>
                            {role}
                          </span>
                          <span className={`w-2 h-2 rounded-full ${STATUS_COLORS[conv.status]}`} />
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
                );
              })
            )}
          </div>
        </div>

        {/* Message Panel */}
        <div className={`flex-1 flex flex-col min-w-0 ${!selectedConversation ? 'hidden lg:flex' : 'flex'}`}>
          {selectedConversation ? (
            <>
              {/* Conversation Header */}
              <div className="p-4 border-b border-slate-200 dark:border-slate-700 flex items-center gap-4">
                <button
                  onClick={() => setSelectedConversation(null)}
                  className="lg:hidden p-2 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <div className="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center text-slate-600 dark:text-slate-400">
                  {MAIN_TABS.find(t => t.value === activeTab)?.icon}
                </div>
                <div className="flex-1">
                  <h2 className="font-semibold text-slate-900 dark:text-white">
                    {selectedConversation.subject || 'Conversation'}
                  </h2>
                  <div className="flex items-center gap-2 mt-1">
                    {(() => {
                      const role = getStaffRole(selectedConversation);
                      const roleColors = ROLE_BADGE_COLORS[role];
                      return (
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${roleColors.bg} ${roleColors.text}`}>
                          {role}
                        </span>
                      );
                    })()}
                    <span className={`w-2 h-2 rounded-full ${STATUS_COLORS[selectedConversation.status]}`} />
                    <span className="text-xs text-slate-500 dark:text-slate-400">{selectedConversation.status}</span>
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-slate-50 dark:bg-slate-900">
                {selectedConversation.messages.map((msg) => {
                  const isOwn = msg.senderRole === 'HOMEOWNER';
                  const isSystem = msg.senderRole === 'SYSTEM';

                  // Determine staff role for non-homeowner messages
                  const staffRole: StaffRole = getStaffRole(selectedConversation);
                  const roleColors = ROLE_BADGE_COLORS[staffRole];

                  if (isSystem) {
                    return (
                      <div key={msg.id} className="flex justify-center my-4">
                        <span className="text-xs text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-slate-700 px-3 py-1 rounded-full">
                          {msg.body}
                        </span>
                      </div>
                    );
                  }

                  return (
                    <div
                      key={msg.id}
                      className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}
                    >
                      <div
                        className={`max-w-[70%] rounded-2xl px-4 py-2 ${
                          isOwn
                            ? 'bg-emerald-600 text-white rounded-br-sm'
                            : 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white rounded-bl-sm shadow-sm'
                        }`}
                      >
                        {!isOwn && (
                          <div className="mb-1">
                            <p className="text-sm font-medium text-slate-900 dark:text-white">
                              {msg.sender?.firstName || 'Haven Team'}
                            </p>
                            {/* Role Tag */}
                            <span className={`inline-block text-xs px-2 py-0.5 rounded-full font-medium mt-0.5 ${roleColors.bg} ${roleColors.text}`}>
                              {staffRole}
                            </span>
                          </div>
                        )}
                        <p className="text-sm whitespace-pre-wrap">{msg.body}</p>
                        {/* Attachment handling */}
                        {msg.attachmentUrl && (
                          <a
                            href={msg.attachmentUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="block mt-2"
                          >
                            {msg.attachmentUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
                              <img
                                src={msg.attachmentUrl}
                                alt="Attachment"
                                className="max-w-full max-h-64 rounded-lg object-cover"
                              />
                            ) : (
                              <span className={`text-sm underline ${isOwn ? 'text-emerald-100' : 'text-emerald-600 dark:text-emerald-400'}`}>
                                View attachment
                              </span>
                            )}
                          </a>
                        )}
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
              {selectedConversation.status !== 'CLOSED' && (
                <form onSubmit={handleSendMessage} className="border-t border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
                  {/* File Preview */}
                  {selectedFile && filePreview && (
                    <div className="px-4 pt-3">
                      <div className="relative inline-block">
                        <img
                          src={filePreview}
                          alt="Preview"
                          className="max-h-24 rounded-lg object-cover"
                        />
                        <button
                          type="button"
                          onClick={clearSelectedFile}
                          className="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center hover:bg-red-600"
                        >
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  )}
                  {/* Upload Error */}
                  {uploadError && (
                    <div className="px-4 pt-2">
                      <p className="text-sm text-red-500">{uploadError}</p>
                    </div>
                  )}
                  <div className="flex gap-3 p-4">
                    {/* Hidden file input */}
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept={ALLOWED_IMAGE_TYPES.join(',')}
                      onChange={handleFileSelect}
                      className="hidden"
                    />
                    {/* Attach button */}
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={isUploading || isSending}
                      className="p-2 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg transition-colors disabled:opacity-50"
                      title="Attach photo"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                    </button>
                    <input
                      type="text"
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      placeholder="Type a message..."
                      className="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-full bg-white dark:bg-slate-700 text-slate-900 dark:text-white placeholder-slate-400"
                      disabled={isSending || isUploading}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          handleSendMessage(e);
                        }
                      }}
                    />
                    <button
                      type="submit"
                      disabled={isSending || isUploading || (!newMessage.trim() && !selectedFile)}
                      className="px-4 py-2 bg-emerald-600 text-white rounded-full hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {isSending || isUploading ? (
                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      ) : (
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                        </svg>
                      )}
                    </button>
                  </div>
                </form>
              )}
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
              <div className="w-16 h-16 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center mb-4">
                {MAIN_TABS.find(t => t.value === activeTab)?.icon}
              </div>
              <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
                {activeTab === 'concierge' && 'Contact Your Home Team'}
                {activeTab === 'support' && 'Get Help & Support'}
                {activeTab === 'travel' && 'Plan Your Next Trip'}
              </h3>
              <p className="text-slate-600 dark:text-slate-400 mb-4 max-w-sm">
                {activeTab === 'concierge' && 'Chat with your Home Manager, Handyman, or Vendors about your home needs.'}
                {activeTab === 'support' && 'Get assistance with issues, questions, or anything you need help with.'}
                {activeTab === 'travel' && 'Work with our travel concierge to plan trips and vacations.'}
              </p>
              <button
                onClick={() => {
                  setNewChatType(activeTab);
                  setShowNewChat(true);
                }}
                className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Start New Conversation
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
                {/* Conversation Type */}
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                    What do you need help with?
                  </label>
                  <div className="grid grid-cols-3 gap-2">
                    {MAIN_TABS.map(tab => (
                      <button
                        key={tab.value}
                        type="button"
                        onClick={() => setNewChatType(tab.value)}
                        className={`p-3 rounded-lg border-2 transition-colors text-center ${
                          newChatType === tab.value
                            ? 'border-emerald-600 bg-emerald-50 dark:bg-emerald-900/20'
                            : 'border-slate-200 dark:border-slate-600 hover:border-slate-300 dark:hover:border-slate-500'
                        }`}
                      >
                        <div className={`mx-auto mb-1 ${newChatType === tab.value ? 'text-emerald-600' : 'text-slate-400'}`}>
                          {tab.icon}
                        </div>
                        <span className={`text-sm font-medium ${newChatType === tab.value ? 'text-emerald-700 dark:text-emerald-400' : 'text-slate-600 dark:text-slate-300'}`}>
                          {tab.label}
                        </span>
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Subject (Optional)
                  </label>
                  <input
                    type="text"
                    value={newChatSubject}
                    onChange={(e) => setNewChatSubject(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                    placeholder={
                      newChatType === 'concierge' ? 'e.g., Kitchen faucet repair' :
                      newChatType === 'support' ? 'e.g., Question about my bill' :
                      'e.g., Spring break trip planning'
                    }
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
                        {newChatType === 'concierge' && 'Your home team will respond'}
                        {newChatType === 'support' && 'Our support team will help'}
                        {newChatType === 'travel' && 'Your travel concierge will assist'}
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
