'use client';

import { useState, useEffect, useCallback } from 'react';
import { API_BASE_URL, getAccessToken } from '@/lib/api';
import type {
  Conversation,
  ConversationDetail,
  SupportMessage,
  CreateConversationRequest,
  SendMessageRequest,
  ConversationStatus,
} from '@haven/core';

// Fetch helper with auth
async function authFetch(path: string, options: RequestInit = {}): Promise<Response> {
  const token = getAccessToken();
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
export function useConversations(status?: ConversationStatus, enabled = true) {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchConversations = useCallback(async () => {
    // Don't fetch if not enabled or no auth token
    const token = getAccessToken();
    if (!enabled || !token) {
      setIsLoading(false);
      return;
    }

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
  }, [status, enabled]);

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

    // Don't fetch if no auth token
    const token = getAccessToken();
    if (!token) {
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
export function useCreateConversation() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const createConversation = async (data: CreateConversationRequest): Promise<Conversation | null> => {
    try {
      setIsLoading(true);
      setError(null);

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
      setError(err instanceof Error ? err : new Error('Unknown error'));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  return {
    createConversation,
    isLoading,
    error,
  };
}

// Send a message in a conversation
export function useSendMessage() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const sendMessage = async (
    conversationId: string,
    data: SendMessageRequest
  ): Promise<SupportMessage | null> => {
    try {
      setIsLoading(true);
      setError(null);

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
      setError(err instanceof Error ? err : new Error('Unknown error'));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  return {
    sendMessage,
    isLoading,
    error,
  };
}

// Count unread conversations
export function useUnreadCount() {
  const [unreadCount, setUnreadCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);

  const fetchUnreadCount = useCallback(async () => {
    // Don't fetch if no auth token
    const token = getAccessToken();
    if (!token) {
      setIsLoading(false);
      return;
    }

    try {
      const response = await authFetch('/conversations?status=OPEN');
      if (!response.ok) return;

      const data: Conversation[] = await response.json();
      const count = data.reduce((sum, c) => sum + c.homeownerUnreadCount, 0);
      setUnreadCount(count);
    } catch {
      // Ignore errors for badge count
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchUnreadCount();
    // Poll every 30 seconds
    const interval = setInterval(fetchUnreadCount, 30000);
    return () => clearInterval(interval);
  }, [fetchUnreadCount]);

  return { unreadCount, isLoading, refetch: fetchUnreadCount };
}
