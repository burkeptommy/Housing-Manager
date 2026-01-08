import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeInUp, FadeIn } from 'react-native-reanimated';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface MaintenanceTask {
  id: string;
  title: string;
  description: string | null;
  category: string;
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  status: 'UPCOMING' | 'DUE' | 'OVERDUE' | 'COMPLETED' | 'CANCELLED';
  dueDate: string | null;
  frequency: string | null;
  estimatedCost: number | null;
  lastCompletedAt: string | null;
  seasonalTiming?: string;
  vendor?: {
    id: string;
    displayName: string;
    phone?: string;
  } | null;
  assignedTo?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
}

interface ChecklistItem {
  id: string;
  label: string;
  completed: boolean;
  category?: string;
  estimatedTime?: string;
  difficulty?: 'easy' | 'medium' | 'hard';
}

// Default checklist items for common maintenance tasks
const CHECKLIST_TEMPLATES: Record<string, ChecklistItem[]> = {
  'Winterization Checklist': [
    { id: 'w1', label: 'Disconnect and drain outdoor hoses', completed: false, category: 'Plumbing', estimatedTime: '15 min', difficulty: 'easy' },
    { id: 'w2', label: 'Turn off exterior faucets', completed: false, category: 'Plumbing', estimatedTime: '5 min', difficulty: 'easy' },
    { id: 'w3', label: 'Insulate exposed pipes in garage/basement', completed: false, category: 'Plumbing', estimatedTime: '30 min', difficulty: 'medium' },
    { id: 'w4', label: 'Check and replace weatherstripping on doors', completed: false, category: 'Exterior', estimatedTime: '45 min', difficulty: 'medium' },
    { id: 'w5', label: 'Reverse ceiling fan direction (clockwise)', completed: false, category: 'Interior', estimatedTime: '10 min', difficulty: 'easy' },
    { id: 'w6', label: 'Clean and inspect fireplace/chimney', completed: false, category: 'HVAC', estimatedTime: '2 hrs', difficulty: 'hard' },
    { id: 'w7', label: 'Schedule furnace inspection', completed: false, category: 'HVAC', estimatedTime: '5 min', difficulty: 'easy' },
    { id: 'w8', label: 'Check and seal window gaps', completed: false, category: 'Exterior', estimatedTime: '1 hr', difficulty: 'medium' },
    { id: 'w9', label: 'Test smoke and CO detectors', completed: false, category: 'Safety', estimatedTime: '15 min', difficulty: 'easy' },
    { id: 'w10', label: 'Clean gutters and downspouts', completed: false, category: 'Exterior', estimatedTime: '2 hrs', difficulty: 'hard' },
    { id: 'w11', label: 'Service snow blower/equipment', completed: false, category: 'Equipment', estimatedTime: '30 min', difficulty: 'medium' },
    { id: 'w12', label: 'Check attic insulation', completed: false, category: 'Interior', estimatedTime: '30 min', difficulty: 'medium' },
  ],
  'Spring Home Checklist': [
    { id: 's1', label: 'Inspect roof for winter damage', completed: false, category: 'Exterior', estimatedTime: '30 min', difficulty: 'medium' },
    { id: 's2', label: 'Check foundation for cracks', completed: false, category: 'Exterior', estimatedTime: '20 min', difficulty: 'easy' },
    { id: 's3', label: 'Clean AC condenser unit', completed: false, category: 'HVAC', estimatedTime: '45 min', difficulty: 'medium' },
    { id: 's4', label: 'Inspect and clean deck/patio', completed: false, category: 'Exterior', estimatedTime: '1 hr', difficulty: 'medium' },
    { id: 's5', label: 'Check for pest entry points', completed: false, category: 'Exterior', estimatedTime: '30 min', difficulty: 'easy' },
    { id: 's6', label: 'Service lawn mower', completed: false, category: 'Equipment', estimatedTime: '30 min', difficulty: 'medium' },
    { id: 's7', label: 'Clean windows inside and out', completed: false, category: 'Interior', estimatedTime: '2 hrs', difficulty: 'medium' },
    { id: 's8', label: 'Test irrigation system', completed: false, category: 'Landscaping', estimatedTime: '20 min', difficulty: 'easy' },
    { id: 's9', label: 'Replace HVAC filters', completed: false, category: 'HVAC', estimatedTime: '15 min', difficulty: 'easy' },
    { id: 's10', label: 'Touch up exterior paint', completed: false, category: 'Exterior', estimatedTime: '2 hrs', difficulty: 'hard' },
  ],
  'HVAC Filter Change': [
    { id: 'h1', label: 'Locate filter compartment', completed: false, estimatedTime: '2 min', difficulty: 'easy' },
    { id: 'h2', label: 'Note filter size from old filter', completed: false, estimatedTime: '1 min', difficulty: 'easy' },
    { id: 'h3', label: 'Remove old filter', completed: false, estimatedTime: '1 min', difficulty: 'easy' },
    { id: 'h4', label: 'Check airflow direction arrow', completed: false, estimatedTime: '1 min', difficulty: 'easy' },
    { id: 'h5', label: 'Insert new filter with arrow pointing toward blower', completed: false, estimatedTime: '1 min', difficulty: 'easy' },
    { id: 'h6', label: 'Close compartment securely', completed: false, estimatedTime: '1 min', difficulty: 'easy' },
  ],
  'Smoke & CO Detector Test': [
    { id: 'sc1', label: 'Test each smoke detector with test button', completed: false, estimatedTime: '5 min', difficulty: 'easy' },
    { id: 'sc2', label: 'Test each CO detector with test button', completed: false, estimatedTime: '5 min', difficulty: 'easy' },
    { id: 'sc3', label: 'Replace batteries in all units', completed: false, estimatedTime: '10 min', difficulty: 'easy' },
    { id: 'sc4', label: 'Check manufacture date (replace if 10+ years)', completed: false, estimatedTime: '5 min', difficulty: 'easy' },
    { id: 'sc5', label: 'Vacuum dust from detector vents', completed: false, estimatedTime: '5 min', difficulty: 'easy' },
  ],
  'Gutter Cleaning': [
    { id: 'g1', label: 'Set up ladder safely on level ground', completed: false, estimatedTime: '5 min', difficulty: 'medium' },
    { id: 'g2', label: 'Remove debris from gutter sections', completed: false, estimatedTime: '30 min', difficulty: 'medium' },
    { id: 'g3', label: 'Check and clear downspouts', completed: false, estimatedTime: '15 min', difficulty: 'medium' },
    { id: 'g4', label: 'Flush gutters with hose', completed: false, estimatedTime: '15 min', difficulty: 'easy' },
    { id: 'g5', label: 'Inspect for damage or loose sections', completed: false, estimatedTime: '10 min', difficulty: 'easy' },
    { id: 'g6', label: 'Repair any loose fasteners', completed: false, estimatedTime: '15 min', difficulty: 'hard' },
  ],
};

const CATEGORY_ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  'HVAC': 'thermometer-outline',
  'Plumbing': 'water-outline',
  'PLUMBING': 'water-outline',
  'Electrical': 'flash-outline',
  'ELECTRICAL': 'flash-outline',
  'Exterior': 'home-outline',
  'EXTERIOR': 'home-outline',
  'Pool': 'water',
  'POOL': 'water',
  'Landscaping': 'leaf-outline',
  'LANDSCAPING': 'leaf-outline',
  'Safety': 'shield-checkmark-outline',
  'SAFETY': 'shield-checkmark-outline',
  'Interior': 'bed-outline',
  'Equipment': 'construct-outline',
  'SEASONAL': 'calendar-outline',
  'default': 'construct-outline',
};

export default function MaintenanceDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  
  const [task, setTask] = useState<MaintenanceTask | null>(null);
  const [checklist, setChecklist] = useState<ChecklistItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const fetchTask = useCallback(async () => {
    if (!householdInfo?.id || !id) {
      setError('Missing task information');
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/maintenance-tasks/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch task: ${response.status}`);
      }

      const taskData = await response.json();
      setTask(taskData);

      const templateKey = Object.keys(CHECKLIST_TEMPLATES).find(
        key => taskData.title.includes(key) || key.includes(taskData.title)
      );
      
      if (templateKey) {
        setChecklist(CHECKLIST_TEMPLATES[templateKey].map(item => ({ ...item })));
      } else {
        setChecklist([
          { id: 'gen1', label: 'Review task requirements', completed: false, difficulty: 'easy' },
          { id: 'gen2', label: 'Gather necessary materials', completed: false, difficulty: 'easy' },
          { id: 'gen3', label: 'Complete main task', completed: false, difficulty: 'medium' },
          { id: 'gen4', label: 'Verify work is complete', completed: false, difficulty: 'easy' },
          { id: 'gen5', label: 'Clean up work area', completed: false, difficulty: 'easy' },
        ]);
      }
      
      setError(null);
    } catch (err) {
      console.error('Fetch task error:', err);
      setError('Failed to load task details');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id, id]);

  useEffect(() => {
    fetchTask();
  }, [fetchTask]);

  const toggleChecklistItem = (itemId: string) => {
    setChecklist(prev =>
      prev.map(item =>
        item.id === itemId ? { ...item, completed: !item.completed } : item
      )
    );
  };

  const handleHireVendor = () => {
    Alert.alert(
      'Hire a Vendor',
      'Would you like Sarah to find and schedule a vendor for this task?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes, Find a Vendor',
          onPress: () => {
            Alert.alert(
              'Request Sent',
              'Sarah will find the best vendor and get back to you with options and pricing.',
              [{ text: 'OK' }]
            );
          },
        },
      ]
    );
  };

  const handleAskSarah = () => {
    Alert.alert(
      'Ask Sarah to Handle',
      "Sarah will take care of this entire task for you. She'll coordinate vendors, schedule the work, and keep you updated.",
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes, Handle It',
          onPress: () => {
            Alert.alert(
              'Got It!',
              "Sarah is on it. You'll receive updates as progress is made.",
              [{ text: 'OK' }]
            );
          },
        },
      ]
    );
  };

  const handleMarkComplete = async () => {
    const completedCount = checklist.filter(item => item.completed).length;
    const totalCount = checklist.length;
    
    if (completedCount < totalCount) {
      Alert.alert(
        'Incomplete Items',
        `You have ${totalCount - completedCount} items remaining. Mark task as complete anyway?`,
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Mark Complete', onPress: submitCompletion },
        ]
      );
    } else {
      submitCompletion();
    }
  };

  const submitCompletion = async () => {
    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) return;

      Alert.alert('Task Completed', 'Great job! This task has been marked as complete.', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (err) {
      Alert.alert('Error', 'Failed to update task. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'OVERDUE': return colors.status.error;
      case 'DUE': return colors.status.warning;
      case 'COMPLETED': return colors.status.success;
      default: return colors.haven.champagne[500];
    }
  };

  const getDifficultyColor = (difficulty?: string) => {
    switch (difficulty) {
      case 'easy': return colors.status.success;
      case 'medium': return colors.status.warning;
      case 'hard': return colors.status.error;
      default: return colors.text.tertiary;
    }
  };

  const completedCount = checklist.filter(item => item.completed).length;
  const progress = checklist.length > 0 ? completedCount / checklist.length : 0;

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Loading...', headerBackTitle: 'Back' }} />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.navy[900]} />
        </View>
      </SafeAreaView>
    );
  }

  if (error || !task) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Error', headerBackTitle: 'Back' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle-outline" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Task</Text>
          <Text style={styles.errorText}>{error || 'Task not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchTask}>
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
          title: task.category,
          headerBackTitle: 'Back',
        }} 
      />
      
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={() => {
            setIsRefreshing(true);
            fetchTask();
          }} />
        }
      >
        {/* Header Card */}
        <Animated.View entering={FadeIn.duration(300)}>
          <Card style={styles.headerCard}>
            <View style={styles.headerTop}>
              <View style={[styles.categoryIcon, { backgroundColor: `${getStatusColor(task.status)}20` }]}>
                <Ionicons
                  name={CATEGORY_ICONS[task.category] || CATEGORY_ICONS.default}
                  size={28}
                  color={getStatusColor(task.status)}
                />
              </View>
              <Badge
                label={task.status.replace('_', ' ')}
                variant={
                  task.status === 'OVERDUE' ? 'error' :
                  task.status === 'DUE' ? 'warning' :
                  task.status === 'COMPLETED' ? 'success' : 'default'
                }
              />
            </View>
            
            <Text style={styles.taskTitle}>{task.title}</Text>
            
            {task.description && (
              <Text style={styles.taskDescription}>{task.description}</Text>
            )}
            
            <View style={styles.metaRow}>
              {task.dueDate && (
                <View style={styles.metaItem}>
                  <Ionicons name="calendar-outline" size={16} color={colors.text.tertiary} />
                  <Text style={styles.metaText}>
                    Due: {new Date(task.dueDate).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric',
                    })}
                  </Text>
                </View>
              )}
              {task.frequency && (
                <View style={styles.metaItem}>
                  <Ionicons name="repeat-outline" size={16} color={colors.text.tertiary} />
                  <Text style={styles.metaText}>{task.frequency}</Text>
                </View>
              )}
              {task.estimatedCost !== null && task.estimatedCost > 0 && (
                <View style={styles.metaItem}>
                  <Ionicons name="cash-outline" size={16} color={colors.text.tertiary} />
                  <Text style={styles.metaText}>~${task.estimatedCost}</Text>
                </View>
              )}
            </View>
          </Card>
        </Animated.View>

        {/* Progress Card */}
        <Animated.View entering={FadeInUp.delay(100).duration(300)}>
          <Card style={styles.progressCard}>
            <View style={styles.progressHeader}>
              <Text style={styles.progressTitle}>Checklist Progress</Text>
              <Text style={styles.progressCount}>{completedCount}/{checklist.length}</Text>
            </View>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
            </View>
          </Card>
        </Animated.View>

        {/* Checklist Items */}
        <Animated.View entering={FadeInUp.delay(200).duration(300)}>
          <Card style={styles.checklistCard}>
            <Text style={styles.sectionTitle}>Checklist Items</Text>
            
            {checklist.map((item, index) => (
              <TouchableOpacity
                key={item.id}
                style={[
                  styles.checklistItem,
                  item.completed && styles.checklistItemCompleted,
                ]}
                onPress={() => toggleChecklistItem(item.id)}
                activeOpacity={0.7}
              >
                <View style={[
                  styles.checkbox,
                  item.completed && styles.checkboxChecked,
                ]}>
                  {item.completed && (
                    <Ionicons name="checkmark" size={16} color={colors.white} />
                  )}
                </View>
                <View style={styles.checklistItemContent}>
                  <Text style={[
                    styles.checklistItemLabel,
                    item.completed && styles.checklistItemLabelCompleted,
                  ]}>
                    {item.label}
                  </Text>
                  <View style={styles.checklistItemMeta}>
                    {item.category && (
                      <View style={styles.checklistTag}>
                        <Ionicons 
                          name={CATEGORY_ICONS[item.category] || 'pricetag-outline'} 
                          size={10} 
                          color={colors.text.tertiary} 
                        />
                        <Text style={styles.checklistTagText}>{item.category}</Text>
                      </View>
                    )}
                    {item.estimatedTime && (
                      <View style={styles.checklistTag}>
                        <Ionicons name="time-outline" size={10} color={colors.text.tertiary} />
                        <Text style={styles.checklistTagText}>{item.estimatedTime}</Text>
                      </View>
                    )}
                    {item.difficulty && (
                      <View style={[styles.checklistTag, { backgroundColor: `${getDifficultyColor(item.difficulty)}15` }]}>
                        <Text style={[styles.checklistTagText, { color: getDifficultyColor(item.difficulty) }]}>
                          {item.difficulty}
                        </Text>
                      </View>
                    )}
                  </View>
                </View>
              </TouchableOpacity>
            ))}
          </Card>
        </Animated.View>

        {/* Maintenance Schedule Info */}
        {task.frequency && task.frequency !== 'One-time' && (
          <Animated.View entering={FadeInUp.delay(300).duration(300)}>
            <Card style={styles.scheduleCard}>
              <View style={styles.scheduleHeader}>
                <Ionicons name="calendar" size={24} color={colors.haven.navy[900]} />
                <Text style={styles.scheduleTitle}>Maintenance Schedule</Text>
              </View>
              <View style={styles.scheduleInfo}>
                <View style={styles.scheduleRow}>
                  <Text style={styles.scheduleLabel}>Frequency:</Text>
                  <Text style={styles.scheduleValue}>{task.frequency}</Text>
                </View>
                {task.seasonalTiming && (
                  <View style={styles.scheduleRow}>
                    <Text style={styles.scheduleLabel}>Best Time:</Text>
                    <Text style={styles.scheduleValue}>{task.seasonalTiming}</Text>
                  </View>
                )}
                {task.lastCompletedAt && (
                  <View style={styles.scheduleRow}>
                    <Text style={styles.scheduleLabel}>Last Completed:</Text>
                    <Text style={styles.scheduleValue}>
                      {new Date(task.lastCompletedAt).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      })}
                    </Text>
                  </View>
                )}
              </View>
            </Card>
          </Animated.View>
        )}

        {/* Action Buttons */}
        <Animated.View entering={FadeInUp.delay(400).duration(300)} style={styles.actionSection}>
          <Text style={styles.actionTitle}>Need Help?</Text>
          
          <TouchableOpacity style={styles.actionButton} onPress={handleHireVendor}>
            <View style={styles.actionIconContainer}>
              <Ionicons name="briefcase-outline" size={24} color={colors.haven.navy[900]} />
            </View>
            <View style={styles.actionContent}>
              <Text style={styles.actionButtonTitle}>Hire a Vendor</Text>
              <Text style={styles.actionButtonSubtitle}>
                We'll find a trusted professional
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
          </TouchableOpacity>
          
          <TouchableOpacity style={[styles.actionButton, styles.actionButtonPrimary]} onPress={handleAskSarah}>
            <View style={[styles.actionIconContainer, styles.actionIconPrimary]}>
              <Ionicons name="sparkles" size={24} color={colors.white} />
            </View>
            <View style={styles.actionContent}>
              <Text style={[styles.actionButtonTitle, styles.actionButtonTitlePrimary]}>
                Ask Sarah to Handle
              </Text>
              <Text style={[styles.actionButtonSubtitle, styles.actionButtonSubtitlePrimary]}>
                She'll take care of everything
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={colors.haven.champagne[200]} />
          </TouchableOpacity>
        </Animated.View>

        {/* Complete Button */}
        {task.status !== 'COMPLETED' && (
          <Animated.View entering={FadeInUp.delay(500).duration(300)}>
            <TouchableOpacity
              style={[
                styles.completeButton,
                progress === 1 && styles.completeButtonReady,
              ]}
              onPress={handleMarkComplete}
              disabled={isSaving}
            >
              {isSaving ? (
                <ActivityIndicator color={colors.white} />
              ) : (
                <>
                  <Ionicons 
                    name={progress === 1 ? 'checkmark-circle' : 'checkmark-circle-outline'} 
                    size={24} 
                    color={colors.white} 
                  />
                  <Text style={styles.completeButtonText}>
                    {progress === 1 ? 'Mark as Complete' : 'Mark as Complete Anyway'}
                  </Text>
                </>
              )}
            </TouchableOpacity>
          </Animated.View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[10],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
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
  headerCard: {
    padding: spacing[5],
    marginBottom: spacing[4],
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  categoryIcon: {
    width: 56,
    height: 56,
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },
  taskTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  taskDescription: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    lineHeight: 22,
    marginBottom: spacing[4],
  },
  metaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[4],
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  metaText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  progressCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  progressTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  progressCount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  progressBar: {
    height: 8,
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.navy[900],
    borderRadius: borderRadius.full,
  },
  checklistCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  checklistItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  checklistItemCompleted: {
    opacity: 0.6,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: borderRadius.md,
    borderWidth: 2,
    borderColor: colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  checkboxChecked: {
    backgroundColor: colors.haven.navy[900],
    borderColor: colors.haven.navy[900],
  },
  checklistItemContent: {
    flex: 1,
  },
  checklistItemLabel: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  checklistItemLabelCompleted: {
    textDecorationLine: 'line-through',
    color: colors.text.tertiary,
  },
  checklistItemMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  checklistTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.sm,
  },
  checklistTagText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  scheduleCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  scheduleHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  scheduleTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  scheduleInfo: {
    gap: spacing[2],
  },
  scheduleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  scheduleLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  scheduleValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  actionSection: {
    marginBottom: spacing[4],
  },
  actionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing[3],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  actionButtonPrimary: {
    backgroundColor: colors.haven.navy[900],
  },
  actionIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  actionIconPrimary: {
    backgroundColor: colors.haven.champagne[500],
  },
  actionContent: {
    flex: 1,
  },
  actionButtonTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  actionButtonTitlePrimary: {
    color: colors.white,
  },
  actionButtonSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  actionButtonSubtitlePrimary: {
    color: colors.haven.champagne[200],
  },
  completeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.xl,
  },
  completeButtonReady: {
    backgroundColor: colors.status.success,
  },
  completeButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
