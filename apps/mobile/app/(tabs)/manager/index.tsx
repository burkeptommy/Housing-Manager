import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Animated,
  FlatList,
  RefreshControl,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams, useFocusEffect } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { useSubscription } from '../../../src/contexts/subscription-context';
import { AlfredAvatar } from '../../../src/components/Alfred';
import { AlfredSuggestions } from '../../../src/components/AlfredSuggestions';
import { Card, Badge, AlfredTabIcon } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

type TabType = 'alfred' | 'messages';

interface Message {
  id: string;
  role: 'user' | 'alfred';
  content: string;
  timestamp: Date;
  action?: {
    type: 'schedule_vendor' | 'create_task' | 'approve_request' | 'book_handyman' | 'view_checklist';
    label: string;
    data?: Record<string, unknown>;
  };
  quickReplies?: string[];
}

interface Conversation {
  id: string;
  vendorName: string;
  vendorCategory: string;
  lastMessage: string;
  lastMessageAt: string;
  unreadCount: number;
  vendorId: string;
}

// =============================================================================
// INITIAL MESSAGE
// =============================================================================

const INITIAL_MESSAGE: Message = {
  id: '1',
  role: 'alfred',
  content: "Hi! I'm Alfred, your AI Home Manager. I can help you with:\n\n• Scheduling vendors and maintenance\n• Answering home care questions\n• Managing your maintenance checklist\n• Booking a handyman ($50/visit)\n\nWhat can I help you with today?",
  timestamp: new Date(),
};

// =============================================================================
// ALFRED MANAGER SCREEN WITH TABS
// =============================================================================

export default function ManagerScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { householdInfo } = useAuth();
  const { isEssentials } = useSubscription();
  const { prefill } = useLocalSearchParams<{ prefill?: string }>();

  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('alfred');

  // Alfred Chat state
  const scrollViewRef = useRef<ScrollView>(null);
  const inputRef = useRef<TextInput>(null);
  const [messages, setMessages] = useState<Message[]>([INITIAL_MESSAGE]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(true);
  const hasHandledPrefill = useRef(false);

  // Messages state
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoadingConversations, setIsLoadingConversations] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Handle prefill when screen comes into focus
  useFocusEffect(
    useCallback(() => {
      if (prefill && !hasHandledPrefill.current) {
        setInput(prefill);
        hasHandledPrefill.current = true;
        setShowSuggestions(false);
        setActiveTab('alfred');
        setTimeout(() => {
          inputRef.current?.focus();
        }, 100);
      }
      return () => {
        hasHandledPrefill.current = false;
      };
    }, [prefill])
  );

  // Typing indicator animation
  const dot1Opacity = useRef(new Animated.Value(0.3)).current;
  const dot2Opacity = useRef(new Animated.Value(0.3)).current;
  const dot3Opacity = useRef(new Animated.Value(0.3)).current;

  const animateTypingDots = useCallback(() => {
    const animateDot = (dot: Animated.Value, delay: number) => {
      return Animated.sequence([
        Animated.delay(delay),
        Animated.loop(
          Animated.sequence([
            Animated.timing(dot, { toValue: 1, duration: 300, useNativeDriver: true }),
            Animated.timing(dot, { toValue: 0.3, duration: 300, useNativeDriver: true }),
          ])
        ),
      ]);
    };

    Animated.parallel([
      animateDot(dot1Opacity, 0),
      animateDot(dot2Opacity, 150),
      animateDot(dot3Opacity, 300),
    ]).start();
  }, [dot1Opacity, dot2Opacity, dot3Opacity]);

  // Fetch conversations for Messages tab
  const fetchConversations = useCallback(async () => {
    if (!householdInfo?.id) return;

    setIsLoadingConversations(true);
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(`${API_BASE_URL}/conversations`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        setConversations(data);
      } else {
        // Mock data for demo
        setConversations([
          {
            id: '1',
            vendorName: 'Ace Roofing',
            vendorCategory: 'ROOFING',
            lastMessage: 'We can come out next Tuesday at 10am',
            lastMessageAt: new Date(Date.now() - 3600000).toISOString(),
            unreadCount: 1,
            vendorId: 'v1',
          },
          {
            id: '2',
            vendorName: 'Green Thumb Landscaping',
            vendorCategory: 'LANDSCAPING',
            lastMessage: 'The spring cleanup is complete',
            lastMessageAt: new Date(Date.now() - 86400000).toISOString(),
            unreadCount: 0,
            vendorId: 'v2',
          },
        ]);
      }
    } catch (err) {
      console.error('Fetch conversations error:', err);
    } finally {
      setIsLoadingConversations(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    if (activeTab === 'messages') {
      fetchConversations();
    }
  }, [activeTab, fetchConversations]);

  const sendMessage = async (messageText?: string) => {
    const textToSend = messageText || input.trim();
    if (!textToSend) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: textToSend,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setShowSuggestions(false);
    setIsTyping(true);
    animateTypingDots();

    setTimeout(() => {
      scrollViewRef.current?.scrollToEnd({ animated: true });
    }, 100);

    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Not authenticated');

      const response = await fetch(`${API_BASE_URL}/alfred/chat`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: textToSend,
          conversationHistory: messages.slice(-10).map(m => ({
            role: m.role === 'alfred' ? 'assistant' : 'user',
            content: m.content,
          })),
        }),
      });

      if (!response.ok) throw new Error(`Failed to get response: ${response.status}`);

      const data = await response.json();
      const messageContent = data.message || "I understand. Let me help you with that.";
      const isYesNoQuestion = /would you like|do you want|shall i|should i|can i help/i.test(messageContent);

      const alfredResponse: Message = {
        id: (Date.now() + 1).toString(),
        role: 'alfred',
        content: messageContent,
        timestamp: new Date(),
        action: data.action,
        quickReplies: data.quickReplies || (isYesNoQuestion ? ['Yes, please', 'No, thanks', 'Tell me more'] : undefined),
      };

      setMessages(prev => [...prev, alfredResponse]);
    } catch (error) {
      console.error('Alfred chat error:', error);

      const fallbackResponse: Message = {
        id: (Date.now() + 1).toString(),
        role: 'alfred',
        content: "I'm having trouble connecting right now. In the meantime, you can:\n\n• View your maintenance checklist\n• Book a handyman directly\n• Browse your vendors\n\nPlease try again in a moment.",
        timestamp: new Date(),
        action: { type: 'view_checklist', label: 'View Checklist' },
      };

      setMessages(prev => [...prev, fallbackResponse]);
    } finally {
      setIsTyping(false);
    }
  };

  const handleSuggestionPress = (suggestion: string) => {
    sendMessage(suggestion);
  };

  const handleActionPress = (action: Message['action']) => {
    if (!action) return;

    switch (action.type) {
      case 'schedule_vendor':
        router.push('/(tabs)/manager/vendors' as any);
        break;
      case 'book_handyman':
        router.push('/(tabs)/manager/handyman' as any);
        break;
      case 'view_checklist':
        router.push('/(tabs)/maintenance' as any);
        break;
      case 'approve_request':
        router.push('/(tabs)/approvals' as any);
        break;
      case 'create_task':
        router.push('/(tabs)/maintenance' as any);
        break;
    }
  };

  const handleConversationPress = (conversation: Conversation) => {
    router.push(`/(tabs)/manager/vendors/chat/${conversation.vendorId}` as any);
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const formatConversationTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffHrs = diffMs / (1000 * 60 * 60);

    if (diffHrs < 1) return 'Just now';
    if (diffHrs < 24) return `${Math.floor(diffHrs)}h ago`;
    if (diffHrs < 48) return 'Yesterday';
    return date.toLocaleDateString();
  };

  const getCategoryIcon = (category: string): string => {
    const icons: Record<string, string> = {
      HVAC: 'thermometer-outline',
      PLUMBING: 'water-outline',
      ELECTRICAL: 'flash-outline',
      LANDSCAPING: 'leaf-outline',
      ROOFING: 'home-outline',
      CLEANING: 'sparkles-outline',
    };
    return icons[category] || 'business-outline';
  };

  // =============================================================================
  // RENDER ALFRED TAB
  // =============================================================================

  const renderAlfredTab = () => (
    <KeyboardAvoidingView
      style={styles.keyboardView}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={90}
    >
      {/* Quick Actions Bar */}
      <View style={styles.quickActions}>
        <TouchableOpacity
          style={styles.quickAction}
          onPress={() => router.push('/(tabs)/maintenance' as any)}
        >
          <View style={styles.quickActionIcon}>
            <Ionicons name="checkbox-outline" size={20} color={colors.haven.navy[900]} />
          </View>
          <Text style={styles.quickActionText}>Checklist</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.quickAction}
          onPress={() => router.push('/(tabs)/manager/handyman' as any)}
        >
          <View style={styles.quickActionIcon}>
            <Ionicons name="construct-outline" size={20} color={colors.haven.navy[900]} />
          </View>
          <Text style={styles.quickActionText}>Handyman</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.quickAction}
          onPress={() => router.push('/(tabs)/manager/vendors' as any)}
        >
          <View style={styles.quickActionIcon}>
            <Ionicons name="people-outline" size={20} color={colors.haven.navy[900]} />
          </View>
          <Text style={styles.quickActionText}>Vendors</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.quickAction}
          onPress={() => router.push('/(tabs)/approvals' as any)}
        >
          <View style={styles.quickActionIcon}>
            <Ionicons name="checkmark-circle-outline" size={20} color={colors.haven.navy[900]} />
          </View>
          <Text style={styles.quickActionText}>Approvals</Text>
        </TouchableOpacity>
      </View>

      {/* Chat Messages */}
      <ScrollView
        ref={scrollViewRef}
        style={styles.messagesContainer}
        contentContainerStyle={styles.messagesContent}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
        keyboardShouldPersistTaps="handled"
      >
        {messages.map((message) => (
          <View
            key={message.id}
            style={[
              styles.messageBubble,
              message.role === 'user' ? styles.userBubble : styles.alfredBubble,
            ]}
          >
            {message.role === 'alfred' && (
              <View style={styles.alfredHeader}>
                <AlfredAvatar size="sm" />
                <Text style={styles.alfredName}>Alfred</Text>
                <Text style={styles.messageTime}>{formatTime(message.timestamp)}</Text>
              </View>
            )}
            <Text
              style={[
                styles.messageText,
                message.role === 'user' ? styles.userText : styles.alfredText,
              ]}
            >
              {message.content}
            </Text>

            {message.action && (
              <TouchableOpacity
                style={styles.actionButton}
                onPress={() => handleActionPress(message.action)}
              >
                <Ionicons
                  name={
                    message.action.type === 'book_handyman'
                      ? 'construct'
                      : message.action.type === 'schedule_vendor'
                      ? 'calendar'
                      : message.action.type === 'view_checklist'
                      ? 'checkbox'
                      : 'arrow-forward'
                  }
                  size={16}
                  color={colors.white}
                />
                <Text style={styles.actionButtonText}>{message.action.label}</Text>
              </TouchableOpacity>
            )}

            {message.quickReplies && message.quickReplies.length > 0 && (
              <View style={styles.quickRepliesContainer}>
                {message.quickReplies.map((reply, index) => (
                  <TouchableOpacity
                    key={index}
                    style={[
                      styles.quickReplyButton,
                      index === 0 && styles.quickReplyButtonPrimary,
                    ]}
                    onPress={() => sendMessage(reply)}
                  >
                    <Text
                      style={[
                        styles.quickReplyText,
                        index === 0 && styles.quickReplyTextPrimary,
                      ]}
                    >
                      {reply}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            )}

            {message.role === 'user' && (
              <Text style={styles.userTime}>{formatTime(message.timestamp)}</Text>
            )}
          </View>
        ))}

        {isTyping && (
          <View style={[styles.messageBubble, styles.alfredBubble]}>
            <View style={styles.alfredHeader}>
              <AlfredAvatar size="sm" />
              <Text style={styles.alfredName}>Alfred</Text>
            </View>
            <View style={styles.typingIndicator}>
              <Animated.View style={[styles.typingDot, { opacity: dot1Opacity }]} />
              <Animated.View style={[styles.typingDot, { opacity: dot2Opacity }]} />
              <Animated.View style={[styles.typingDot, { opacity: dot3Opacity }]} />
            </View>
          </View>
        )}
      </ScrollView>

      {showSuggestions && messages.length <= 1 && (
        <AlfredSuggestions onSelect={handleSuggestionPress} />
      )}

      {/* Input Bar */}
      <View style={styles.inputContainer}>
        <TextInput
          ref={inputRef}
          style={styles.input}
          placeholder="Ask Alfred anything..."
          placeholderTextColor={colors.text.tertiary}
          value={input}
          onChangeText={setInput}
          multiline
          maxLength={500}
          onSubmitEditing={() => sendMessage()}
          blurOnSubmit={false}
        />
        <TouchableOpacity
          style={[styles.sendButton, !input.trim() && styles.sendButtonDisabled]}
          onPress={() => sendMessage()}
          disabled={!input.trim() || isTyping}
        >
          <Ionicons
            name="send"
            size={20}
            color={input.trim() && !isTyping ? colors.white : colors.text.tertiary}
          />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );

  // =============================================================================
  // RENDER MESSAGES TAB
  // =============================================================================

  const renderMessagesTab = () => (
    <View style={styles.messagesTabContainer}>
      <FlatList
        data={conversations}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.conversationsList}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchConversations();
            }}
          />
        }
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.conversationItem}
            onPress={() => handleConversationPress(item)}
          >
            <View style={styles.conversationIcon}>
              <Ionicons
                name={getCategoryIcon(item.vendorCategory) as any}
                size={24}
                color={colors.haven.champagne[500]}
              />
            </View>
            <View style={styles.conversationContent}>
              <View style={styles.conversationHeader}>
                <Text style={styles.conversationName}>{item.vendorName}</Text>
                <Text style={styles.conversationTime}>
                  {formatConversationTime(item.lastMessageAt)}
                </Text>
              </View>
              <Text style={styles.conversationMessage} numberOfLines={1}>
                {item.lastMessage}
              </Text>
            </View>
            {item.unreadCount > 0 && (
              <View style={styles.unreadBadge}>
                <Text style={styles.unreadBadgeText}>{item.unreadCount}</Text>
              </View>
            )}
          </TouchableOpacity>
        )}
        ListEmptyComponent={
          <View style={styles.emptyMessages}>
            <Ionicons name="chatbubbles-outline" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>No Messages Yet</Text>
            <Text style={styles.emptyText}>
              Start a conversation with your vendors or service providers
            </Text>
            <TouchableOpacity
              style={styles.newMessageButton}
              onPress={() => router.push('/(tabs)/manager/vendors' as any)}
            >
              <Ionicons name="add" size={20} color={colors.white} />
              <Text style={styles.newMessageButtonText}>New Message</Text>
            </TouchableOpacity>
          </View>
        }
      />
      {/* FAB for new message */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => router.push('/(tabs)/manager/vendors' as any)}
      >
        <Ionicons name="create-outline" size={24} color={colors.white} />
      </TouchableOpacity>
    </View>
  );

  // =============================================================================
  // MAIN RENDER
  // =============================================================================

  return (
    <View style={styles.container}>
      {/* Blue Header */}
      <View style={[styles.headerWrapper, { paddingTop: insets.top }]}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>
            {isEssentials ? 'Alfred' : 'Manager'}
          </Text>
        </View>
      </View>

      {/* Tab Selector */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'alfred' && styles.tabActive]}
          onPress={() => setActiveTab('alfred')}
        >
          <AlfredTabIcon
            size={18}
            color={activeTab === 'alfred' ? colors.haven.champagne[500] : colors.text.secondary}
          />
          <Text style={[styles.tabText, activeTab === 'alfred' && styles.tabTextActive]}>
            Ask Alfred
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'messages' && styles.tabActive]}
          onPress={() => setActiveTab('messages')}
        >
          <Ionicons
            name="chatbubbles-outline"
            size={18}
            color={activeTab === 'messages' ? colors.haven.champagne[500] : colors.text.secondary}
          />
          <Text style={[styles.tabText, activeTab === 'messages' && styles.tabTextActive]}>
            Messages
          </Text>
          {conversations.some(c => c.unreadCount > 0) && (
            <View style={styles.tabBadge}>
              <Text style={styles.tabBadgeText}>
                {conversations.reduce((sum, c) => sum + c.unreadCount, 0)}
              </Text>
            </View>
          )}
        </TouchableOpacity>
      </View>

      {/* Tab Content */}
      <View style={styles.tabContent}>
        {activeTab === 'alfred' ? renderAlfredTab() : renderMessagesTab()}
      </View>
    </View>
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
  headerWrapper: {
    backgroundColor: colors.haven.navy[950],
  },
  header: {
    height: 56,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.white,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[3],
    gap: spacing[2],
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabActive: {
    borderBottomColor: colors.haven.champagne[500],
  },
  tabText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  tabTextActive: {
    color: colors.haven.champagne[500],
  },
  tabBadge: {
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
    minWidth: 20,
    alignItems: 'center',
  },
  tabBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  tabContent: {
    flex: 1,
  },
  keyboardView: {
    flex: 1,
  },
  quickActions: {
    flexDirection: 'row',
    padding: spacing[3],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  quickAction: {
    flex: 1,
    alignItems: 'center',
    padding: spacing[2],
  },
  quickActionIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[1],
  },
  quickActionText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  messagesContainer: {
    flex: 1,
  },
  messagesContent: {
    padding: spacing[4],
    paddingBottom: spacing[6],
  },
  messageBubble: {
    maxWidth: '85%',
    padding: spacing[3],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[3],
  },
  userBubble: {
    alignSelf: 'flex-end',
    backgroundColor: colors.haven.navy[900],
    borderBottomRightRadius: borderRadius.sm,
  },
  alfredBubble: {
    alignSelf: 'flex-start',
    backgroundColor: colors.white,
    borderBottomLeftRadius: borderRadius.sm,
    shadowColor: colors.haven.navy[900],
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  alfredHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  alfredName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[500],
    marginLeft: spacing[2],
    flex: 1,
  },
  messageTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  messageText: {
    fontSize: typography.fontSizes.base,
    lineHeight: 22,
  },
  userText: {
    color: colors.white,
  },
  alfredText: {
    color: colors.text.primary,
  },
  userTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.navy[300],
    marginTop: spacing[1],
    textAlign: 'right',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
    gap: spacing[2],
    alignSelf: 'flex-start',
  },
  actionButtonText: {
    color: colors.white,
    fontWeight: typography.fontWeights.semibold,
    fontSize: typography.fontSizes.sm,
  },
  typingIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingVertical: spacing[1],
  },
  typingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.haven.champagne[400],
  },
  inputContainer: {
    flexDirection: 'row',
    padding: spacing[3],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    alignItems: 'flex-end',
  },
  input: {
    flex: 1,
    backgroundColor: colors.background.tertiary,
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
    backgroundColor: '#c4a574',  // Champagne when active - more inviting
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: spacing[2],
  },
  sendButtonDisabled: {
    backgroundColor: '#e2e8f0',  // Slightly darker gray - more visible
    opacity: 0.6,
  },
  quickRepliesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginTop: spacing[3],
  },
  quickReplyButton: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.haven.champagne[300],
  },
  quickReplyButtonPrimary: {
    backgroundColor: colors.haven.champagne[500],
    borderColor: colors.haven.champagne[500],
  },
  quickReplyText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[600],
  },
  quickReplyTextPrimary: {
    color: colors.white,
  },
  // Messages Tab Styles
  conversationsList: {
    padding: spacing[4],
  },
  conversationItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[3],
  },
  conversationIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  conversationContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  conversationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  conversationName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  conversationTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  conversationMessage: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
  },
  unreadBadge: {
    backgroundColor: colors.status.error,
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: spacing[2],
  },
  unreadBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  emptyMessages: {
    alignItems: 'center',
    paddingVertical: spacing[10],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
    textAlign: 'center',
    paddingHorizontal: spacing[6],
  },
  messagesTabContainer: {
    flex: 1,
  },
  newMessageButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[2],
  },
  newMessageButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  fab: {
    position: 'absolute',
    right: spacing[4],
    bottom: spacing[4],
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[500],
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: colors.haven.navy[900],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 5,
  },
});
