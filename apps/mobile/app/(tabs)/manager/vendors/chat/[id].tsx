import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../../src/contexts/auth-context';
import { LoadingSpinner } from '../../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../../src/lib/api';
import { getIdToken } from '../../../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface Message {
  id: string;
  content: string;
  senderType: 'HOMEOWNER' | 'VENDOR' | 'SYSTEM';
  senderName?: string;
  createdAt: string;
  isRead: boolean;
}

interface VendorInfo {
  id: string;
  displayName: string;
  category: string;
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function VendorChatScreen() {
  const { id: householdVendorId } = useLocalSearchParams<{ id: string }>();
  const { householdInfo, user } = useAuth();
  const flatListRef = useRef<FlatList>(null);

  const [messages, setMessages] = useState<Message[]>([]);
  const [vendorInfo, setVendorInfo] = useState<VendorInfo | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isSending, setIsSending] = useState(false);

  const fetchMessages = useCallback(async () => {
    if (!householdInfo?.id || !householdVendorId) return;

    try {
      const token = await getIdToken(true);
      const response = await fetch(
        `${API_BASE_URL}/vendors/${householdVendorId}/messages?householdId=${householdInfo.id}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      if (response.ok) {
        const data = await response.json();
        setMessages(data.messages || []);
        if (data.vendor) {
          setVendorInfo(data.vendor);
        }
      }
    } catch (err) {
      console.error('Fetch messages error:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id, householdVendorId]);

  useEffect(() => {
    fetchMessages();
  }, [fetchMessages]);

  const handleSend = async () => {
    if (!newMessage.trim() || !householdInfo?.id || !householdVendorId) return;

    const messageContent = newMessage.trim();
    setNewMessage('');
    setIsSending(true);

    // Optimistically add message
    const tempId = `temp-${Date.now()}`;
    const optimisticMessage: Message = {
      id: tempId,
      content: messageContent,
      senderType: 'HOMEOWNER',
      senderName: `${user?.firstName} ${user?.lastName}`,
      createdAt: new Date().toISOString(),
      isRead: true,
    };
    setMessages(prev => [...prev, optimisticMessage]);

    try {
      const token = await getIdToken(true);
      const response = await fetch(
        `${API_BASE_URL}/vendors/${householdVendorId}/messages?householdId=${householdInfo.id}`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ content: messageContent }),
        }
      );

      if (response.ok) {
        const sentMessage = await response.json();
        // Replace temp message with real one
        setMessages(prev =>
          prev.map(m => (m.id === tempId ? sentMessage : m))
        );
      } else {
        // Remove optimistic message on error
        setMessages(prev => prev.filter(m => m.id !== tempId));
      }
    } catch (err) {
      console.error('Send message error:', err);
      setMessages(prev => prev.filter(m => m.id !== tempId));
    } finally {
      setIsSending(false);
    }
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return 'Yesterday';
    } else {
      return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: date.getFullYear() !== today.getFullYear() ? 'numeric' : undefined,
      });
    }
  };

  const renderMessage = ({ item, index }: { item: Message; index: number }) => {
    const isOwn = item.senderType === 'HOMEOWNER';
    const isSystem = item.senderType === 'SYSTEM';
    const showDate =
      index === 0 ||
      formatDate(item.createdAt) !== formatDate(messages[index - 1].createdAt);

    return (
      <View>
        {showDate && (
          <View style={styles.dateSeparator}>
            <Text style={styles.dateText}>{formatDate(item.createdAt)}</Text>
          </View>
        )}

        {isSystem ? (
          <View style={styles.systemMessage}>
            <Text style={styles.systemMessageText}>{item.content}</Text>
          </View>
        ) : (
          <View style={[styles.messageRow, isOwn && styles.messageRowOwn]}>
            <View
              style={[
                styles.messageBubble,
                isOwn ? styles.messageBubbleOwn : styles.messageBubbleOther,
              ]}
            >
              {!isOwn && item.senderName && (
                <Text style={styles.senderName}>{item.senderName}</Text>
              )}
              <Text
                style={[
                  styles.messageText,
                  isOwn ? styles.messageTextOwn : styles.messageTextOther,
                ]}
              >
                {item.content}
              </Text>
              <Text
                style={[
                  styles.messageTime,
                  isOwn ? styles.messageTimeOwn : styles.messageTimeOther,
                ]}
              >
                {formatTime(item.createdAt)}
              </Text>
            </View>
          </View>
        )}
      </View>
    );
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading messages..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: vendorInfo?.displayName || 'Chat',
          headerBackTitle: 'Back',
        }}
      />

      <KeyboardAvoidingView
        style={styles.keyboardView}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={100}
      >
        {/* Messages List */}
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.messagesList}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={() => {
                setIsRefreshing(true);
                fetchMessages();
              }}
            />
          }
          onContentSizeChange={() =>
            flatListRef.current?.scrollToEnd({ animated: true })
          }
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons
                name="chatbubbles-outline"
                size={48}
                color={colors.text.tertiary}
              />
              <Text style={styles.emptyTitle}>No messages yet</Text>
              <Text style={styles.emptySubtitle}>
                Start a conversation with this vendor
              </Text>
            </View>
          }
        />

        {/* Input Area */}
        <View style={styles.inputContainer}>
          <TextInput
            style={styles.textInput}
            value={newMessage}
            onChangeText={setNewMessage}
            placeholder="Type a message..."
            placeholderTextColor={colors.text.tertiary}
            multiline
            maxLength={1000}
          />
          <TouchableOpacity
            style={[
              styles.sendButton,
              (!newMessage.trim() || isSending) && styles.sendButtonDisabled,
            ]}
            onPress={handleSend}
            disabled={!newMessage.trim() || isSending}
          >
            <Ionicons
              name="send"
              size={20}
              color={
                !newMessage.trim() || isSending
                  ? colors.text.tertiary
                  : colors.white
              }
            />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  keyboardView: {
    flex: 1,
  },
  messagesList: {
    padding: spacing[4],
    flexGrow: 1,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[10],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginTop: spacing[3],
  },
  emptySubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  dateSeparator: {
    alignItems: 'center',
    marginVertical: spacing[4],
  },
  dateText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    backgroundColor: colors.background.secondary,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  systemMessage: {
    alignItems: 'center',
    marginVertical: spacing[2],
  },
  systemMessageText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    fontStyle: 'italic',
  },
  messageRow: {
    flexDirection: 'row',
    marginBottom: spacing[2],
  },
  messageRowOwn: {
    justifyContent: 'flex-end',
  },
  messageBubble: {
    maxWidth: '80%',
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  messageBubbleOwn: {
    backgroundColor: colors.haven.champagne[500],
    borderBottomRightRadius: 4,
  },
  messageBubbleOther: {
    backgroundColor: colors.white,
    borderBottomLeftRadius: 4,
  },
  senderName: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[600],
    marginBottom: 2,
  },
  messageText: {
    fontSize: typography.fontSizes.base,
    lineHeight: 20,
  },
  messageTextOwn: {
    color: colors.white,
  },
  messageTextOther: {
    color: colors.text.primary,
  },
  messageTime: {
    fontSize: typography.fontSizes.xs,
    marginTop: 4,
  },
  messageTimeOwn: {
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'right',
  },
  messageTimeOther: {
    color: colors.text.tertiary,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    padding: spacing[3],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[2],
  },
  textInput: {
    flex: 1,
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.xl,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    maxHeight: 100,
  },
  sendButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: colors.background.tertiary,
  },
});
