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
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, ScreenContainer } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface ChecklistStep {
  id: string;
  order: number;
  title: string;
  description?: string;
  completed: boolean;
  completedAt?: string;
  alfredCanHandle: boolean;
  alfredPrompt?: string;
  estimatedMinutes?: number;
  difficulty?: 'easy' | 'medium' | 'hard';
}

interface HomeSystem {
  id: string;
  name: string;
  type: string;
  brand?: string;
  model?: string;
  location?: string;
  installedDate?: string;
  warrantyExpires?: string;
}

interface MaintenanceTask {
  id: string;
  title: string;
  description: string | null;
  category: string;
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  status: 'PENDING' | 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED' | 'SKIPPED' | 'CANCELLED';
  dueDate: string | null;
  nextDueDate: string | null;
  frequency: string | null;
  estimatedCost: number | null;
  lastCompletedDate: string | null;
  seasonalTiming?: string;
  intervalExplanation?: string;
  checklistSteps?: ChecklistStep[];
  homeSystem?: HomeSystem | null;
  assignedVendor?: {
    id: string;
    displayName: string;
    phone?: string;
    email?: string;
  } | null;
  completedBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
}

const CATEGORY_ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  'HVAC': 'thermometer-outline',
  'PLUMBING': 'water-outline',
  'ELECTRICAL': 'flash-outline',
  'EXTERIOR': 'home-outline',
  'POOL': 'water',
  'LANDSCAPING': 'leaf-outline',
  'LAWN': 'leaf-outline',
  'SAFETY': 'shield-checkmark-outline',
  'APPLIANCE': 'cube-outline',
  'SEASONAL': 'calendar-outline',
  'GENERAL': 'construct-outline',
  'default': 'construct-outline',
};

export default function MaintenanceDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();

  const [task, setTask] = useState<MaintenanceTask | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savingStepId, setSavingStepId] = useState<string | null>(null);

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

      // Use the new endpoint that returns full task details with checklist
      const response = await fetch(
        `${API_BASE_URL}/maintenance/${id}`,
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

  const toggleChecklistStep = async (stepId: string, currentCompleted: boolean) => {
    if (!task || savingStepId) return;

    setSavingStepId(stepId);

    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(
        `${API_BASE_URL}/maintenance/${task.id}/step/${stepId}/complete`,
        {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ completed: !currentCompleted }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to update step');
      }

      const updatedTask = await response.json();
      setTask(updatedTask);

      // Check if all steps are now complete
      const steps = updatedTask.checklistSteps as ChecklistStep[] | undefined;
      if (steps && steps.every(s => s.completed)) {
        Alert.alert(
          'Task Complete!',
          'All checklist items have been completed. Great job!',
          [{ text: 'OK' }]
        );
      }
    } catch (err) {
      console.error('Toggle step error:', err);
      Alert.alert('Error', 'Failed to update checklist. Please try again.');
    } finally {
      setSavingStepId(null);
    }
  };

  const handleHaveAlfredDoIt = (step: ChecklistStep) => {
    const prompt = step.alfredPrompt || `Help me with: ${step.title}`;

    Alert.alert(
      'Have Alfred Handle This',
      `Alfred will take care of "${step.title}" for you. He'll coordinate any necessary scheduling or ordering.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes, Have Alfred Do It',
          onPress: () => {
            // Navigate to Alfred chat with prefilled prompt
            router.push({
              pathname: '/(tabs)/manager/chat',
              params: {
                prefillMessage: prompt,
                context: `Maintenance Task: ${task?.title}`,
              },
            });
          },
        },
      ]
    );
  };

  const handleAskAlfred = () => {
    Alert.alert(
      'Have Alfred Handle This Task',
      "Alfred will take care of this entire maintenance task for you. He'll coordinate vendors, schedule the work, and keep you updated.",
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes, Handle It',
          onPress: () => {
            const prompt = `Please help me complete this maintenance task: "${task?.title}". ${task?.description || ''}`;
            router.push({
              pathname: '/(tabs)/manager/chat',
              params: {
                prefillMessage: prompt,
                context: `Maintenance: ${task?.title}`,
              },
            });
          },
        },
      ]
    );
  };

  const handleHireVendor = () => {
    Alert.alert(
      'Hire a Vendor',
      'Would you like Alfred to find and schedule a vendor for this task?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Yes, Find a Vendor',
          onPress: () => {
            const prompt = `I need to hire a vendor for: "${task?.title}". Please find trusted professionals and get quotes.`;
            router.push({
              pathname: '/(tabs)/manager/chat',
              params: {
                prefillMessage: prompt,
                context: `Vendor Request: ${task?.title}`,
              },
            });
          },
        },
      ]
    );
  };

  const handleMarkComplete = async () => {
    const steps = task?.checklistSteps || [];
    const completedCount = steps.filter(s => s.completed).length;
    const totalCount = steps.length;

    if (completedCount < totalCount && totalCount > 0) {
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
    try {
      const token = await getIdToken(true);
      if (!token || !task) return;

      const response = await fetch(
        `${API_BASE_URL}/maintenance/${task.id}/complete`,
        {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({}),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to complete task');
      }

      Alert.alert('Task Completed', 'Great job! This task has been marked as complete.', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (err) {
      Alert.alert('Error', 'Failed to update task. Please try again.');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PENDING': return colors.haven.champagne[500];
      case 'SCHEDULED': return colors.status.info;
      case 'IN_PROGRESS': return colors.status.warning;
      case 'COMPLETED': return colors.status.success;
      case 'SKIPPED': return colors.text.tertiary;
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

  const formatDate = (dateString: string | null | undefined) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const checklist = task?.checklistSteps || [];
  const completedCount = checklist.filter(s => s.completed).length;
  const progress = checklist.length > 0 ? completedCount / checklist.length : 0;
  const isOverdue = task?.nextDueDate && new Date(task.nextDueDate) < new Date() && task.status !== 'COMPLETED';

  if (isLoading) {
    return (
      <ScreenContainer title="Loading...">
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.navy[900]} />
        </View>
      </ScreenContainer>
    );
  }

  if (error || !task) {
    return (
      <ScreenContainer title="Error">
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle-outline" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Task</Text>
          <Text style={styles.errorText}>{error || 'Task not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchTask}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer
      title={task.category}
      refreshing={isRefreshing}
      onRefresh={() => {
        setIsRefreshing(true);
        fetchTask();
      }}
    >
        {/* Header Card */}
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
              label={isOverdue ? 'OVERDUE' : task.status.replace('_', ' ')}
              variant={
                isOverdue ? 'error' :
                task.status === 'COMPLETED' ? 'success' :
                task.status === 'SCHEDULED' ? 'info' : 'default'
              }
            />
          </View>

          <Text style={styles.taskTitle}>{task.title}</Text>

          {task.description && (
            <Text style={styles.taskDescription}>{task.description}</Text>
          )}

          <View style={styles.metaRow}>
            {task.nextDueDate && (
              <View style={styles.metaItem}>
                <Ionicons name="calendar-outline" size={16} color={isOverdue ? colors.status.error : colors.text.tertiary} />
                <Text style={[styles.metaText, isOverdue && styles.metaTextOverdue]}>
                  Due: {formatDate(task.nextDueDate)}
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

        {/* System Info Card */}
        {task.homeSystem && (
          <Card style={styles.systemCard}>
            <View style={styles.systemHeader}>
              <Ionicons name="cube-outline" size={20} color={colors.haven.navy[900]} />
              <Text style={styles.systemTitle}>Related System</Text>
            </View>
            <View style={styles.systemInfo}>
              <Text style={styles.systemName}>{task.homeSystem.name}</Text>
              <View style={styles.systemDetails}>
                {task.homeSystem.brand && (
                  <Text style={styles.systemDetail}>{task.homeSystem.brand} {task.homeSystem.model}</Text>
                )}
                {task.homeSystem.location && (
                  <Text style={styles.systemDetail}>Location: {task.homeSystem.location}</Text>
                )}
                {task.homeSystem.warrantyExpires && (
                  <Text style={styles.systemDetail}>
                    Warranty: {new Date(task.homeSystem.warrantyExpires) > new Date() ? 'Active' : 'Expired'} (until {formatDate(task.homeSystem.warrantyExpires)})
                  </Text>
                )}
              </View>
            </View>
          </Card>
        )}

        {/* Why This Matters Card */}
        {task.intervalExplanation && (
          <Card style={styles.whyCard}>
            <View style={styles.whyHeader}>
              <Ionicons name="bulb-outline" size={20} color={colors.haven.champagne[600]} />
              <Text style={styles.whyTitle}>Why This Matters</Text>
            </View>
            <Text style={styles.whyText}>{task.intervalExplanation}</Text>
          </Card>
        )}

        {/* Progress Card */}
        {checklist.length > 0 && (
          <Card style={styles.progressCard}>
            <View style={styles.progressHeader}>
              <Text style={styles.progressTitle}>Checklist Progress</Text>
              <Text style={styles.progressCount}>{completedCount}/{checklist.length}</Text>
            </View>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
            </View>
          </Card>
        )}

        {/* Checklist Items */}
        {checklist.length > 0 && (
          <Card style={styles.checklistCard}>
            <Text style={styles.sectionTitle}>Checklist</Text>

            {checklist.sort((a, b) => a.order - b.order).map((step) => (
              <View key={step.id} style={styles.checklistItemContainer}>
                <TouchableOpacity
                  style={[
                    styles.checklistItem,
                    step.completed && styles.checklistItemCompleted,
                  ]}
                  onPress={() => toggleChecklistStep(step.id, step.completed)}
                  activeOpacity={0.7}
                  disabled={savingStepId === step.id}
                >
                  <View style={[
                    styles.checkbox,
                    step.completed && styles.checkboxChecked,
                  ]}>
                    {savingStepId === step.id ? (
                      <ActivityIndicator size="small" color={step.completed ? colors.white : colors.haven.navy[900]} />
                    ) : step.completed ? (
                      <Ionicons name="checkmark" size={16} color={colors.white} />
                    ) : null}
                  </View>
                  <View style={styles.checklistItemContent}>
                    <Text style={[
                      styles.checklistItemLabel,
                      step.completed && styles.checklistItemLabelCompleted,
                    ]}>
                      {step.title}
                    </Text>
                    {step.description && (
                      <Text style={styles.checklistItemDescription}>{step.description}</Text>
                    )}
                    <View style={styles.checklistItemMeta}>
                      {step.estimatedMinutes && (
                        <View style={styles.checklistTag}>
                          <Ionicons name="time-outline" size={10} color={colors.text.tertiary} />
                          <Text style={styles.checklistTagText}>{step.estimatedMinutes} min</Text>
                        </View>
                      )}
                      {step.difficulty && (
                        <View style={[styles.checklistTag, { backgroundColor: `${getDifficultyColor(step.difficulty)}15` }]}>
                          <Text style={[styles.checklistTagText, { color: getDifficultyColor(step.difficulty) }]}>
                            {step.difficulty}
                          </Text>
                        </View>
                      )}
                    </View>
                  </View>
                </TouchableOpacity>

                {/* Alfred Can Handle Button */}
                {step.alfredCanHandle && !step.completed && (
                  <TouchableOpacity
                    style={styles.alfredButton}
                    onPress={() => handleHaveAlfredDoIt(step)}
                  >
                    <Ionicons name="sparkles" size={14} color={colors.haven.champagne[600]} />
                    <Text style={styles.alfredButtonText}>Have Alfred Do It</Text>
                  </TouchableOpacity>
                )}
              </View>
            ))}
          </Card>
        )}

        {/* Maintenance Schedule Info */}
        {task.frequency && (
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
              {task.lastCompletedDate && (
                <View style={styles.scheduleRow}>
                  <Text style={styles.scheduleLabel}>Last Completed:</Text>
                  <Text style={styles.scheduleValue}>{formatDate(task.lastCompletedDate)}</Text>
                </View>
              )}
            </View>
          </Card>
        )}

        {/* Assigned Vendor */}
        {task.assignedVendor && (
          <Card style={styles.vendorCard}>
            <View style={styles.vendorHeader}>
              <Ionicons name="business-outline" size={20} color={colors.haven.navy[900]} />
              <Text style={styles.vendorTitle}>Assigned Vendor</Text>
            </View>
            <Text style={styles.vendorName}>{task.assignedVendor.displayName}</Text>
            {task.assignedVendor.phone && (
              <TouchableOpacity style={styles.vendorContact}>
                <Ionicons name="call-outline" size={16} color={colors.haven.champagne[500]} />
                <Text style={styles.vendorPhone}>{task.assignedVendor.phone}</Text>
              </TouchableOpacity>
            )}
          </Card>
        )}

        {/* Action Buttons */}
        <View style={styles.actionSection}>
          <Text style={styles.actionTitle}>Need Help?</Text>

          <TouchableOpacity style={styles.actionButton} onPress={handleHireVendor}>
            <View style={styles.actionIconContainer}>
              <Ionicons name="briefcase-outline" size={24} color={colors.haven.navy[900]} />
            </View>
            <View style={styles.actionContent}>
              <Text style={styles.actionButtonTitle}>Hire a Vendor</Text>
              <Text style={styles.actionButtonSubtitle}>
                Alfred will find a trusted professional
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
          </TouchableOpacity>

          <TouchableOpacity style={[styles.actionButton, styles.actionButtonPrimary]} onPress={handleAskAlfred}>
            <View style={[styles.actionIconContainer, styles.actionIconPrimary]}>
              <Ionicons name="sparkles" size={24} color={colors.white} />
            </View>
            <View style={styles.actionContent}>
              <Text style={[styles.actionButtonTitle, styles.actionButtonTitlePrimary]}>
                Have Alfred Handle It
              </Text>
              <Text style={[styles.actionButtonSubtitle, styles.actionButtonSubtitlePrimary]}>
                He'll take care of everything
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={colors.haven.champagne[200]} />
          </TouchableOpacity>
        </View>

        {/* Complete Button */}
        {task.status !== 'COMPLETED' && (
          <TouchableOpacity
            style={[
              styles.completeButton,
              progress === 1 && styles.completeButtonReady,
            ]}
            onPress={handleMarkComplete}
          >
            <Ionicons
              name={progress === 1 ? 'checkmark-circle' : 'checkmark-circle-outline'}
              size={24}
              color={colors.white}
            />
            <Text style={styles.completeButtonText}>
              {progress === 1 ? 'Mark as Complete' : 'Mark as Complete Anyway'}
            </Text>
          </TouchableOpacity>
        )}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.navy[900],
  },
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollView: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[10],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background.secondary,
  },
  errorContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
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
  metaTextOverdue: {
    color: colors.status.error,
    fontWeight: typography.fontWeights.medium,
  },
  systemCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  systemHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  systemTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  systemInfo: {
    gap: spacing[1],
  },
  systemName: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  systemDetails: {
    marginTop: spacing[1],
    gap: spacing[1],
  },
  systemDetail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  whyCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
    backgroundColor: colors.haven.champagne[50],
    borderLeftWidth: 4,
    borderLeftColor: colors.haven.champagne[500],
  },
  whyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  whyTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[600],
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  whyText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    lineHeight: 22,
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
  checklistItemContainer: {
    marginBottom: spacing[2],
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
  checklistItemDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[2],
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
  alfredButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    alignSelf: 'flex-start',
    marginLeft: 36,
    marginTop: spacing[1],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
  },
  alfredButtonText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[600],
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
  vendorCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  vendorHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  vendorTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  vendorName: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vendorContact: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[2],
  },
  vendorPhone: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
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
