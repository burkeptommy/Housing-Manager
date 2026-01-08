# Haven Mobile: M06 - Core Features Part 1

**Created:** December 29, 2024  
**Priority:** P0 - Core functionality  
**Estimated Time:** 5-6 hours  
**Dependencies:** M01-M05 complete

---

## Overview

This prompt implements the main app screens after onboarding:
1. Dashboard with home health, action items, weather
2. Manager (Sarah) chat interface
3. Approvals system
4. Push notifications setup

---

## PHASE 1: Create Dashboard Screen

### Task 1.1: Update Dashboard Tab

Replace `apps/mobile/app/(tabs)/index.tsx` with a full dashboard:

```typescript
import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius, shadows } from '../../src/lib/theme';
import { getApiClient } from '../../src/lib/api';

interface DashboardData {
  homeHealth: number;
  propertyName: string;
  address: string;
  actionItems: ActionItem[];
  upcomingMaintenance: MaintenanceTask[];
  recentActivity: Activity[];
  weather?: {
    temp: number;
    condition: string;
    icon: string;
  };
}

interface ActionItem {
  id: string;
  title: string;
  description: string;
  type: 'approval' | 'bill' | 'maintenance' | 'document';
  priority: 'high' | 'medium' | 'low';
  dueDate?: string;
}

interface MaintenanceTask {
  id: string;
  title: string;
  category: string;
  dueDate: string;
  status: string;
}

interface Activity {
  id: string;
  title: string;
  timestamp: string;
  icon: string;
}

export default function DashboardScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState<DashboardData | null>(null);

  const fetchDashboard = async () => {
    try {
      const api = getApiClient();
      // TODO: Replace with actual API call
      // const response = await api.request('GET', '/dashboard');
      
      // Mock data for now
      setData({
        homeHealth: 94,
        propertyName: 'Inspiration Farm',
        address: '38 Bedford Road, Greenwich, CT',
        actionItems: [
          {
            id: '1',
            title: 'Approve HVAC Service',
            description: 'Sarah requested approval for $450',
            type: 'approval',
            priority: 'high',
          },
          {
            id: '2',
            title: 'Electric Bill Due',
            description: 'Eversource - $187.50 due Jan 5',
            type: 'bill',
            priority: 'medium',
            dueDate: '2025-01-05',
          },
        ],
        upcomingMaintenance: [
          {
            id: '1',
            title: 'HVAC Filter Replacement',
            category: 'HVAC',
            dueDate: '2025-01-15',
            status: 'scheduled',
          },
        ],
        recentActivity: [
          {
            id: '1',
            title: 'Sarah scheduled pool inspection',
            timestamp: '2 hours ago',
            icon: 'water',
          },
          {
            id: '2',
            title: 'Mortgage payment processed',
            timestamp: 'Yesterday',
            icon: 'cash',
          },
        ],
        weather: {
          temp: 42,
          condition: 'Partly Cloudy',
          icon: 'partly-sunny',
        },
      });
    } catch (error) {
      console.error('Dashboard fetch error:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDashboard();
  }, []);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchDashboard();
  };

  const getHealthColor = (score: number) => {
    if (score >= 90) return colors.status.success;
    if (score >= 70) return colors.status.warning;
    return colors.status.error;
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return colors.status.error;
      case 'medium': return colors.status.warning;
      default: return colors.text.tertiary;
    }
  };

  const getActionIcon = (type: string) => {
    switch (type) {
      case 'approval': return 'checkmark-circle-outline';
      case 'bill': return 'receipt-outline';
      case 'maintenance': return 'construct-outline';
      case 'document': return 'document-outline';
      default: return 'alert-circle-outline';
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading dashboard..." />;
  }

  if (!data) {
    return (
      <SafeAreaView style={styles.container}>
        <Text>Failed to load dashboard</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.greeting}>Good morning, Bob</Text>
            <Text style={styles.propertyName}>{data.propertyName}</Text>
          </View>
          {data.weather && (
            <View style={styles.weather}>
              <Ionicons
                name={data.weather.icon as any}
                size={24}
                color={colors.haven.champagne[500]}
              />
              <Text style={styles.weatherTemp}>{data.weather.temp}°F</Text>
            </View>
          )}
        </View>

        {/* Home Health Card */}
        <Card style={styles.healthCard}>
          <View style={styles.healthHeader}>
            <Text style={styles.healthTitle}>Home Health</Text>
            <Badge label="Excellent" variant="success" />
          </View>
          <View style={styles.healthScore}>
            <Text style={[styles.healthNumber, { color: getHealthColor(data.homeHealth) }]}>
              {data.homeHealth}
            </Text>
            <Text style={styles.healthMax}>/100</Text>
          </View>
          <View style={styles.healthBar}>
            <View
              style={[
                styles.healthFill,
                {
                  width: `${data.homeHealth}%`,
                  backgroundColor: getHealthColor(data.homeHealth),
                },
              ]}
            />
          </View>
          <Text style={styles.healthSubtext}>
            All systems running smoothly
          </Text>
        </Card>

        {/* Action Items */}
        {data.actionItems.length > 0 && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Action Required</Text>
              <Badge label={`${data.actionItems.length}`} variant="error" size="sm" />
            </View>
            {data.actionItems.map((item) => (
              <TouchableOpacity
                key={item.id}
                style={styles.actionCard}
                onPress={() => {
                  if (item.type === 'approval') {
                    router.push('/(tabs)/approvals');
                  }
                }}
              >
                <View style={[styles.actionIcon, { backgroundColor: `${getPriorityColor(item.priority)}20` }]}>
                  <Ionicons
                    name={getActionIcon(item.type) as any}
                    size={20}
                    color={getPriorityColor(item.priority)}
                  />
                </View>
                <View style={styles.actionContent}>
                  <Text style={styles.actionTitle}>{item.title}</Text>
                  <Text style={styles.actionDescription}>{item.description}</Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.quickActions}>
            <TouchableOpacity
              style={styles.quickAction}
              onPress={() => router.push('/(tabs)/sarah')}
            >
              <View style={[styles.quickIcon, { backgroundColor: colors.haven.champagne[100] }]}>
                <Ionicons name="chatbubble" size={24} color={colors.haven.champagne[600]} />
              </View>
              <Text style={styles.quickLabel}>Message Sarah</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.quickAction}
              onPress={() => router.push('/(tabs)/approvals')}
            >
              <View style={[styles.quickIcon, { backgroundColor: colors.haven.navy[100] }]}>
                <Ionicons name="checkmark-circle" size={24} color={colors.haven.navy[600]} />
              </View>
              <Text style={styles.quickLabel}>Approvals</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.quickAction}
              onPress={() => router.push('/(tabs)/maintenance')}
            >
              <View style={[styles.quickIcon, { backgroundColor: colors.status.successLight }]}>
                <Ionicons name="construct" size={24} color={colors.status.success} />
              </View>
              <Text style={styles.quickLabel}>Maintenance</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.quickAction}
              onPress={() => router.push('/(tabs)/vault')}
            >
              <View style={[styles.quickIcon, { backgroundColor: colors.status.infoLight }]}>
                <Ionicons name="folder" size={24} color={colors.status.info} />
              </View>
              <Text style={styles.quickLabel}>Documents</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Recent Activity */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recent Activity</Text>
          <Card style={styles.activityCard}>
            {data.recentActivity.map((activity, index) => (
              <View
                key={activity.id}
                style={[
                  styles.activityRow,
                  index < data.recentActivity.length - 1 && styles.activityBorder,
                ]}
              >
                <View style={styles.activityIcon}>
                  <Ionicons
                    name={activity.icon as any}
                    size={16}
                    color={colors.haven.champagne[500]}
                  />
                </View>
                <View style={styles.activityContent}>
                  <Text style={styles.activityTitle}>{activity.title}</Text>
                  <Text style={styles.activityTime}>{activity.timestamp}</Text>
                </View>
              </View>
            ))}
          </Card>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[4],
  },
  greeting: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  propertyName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  weather: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  weatherTemp: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  healthCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  healthHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  healthTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  healthScore: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: spacing[2],
  },
  healthNumber: {
    fontSize: 48,
    fontWeight: typography.fontWeights.bold,
  },
  healthMax: {
    fontSize: typography.fontSizes.lg,
    color: colors.text.tertiary,
    marginLeft: spacing[1],
  },
  healthBar: {
    height: 8,
    backgroundColor: colors.gray[200],
    borderRadius: 4,
    marginBottom: spacing[2],
  },
  healthFill: {
    height: '100%',
    borderRadius: 4,
  },
  healthSubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  section: {
    marginBottom: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  actionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[2],
    ...shadows.sm,
  },
  actionIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  actionContent: {
    flex: 1,
  },
  actionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  actionDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  quickActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  quickAction: {
    width: '47%',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    ...shadows.sm,
  },
  quickIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  quickLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityCard: {
    padding: spacing[3],
  },
  activityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  activityBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityIcon: {
    width: 32,
    height: 32,
    borderRadius: borderRadius.md,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  activityContent: {
    flex: 1,
  },
  activityTitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  activityTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
});
```

---

## PHASE 2: Create Sarah (Manager) Chat Screen

### Task 2.1: Create Chat Screen

Create `apps/mobile/app/(tabs)/sarah.tsx`:

```typescript
import React, { useState, useRef, useEffect } from 'react';
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
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

interface Message {
  id: string;
  text: string;
  sender: 'user' | 'sarah';
  timestamp: Date;
  image?: string;
}

export default function SarahScreen() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      text: "Hi Bob! I'm Sarah, your Home Manager. How can I help you today?",
      sender: 'sarah',
      timestamp: new Date(Date.now() - 3600000),
    },
    {
      id: '2',
      text: "I noticed your HVAC filter is due for replacement. I can schedule that for you if you'd like.",
      sender: 'sarah',
      timestamp: new Date(Date.now() - 3500000),
    },
  ]);
  const [inputText, setInputText] = useState('');
  const flatListRef = useRef<FlatList>(null);

  const sendMessage = () => {
    if (!inputText.trim()) return;

    const newMessage: Message = {
      id: Date.now().toString(),
      text: inputText.trim(),
      sender: 'user',
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, newMessage]);
    setInputText('');

    // Simulate Sarah's response
    setTimeout(() => {
      const response: Message = {
        id: (Date.now() + 1).toString(),
        text: "Got it! I'll take care of that for you. Is there anything else you need?",
        sender: 'sarah',
        timestamp: new Date(),
      };
      setMessages(prev => [...prev, response]);
    }, 1500);
  };

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      const newMessage: Message = {
        id: Date.now().toString(),
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
            <Text style={styles.avatarText}>SC</Text>
          </View>
        )}
        <View
          style={[
            styles.messageBubble,
            isUser ? styles.userBubble : styles.sarahBubble,
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

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
        keyboardVerticalOffset={90}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerAvatar}>
            <Text style={styles.headerAvatarText}>SC</Text>
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.headerName}>Sarah Chen</Text>
            <Text style={styles.headerStatus}>Your Home Manager • Online</Text>
          </View>
          <TouchableOpacity style={styles.headerAction}>
            <Ionicons name="call" size={22} color={colors.haven.champagne[500]} />
          </TouchableOpacity>
        </View>

        {/* Messages */}
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
          showsVerticalScrollIndicator={false}
        />

        {/* Input */}
        <View style={styles.inputContainer}>
          <TouchableOpacity style={styles.attachButton} onPress={pickImage}>
            <Ionicons name="camera" size={24} color={colors.haven.navy[600]} />
          </TouchableOpacity>
          <TextInput
            style={styles.input}
            placeholder="Message Sarah..."
            placeholderTextColor={colors.text.tertiary}
            value={inputText}
            onChangeText={setInputText}
            multiline
            maxLength={500}
          />
          <TouchableOpacity
            style={[styles.sendButton, !inputText.trim() && styles.sendButtonDisabled]}
            onPress={sendMessage}
            disabled={!inputText.trim()}
          >
            <Ionicons
              name="send"
              size={20}
              color={inputText.trim() ? colors.white : colors.gray[400]}
            />
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  headerAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerAvatarText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  headerInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  headerName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  headerStatus: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.success,
    marginTop: 2,
  },
  headerAction: {
    padding: spacing[2],
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
  sarahBubble: {
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
```

---

## PHASE 3: Create Approvals Screen

### Task 3.1: Create Approvals Screen

Create `apps/mobile/app/(tabs)/approvals.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Card, Badge, Button, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import { getApiClient } from '../../src/lib/api';

interface Approval {
  id: string;
  title: string;
  description: string;
  amount: number;
  category: string;
  requestedBy: string;
  requestedAt: string;
  status: 'pending' | 'approved' | 'rejected';
  vendor?: string;
  attachments?: string[];
}

export default function ApprovalsScreen() {
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'pending' | 'all'>('pending');

  const fetchApprovals = async () => {
    try {
      const api = getApiClient();
      // TODO: Replace with actual API call
      // const response = await api.request('GET', '/approvals');
      
      // Mock data
      setApprovals([
        {
          id: '1',
          title: 'HVAC Maintenance',
          description: 'Annual HVAC system inspection and filter replacement',
          amount: 450,
          category: 'Maintenance',
          requestedBy: 'Sarah Chen',
          requestedAt: '2024-12-29T10:30:00Z',
          status: 'pending',
          vendor: 'Cool Air Services',
        },
        {
          id: '2',
          title: 'Pool Cleaning Supplies',
          description: 'Monthly pool chemicals and testing kit',
          amount: 125,
          category: 'Supplies',
          requestedBy: 'Sarah Chen',
          requestedAt: '2024-12-28T14:00:00Z',
          status: 'pending',
          vendor: 'Pool Pro Supply',
        },
        {
          id: '3',
          title: 'Landscaping - Fall Cleanup',
          description: 'Leaf removal and garden bed preparation',
          amount: 350,
          category: 'Landscaping',
          requestedBy: 'Sarah Chen',
          requestedAt: '2024-12-27T09:00:00Z',
          status: 'approved',
          vendor: 'Green Thumb Landscaping',
        },
      ]);
    } catch (error) {
      console.error('Fetch approvals error:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchApprovals();
  }, []);

  const handleApprove = async (id: string) => {
    Alert.alert(
      'Approve Request',
      'Are you sure you want to approve this request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Approve',
          onPress: async () => {
            // TODO: API call
            setApprovals(prev =>
              prev.map(a => (a.id === id ? { ...a, status: 'approved' as const } : a))
            );
          },
        },
      ]
    );
  };

  const handleReject = async (id: string) => {
    Alert.alert(
      'Reject Request',
      'Are you sure you want to reject this request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reject',
          style: 'destructive',
          onPress: async () => {
            // TODO: API call
            setApprovals(prev =>
              prev.map(a => (a.id === id ? { ...a, status: 'rejected' as const } : a))
            );
          },
        },
      ]
    );
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const filteredApprovals = approvals.filter(a =>
    filter === 'all' ? true : a.status === 'pending'
  );

  const pendingCount = approvals.filter(a => a.status === 'pending').length;

  const renderApproval = ({ item }: { item: Approval }) => (
    <Card style={styles.approvalCard}>
      <View style={styles.approvalHeader}>
        <View style={styles.approvalInfo}>
          <Text style={styles.approvalTitle}>{item.title}</Text>
          <Text style={styles.approvalVendor}>{item.vendor}</Text>
        </View>
        <Text style={styles.approvalAmount}>{formatCurrency(item.amount)}</Text>
      </View>

      <Text style={styles.approvalDescription}>{item.description}</Text>

      <View style={styles.approvalMeta}>
        <View style={styles.metaItem}>
          <Ionicons name="person-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.metaText}>{item.requestedBy}</Text>
        </View>
        <View style={styles.metaItem}>
          <Ionicons name="time-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.metaText}>{formatDate(item.requestedAt)}</Text>
        </View>
      </View>

      {item.status === 'pending' ? (
        <View style={styles.approvalActions}>
          <Button
            title="Reject"
            variant="outline"
            onPress={() => handleReject(item.id)}
            style={styles.rejectButton}
          />
          <Button
            title="Approve"
            onPress={() => handleApprove(item.id)}
            style={styles.approveButton}
          />
        </View>
      ) : (
        <View style={styles.statusContainer}>
          <Badge
            label={item.status === 'approved' ? 'Approved' : 'Rejected'}
            variant={item.status === 'approved' ? 'success' : 'error'}
          />
        </View>
      )}
    </Card>
  );

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading approvals..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'pending' && styles.filterTabActive]}
          onPress={() => setFilter('pending')}
        >
          <Text style={[styles.filterText, filter === 'pending' && styles.filterTextActive]}>
            Pending
          </Text>
          {pendingCount > 0 && (
            <View style={styles.filterBadge}>
              <Text style={styles.filterBadgeText}>{pendingCount}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
            All
          </Text>
        </TouchableOpacity>
      </View>

      {/* Approvals List */}
      <FlatList
        data={filteredApprovals}
        renderItem={renderApproval}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchApprovals();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="checkmark-circle" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>All caught up!</Text>
            <Text style={styles.emptyText}>No pending approvals</Text>
          </View>
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  filterContainer: {
    flexDirection: 'row',
    padding: spacing[4],
    gap: spacing[2],
  },
  filterTab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
  },
  filterTabActive: {
    backgroundColor: colors.haven.navy[900],
  },
  filterText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  filterTextActive: {
    color: colors.white,
  },
  filterBadge: {
    marginLeft: spacing[2],
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  filterBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingTop: 0,
  },
  approvalCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  approvalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  approvalInfo: {
    flex: 1,
  },
  approvalTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  approvalVendor: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  approvalAmount: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  approvalDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
    lineHeight: 20,
  },
  approvalMeta: {
    flexDirection: 'row',
    gap: spacing[4],
    marginBottom: spacing[3],
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  metaText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  approvalActions: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  rejectButton: {
    flex: 1,
  },
  approveButton: {
    flex: 1,
  },
  statusContainer: {
    alignItems: 'flex-start',
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
    marginTop: spacing[1],
  },
});
```

---

## PHASE 4: Setup Push Notifications

### Task 4.1: Install Push Notification Dependencies

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

pnpm add expo-notifications expo-device expo-constants
```

### Task 4.2: Create Notifications Service

Create `apps/mobile/src/lib/notifications.ts`:

```typescript
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import { getApiClient } from './api';

// Configure notification behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export interface PushToken {
  token: string;
  platform: 'ios' | 'android';
}

/**
 * Register for push notifications and get token
 */
export async function registerForPushNotifications(): Promise<PushToken | null> {
  // Only works on physical devices
  if (!Device.isDevice) {
    console.log('Push notifications require a physical device');
    return null;
  }

  // Check existing permissions
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  // Request permissions if not granted
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') {
    console.log('Push notification permission not granted');
    return null;
  }

  // Get push token
  const projectId = Constants.expoConfig?.extra?.eas?.projectId;
  const token = await Notifications.getExpoPushTokenAsync({
    projectId,
  });

  // Configure for Android
  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#c4a574',
    });
  }

  return {
    token: token.data,
    platform: Platform.OS as 'ios' | 'android',
  };
}

/**
 * Save push token to backend
 */
export async function savePushToken(userId: string, pushToken: PushToken): Promise<void> {
  const api = getApiClient();
  await api.request('POST', '/users/push-token', {
    userId,
    token: pushToken.token,
    platform: pushToken.platform,
  });
}

/**
 * Add notification received listener
 */
export function addNotificationReceivedListener(
  callback: (notification: Notifications.Notification) => void
) {
  return Notifications.addNotificationReceivedListener(callback);
}

/**
 * Add notification response listener (when user taps notification)
 */
export function addNotificationResponseListener(
  callback: (response: Notifications.NotificationResponse) => void
) {
  return Notifications.addNotificationResponseReceivedListener(callback);
}

/**
 * Schedule a local notification
 */
export async function scheduleLocalNotification(
  title: string,
  body: string,
  data?: Record<string, unknown>,
  trigger?: Notifications.NotificationTriggerInput
): Promise<string> {
  return await Notifications.scheduleNotificationAsync({
    content: {
      title,
      body,
      data,
      sound: true,
    },
    trigger: trigger || null,
  });
}

/**
 * Cancel all scheduled notifications
 */
export async function cancelAllNotifications(): Promise<void> {
  await Notifications.cancelAllScheduledNotificationsAsync();
}

/**
 * Get badge count
 */
export async function getBadgeCount(): Promise<number> {
  return await Notifications.getBadgeCountAsync();
}

/**
 * Set badge count
 */
export async function setBadgeCount(count: number): Promise<void> {
  await Notifications.setBadgeCountAsync(count);
}
```

### Task 4.3: Create Notifications Context

Create `apps/mobile/src/contexts/notifications-context.tsx`:

```typescript
import React, { createContext, useContext, useEffect, useState, useRef } from 'react';
import { useRouter } from 'expo-router';
import * as Notifications from 'expo-notifications';
import { useAuth } from './auth-context';
import {
  registerForPushNotifications,
  savePushToken,
  addNotificationReceivedListener,
  addNotificationResponseListener,
  PushToken,
} from '../lib/notifications';

interface NotificationsContextType {
  pushToken: PushToken | null;
  isEnabled: boolean;
  requestPermissions: () => Promise<boolean>;
}

const NotificationsContext = createContext<NotificationsContextType | null>(null);

export function NotificationsProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { user } = useAuth();
  const [pushToken, setPushToken] = useState<PushToken | null>(null);
  const [isEnabled, setIsEnabled] = useState(false);
  const notificationListener = useRef<Notifications.Subscription>();
  const responseListener = useRef<Notifications.Subscription>();

  // Register for push notifications when user logs in
  useEffect(() => {
    if (user) {
      registerForPushNotifications().then(async (token) => {
        if (token) {
          setPushToken(token);
          setIsEnabled(true);
          await savePushToken(user.uid, token);
        }
      });
    }
  }, [user]);

  // Setup notification listeners
  useEffect(() => {
    // When notification received while app is open
    notificationListener.current = addNotificationReceivedListener((notification) => {
      console.log('Notification received:', notification);
    });

    // When user taps on notification
    responseListener.current = addNotificationResponseListener((response) => {
      const data = response.notification.request.content.data;
      
      // Navigate based on notification type
      if (data?.type === 'approval') {
        router.push('/(tabs)/approvals');
      } else if (data?.type === 'message') {
        router.push('/(tabs)/sarah');
      } else if (data?.type === 'bill') {
        router.push('/(tabs)/money');
      }
    });

    return () => {
      if (notificationListener.current) {
        Notifications.removeNotificationSubscription(notificationListener.current);
      }
      if (responseListener.current) {
        Notifications.removeNotificationSubscription(responseListener.current);
      }
    };
  }, [router]);

  const requestPermissions = async (): Promise<boolean> => {
    const token = await registerForPushNotifications();
    if (token) {
      setPushToken(token);
      setIsEnabled(true);
      if (user) {
        await savePushToken(user.uid, token);
      }
      return true;
    }
    return false;
  };

  return (
    <NotificationsContext.Provider
      value={{
        pushToken,
        isEnabled,
        requestPermissions,
      }}
    >
      {children}
    </NotificationsContext.Provider>
  );
}

export function useNotifications() {
  const context = useContext(NotificationsContext);
  if (!context) {
    throw new Error('useNotifications must be used within NotificationsProvider');
  }
  return context;
}
```

---

## PHASE 5: Update Tab Navigation

### Task 5.1: Update Tab Layout

Update `apps/mobile/app/(tabs)/_layout.tsx`:

```typescript
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography } from '../../src/lib/theme';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.haven.champagne[500],
        tabBarInactiveTintColor: colors.haven.navy[400],
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopColor: colors.border.light,
          height: 85,
          paddingBottom: 25,
          paddingTop: 10,
        },
        tabBarLabelStyle: {
          fontSize: typography.fontSizes.xs,
          fontWeight: typography.fontWeights.medium,
        },
        headerStyle: {
          backgroundColor: colors.white,
        },
        headerTintColor: colors.haven.navy[900],
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
        },
        headerShadowVisible: false,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home" size={size} color={color} />
          ),
          headerTitle: 'Dashboard',
        }}
      />
      <Tabs.Screen
        name="sarah"
        options={{
          title: 'Sarah',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="chatbubble" size={size} color={color} />
          ),
          headerTitle: 'Your Manager',
        }}
      />
      <Tabs.Screen
        name="approvals"
        options={{
          title: 'Approvals',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="checkmark-circle" size={size} color={color} />
          ),
          headerTitle: 'Approvals',
        }}
      />
      <Tabs.Screen
        name="money"
        options={{
          title: 'Money',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="wallet" size={size} color={color} />
          ),
          headerTitle: 'Financial',
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: 'More',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="menu" size={size} color={color} />
          ),
          headerTitle: 'More',
        }}
      />
    </Tabs>
  );
}
```

---

## PHASE 6: Update Root Layout with Notifications Provider

### Task 6.1: Update _layout.tsx

Update `apps/mobile/app/_layout.tsx`:

```typescript
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from '../src/contexts/auth-context';
import { OnboardingProvider } from '../src/contexts/onboarding-context';
import { PlaidProvider } from '../src/contexts/plaid-context';
import { NotificationsProvider } from '../src/contexts/notifications-context';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <AuthProvider>
          <NotificationsProvider>
            <PlaidProvider>
              <OnboardingProvider>
                <StatusBar style="dark" />
                <Stack screenOptions={{ headerShown: false }}>
                  <Stack.Screen name="index" />
                  <Stack.Screen name="(auth)" />
                  <Stack.Screen name="(tabs)" />
                </Stack>
              </OnboardingProvider>
            </PlaidProvider>
          </NotificationsProvider>
        </AuthProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

---

## PHASE 7: Verification

### Task 7.1: Test Checklist

- [ ] Dashboard displays with home health score, action items, quick actions
- [ ] Sarah chat screen shows message history
- [ ] Can send messages and see simulated response
- [ ] Camera/photo picker works in chat
- [ ] Approvals list shows pending items
- [ ] Can approve/reject items
- [ ] Push notification permissions requested
- [ ] Tab navigation works correctly
- [ ] No TypeScript errors (`pnpm typecheck`)

### Task 7.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

---

## Summary

After completing this prompt:
1. ✅ Dashboard with home health, actions, weather
2. ✅ Sarah manager chat with photo support
3. ✅ Approvals system (view, approve, reject)
4. ✅ Push notifications infrastructure
5. ✅ Updated tab navigation
6. ✅ NotificationsContext for state management

**Next Prompt:** M07 - Core Features Part 2 (Maintenance, Documents, Family)
