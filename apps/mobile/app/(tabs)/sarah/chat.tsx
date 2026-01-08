import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Image,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useAuth } from '../../../src/contexts/auth-context';
import { LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface ConversationMessage {
  id: string;
  content: string;
  attachmentUrl?: string | null;
  createdAt: string;
  sender: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    role: string;
  };
}

interface Conversation {
  id: string;
  subject: string;
  status: string;
  createdAt: string;
  messages: ConversationMessage[];
  manager?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
}

interface Message {
  id: string;
  text: string;
  sender: 'user' | 'manager';
  timestamp: Date;
  image?: string;
}

export default function SarahChatScreen() {
  const { user, householdInfo } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [managerName, setManagerName] = useState<string>('Sarah Chen');
  const [managerInitials, setManagerInitials] = useState<string>('SC');
  const flatListRef = useRef<FlatList>(null);

  const fetchConversation = useCallback(async () => {
    if (!householdInfo?.id) {
      setError('No household found. Please complete onboarding.');
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/conversations`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch conversations: ${response.status}`);
      }

      const conversations: Conversation[] = await response.json();
      let conversation: Conversation | null = null;

      if (conversations.length > 0) {
        conversation = conversations.find(c => c.status === 'OPEN' || c.status === 'PENDING') || conversations[0];

        const detailResponse = await fetch(`${API_BASE_URL}/conversations/${conversation.id}`, {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        });

        if (detailResponse.ok) {
          conversation = await detailResponse.json();
        }
      }

      if (conversation) {
        setConversationId(conversation.id);

        if (conversation.manager) {
          const name = `${conversation.manager.firstName || ''} ${conversation.manager.lastName || ''}`.trim() || 'Sarah Chen';
          setManagerName(name);
          setManagerInitials(name.split(' ').map(n => n[0]).join('').toUpperCase() || 'SC');
        }

        const convertedMessages: Message[] = (conversation.messages || []).map(msg => ({
          id: msg.id,
          text: msg.content,
          sender: msg.sender.role === 'HOME_MANAGER' || msg.sender.role === 'ADMIN' ? 'manager' : 'user',
          timestamp: new Date(msg.createdAt),
          image: msg.attachmentUrl || undefined,
        }));

        setMessages(convertedMessages.reverse());
      } else {
        setMessages([
          {
            id: 'welcome',
            text: `Hi ${user?.firstName || 'there'}! I'm Sarah, your Home Manager. How can I help you today?`,
            sender: 'manager',
            timestamp: new Date(),
          },
        ]);
      }

      setError(null);
    } catch (err) {
      console.error('Fetch conversation error:', err);
      setError('Failed to load messages. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [householdInfo?.id, user?.firstName]);

  useEffect(() => {
    fetchConversation();
  }, [fetchConversation]);

  const sendMessage = async () => {
    if (!inputText.trim() || isSending) return;

    const messageText = inputText.trim();
    setInputText('');
    setIsSending(true);

    const tempMessage: Message = {
      id: `temp-${Date.now()}`,
      text: messageText,
      sender: 'user',
      timestamp: new Date(),
    };
    setMessages(prev => [...prev, tempMessage]);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsSending(false);
        return;
      }

      let currentConversationId = conversationId;

      if (!currentConversationId) {
        const createResponse = await fetch(`${API_BASE_URL}/conversations`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            subject: 'General Support',
            message: messageText,
          }),
        });

        if (!createResponse.ok) {
          throw new Error('Failed to create conversation');
        }

        const newConversation = await createResponse.json();
        currentConversationId = newConversation.id;
        setConversationId(currentConversationId);
      } else {
        const sendResponse = await fetch(
          `${API_BASE_URL}/conversations/${currentConversationId}/messages`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${token}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              content: messageText,
            }),
          }
        );

        if (!sendResponse.ok) {
          throw new Error('Failed to send message');
        }

        const sentMessage = await sendResponse.json();

        setMessages(prev =>
          prev.map(msg =>
            msg.id === tempMessage.id
              ? { ...msg, id: sentMessage.id }
              : msg
          )
        );
      }
    } catch (err) {
      console.error('Send message error:', err);
      setMessages(prev => prev.filter(msg => msg.id !== tempMessage.id));
      setError('Failed to send message. Please try again.');
    } finally {
      setIsSending(false);
    }
  };

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      const newMessage: Message = {
        id: `temp-img-${Date.now()}`,
        text: '',
        sender: 'user',
        timestamp: new Date(),
        image: result.assets[0].uri,
      };
      setMessages(prev => [...prev, newMessage]);
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });
  };

  const renderMessage = ({ item }: { item: Message }) => {
    const isUser = item.sender === 'user';

    return (
      <View style={[styles.messageRow, isUser && styles.messageRowUser]}>
        {!isUser && (
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{managerInitials}</Text>
          </View>
        )}
        <View
          style={[
            styles.messageBubble,
            isUser ? styles.userBubble : styles.managerBubble,
          ]}
        >
          {item.image ? (
            <Image source={{ uri: item.image }} style={styles.messageImage} />
          ) : (
            <Text style={[styles.messageText, isUser && styles.userText]}>
              {item.text}
            </Text>
          )}
          <Text style={[styles.messageTime, isUser && styles.userTime]}>
            {formatTime(item.timestamp)}
          </Text>
        </View>
      </View>
    );
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading conversation..." />;
  }

  if (error && messages.length === 0) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Chat with Sarah' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Messages</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchConversation}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: `Chat with ${managerName.split(' ')[0]}` }} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
        keyboardVerticalOffset={90}
      >
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
          showsVerticalScrollIndicator={false}
        />

        <View style={styles.inputContainer}>
          <TouchableOpacity style={styles.attachButton} onPress={pickImage}>
            <Ionicons name="camera" size={24} color={colors.haven.navy[600]} />
          </TouchableOpacity>
          <TextInput
            style={styles.input}
            placeholder={`Message ${managerName.split(' ')[0]}...`}
            placeholderTextColor={colors.text.tertiary}
            value={inputText}
            onChangeText={setInputText}
            multiline
            maxLength={500}
            editable={!isSending}
          />
          <TouchableOpacity
            style={[
              styles.sendButton,
              (!inputText.trim() || isSending) && styles.sendButtonDisabled,
            ]}
            onPress={sendMessage}
            disabled={!inputText.trim() || isSending}
          >
            {isSending ? (
              <ActivityIndicator size="small" color={colors.white} />
            ) : (
              <Ionicons
                name="send"
                size={20}
                color={inputText.trim() ? colors.white : colors.gray[400]}
              />
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  keyboardView: {
    flex: 1,
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  messagesList: {
    padding: spacing[4],
  },
  messageRow: {
    flexDirection: 'row',
    marginBottom: spacing[3],
    alignItems: 'flex-end',
  },
  messageRowUser: {
    justifyContent: 'flex-end',
  },
  avatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[2],
  },
  avatarText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  messageBubble: {
    maxWidth: '75%',
    padding: spacing[3],
    borderRadius: borderRadius.xl,
  },
  managerBubble: {
    backgroundColor: colors.white,
    borderBottomLeftRadius: spacing[1],
  },
  userBubble: {
    backgroundColor: colors.haven.navy[900],
    borderBottomRightRadius: spacing[1],
  },
  messageText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    lineHeight: 20,
  },
  userText: {
    color: colors.white,
  },
  messageTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  userTime: {
    color: colors.haven.navy[300],
  },
  messageImage: {
    width: 200,
    height: 150,
    borderRadius: borderRadius.lg,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    padding: spacing[3],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  attachButton: {
    padding: spacing[2],
    marginRight: spacing[2],
  },
  input: {
    flex: 1,
    minHeight: 40,
    maxHeight: 100,
    backgroundColor: colors.gray[100],
    borderRadius: borderRadius.xl,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  sendButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: spacing[2],
  },
  sendButtonDisabled: {
    backgroundColor: colors.gray[200],
  },
});
