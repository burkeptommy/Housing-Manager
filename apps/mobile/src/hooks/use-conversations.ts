import { useState, useEffect, useCallback } from 'react';
import { getApiClient, API_BASE_URL, getCachedAccessToken } from '../lib/api';
import type {
  Conversation,
  ConversationDetail,
  SupportMessage,
  CreateConversationRequest,
  SendMessageRequest,
  ConversationStatus,
} from '@haven/core';

// Fetch helper with auth
async function authFetch(path: string, options: RequestInit = {}) {
  const token = getCachedAccessToken();
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  if (token) {
    (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
  }
  return fetch(`${API_BASE_URL}${path}`, { ...options, headers });
}

// Fetch conversations for the current household
export function useConversations(status?: ConversationStatus) {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchConversations = useCallback(async () => {
    try {
      setIsLoading(true);
      const params = new URLSearchParams();
      if (status) params.set('status', status);

      const response = await authFetch(`/conversations?${params}`);
      if (!response.ok) throw new Error('Failed to fetch conversations');

      const data = await response.json();
      setConversations(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setIsLoading(false);
    }
  }, [status]);

  useEffect(() => {
    fetchConversations();
  }, [fetchConversations]);

  return {
    conversations,
    isLoading,
    error,
    refetch: fetchConversations,
  };
}

// Fetch a single conversation with messages
export function useConversation(conversationId: string | null) {
  const [conversation, setConversation] = useState<ConversationDetail | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchConversation = useCallback(async () => {
    if (!conversationId) {
      setConversation(null);
      return;
    }

    try {
      setIsLoading(true);
      const response = await authFetch(`/conversations/${conversationId}`);
      if (!response.ok) throw new Error('Failed to fetch conversation');

      const data = await response.json();
      setConversation(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setIsLoading(false);
    }
  }, [conversationId]);

  useEffect(() => {
    fetchConversation();
  }, [fetchConversation]);

  return {
    conversation,
    isLoading,
    error,
    refetch: fetchConversation,
  };
}

// Create a new conversation
export async function createConversation(
  data: CreateConversationRequest
): Promise<Conversation | null> {
  try {
    const response = await authFetch('/conversations', {
      method: 'POST',
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errData = await response.json().catch(() => ({}));
      throw new Error(errData.message || 'Failed to create conversation');
    }

    return await response.json();
  } catch (err) {
    console.error('Failed to create conversation:', err);
    return null;
  }
}

// Send a message in a conversation
export async function sendMessage(
  conversationId: string,
  data: SendMessageRequest
): Promise<SupportMessage | null> {
  try {
    const response = await authFetch(`/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errData = await response.json().catch(() => ({}));
      throw new Error(errData.message || 'Failed to send message');
    }

    return await response.json();
  } catch (err) {
    console.error('Failed to send message:', err);
    return null;
  }
}

// Count total unread from conversations
export function useUnreadCount() {
  const { conversations, isLoading, refetch } = useConversations('OPEN');

  const unreadCount = conversations.reduce(
    (sum, c) => sum + c.homeownerUnreadCount,
    0
  );

  return { unreadCount, isLoading, refetch };
}
