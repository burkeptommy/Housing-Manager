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
import { useSubscription } from '../../../src/contexts/subscription-context';
import { AlfredAvatar } from '../../../src/components/Alfred';
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
  pendingQuestion?: AlfredQuestion | null;
}

interface AlfredQuestion {
  id: string;
  dataGap: string;
  question: string;
  followUp?: string;
  responseType: 'choice' | 'text' | 'confirm';
  choices?: { label: string; value: string }[];
  priority: number;
}

export default function ManagerChatScreen() {
  const { user, householdInfo } = useAuth();
  const { isEssentials, managerInfo } = useSubscription();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [pendingQuestion, setPendingQuestion] = useState<AlfredQuestion | null>(null);
  const [isAnswering, setIsAnswering] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  // Fetch pending Alfred question for Essentials tier
  const fetchPendingQuestion = useCallback(async () => {
    if (!isEssentials || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(
        `${API_BASE_URL}/alfred/next-question/${householdInfo.id}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (response.ok) {
        const data = await response.json();
        if (data.question) {
          setPendingQuestion(data.question);
          // Add question as a message if not already present
          setMessages(prev => {
            const hasQuestion = prev.some(m => m.id === `question-${data.question.id}`);
            if (!hasQuestion) {
              return [
                ...prev,
                {
                  id: `question-${data.question.id}`,
                  text: data.question.question,
                  sender: 'manager' as const,
                  timestamp: new Date(),
                  pendingQuestion: data.question,
                },
              ];
            }
            return prev;
          });
        }
      }
    } catch (err) {
      console.error('Fetch pending question error:', err);
    }
  }, [isEssentials, householdInfo?.id]);

  // Submit answer to Alfred question
  const answerQuestion = async (questionId: string, answer: string, label: string) => {
    if (isAnswering || !householdInfo?.id) return;

    setIsAnswering(true);

    // Add user's answer as a message
    const userMessage: Message = {
      id: `answer-${Date.now()}`,
      text: label,
      sender: 'user',
      timestamp: new Date(),
    };
    setMessages(prev => [...prev, userMessage]);

    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(`${API_BASE_URL}/alfred/answer-question`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          householdId: householdInfo.id,
          questionId,
          answer,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        // Add Alfred's response
        if (data.message) {
          setMessages(prev => [
            ...prev,
            {
              id: `response-${Date.now()}`,
              text: data.message,
              sender: 'manager',
              timestamp: new Date(),
            },
          ]);
        }
        setPendingQuestion(null);

        // Check for next question after a short delay
        setTimeout(() => fetchPendingQuestion(), 1500);
      }
    } catch (err) {
      console.error('Answer question error:', err);
    } finally {
      setIsAnswering(false);
    }
  };

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
        conversation =
          conversations.find(c => c.status === 'OPEN' || c.status === 'PENDING') ||
          conversations[0];

        const detailResponse = await fetch(
          `${API_BASE_URL}/conversations/${conversation.id}`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
              'Content-Type': 'application/json',
            },
          }
        );

        if (detailResponse.ok) {
          conversation = await detailResponse.json();
        }
      }

      if (conversation) {
        setConversationId(conversation.id);

        const convertedMessages: Message[] = (conversation.messages || []).map(msg => ({
          id: msg.id,
          text: msg.content,
          sender:
            msg.sender.role === 'HOME_MANAGER' || msg.sender.role === 'ADMIN'
              ? 'manager'
              : 'user',
          timestamp: new Date(msg.createdAt),
          image: msg.attachmentUrl || undefined,
        }));

        setMessages(convertedMessages.reverse());
      } else {
        // Welcome message from manager
        const welcomeMessage = isEssentials
          ? `Hi ${user?.firstName || 'there'}! I'm Alfred, your AI Home Manager. How can I help you today?`
          : `Hi ${user?.firstName || 'there'}! I'm ${managerInfo.name}, your Home Manager. How can I help you today?`;

        setMessages([
          {
            id: 'welcome',
            text: welcomeMessage,
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
  }, [householdInfo?.id, user?.firstName, isEssentials, managerInfo.name]);

  useEffect(() => {
    fetchConversation();
  }, [fetchConversation]);

  // Fetch pending questions after conversation loads for Essentials tier
  useEffect(() => {
    if (!isLoading && isEssentials && householdInfo?.id) {
      fetchPendingQuestion();
    }
  }, [isLoading, isEssentials, householdInfo?.id, fetchPendingQuestion]);

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
          prev.map(msg => (msg.id === tempMessage.id ? { ...msg, id: sentMessage.id } : msg))
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

  const getManagerInitials = () => {
    return managerInfo.name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase();
  };

  const renderMessage = ({ item }: { item: Message }) => {
    const isUser = item.sender === 'user';
    const hasChoices = item.pendingQuestion?.responseType === 'choice' && item.pendingQuestion?.choices;

    return (
      <View>
        <View style={[styles.messageRow, isUser && styles.messageRowUser]}>
          {!isUser &&
            (isEssentials ? (
              <AlfredAvatar size="sm" />
            ) : (
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>{getManagerInitials()}</Text>
              </View>
            ))}
          <View
            style={[styles.messageBubble, isUser ? styles.userBubble : styles.managerBubble]}
          >
            {item.image ? (
              <Image source={{ uri: item.image }} style={styles.messageImage} />
            ) : (
              <Text style={[styles.messageText, isUser && styles.userText]}>{item.text}</Text>
            )}
            <Text style={[styles.messageTime, isUser && styles.userTime]}>
              {formatTime(item.timestamp)}
            </Text>
          </View>
        </View>
        {/* Choice buttons for Alfred questions */}
        {hasChoices && pendingQuestion?.id === item.pendingQuestion?.id && (
          <View style={styles.choicesContainer}>
            {item.pendingQuestion!.choices!.map(choice => (
              <TouchableOpacity
                key={choice.value}
                style={[styles.choiceButton, isAnswering && styles.choiceButtonDisabled]}
                onPress={() => answerQuestion(item.pendingQuestion!.id, choice.value, choice.label)}
                disabled={isAnswering}
              >
                {isAnswering ? (
                  <ActivityIndicator size="small" color={colors.haven.purple[900]} />
                ) : (
                  <Text style={styles.choiceButtonText}>{choice.label}</Text>
                )}
              </TouchableOpacity>
            ))}
          </View>
        )}
      </View>
    );
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading conversation..." />;
  }

  if (error && messages.length === 0) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen
          options={{
            title: `Chat with ${isEssentials ? 'Alfred' : managerInfo.name.split(' ')[0]}`,
          }}
        />
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
      <Stack.Screen
        options={{
          title: `Chat with ${isEssentials ? 'Alfred' : managerInfo.name.split(' ')[0]}`,
        }}
      />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
        keyboardVerticalOffset={90}
      >
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
          showsVerticalScrollIndicator={false}
        />

        <View style={styles.inputContainer}>
          <TouchableOpacity style={styles.attachButton} onPress={pickImage}>
            <Ionicons name="camera" size={24} color={colors.haven.purple[600]} />
          </TouchableOpacity>
          <TextInput
            style={styles.input}
            placeholder={`Message ${isEssentials ? 'Alfred' : managerInfo.name.split(' ')[0]}...`}
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
    backgroundColor: colors.haven.purple[500],
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
    backgroundColor: colors.haven.purple[900],
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
    marginLeft: spacing[2],
  },
  userBubble: {
    backgroundColor: colors.haven.purple[900],
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
    color: colors.haven.purple[300],
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
    backgroundColor: colors.haven.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: spacing[2],
  },
  sendButtonDisabled: {
    backgroundColor: colors.gray[200],
  },
  choicesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginLeft: 42, // Align with message bubble (avatar width + margin)
    marginTop: spacing[2],
    marginBottom: spacing[2],
  },
  choiceButton: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    backgroundColor: colors.white,
    borderRadius: borderRadius.full,
    borderWidth: 1.5,
    borderColor: colors.haven.purple[900],
  },
  choiceButtonDisabled: {
    opacity: 0.6,
  },
  choiceButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[900],
  },
});
