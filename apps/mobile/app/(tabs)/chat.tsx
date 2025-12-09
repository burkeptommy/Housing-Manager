import { useState, useRef, useEffect, useCallback } from 'react';
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
  Modal,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../src/contexts/auth-context';
import {
  useConversations,
  useConversation,
  createConversation,
  sendMessage,
} from '../../src/hooks/use-conversations';
import type { Conversation, SupportMessage, SenderRole } from '@haven/core';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';

// Format time helper
function formatTime(dateString: string): string {
  const date = new Date(dateString);
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

// Get sender display name
function getSenderName(message: SupportMessage): string {
  if (message.senderRole === 'SYSTEM') return 'System';
  if (message.sender) {
    const firstName = message.sender.firstName || '';
    const lastName = message.sender.lastName || '';
    if (firstName || lastName) return `${firstName} ${lastName}`.trim();
    return message.sender.email;
  }
  return message.senderRole === 'HOME_MANAGER' ? 'Home Manager' : 'You';
}

// Get role badge color
function getRoleBadgeColor(role: SenderRole): string {
  switch (role) {
    case 'HOME_MANAGER':
      return colors.accent[500];
    case 'SYSTEM':
      return colors.slate[500];
    default:
      return colors.primary[500];
  }
}

// Conversation List Item Component
function ConversationListItem({
  conversation,
  onPress,
}: {
  conversation: Conversation;
  onPress: () => void;
}) {
  const hasUnread = conversation.homeownerUnreadCount > 0;

  return (
    <TouchableOpacity style={styles.conversationItem} onPress={onPress}>
      <View style={styles.conversationContent}>
        <View style={styles.conversationHeader}>
          <Text
            style={[
              styles.conversationSubject,
              hasUnread && styles.conversationSubjectUnread,
            ]}
            numberOfLines={1}
          >
            {conversation.subject || 'Support Request'}
          </Text>
          <Text style={styles.conversationTime}>
            {formatTime(conversation.updatedAt)}
          </Text>
        </View>
        <View style={styles.conversationMeta}>
          <View
            style={[
              styles.statusBadge,
              conversation.status === 'OPEN' && styles.statusOpen,
              conversation.status === 'PENDING' && styles.statusPending,
              conversation.status === 'CLOSED' && styles.statusClosed,
            ]}
          >
            <Text style={styles.statusText}>{conversation.status}</Text>
          </View>
          {hasUnread && (
            <View style={styles.unreadBadge}>
              <Text style={styles.unreadText}>
                {conversation.homeownerUnreadCount}
              </Text>
            </View>
          )}
        </View>
        {conversation.lastMessage && (
          <Text style={styles.lastMessage} numberOfLines={2}>
            {conversation.lastMessage.body}
          </Text>
        )}
      </View>
      <Text style={styles.chevron}>›</Text>
    </TouchableOpacity>
  );
}

// Message Bubble Component
function MessageBubble({
  message,
  isOwn,
}: {
  message: SupportMessage;
  isOwn: boolean;
}) {
  const senderName = getSenderName(message);
  const isSystem = message.senderRole === 'SYSTEM';

  if (isSystem) {
    return (
      <View style={styles.systemMessage}>
        <Text style={styles.systemMessageText}>{message.body}</Text>
        <Text style={styles.systemMessageTime}>{formatTime(message.createdAt)}</Text>
      </View>
    );
  }

  return (
    <View
      style={[
        styles.messageContainer,
        isOwn ? styles.messageOwn : styles.messageOther,
      ]}
    >
      {!isOwn && (
        <View style={styles.avatarContainer}>
          <View
            style={[
              styles.avatar,
              { backgroundColor: getRoleBadgeColor(message.senderRole) },
            ]}
          >
            <Text style={styles.avatarText}>
              {senderName.charAt(0).toUpperCase()}
            </Text>
          </View>
        </View>
      )}
      <View
        style={[
          styles.messageBubble,
          isOwn ? styles.bubbleOwn : styles.bubbleOther,
        ]}
      >
        {!isOwn && <Text style={styles.senderName}>{senderName}</Text>}
        <Text
          style={[
            styles.messageText,
            isOwn ? styles.messageTextOwn : styles.messageTextOther,
          ]}
        >
          {message.body}
        </Text>
        <Text
          style={[
            styles.messageTime,
            isOwn ? styles.messageTimeOwn : styles.messageTimeOther,
          ]}
        >
          {formatTime(message.createdAt)}
        </Text>
      </View>
    </View>
  );
}

// Chat View Component
function ChatView({
  conversationId,
  onBack,
  userId,
}: {
  conversationId: string;
  onBack: () => void;
  userId: string;
}) {
  const { conversation, isLoading, refetch } = useConversation(conversationId);
  const [newMessage, setNewMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  // Poll for new messages
  useEffect(() => {
    const interval = setInterval(() => {
      refetch();
    }, 5000);
    return () => clearInterval(interval);
  }, [refetch]);

  // Scroll to bottom when messages change
  useEffect(() => {
    if (conversation?.messages?.length) {
      setTimeout(() => {
        flatListRef.current?.scrollToEnd({ animated: true });
      }, 100);
    }
  }, [conversation?.messages?.length]);

  const handleSend = async () => {
    if (!newMessage.trim() || isSending) return;

    setIsSending(true);
    const result = await sendMessage(conversationId, { body: newMessage.trim() });
    setIsSending(false);

    if (result) {
      setNewMessage('');
      refetch();
    }
  };

  if (isLoading && !conversation) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary[600]} />
      </View>
    );
  }

  return (
    <View style={styles.chatContainer}>
      {/* Header */}
      <View style={styles.chatHeader}>
        <TouchableOpacity onPress={onBack} style={styles.backButton}>
          <Text style={styles.backText}>‹ Back</Text>
        </TouchableOpacity>
        <View style={styles.chatHeaderContent}>
          <Text style={styles.chatHeaderTitle} numberOfLines={1}>
            {conversation?.subject || 'Support Request'}
          </Text>
          <View
            style={[
              styles.statusBadgeSmall,
              conversation?.status === 'OPEN' && styles.statusOpen,
              conversation?.status === 'PENDING' && styles.statusPending,
              conversation?.status === 'CLOSED' && styles.statusClosed,
            ]}
          >
            <Text style={styles.statusTextSmall}>{conversation?.status}</Text>
          </View>
        </View>
      </View>

      {/* Messages */}
      <FlatList
        ref={flatListRef}
        data={conversation?.messages || []}
        renderItem={({ item }) => (
          <MessageBubble message={item} isOwn={item.senderUserId === userId} />
        )}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.messagesList}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View style={styles.emptyMessages}>
            <Text style={styles.emptyMessagesText}>No messages yet</Text>
          </View>
        }
      />

      {/* Composer */}
      {conversation?.status !== 'CLOSED' && (
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
                (!newMessage.trim() || isSending) && styles.sendButtonDisabled,
              ]}
              onPress={handleSend}
              disabled={!newMessage.trim() || isSending}
            >
              {isSending ? (
                <ActivityIndicator size="small" color={colors.white} />
              ) : (
                <Text style={styles.sendIcon}>➤</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      )}

      {conversation?.status === 'CLOSED' && (
        <View style={styles.closedBanner}>
          <Text style={styles.closedText}>
            This conversation is closed. Start a new one if you need help.
          </Text>
        </View>
      )}
    </View>
  );
}

// New Conversation Modal
function NewConversationModal({
  visible,
  onClose,
  onCreated,
}: {
  visible: boolean;
  onClose: () => void;
  onCreated: (id: string) => void;
}) {
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  const handleCreate = async () => {
    if (!message.trim()) return;

    setIsCreating(true);
    const result = await createConversation({
      subject: subject.trim() || undefined,
      body: message.trim(),
    });
    setIsCreating(false);

    if (result) {
      setSubject('');
      setMessage('');
      onCreated(result.id);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.modalContainer}>
        <View style={styles.modalHeader}>
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.modalCancel}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.modalTitle}>New Conversation</Text>
          <TouchableOpacity
            onPress={handleCreate}
            disabled={!message.trim() || isCreating}
          >
            <Text
              style={[
                styles.modalSend,
                (!message.trim() || isCreating) && styles.modalSendDisabled,
              ]}
            >
              {isCreating ? 'Sending...' : 'Send'}
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.modalContent}>
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Subject (optional)</Text>
            <TextInput
              style={styles.modalInput}
              placeholder="What do you need help with?"
              placeholderTextColor={colors.slate[400]}
              value={subject}
              onChangeText={setSubject}
              maxLength={100}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Message</Text>
            <TextInput
              style={[styles.modalInput, styles.modalTextarea]}
              placeholder="Describe your issue or question..."
              placeholderTextColor={colors.slate[400]}
              value={message}
              onChangeText={setMessage}
              multiline
              maxLength={2000}
              textAlignVertical="top"
            />
          </View>
        </View>
      </SafeAreaView>
    </Modal>
  );
}

// Main Chat Screen
export default function ChatScreen() {
  const { user, currentHousehold } = useAuth();
  const { conversations, isLoading, refetch } = useConversations();
  const [selectedConversationId, setSelectedConversationId] = useState<string | null>(
    null
  );
  const [showNewModal, setShowNewModal] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  }, [refetch]);

  const handleConversationCreated = (id: string) => {
    setShowNewModal(false);
    setSelectedConversationId(id);
    refetch();
  };

  if (!currentHousehold) {
    return (
      <SafeAreaView style={styles.emptyContainer} edges={['bottom']}>
        <Text style={styles.emptyText}>No household selected</Text>
      </SafeAreaView>
    );
  }

  // Show chat view if a conversation is selected
  if (selectedConversationId && user) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
          keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}
        >
          <ChatView
            conversationId={selectedConversationId}
            onBack={() => {
              setSelectedConversationId(null);
              refetch();
            }}
            userId={user.id}
          />
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }

  // Show conversation list
  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Header */}
      <View style={styles.listHeader}>
        <View>
          <Text style={styles.listTitle}>Support</Text>
          <Text style={styles.listSubtitle}>Chat with your home manager</Text>
        </View>
        <TouchableOpacity
          style={styles.newButton}
          onPress={() => setShowNewModal(true)}
        >
          <Text style={styles.newButtonText}>+ New</Text>
        </TouchableOpacity>
      </View>

      {/* Conversations List */}
      {isLoading && conversations.length === 0 ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary[600]} />
        </View>
      ) : (
        <FlatList
          data={conversations}
          renderItem={({ item }) => (
            <ConversationListItem
              conversation={item}
              onPress={() => setSelectedConversationId(item.id)}
            />
          )}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContainer}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={handleRefresh}
              tintColor={colors.primary[600]}
            />
          }
          ListEmptyComponent={
            <View style={styles.emptyList}>
              <Text style={styles.emptyListTitle}>No conversations yet</Text>
              <Text style={styles.emptyListText}>
                Tap the "+ New" button to start a conversation with your home
                manager
              </Text>
            </View>
          }
        />
      )}

      {/* New Conversation Modal */}
      <NewConversationModal
        visible={showNewModal}
        onClose={() => setShowNewModal(false)}
        onCreated={handleConversationCreated}
      />
    </SafeAreaView>
  );
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
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },

  // List Header
  listHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[200],
  },
  listTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  listSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  newButton: {
    backgroundColor: colors.primary[600],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  newButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },

  // Conversation List
  listContainer: {
    padding: spacing[4],
  },
  conversationItem: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    flexDirection: 'row',
    alignItems: 'center',
    ...shadows.sm,
  },
  conversationContent: {
    flex: 1,
  },
  conversationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[1],
  },
  conversationSubject: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[800],
    flex: 1,
    marginRight: spacing[2],
  },
  conversationSubjectUnread: {
    fontWeight: typography.fontWeights.bold,
  },
  conversationTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
  },
  conversationMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  statusBadge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  statusOpen: {
    backgroundColor: colors.green[100],
  },
  statusPending: {
    backgroundColor: '#fef3c7', // amber-100
  },
  statusClosed: {
    backgroundColor: colors.slate[100],
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  unreadBadge: {
    backgroundColor: colors.primary[600],
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 6,
  },
  unreadText: {
    color: colors.white,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.bold,
  },
  lastMessage: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    lineHeight: 18,
  },
  chevron: {
    fontSize: 24,
    color: colors.slate[400],
    marginLeft: spacing[2],
  },

  // Empty List
  emptyList: {
    alignItems: 'center',
    paddingVertical: spacing[10],
    paddingHorizontal: spacing[6],
  },
  emptyListTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[700],
    marginBottom: spacing[2],
  },
  emptyListText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    textAlign: 'center',
    lineHeight: 22,
  },

  // Chat View
  chatContainer: {
    flex: 1,
  },
  chatHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[200],
  },
  backButton: {
    marginRight: spacing[3],
  },
  backText: {
    fontSize: typography.fontSizes.base,
    color: colors.primary[600],
    fontWeight: typography.fontWeights.medium,
  },
  chatHeaderContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  chatHeaderTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    flex: 1,
  },
  statusBadgeSmall: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  statusTextSmall: {
    fontSize: 10,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },

  // Messages
  messagesList: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[4],
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

  // System Message
  systemMessage: {
    alignItems: 'center',
    marginVertical: spacing[2],
  },
  systemMessageText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    backgroundColor: colors.slate[100],
    paddingHorizontal: spacing[3],
    paddingVertical: 6,
    borderRadius: borderRadius.full,
    textAlign: 'center',
  },
  systemMessageTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: spacing[1],
  },

  // Empty Messages
  emptyMessages: {
    alignItems: 'center',
    paddingVertical: spacing[10],
  },
  emptyMessagesText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[400],
  },

  // Composer
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

  // Closed Banner
  closedBanner: {
    backgroundColor: colors.slate[100],
    padding: spacing[4],
    borderTopWidth: 1,
    borderTopColor: colors.slate[200],
  },
  closedText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    textAlign: 'center',
  },

  // Modal
  modalContainer: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[4],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[200],
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  modalCancel: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[600],
  },
  modalSend: {
    fontSize: typography.fontSizes.base,
    color: colors.primary[600],
    fontWeight: typography.fontWeights.semibold,
  },
  modalSendDisabled: {
    color: colors.slate[400],
  },
  modalContent: {
    padding: spacing[4],
  },
  inputGroup: {
    marginBottom: spacing[4],
  },
  inputLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[2],
  },
  modalInput: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  modalTextarea: {
    minHeight: 150,
    textAlignVertical: 'top',
  },
});
