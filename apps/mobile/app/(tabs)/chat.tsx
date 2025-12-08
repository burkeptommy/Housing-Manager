import { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';

// Placeholder message type until we connect to the actual API
interface Message {
  id: string;
  content: string;
  senderId: string;
  senderName: string;
  createdAt: Date;
  isOwn: boolean;
}

// Mock messages for UI demonstration
const MOCK_MESSAGES: Message[] = [
  {
    id: '1',
    content: 'Welcome to your household chat! This is where you can communicate with your property manager and other household members.',
    senderId: 'system',
    senderName: 'Haven',
    createdAt: new Date(Date.now() - 86400000),
    isOwn: false,
  },
  {
    id: '2',
    content: 'Hi! I noticed your service request for HVAC maintenance. I\'ve scheduled a technician to come by on Friday at 2 PM. Does that work for you?',
    senderId: 'manager',
    senderName: 'Property Manager',
    createdAt: new Date(Date.now() - 3600000),
    isOwn: false,
  },
];

export default function ChatScreen() {
  const { user, currentHousehold } = useAuth();
  const [messages, setMessages] = useState<Message[]>(MOCK_MESSAGES);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  // Scroll to bottom when new message is added
  useEffect(() => {
    if (messages.length > 0) {
      setTimeout(() => {
        flatListRef.current?.scrollToEnd({ animated: true });
      }, 100);
    }
  }, [messages.length]);

  const handleSend = async () => {
    if (!newMessage.trim() || !user) return;

    const message: Message = {
      id: Date.now().toString(),
      content: newMessage.trim(),
      senderId: user.id,
      senderName: `${user.firstName} ${user.lastName}`,
      createdAt: new Date(),
      isOwn: true,
    };

    setMessages((prev) => [...prev, message]);
    setNewMessage('');

    // TODO: Send message to API
    // In a real implementation, this would connect to the MessagesModule WebSocket
  };

  const renderMessage = ({ item }: { item: Message }) => (
    <View
      style={[
        styles.messageContainer,
        item.isOwn ? styles.messageOwn : styles.messageOther,
      ]}
    >
      {!item.isOwn && (
        <View style={styles.avatarContainer}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>
              {item.senderName.charAt(0).toUpperCase()}
            </Text>
          </View>
        </View>
      )}
      <View
        style={[
          styles.messageBubble,
          item.isOwn ? styles.bubbleOwn : styles.bubbleOther,
        ]}
      >
        {!item.isOwn && (
          <Text style={styles.senderName}>{item.senderName}</Text>
        )}
        <Text
          style={[
            styles.messageText,
            item.isOwn ? styles.messageTextOwn : styles.messageTextOther,
          ]}
        >
          {item.content}
        </Text>
        <Text
          style={[
            styles.messageTime,
            item.isOwn ? styles.messageTimeOwn : styles.messageTimeOther,
          ]}
        >
          {formatTime(item.createdAt)}
        </Text>
      </View>
    </View>
  );

  if (!currentHousehold) {
    return (
      <SafeAreaView style={styles.emptyContainer} edges={['bottom']}>
        <Text style={styles.emptyText}>No household selected</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}
      >
        {/* Messages List */}
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messagesList}
          showsVerticalScrollIndicator={false}
          ListHeaderComponent={
            <View style={styles.headerBanner}>
              <Text style={styles.headerText}>
                {currentHousehold.name} Chat
              </Text>
              <Text style={styles.headerSubtext}>
                Messages with your property manager and household members
              </Text>
            </View>
          }
          ListEmptyComponent={
            <View style={styles.emptyMessages}>
              <Text style={styles.emptyMessagesText}>
                No messages yet. Start a conversation!
              </Text>
            </View>
          }
        />

        {/* Message Composer */}
        <View style={styles.composerContainer}>
          <View style={styles.composer}>
            <TextInput
              style={styles.input}
              placeholder="Type a message..."
              placeholderTextColor={colors.slate[400]}
              value={newMessage}
              onChangeText={setNewMessage}
              multiline
              maxLength={1000}
            />
            <TouchableOpacity
              style={[
                styles.sendButton,
                !newMessage.trim() && styles.sendButtonDisabled,
              ]}
              onPress={handleSend}
              disabled={!newMessage.trim() || isLoading}
            >
              {isLoading ? (
                <ActivityIndicator size="small" color={colors.white} />
              ) : (
                <Text style={styles.sendIcon}>➤</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function formatTime(date: Date): string {
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));

  if (days > 0) {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  }

  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.slate[50],
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
  },
  keyboardView: {
    flex: 1,
  },
  messagesList: {
    paddingHorizontal: spacing[4],
    paddingBottom: spacing[4],
  },
  headerBanner: {
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[4],
    marginTop: spacing[2],
  },
  headerText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.primary[800],
  },
  headerSubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.primary[600],
    marginTop: spacing[1],
  },
  emptyMessages: {
    alignItems: 'center',
    paddingVertical: spacing[10],
  },
  emptyMessagesText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[400],
  },
  messageContainer: {
    flexDirection: 'row',
    marginBottom: spacing[3],
  },
  messageOwn: {
    justifyContent: 'flex-end',
  },
  messageOther: {
    justifyContent: 'flex-start',
  },
  avatarContainer: {
    marginRight: spacing[2],
    alignSelf: 'flex-end',
  },
  avatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.accent[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },
  messageBubble: {
    maxWidth: '75%',
    borderRadius: borderRadius.xl,
    padding: spacing[3],
    paddingBottom: spacing[2],
  },
  bubbleOwn: {
    backgroundColor: colors.primary[600],
    borderBottomRightRadius: borderRadius.sm,
  },
  bubbleOther: {
    backgroundColor: colors.white,
    borderBottomLeftRadius: borderRadius.sm,
    ...shadows.sm,
  },
  senderName: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[600],
    marginBottom: spacing[1],
  },
  messageText: {
    fontSize: typography.fontSizes.base,
    lineHeight: 22,
  },
  messageTextOwn: {
    color: colors.white,
  },
  messageTextOther: {
    color: colors.slate[800],
  },
  messageTime: {
    fontSize: typography.fontSizes.xs,
    marginTop: spacing[1],
  },
  messageTimeOwn: {
    color: colors.primary[200],
    textAlign: 'right',
  },
  messageTimeOther: {
    color: colors.slate[400],
  },
  composerContainer: {
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.slate[200],
    padding: spacing[3],
  },
  composer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: spacing[2],
  },
  input: {
    flex: 1,
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.xl,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
    maxHeight: 100,
  },
  sendButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.primary[600],
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: colors.slate[300],
  },
  sendIcon: {
    color: colors.white,
    fontSize: 18,
    marginLeft: 2,
  },
});
