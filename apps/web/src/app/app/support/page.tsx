'use client';

import { useState, useEffect, useRef } from 'react';
import {
  useConversations,
  useConversation,
  useCreateConversation,
  useSendMessage,
} from '@/hooks/use-conversations';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { Conversation, SupportMessage, ConversationStatus } from '@haven/core';

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

function formatTime(date: string): string {
  return new Date(date).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

function formatDate(date: string): string {
  const d = new Date(date);
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  if (d.toDateString() === today.toDateString()) {
    return 'Today';
  }
  if (d.toDateString() === yesterday.toDateString()) {
    return 'Yesterday';
  }
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function getStatusBadge(status: ConversationStatus): { bg: string; text: string } {
  switch (status) {
    case 'OPEN':
      return { bg: 'bg-green-100 dark:bg-green-900/30', text: 'text-green-800 dark:text-green-400' };
    case 'PENDING':
      return { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-800 dark:text-amber-400' };
    case 'CLOSED':
      return { bg: 'bg-slate-100 dark:bg-slate-700', text: 'text-slate-600 dark:text-slate-400' };
    default:
      return { bg: 'bg-slate-100 dark:bg-slate-700', text: 'text-slate-600 dark:text-slate-400' };
  }
}

// New Conversation Modal
function NewConversationModal({
  isOpen,
  onClose,
  onCreated,
}: {
  isOpen: boolean;
  onClose: () => void;
  onCreated: (conversation: Conversation) => void;
}) {
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const { createConversation, isLoading } = useCreateConversation();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim()) return;

    const result = await createConversation({
      subject: subject.trim() || undefined,
      body: message.trim(),
    });

    if (result) {
      setSubject('');
      setMessage('');
      onClose();
      onCreated(result);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-lg w-full p-6">
        <h2 className="text-xl font-semibold text-slate-900 dark:text-white mb-4">
          Start a New Conversation
        </h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="label block mb-1.5">Subject (optional)</label>
            <input
              type="text"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              className="input"
              placeholder="e.g., Leaking faucet in kitchen"
            />
          </div>
          <div>
            <label className="label block mb-1.5">Your message</label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="input min-h-[120px]"
              placeholder="Describe what you need help with..."
              required
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="btn btn-secondary"
              disabled={isLoading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={isLoading || !message.trim()}
            >
              {isLoading ? 'Sending...' : 'Send Message'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Conversation List Item
function ConversationListItem({
  conversation,
  isSelected,
  onClick,
}: {
  conversation: Conversation;
  isSelected: boolean;
  onClick: () => void;
}) {
  const statusBadge = getStatusBadge(conversation.status);

  return (
    <button
      onClick={onClick}
      className={`w-full text-left p-4 border-b border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors ${
        isSelected ? 'bg-blue-50 dark:bg-blue-900/20 border-l-4 border-l-blue-600' : ''
      }`}
    >
      <div className="flex items-start justify-between mb-1">
        <h3 className="font-medium text-slate-900 dark:text-white truncate pr-2">
          {conversation.subject || 'Support request'}
        </h3>
        {conversation.homeownerUnreadCount > 0 && (
          <span className="flex-shrink-0 w-5 h-5 bg-blue-600 text-white text-xs rounded-full flex items-center justify-center">
            {conversation.homeownerUnreadCount}
          </span>
        )}
      </div>
      <p className="text-sm text-slate-500 dark:text-slate-400 truncate mb-2">
        {conversation.lastMessage?.body || 'No messages yet'}
      </p>
      <div className="flex items-center justify-between">
        <span className={`text-xs px-2 py-0.5 rounded-full ${statusBadge.bg} ${statusBadge.text}`}>
          {conversation.status}
        </span>
        <span className="text-xs text-slate-400 dark:text-slate-500">
          {formatDate(conversation.updatedAt)}
        </span>
      </div>
    </button>
  );
}

// Message Bubble
function MessageBubble({ message }: { message: SupportMessage }) {
  const isFromHomeowner = message.senderRole === 'HOMEOWNER';
  const isSystem = message.senderRole === 'SYSTEM';
  const [imageUrl, setImageUrl] = useState<string | null>(null);

  // Load signed URL for file assets
  useEffect(() => {
    if (message.attachmentFile?.id) {
      const api = getApiClient();
      api.getFileAssetUrl(message.attachmentFile.id)
        .then((res) => setImageUrl(res.url))
        .catch(() => setImageUrl(null));
    }
  }, [message.attachmentFile?.id]);

  if (isSystem) {
    return (
      <div className="flex justify-center my-4">
        <span className="text-xs text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-slate-700 px-3 py-1 rounded-full">
          {message.body}
        </span>
      </div>
    );
  }

  const attachmentUrl = imageUrl || message.attachmentUrl;
  const isImage = message.attachmentFile?.contentType?.startsWith('image/') ||
    (attachmentUrl && /\.(jpg|jpeg|png|gif|webp)$/i.test(attachmentUrl));

  return (
    <div className={`flex ${isFromHomeowner ? 'justify-end' : 'justify-start'} mb-3`}>
      <div
        className={`max-w-[80%] px-4 py-2 rounded-2xl ${
          isFromHomeowner
            ? 'bg-blue-600 text-white rounded-br-sm'
            : 'bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-white rounded-bl-sm'
        }`}
      >
        {!isFromHomeowner && message.sender && (
          <p className="text-xs font-medium text-blue-600 dark:text-blue-400 mb-1">
            {message.sender.firstName || 'Haven Support'}
          </p>
        )}
        <p className="whitespace-pre-wrap break-words">{message.body}</p>
        {attachmentUrl && isImage && (
          <a
            href={attachmentUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="block mt-2"
          >
            <img
              src={attachmentUrl}
              alt="Attachment"
              className="max-w-full max-h-64 rounded-lg object-cover"
            />
          </a>
        )}
        {attachmentUrl && !isImage && (
          <a
            href={attachmentUrl}
            target="_blank"
            rel="noopener noreferrer"
            className={`text-sm underline mt-2 block ${
              isFromHomeowner ? 'text-blue-100' : 'text-blue-600 dark:text-blue-400'
            }`}
          >
            View attachment
          </a>
        )}
        <p
          className={`text-xs mt-1 ${
            isFromHomeowner ? 'text-blue-200' : 'text-slate-400 dark:text-slate-500'
          }`}
        >
          {formatTime(message.createdAt)}
        </p>
      </div>
    </div>
  );
}

// Chat View
function ChatView({
  conversationId,
  onBack,
  householdId,
}: {
  conversationId: string;
  onBack?: () => void;
  householdId: string;
}) {
  const { conversation, isLoading, refetch } = useConversation(conversationId);
  const { sendMessage, isLoading: isSending } = useSendMessage();
  const [newMessage, setNewMessage] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [conversation?.messages]);

  // Poll for new messages every 5 seconds
  useEffect(() => {
    const interval = setInterval(refetch, 5000);
    return () => clearInterval(interval);
  }, [refetch]);

  // Clean up file preview URL
  useEffect(() => {
    return () => {
      if (filePreview) URL.revokeObjectURL(filePreview);
    };
  }, [filePreview]);

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

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if ((!newMessage.trim() && !selectedFile) || isSending || isUploading) return;

    let attachmentFileId: string | undefined;

    // Upload file if selected
    if (selectedFile) {
      setIsUploading(true);
      try {
        const api = getApiClient();
        const fileAsset = await api.uploadFileToGcs(selectedFile, {
          householdId,
          type: 'ISSUE_PHOTO',
        });
        attachmentFileId = fileAsset.id;
      } catch (err: any) {
        setUploadError(err.message || 'Failed to upload file');
        setIsUploading(false);
        return;
      }
      setIsUploading(false);
    }

    const result = await sendMessage(conversationId, {
      body: newMessage.trim() || (selectedFile ? 'Sent a photo' : ''),
      attachmentFileId,
    });
    if (result) {
      setNewMessage('');
      clearSelectedFile();
      refetch();
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!conversation) {
    return (
      <div className="flex items-center justify-center h-full text-slate-500 dark:text-slate-400">
        Conversation not found
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center gap-3 p-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
        {onBack && (
          <button
            onClick={onBack}
            className="lg:hidden p-2 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
        )}
        <div className="flex-1">
          <h2 className="font-semibold text-slate-900 dark:text-white">
            {conversation.subject || 'Support Conversation'}
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Started {formatDate(conversation.createdAt)}
          </p>
        </div>
        <span className={`text-xs px-2 py-1 rounded-full ${getStatusBadge(conversation.status).bg} ${getStatusBadge(conversation.status).text}`}>
          {conversation.status}
        </span>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 bg-slate-50 dark:bg-slate-900">
        {conversation.messages.map((msg) => (
          <MessageBubble key={msg.id} message={msg} />
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      {conversation.status !== 'CLOSED' && (
        <form onSubmit={handleSend} className="border-t border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
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
          <div className="flex gap-2 p-4">
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
            <textarea
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Type your message..."
              className="input flex-1 min-h-[44px] max-h-[120px] resize-none"
              rows={1}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  handleSend(e);
                }
              }}
            />
            <button
              type="submit"
              disabled={(!newMessage.trim() && !selectedFile) || isSending || isUploading}
              className="btn btn-primary px-4"
            >
              {isSending || isUploading ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
              )}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}

// Main Support Page
export default function SupportPage() {
  const { householdInfo } = useAuth();
  const { conversations, isLoading, refetch } = useConversations();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);
  const householdId = householdInfo?.id || '';

  // Select first conversation on load if on desktop
  useEffect(() => {
    if (conversations.length > 0 && !selectedId && window.innerWidth >= 1024) {
      setSelectedId(conversations[0]?.id ?? null);
    }
  }, [conversations, selectedId]);

  const handleNewConversation = (conversation: Conversation) => {
    refetch();
    setSelectedId(conversation.id);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-200px)]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="h-[calc(100vh-120px)] flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Support</h1>
          <p className="text-slate-500 dark:text-slate-400">
            Get help from your home management team
          </p>
        </div>
        <button
          onClick={() => setShowNewModal(true)}
          className="btn btn-primary"
        >
          <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Conversation
        </button>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
        {/* Conversation List */}
        <div className={`w-full lg:w-80 border-r border-slate-200 dark:border-slate-700 flex flex-col ${
          selectedId ? 'hidden lg:flex' : 'flex'
        }`}>
          <div className="p-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="font-semibold text-slate-900 dark:text-white">Conversations</h2>
          </div>
          <div className="flex-1 overflow-y-auto">
            {conversations.length === 0 ? (
              <div className="p-8 text-center text-slate-500 dark:text-slate-400">
                <div className="text-4xl mb-3">💬</div>
                <p>No conversations yet</p>
                <p className="text-sm mt-1">Start one to get help!</p>
              </div>
            ) : (
              conversations.map((conv) => (
                <ConversationListItem
                  key={conv.id}
                  conversation={conv}
                  isSelected={conv.id === selectedId}
                  onClick={() => setSelectedId(conv.id)}
                />
              ))
            )}
          </div>
        </div>

        {/* Chat View */}
        <div className={`flex-1 flex flex-col ${!selectedId ? 'hidden lg:flex' : 'flex'}`}>
          {selectedId ? (
            <ChatView
              conversationId={selectedId}
              onBack={() => setSelectedId(null)}
              householdId={householdId}
            />
          ) : (
            <div className="flex-1 flex items-center justify-center text-slate-500 dark:text-slate-400">
              <div className="text-center">
                <div className="text-6xl mb-4">💬</div>
                <p className="text-lg">Select a conversation</p>
                <p className="text-sm mt-1">or start a new one</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* New Conversation Modal */}
      <NewConversationModal
        isOpen={showNewModal}
        onClose={() => setShowNewModal(false)}
        onCreated={handleNewConversation}
      />
    </div>
  );
}
