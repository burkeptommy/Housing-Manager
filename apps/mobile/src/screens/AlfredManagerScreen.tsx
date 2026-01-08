import React, { useState, useRef, useCallback } from 'react';
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
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { AlfredAvatar } from '../components/Alfred';
import { AlfredSuggestions } from '../components/AlfredSuggestions';
import { colors, typography, spacing, borderRadius } from '../lib/theme';
import { API_BASE_URL } from '../lib/api';
import { getIdToken } from '../lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

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
// ALFRED MANAGER SCREEN
// =============================================================================

export function AlfredManagerScreen() {
  const router = useRouter();
  const scrollViewRef = useRef<ScrollView>(null);
  const [messages, setMessages] = useState<Message[]>([INITIAL_MESSAGE]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(true);

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

    // Scroll to bottom
    setTimeout(() => {
      scrollViewRef.current?.scrollToEnd({ animated: true });
    }, 100);

    try {
      const token = await getIdToken(true);
      if (!token) {
        throw new Error('Not authenticated');
      }

      // Send to Alfred AI backend
      const response = await fetch(`${API_BASE_URL}/alfred/chat`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: textToSend,
          conversationHistory: messages.slice(-10).map(m => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to get response');
      }

      const data = await response.json();

      const alfredResponse: Message = {
        id: (Date.now() + 1).toString(),
        role: 'alfred',
        content: data.message || "I understand. Let me help you with that.",
        timestamp: new Date(),
        action: data.action,
      };

      setMessages(prev => [...prev, alfredResponse]);
    } catch (error) {
      console.error('Alfred chat error:', error);

      // Provide helpful fallback response
      const fallbackResponse: Message = {
        id: (Date.now() + 1).toString(),
        role: 'alfred',
        content: "I'm having trouble connecting right now. In the meantime, you can:\n\n• View your maintenance checklist\n• Book a handyman directly\n• Browse your vendors\n\nPlease try again in a moment.",
        timestamp: new Date(),
        action: {
          type: 'view_checklist',
          label: 'View Checklist',
        },
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

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
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
                  <AlfredAvatar size="small" showBadge={false} />
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

              {/* Action button if Alfred suggests an action */}
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

              {message.role === 'user' && (
                <Text style={styles.userTime}>{formatTime(message.timestamp)}</Text>
              )}
            </View>
          ))}

          {/* Typing Indicator */}
          {isTyping && (
            <View style={[styles.messageBubble, styles.alfredBubble]}>
              <View style={styles.alfredHeader}>
                <AlfredAvatar size="small" showBadge={false} />
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

        {/* Suggestions (shown when no messages sent) */}
        {showSuggestions && messages.length <= 1 && (
          <AlfredSuggestions onSelect={handleSuggestionPress} />
        )}

        {/* Input Bar */}
        <View style={styles.inputContainer}>
          <TextInput
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
    backgroundColor: colors.haven.navy[900],
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: spacing[2],
  },
  sendButtonDisabled: {
    backgroundColor: colors.background.tertiary,
  },
});
