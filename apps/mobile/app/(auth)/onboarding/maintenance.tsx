import { useState, useCallback, useMemo, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useOnboarding, type TaskSelection } from '../../../src/contexts/onboarding-context';
import { getApiClient } from '../../../src/lib/api';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import type { MaintenanceTask, MaintenanceCategory, HouseholdVendor } from '@haven/core';
import { MAINTENANCE_CATEGORY_INFO, MAINTENANCE_FREQUENCY_LABELS } from '@haven/core';

export default function OnboardingMaintenanceScreen() {
  const router = useRouter();
  const {
    householdId,
    vendors,
    maintenanceTasks,
    setMaintenanceTasks,
    setTaskSelections,
  } = useOnboarding();
  const api = getApiClient();

  const [isLoadingTasks, setIsLoadingTasks] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selections, setSelections] = useState<Map<string, TaskSelection>>(new Map());

  // Load tasks when screen mounts
  useEffect(() => {
    if (householdId && maintenanceTasks.length === 0) {
      setIsLoadingTasks(true);
      api
        .generateMaintenanceTasksFromTemplates({ householdId })
        .then((result) => {
          setMaintenanceTasks(result.tasks);
          // Initialize selections
          const initialSelections = new Map<string, TaskSelection>();
          result.tasks.forEach((task: MaintenanceTask) => {
            initialSelections.set(task.id, {
              taskId: task.id,
              keep: true,
              vendorId: task.assignedVendorId || undefined,
              dueDate: task.dueDate
                ? new Date(task.dueDate).toISOString().split('T')[0]
                : undefined,
            });
          });
          setSelections(initialSelections);
        })
        .catch((err) => {
          console.error('Failed to generate maintenance tasks:', err);
          Alert.alert('Error', 'Failed to load maintenance tasks');
        })
        .finally(() => {
          setIsLoadingTasks(false);
        });
    } else if (maintenanceTasks.length > 0 && selections.size === 0) {
      // Initialize selections from existing tasks
      const initialSelections = new Map<string, TaskSelection>();
      maintenanceTasks.forEach((task) => {
        initialSelections.set(task.id, {
          taskId: task.id,
          keep: true,
          vendorId: task.assignedVendorId || undefined,
          dueDate: task.dueDate
            ? new Date(task.dueDate).toISOString().split('T')[0]
            : undefined,
        });
      });
      setSelections(initialSelections);
    }
  }, [householdId, maintenanceTasks, api, setMaintenanceTasks, selections.size]);

  // Group tasks by category
  const groupedTasks = useMemo(() => {
    const groups = new Map<MaintenanceCategory, MaintenanceTask[]>();
    maintenanceTasks.forEach((task) => {
      const existing = groups.get(task.category) || [];
      existing.push(task);
      groups.set(task.category, existing);
    });
    return groups;
  }, [maintenanceTasks]);

  // Get vendors that match a task's category
  const getMatchingVendors = useCallback(
    (task: MaintenanceTask): HouseholdVendor[] => {
      const vendorCategoryMap: Record<string, MaintenanceCategory[]> = {
        HVAC_SERVICE: ['HVAC'],
        FILTER_SERVICE: ['HVAC'],
        PLUMBING: ['PLUMBING'],
        GUTTER_CLEANING: ['ROOF_GUTTER'],
        CHIMNEY_SWEEP: ['CHIMNEY'],
        SEPTIC_SERVICE: ['SEPTIC'],
        LANDSCAPING: ['LANDSCAPING'],
        LAWN_CARE: ['LANDSCAPING'],
        PEST_CONTROL: ['PEST'],
        POOL_SERVICE: ['POOL'],
        CLEANING: ['CLEANING'],
        WINDOW_WASHING: ['CLEANING'],
        HANDYMAN: ['GENERAL', 'EXTERIOR', 'INTERIOR'],
      };
      return vendors.filter((vendor) => {
        const matchingCategories = vendorCategoryMap[vendor.category] || [];
        return matchingCategories.includes(task.category);
      });
    },
    [vendors]
  );

  const toggleTask = useCallback((taskId: string) => {
    setSelections((prev) => {
      const next = new Map(prev);
      const existing = next.get(taskId);
      if (existing) {
        next.set(taskId, { ...existing, keep: !existing.keep });
      }
      return next;
    });
  }, []);

  const selectedCount = useMemo(() => {
    return Array.from(selections.values()).filter((s) => s.keep).length;
  }, [selections]);

  const handleContinue = async () => {
    if (!householdId) {
      Alert.alert('Error', 'Please complete the previous steps first');
      router.back();
      return;
    }

    setIsSubmitting(true);
    try {
      const selectionsArray = Array.from(selections.values());

      // Update tasks based on selections
      for (const selection of selectionsArray) {
        if (!selection.keep) {
          await api.updateMaintenanceTask(selection.taskId, { status: 'SKIPPED' });
        } else if (selection.vendorId || selection.dueDate) {
          await api.updateMaintenanceTask(selection.taskId, {
            assignedVendorId: selection.vendorId || null,
            dueDate: selection.dueDate || null,
          });
        }
      }

      setTaskSelections(selectionsArray);
      router.push('/(auth)/onboarding/payment');
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to save maintenance preferences');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoadingTasks) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary[600]} />
          <Text style={styles.loadingTitle}>Setting up your maintenance plan</Text>
          <Text style={styles.loadingSubtitle}>
            Generating personalized tasks based on your property features...
          </Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress indicator */}
        <View style={styles.progressContainer}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '60%' }]} />
          </View>
          <Text style={styles.progressText}>Step 3 of 5</Text>
        </View>

        <View style={styles.header}>
          <Text style={styles.title}>Your maintenance plan</Text>
          <Text style={styles.subtitle}>
            Based on your home features, we've created a personalized maintenance schedule. Review
            and adjust as needed.
          </Text>
        </View>

        {maintenanceTasks.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📋</Text>
            <Text style={styles.emptyTitle}>No maintenance tasks generated</Text>
            <Text style={styles.emptySubtitle}>
              This might happen if no templates match your property features.
            </Text>
          </View>
        ) : (
          <>
            {Array.from(groupedTasks.entries()).map(([category, categoryTasks]) => {
              const categoryInfo = MAINTENANCE_CATEGORY_INFO[category];
              return (
                <View key={category} style={styles.categorySection}>
                  <View style={styles.categoryHeader}>
                    <Text style={styles.categoryIcon}>{categoryInfo?.icon || '📋'}</Text>
                    <Text style={styles.categoryLabel}>
                      {categoryInfo?.label || category}
                    </Text>
                    <Text style={styles.categoryCount}>({categoryTasks.length})</Text>
                  </View>

                  {categoryTasks.map((task) => {
                    const selection = selections.get(task.id);
                    const isSelected = selection?.keep ?? true;
                    const matchingVendors = getMatchingVendors(task);
                    const frequencyLabel = task.template?.recommendedFrequencyMonths
                      ? MAINTENANCE_FREQUENCY_LABELS[task.template.recommendedFrequencyMonths] ||
                        `Every ${task.template.recommendedFrequencyMonths} months`
                      : null;

                    return (
                      <TouchableOpacity
                        key={task.id}
                        style={[styles.taskCard, !isSelected && styles.taskCardDisabled]}
                        onPress={() => toggleTask(task.id)}
                        activeOpacity={0.7}
                      >
                        <View style={styles.taskHeader}>
                          <View
                            style={[
                              styles.checkbox,
                              isSelected && styles.checkboxChecked,
                            ]}
                          >
                            {isSelected && <Text style={styles.checkmark}>✓</Text>}
                          </View>
                          <View style={styles.taskInfo}>
                            <Text
                              style={[
                                styles.taskTitle,
                                !isSelected && styles.taskTitleDisabled,
                              ]}
                            >
                              {task.title}
                            </Text>
                            {task.description && (
                              <Text style={styles.taskDescription}>{task.description}</Text>
                            )}
                          </View>
                        </View>

                        {frequencyLabel && (
                          <View style={styles.taskMeta}>
                            <View style={styles.frequencyBadge}>
                              <Text style={styles.frequencyText}>{frequencyLabel}</Text>
                            </View>
                            {task.template?.estimatedCostMin !== null &&
                              task.template?.estimatedCostMax !== null && (
                                <Text style={styles.costText}>
                                  Est. ${task.template.estimatedCostMin} - $
                                  {task.template.estimatedCostMax}
                                </Text>
                              )}
                          </View>
                        )}

                        {isSelected && matchingVendors.length > 0 && (
                          <View style={styles.vendorHint}>
                            <Text style={styles.vendorHintText}>
                              {matchingVendors.length} vendor
                              {matchingVendors.length !== 1 ? 's' : ''} available
                            </Text>
                          </View>
                        )}
                      </TouchableOpacity>
                    );
                  })}
                </View>
              );
            })}
          </>
        )}

        {/* Summary */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryText}>
            <Text style={styles.summaryCount}>{selectedCount}</Text> task
            {selectedCount !== 1 ? 's' : ''} will be added to your maintenance schedule.
          </Text>
        </View>

        {/* Buttons */}
        <View style={styles.buttonRow}>
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => router.back()}
            disabled={isSubmitting}
          >
            <Text style={styles.backButtonText}>Back</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.continueButton, isSubmitting && styles.buttonDisabled]}
            onPress={handleContinue}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={styles.continueButtonText}>Continue</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing[6],
  },
  loadingTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginTop: spacing[4],
    textAlign: 'center',
  },
  loadingSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: spacing[2],
    textAlign: 'center',
  },
  progressContainer: {
    marginBottom: spacing[4],
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.slate[200],
    borderRadius: 2,
    marginBottom: spacing[2],
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary[600],
    borderRadius: 2,
  },
  progressText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    textAlign: 'center',
  },
  header: {
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    lineHeight: 20,
  },
  emptyContainer: {
    alignItems: 'center',
    padding: spacing[8],
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing[4],
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: spacing[3],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[1],
  },
  emptySubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    textAlign: 'center',
  },
  categorySection: {
    marginBottom: spacing[4],
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingBottom: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[200],
    marginBottom: spacing[3],
  },
  categoryIcon: {
    fontSize: 18,
  },
  categoryLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  categoryCount: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  taskCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[2],
    borderWidth: 1,
    borderColor: colors.primary[200],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  taskCardDisabled: {
    opacity: 0.6,
    borderColor: colors.slate[200],
  },
  taskHeader: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  checkbox: {
    width: 22,
    height: 22,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: colors.slate[300],
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  checkboxChecked: {
    backgroundColor: colors.primary[600],
    borderColor: colors.primary[600],
  },
  checkmark: {
    color: colors.white,
    fontSize: 14,
    fontWeight: typography.fontWeights.bold,
  },
  taskInfo: {
    flex: 1,
  },
  taskTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  taskTitleDisabled: {
    color: colors.slate[500],
  },
  taskDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 4,
    lineHeight: 16,
  },
  taskMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    marginTop: spacing[3],
    marginLeft: spacing[8],
  },
  frequencyBadge: {
    backgroundColor: colors.slate[100],
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  frequencyText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
  },
  costText: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
  },
  vendorHint: {
    marginTop: spacing[2],
    marginLeft: spacing[8],
  },
  vendorHintText: {
    fontSize: typography.fontSizes.xs,
    color: colors.primary[600],
  },
  summaryCard: {
    padding: spacing[4],
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
    marginBottom: spacing[4],
  },
  summaryText: {
    fontSize: typography.fontSizes.sm,
    color: colors.primary[800],
  },
  summaryCount: {
    fontWeight: typography.fontWeights.bold,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  backButton: {
    flex: 1,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[300],
    alignItems: 'center',
  },
  backButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
  },
  continueButton: {
    flex: 1,
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  continueButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
