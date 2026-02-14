import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  ScrollView,
  TextInput,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { useSubscription } from '../../../src/contexts/subscription-context';
import { Card, Badge, LoadingSpinner, ScreenContainer } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

type TabType = 'conversations' | 'projects';
type CategoryType = 'all' | 'team' | 'vendors' | 'community';

interface Conversation {
  id: string;
  subject: string;
  status: string;
  createdAt: string;
  lastMessageAt?: string;
  unreadCount?: number;
  category?: CategoryType;
  lastMessage?: {
    content: string;
    createdAt: string;
    sender: {
      firstName: string | null;
      lastName: string | null;
      role: string;
    };
  };
}

interface Contact {
  id: string;
  name: string;
  role: string;
  category: CategoryType;
  isOnline?: boolean;
  isPinned?: boolean;
}

// Demo contacts for new message picker - dynamically generated based on tier
const getContacts = (isEssentials: boolean): Contact[] => [
  {
    id: 'manager',
    name: isEssentials ? 'Alfred' : 'Sarah Chen',
    role: isEssentials ? 'Your AI Home Manager' : 'Your Home Manager',
    category: 'team',
    isOnline: true,
    isPinned: true
  },
  { id: 'marcus', name: 'Marcus Johnson', role: 'Your Handyman', category: 'team', isOnline: false, isPinned: true },
  { id: 'mike-plumbing', name: "Mike's Plumbing Pro", role: 'Plumber', category: 'vendors' },
  { id: 'country-landscape', name: 'Country Landscape', role: 'Landscaper', category: 'vendors' },
  { id: 'comfort-hvac', name: 'Comfort Zone HVAC', role: 'HVAC', category: 'vendors' },
  { id: 'ace-roofing', name: 'Ace Roofing', role: 'Roofing', category: 'vendors' },
];

const CATEGORY_CONFIG = {
  all: { label: 'All', icon: 'chatbubbles-outline' as const },
  team: { label: 'Team', icon: 'shield-outline' as const },
  vendors: { label: 'Vendors', icon: 'construct-outline' as const },
  community: { label: 'Community', icon: 'people-outline' as const },
};

// =============================================================================
// COMPONENT
// =============================================================================

export default function MessagesScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const { isEssentials } = useSubscription();
  const contacts = getContacts(isEssentials);
  const [activeTab, setActiveTab] = useState<TabType>('conversations');
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [categoryFilter, setCategoryFilter] = useState<CategoryType>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showNewMessageModal, setShowNewMessageModal] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchConversations = useCallback(async () => {
    if (!householdInfo?.id) {
      setError('No household found.');
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
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
        throw new Error('Failed to fetch conversations');
      }

      const data: Conversation[] = await response.json();

      // Sort by last message date and add category info
      data.sort((a, b) => {
        const dateA = new Date(a.lastMessageAt || a.createdAt).getTime();
        const dateB = new Date(b.lastMessageAt || b.createdAt).getTime();
        return dateB - dateA;
      });

      // Assign categories based on sender role
      const categorizedData = data.map(conv => ({
        ...conv,
        category: determineCategory(conv) as CategoryType,
      }));

      setConversations(categorizedData);
      setError(null);
    } catch (err) {
      console.error('Fetch conversations error:', err);
      setError('Failed to load messages.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchConversations();
  }, [fetchConversations]);

  const determineCategory = (conv: Conversation): CategoryType => {
    const senderRole = conv.lastMessage?.sender?.role?.toUpperCase() || '';
    if (senderRole.includes('MANAGER') || senderRole.includes('ADMIN') || senderRole.includes('HANDYMAN')) {
      return 'team';
    }
    if (senderRole.includes('VENDOR')) {
      return 'vendors';
    }
    return 'team'; // Default to team
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m`;
    if (diffHours < 24) return `${diffHours}h`;
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return date.toLocaleDateString('en-US', { weekday: 'short' });
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const truncateMessage = (message: string, maxLength: number = 50) => {
    if (message.length <= maxLength) return message;
    return message.substring(0, maxLength).trim() + '...';
  };

  // Filter conversations based on category and search
  const filteredConversations = conversations.filter(c => {
    if (categoryFilter !== 'all' && c.category !== categoryFilter) return false;
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return c.subject.toLowerCase().includes(query);
    }
    return true;
  });

  const totalUnread = conversations.reduce((sum, c) => sum + (c.unreadCount || 0), 0);

  const handleContactSelect = (contact: Contact) => {
    setShowNewMessageModal(false);
    // Navigate to chat with this contact
    router.push('/(tabs)/manager/chat' as any);
  };

  const renderConversation = ({ item }: { item: Conversation }) => {
    const hasUnread = item.unreadCount && item.unreadCount > 0;
    const senderName = item.lastMessage?.sender
      ? `${item.lastMessage.sender.firstName || ''} ${item.lastMessage.sender.lastName || ''}`.trim() || 'Unknown'
      : '';
    const isFromTeam = item.category === 'team';

    return (
      <TouchableOpacity
        activeOpacity={0.7}
        onPress={() => router.push(`/(tabs)/messages/${item.id}` as any)}
      >
        <Card style={[styles.conversationCard, hasUnread ? styles.conversationCardUnread : undefined]}>
          <View style={styles.conversationHeader}>
            <View style={[styles.avatar, isFromTeam && styles.avatarTeam]}>
              <Ionicons
                name={isFromTeam ? 'shield' : item.category === 'vendors' ? 'construct' : 'chatbubble'}
                size={18}
                color={colors.white}
              />
            </View>
            <View style={styles.conversationInfo}>
              <View style={styles.conversationTitleRow}>
                <Text style={[styles.conversationSubject, hasUnread ? styles.conversationSubjectUnread : undefined]} numberOfLines={1}>
                  {item.subject}
                </Text>
                <Text style={styles.conversationTime}>
                  {formatDate(item.lastMessageAt || item.createdAt)}
                </Text>
              </View>
              {item.lastMessage && (
                <Text style={styles.conversationPreview} numberOfLines={1}>
                  {senderName}: {truncateMessage(item.lastMessage.content)}
                </Text>
              )}
            </View>
          </View>
          <View style={styles.conversationFooter}>
            <Badge
              label={item.status === 'OPEN' ? 'Open' : item.status === 'PENDING' ? 'Pending' : 'Resolved'}
              variant={item.status === 'OPEN' || item.status === 'PENDING' ? 'warning' : 'success'}
              size="sm"
            />
            {hasUnread && (
              <View style={styles.unreadBadge}>
                <Text style={styles.unreadText}>{item.unreadCount}</Text>
              </View>
            )}
          </View>
        </Card>
      </TouchableOpacity>
    );
  };

  const renderContactItem = ({ item }: { item: Contact }) => (
    <TouchableOpacity
      style={styles.contactItem}
      onPress={() => handleContactSelect(item)}
      activeOpacity={0.7}
    >
      <View style={[styles.contactAvatar, item.category === 'team' && styles.avatarTeam]}>
        <Ionicons
          name={item.category === 'team' ? 'shield' : 'construct'}
          size={20}
          color={colors.white}
        />
        {item.isOnline && <View style={styles.onlineIndicator} />}
      </View>
      <View style={styles.contactInfo}>
        <View style={styles.contactNameRow}>
          <Text style={styles.contactName}>{item.name}</Text>
          {item.isPinned && (
            <Ionicons name="pin" size={12} color={colors.haven.purple[500]} />
          )}
        </View>
        <Text style={styles.contactRole}>{item.role}</Text>
      </View>
      <Ionicons name="chevron-forward" size={20} color={colors.gray[400]} />
    </TouchableOpacity>
  );

  if (isLoading) {
    return (
      <ScreenContainer title="Messages" onBackPress={() => router.navigate('/more')}>
        <LoadingSpinner fullScreen message="Loading messages..." />
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Messages" onBackPress={() => router.navigate('/more')} scrollable={false}>
      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <Ionicons name="search" size={20} color={colors.gray[400]} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search messages..."
          placeholderTextColor={colors.gray[400]}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
      </View>

      {/* Tab Switcher */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'conversations' && styles.tabActive]}
          onPress={() => setActiveTab('conversations')}
        >
          <Ionicons
            name="chatbubbles"
            size={18}
            color={activeTab === 'conversations' ? colors.haven.purple[900] : colors.gray[500]}
          />
          <Text style={[styles.tabText, activeTab === 'conversations' && styles.tabTextActive]}>
            Conversations
          </Text>
          {totalUnread > 0 && (
            <View style={styles.tabBadge}>
              <Text style={styles.tabBadgeText}>{totalUnread}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'projects' && styles.tabActive]}
          onPress={() => setActiveTab('projects')}
        >
          <Ionicons
            name="folder-open"
            size={18}
            color={activeTab === 'projects' ? colors.haven.purple[900] : colors.gray[500]}
          />
          <Text style={[styles.tabText, activeTab === 'projects' && styles.tabTextActive]}>
            Projects
          </Text>
        </TouchableOpacity>
      </View>

      {/* Category Filter Pills */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.filterContainer}
      >
        {(Object.keys(CATEGORY_CONFIG) as CategoryType[]).map((category) => {
          const config = CATEGORY_CONFIG[category];
          return (
            <TouchableOpacity
              key={category}
              style={[
                styles.filterPill,
                categoryFilter === category && styles.filterPillActive,
              ]}
              onPress={() => setCategoryFilter(category)}
            >
              <Ionicons
                name={config.icon}
                size={16}
                color={categoryFilter === category ? colors.white : colors.text.secondary}
              />
              <Text
                style={[
                  styles.filterPillText,
                  categoryFilter === category && styles.filterPillTextActive,
                ]}
              >
                {config.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* Conversations List */}
      <FlatList
        data={filteredConversations}
        renderItem={renderConversation}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchConversations();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="mail-outline" size={48} color={colors.haven.purple[300]} />
            <Text style={styles.emptyTitle}>No messages</Text>
            <Text style={styles.emptyText}>
              Start a conversation with your home manager, vendors, or community.
            </Text>
            <TouchableOpacity
              style={styles.emptyButton}
              onPress={() => setShowNewMessageModal(true)}
            >
              <Text style={styles.emptyButtonText}>New Message</Text>
            </TouchableOpacity>
          </View>
        }
      />

      {/* FAB for new message */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => setShowNewMessageModal(true)}
      >
        <Ionicons name="add" size={28} color={colors.white} />
      </TouchableOpacity>

      {/* New Message Modal */}
      <Modal
        visible={showNewMessageModal}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setShowNewMessageModal(false)}
      >
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity
              onPress={() => setShowNewMessageModal(false)}
              style={styles.modalCloseButton}
            >
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.modalTitle}>New Message</Text>
            <View style={{ width: 40 }} />
          </View>

          {/* Search in modal */}
          <View style={styles.modalSearchContainer}>
            <Ionicons name="search" size={18} color={colors.gray[400]} />
            <TextInput
              style={styles.modalSearchInput}
              placeholder="Search contacts..."
              placeholderTextColor={colors.gray[400]}
            />
          </View>

          {/* Contact Categories */}
          <FlatList
            data={contacts}
            renderItem={renderContactItem}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.contactList}
            ListHeaderComponent={
              <>
                {/* Team Section */}
                <View style={styles.sectionHeader}>
                  <Ionicons name="shield-outline" size={16} color={colors.haven.purple[500]} />
                  <Text style={styles.sectionTitle}>Your Team</Text>
                </View>
                {contacts.filter(c => c.category === 'team').map(contact => (
                  <TouchableOpacity
                    key={contact.id}
                    style={styles.contactItem}
                    onPress={() => handleContactSelect(contact)}
                    activeOpacity={0.7}
                  >
                    <View style={[styles.contactAvatar, styles.avatarTeam]}>
                      <Ionicons name="shield" size={20} color={colors.white} />
                      {contact.isOnline && <View style={styles.onlineIndicator} />}
                    </View>
                    <View style={styles.contactInfo}>
                      <View style={styles.contactNameRow}>
                        <Text style={styles.contactName}>{contact.name}</Text>
                        {contact.isPinned && (
                          <Ionicons name="pin" size={12} color={colors.haven.purple[500]} />
                        )}
                      </View>
                      <Text style={styles.contactRole}>{contact.role}</Text>
                    </View>
                    <Ionicons name="chevron-forward" size={20} color={colors.gray[400]} />
                  </TouchableOpacity>
                ))}

                {/* Vendors Section */}
                <View style={styles.sectionHeader}>
                  <Ionicons name="construct-outline" size={16} color={colors.haven.purple[500]} />
                  <Text style={styles.sectionTitle}>Vendors</Text>
                </View>
                {contacts.filter(c => c.category === 'vendors').map(contact => (
                  <TouchableOpacity
                    key={contact.id}
                    style={styles.contactItem}
                    onPress={() => handleContactSelect(contact)}
                    activeOpacity={0.7}
                  >
                    <View style={styles.contactAvatar}>
                      <Ionicons name="construct" size={20} color={colors.white} />
                    </View>
                    <View style={styles.contactInfo}>
                      <Text style={styles.contactName}>{contact.name}</Text>
                      <Text style={styles.contactRole}>{contact.role}</Text>
                    </View>
                    <Ionicons name="chevron-forward" size={20} color={colors.gray[400]} />
                  </TouchableOpacity>
                ))}
              </>
            }
          />
        </SafeAreaView>
      </Modal>
    </ScreenContainer>
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
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.xl,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  searchInput: {
    flex: 1,
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[2],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  tabContainer: {
    flexDirection: 'row',
    marginHorizontal: spacing[4],
    marginTop: spacing[3],
    padding: spacing[1],
    backgroundColor: colors.gray[100],
    borderRadius: borderRadius.xl,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[2],
    gap: spacing[2],
    borderRadius: borderRadius.lg,
  },
  tabActive: {
    backgroundColor: colors.white,
    shadowColor: colors.haven.purple[900],
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  tabText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.gray[500],
  },
  tabTextActive: {
    color: colors.haven.purple[900],
  },
  tabBadge: {
    backgroundColor: colors.haven.purple[500],
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: borderRadius.full,
    minWidth: 18,
    alignItems: 'center',
  },
  tabBadgeText: {
    fontSize: 11,  // Minimum for badges
    fontWeight: typography.fontWeights.bold,  // Bolder to compensate
    color: colors.white,
  },
  filterContainer: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    gap: spacing[2],
  },
  filterPill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.border.light,
    marginRight: spacing[2],
    gap: spacing[1],
  },
  filterPillActive: {
    backgroundColor: colors.haven.purple[900],
    borderColor: colors.haven.purple[900],
  },
  filterPillText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  filterPillTextActive: {
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingTop: 0,
  },
  conversationCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  conversationCardUnread: {
    borderLeftWidth: 3,
    borderLeftColor: colors.haven.purple[500],
  },
  conversationHeader: {
    flexDirection: 'row',
    marginBottom: spacing[2],
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.purple[400],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  avatarTeam: {
    backgroundColor: colors.haven.purple[500],
  },
  conversationInfo: {
    flex: 1,
  },
  conversationTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  conversationSubject: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginRight: spacing[2],
  },
  conversationSubjectUnread: {
    fontWeight: typography.fontWeights.semibold,
  },
  conversationTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  conversationPreview: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  conversationFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing[2],
  },
  unreadBadge: {
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
    minWidth: 22,
    alignItems: 'center',
  },
  unreadText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  emptyContainer: {
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
    textAlign: 'center',
    marginTop: spacing[1],
    marginBottom: spacing[4],
    paddingHorizontal: spacing[6],
  },
  emptyButton: {
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[6],
    backgroundColor: colors.haven.purple[500],
    borderRadius: borderRadius.lg,
  },
  emptyButtonText: {
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
    backgroundColor: colors.haven.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: colors.haven.purple[900],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 5,
  },
  // Modal styles
  modalContainer: {
    flex: 1,
    backgroundColor: colors.white,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  modalCloseButton: {
    padding: spacing[2],
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  modalSearchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: spacing[4],
    marginVertical: spacing[3],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  modalSearchInput: {
    flex: 1,
    paddingHorizontal: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  contactList: {
    paddingBottom: spacing[6],
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    backgroundColor: colors.gray[50],
    gap: spacing[2],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  contactItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  contactAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.haven.purple[400],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
    position: 'relative',
  },
  onlineIndicator: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.status.success,
    borderWidth: 2,
    borderColor: colors.white,
  },
  contactInfo: {
    flex: 1,
  },
  contactNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  contactName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  contactRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
});
